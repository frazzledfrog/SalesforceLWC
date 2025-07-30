import { LightningElement, track, wire } from 'lwc';
import { launchConfetti } from './confetti';
import getActivityData from '@salesforce/apex/ActivityController.getActivityData';
import getSalespeople from '@salesforce/apex/ActivityController.getSalespeople';
import getLastSalesperson from '@salesforce/apex/UserComponentPreferenceService.getLastSalesperson';
import setLastSalesperson from '@salesforce/apex/UserComponentPreferenceService.setLastSalesperson';

export default class ActivityTracker extends LightningElement {
    @track selectedSalesperson = '';
    @track activityData = [];
    @track salespeople = [];
    @track isLoading = false;
    @track error = null;
    @track preferenceLoaded = false;
    
    componentName = 'ActivityTracker';
    dailyGoal = 30;

    // Track if confetti has been shown for the current salesperson
    _confettiShownFor = '';

    connectedCallback() {
        // Preference loading will happen after salespeople data is loaded
    }

    get hasData() {
        return this.activityData && this.activityData.length > 0;
    }

    get showFilters() {
        return this.salespeople && this.salespeople.length > 0;
    }

    @wire(getSalespeople)
    wiredSalespeople({ error, data }) {
        if (data) {
            this.salespeople = data.map(person => ({ 
                label: person.name, 
                value: person.id 
            }));
            // Load preference after salespeople data is available
            if (!this.preferenceLoaded) {
                this.loadLastSalesperson();
            }
        } else if (error) {
            this.error = 'Error loading salespeople: ' + error.body.message;
            console.error('Error getting salespeople', error);
        }
    }

    loadLastSalesperson() {
        this.preferenceLoaded = true;
        getLastSalesperson({ componentName: this.componentName })
            .then(result => {
                if (result && result !== '') {
                    this.selectedSalesperson = result;
                } else if (this.salespeople.length > 0) {
                    // Default to first salesperson if no preference or preference was "All"
                    this.selectedSalesperson = this.salespeople[0].value;
                }
                this.loadActivityData();
            })
            .catch(error => {
                console.error('Error loading last salesperson preference', error);
                if (this.salespeople.length > 0) {
                    this.selectedSalesperson = this.salespeople[0].value;
                }
                this.loadActivityData();
            });
    }

    handleSalespersonChange(event) {
        this.selectedSalesperson = event.detail.value;
        this.saveLastSalesperson();
        this.loadActivityData();
    }

    saveLastSalesperson() {
        // Only save if a valid salesperson is selected
        if (this.selectedSalesperson) {
            setLastSalesperson({ 
                componentName: this.componentName, 
                salespersonId: this.selectedSalesperson 
            }).catch(error => {
                console.error('Error saving salesperson preference', error);
            });
        }
    }

    loadActivityData() {
        if (!this.selectedSalesperson) return;
        
        this.isLoading = true;
        this.error = null;

        const params = {
            salespersonId: this.selectedSalesperson,
            eventType: null,
            timeframe: 'today'
        };

        getActivityData(params)
            .then(result => {
                this.activityData = result.map(item => ({
                    ...item,
                    formattedTotal: this.formatNumber(item.totalActivities),
                    averagePerDay: this.calculateAveragePerDay(item.totalActivities),
                    goalProgress: this.calculateGoalProgress(item.totalActivities)
                }));
                this.isLoading = false;

                // Confetti logic: show if rep meets/exceeds goal, only once per rep per load
                const data = this.selectedSalespersonData;
                if (data && data.goalProgress && data.goalProgress.isComplete && this._confettiShownFor !== this.selectedSalesperson) {
                    // Wait for DOM to update, then launch confetti
                    setTimeout(() => launchConfetti(this.template), 100);
                    this._confettiShownFor = this.selectedSalesperson;
                }
                // Reset confetti if rep falls below goal
                if (data && (!data.goalProgress.isComplete) && this._confettiShownFor === this.selectedSalesperson) {
                    this._confettiShownFor = '';
                }
            })
            .catch(error => {
                this.error = 'Error loading activity data: ' + error.body.message;
                this.isLoading = false;
                console.error('Error getting activity data', error);
            });
    }
    renderedCallback() {
        // On initial load, if a rep is already at/over goal, show confetti (only once)
        const data = this.selectedSalespersonData;
        if (data && data.goalProgress && data.goalProgress.isComplete && this._confettiShownFor !== this.selectedSalesperson) {
            setTimeout(() => launchConfetti(this.template), 100);
            this._confettiShownFor = this.selectedSalesperson;
        }
    }

    formatNumber(value) {
        if (value === null || value === undefined) return '0';
        return new Intl.NumberFormat('en-US').format(value);
    }

    calculateAveragePerDay(total) {
        // Since we're only showing today's data, average per day is just the total
        return total ? total.toString() : '0';
    }

    calculateGoalProgress(total) {
        const calls = total || 0;
        const baseProgress = Math.min((calls / this.dailyGoal) * 100, 100);
        const isOverGoal = calls > this.dailyGoal;
        const overflowProgress = isOverGoal ? ((calls - this.dailyGoal) / this.dailyGoal) * 100 : 0;
        
        return {
            percentage: Math.round(baseProgress),
            calls: calls,
            remaining: Math.max(this.dailyGoal - calls, 0),
            isComplete: calls >= this.dailyGoal,
            isOverGoal: isOverGoal,
            overflowPercentage: Math.min(Math.round(overflowProgress), 100)
        };
    }

    get selectedSalespersonData() {
        if (this.activityData.length > 0) {
            return this.activityData[0];
        }
        
        // Create default data when no activity data exists but salesperson is selected
        if (this.selectedSalesperson && this.salespeople.length > 0) {
            const selectedPerson = this.salespeople.find(p => p.value === this.selectedSalesperson);
            if (selectedPerson) {
                return {
                    salespersonName: selectedPerson.label,
                    goalProgress: this.calculateGoalProgress(0)
                };
            }
        }
        
        return null;
    }

    get progressOffset() {
        if (!this.selectedSalespersonData) return 282.74;
        
        const progress = Math.min(this.selectedSalespersonData.goalProgress.percentage, 100);
        const circumference = 282.74; // 2 * PI * 45
        const offset = circumference - (progress / 100) * circumference;
        
        // Debug logging
        console.log('Progress:', progress, 'Offset:', offset, 'Circumference:', circumference);
        
        // Ensure we never return exactly the full circumference for any progress > 0
        if (progress > 0 && offset >= circumference) {
            return circumference - 5; // Show at least a small amount
        }
        
        return offset;
    }

    get overflowOffset() {
        if (!this.selectedSalespersonData || !this.selectedSalespersonData.goalProgress.isOverGoal) return 282.74;
        const overflowProgress = Math.min(this.selectedSalespersonData.goalProgress.overflowPercentage, 100);
        const circumference = 282.74;
        return circumference - (overflowProgress / 100) * circumference;
    }

    get overGoalCalls() {
        if (!this.selectedSalespersonData || !this.selectedSalespersonData.goalProgress.isOverGoal) return 0;
        return this.selectedSalespersonData.goalProgress.calls - this.dailyGoal;
    }

    get timeframeLabel() {
        return 'Today';
    }

    get progressColor() {
        if (!this.selectedSalespersonData) return '#ef4444';
        
        const progress = this.selectedSalespersonData.goalProgress;
        
        if (progress.isOverGoal) {
            return '#10b981'; // Green when over goal
        } else if (progress.percentage >= 75) {
            return '#10b981'; // Green for high progress (75-100%)
        } else if (progress.percentage >= 50) {
            return '#84cc16'; // Yellow-green for medium-high progress (50-75%)
        } else if (progress.percentage >= 25) {
            return '#f59e0b'; // Orange for medium progress (25-50%)
        } else if (progress.percentage > 0) {
            return '#ef4444'; // Red for low progress (1-25%)
        } else {
            return '#ef4444'; // Red for no progress
        }
    }

    get nextCallOffset() {
        if (!this.selectedSalespersonData || this.selectedSalespersonData.goalProgress.isOverGoal) return 282.74;
        
        const currentCalls = this.selectedSalespersonData.goalProgress.calls;
        const nextCallProgress = Math.min(((currentCalls + 1) / this.dailyGoal) * 100, 100);
        const circumference = 282.74;
        const offset = circumference - (nextCallProgress / 100) * circumference;
        
        return offset;
    }


}
