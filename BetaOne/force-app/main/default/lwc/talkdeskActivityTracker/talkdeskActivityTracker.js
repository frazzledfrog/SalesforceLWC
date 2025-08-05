import { LightningElement, track, wire } from 'lwc';
import { loadUnifiedStyles } from 'c/unifiedStylesHelper';
import getTalkdeskActivityData from '@salesforce/apex/TalkdeskActivityController.getTalkdeskActivityData';
import getSalespeople from '@salesforce/apex/TalkdeskActivityController.getSalespeople';
import getChannelOptions from '@salesforce/apex/TalkdeskActivityController.getChannelOptions';
import getDirectionOptions from '@salesforce/apex/TalkdeskActivityController.getDirectionOptions';
import getPerformanceInsights from '@salesforce/apex/TalkdeskActivityController.getPerformanceInsights';
import getLastSalesperson from '@salesforce/apex/UserComponentPreferenceService.getLastSalesperson';
import setLastSalesperson from '@salesforce/apex/UserComponentPreferenceService.setLastSalesperson';

export default class TalkdeskActivityTracker extends LightningElement {
    @track selectedSalesperson = '';
    @track selectedChannel = '';
    @track selectedDirection = '';
    @track selectedTimeframe = 'today';
    @track activityData = [];
    @track performanceInsights = {};
    @track salespeople = [];
    @track channelOptions = [];
    @track directionOptions = [];
    @track isLoading = false;
    @track error = null;
    @track preferenceLoaded = false;
    
    componentName = 'TalkdeskActivityTracker';
    dailyGoal = 25;

    timeframeOptions = [
        { label: 'Today', value: 'today' },
        { label: 'This Week', value: 'week' },
        { label: 'This Month', value: 'month' }
    ];

    async connectedCallback() {
        await loadUnifiedStyles(this);
        this.loadPicklistOptions();
    }

    get hasData() {
        return this.activityData && this.activityData.length > 0;
    }

    get showFilters() {
        return this.salespeople && this.salespeople.length > 0;
    }

    get totalCalls() {
        return this.performanceInsights.totalCalls || 0;
    }

    get totalTalkTimeFormatted() {
        return this.performanceInsights.formattedTotalTalkTime || '0:00';
    }

    get averageTalkTimeFormatted() {
        return this.performanceInsights.formattedAvgTalkTime || '0:00';
    }

    get successRate() {
        return this.performanceInsights.successRateFormatted || '0.0%';
    }

    get totalAttempts() {
        return this.performanceInsights.totalAttempts || 0;
    }

    @wire(getSalespeople)
    wiredSalespeople({ error, data }) {
        if (data) {
            this.salespeople = [
                { label: '-- All Salespeople --', value: '' },
                ...data.map(person => ({ 
                    label: person.name, 
                    value: person.id 
                }))
            ];
            if (!this.preferenceLoaded) {
                this.loadLastSalesperson();
            }
        } else if (error) {
            this.error = 'Error loading salespeople: ' + error.body.message;
            console.error('Error getting salespeople', error);
        }
    }

    async loadPicklistOptions() {
        try {
            const [channels, directions] = await Promise.all([
                getChannelOptions(),
                getDirectionOptions()
            ]);
            
            this.channelOptions = [
                { label: '-- All Channels --', value: '' },
                ...channels.map(channel => ({ label: channel, value: channel }))
            ];
            
            this.directionOptions = [
                { label: '-- All Directions --', value: '' },
                ...directions.map(direction => ({ label: direction, value: direction }))
            ];
        } catch (error) {
            console.error('Error loading picklist options:', error);
        }
    }

    loadLastSalesperson() {
        this.preferenceLoaded = true;
        getLastSalesperson({ componentName: this.componentName })
            .then(result => {
                if (result && result !== '') {
                    this.selectedSalesperson = result;
                }
                this.loadActivityData();
            })
            .catch(error => {
                console.error('Error loading last salesperson preference', error);
                this.loadActivityData();
            });
    }

    handleSalespersonChange(event) {
        this.selectedSalesperson = event.detail.value;
        this.saveLastSalesperson();
        this.loadActivityData();
    }

    handleChannelChange(event) {
        this.selectedChannel = event.detail.value;
        this.loadActivityData();
    }

    handleDirectionChange(event) {
        this.selectedDirection = event.detail.value;
        this.loadActivityData();
    }

    handleTimeframeChange(event) {
        this.selectedTimeframe = event.detail.value;
        this.loadActivityData();
    }

    saveLastSalesperson() {
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
        this.isLoading = true;
        this.error = null;

        const params = {
            salespersonId: this.selectedSalesperson || null,
            channel: this.selectedChannel || null,
            direction: this.selectedDirection || null,
            timeframe: this.selectedTimeframe
        };

        Promise.all([
            getTalkdeskActivityData(params),
            getPerformanceInsights({ 
                salespersonId: this.selectedSalesperson || null, 
                timeframe: this.selectedTimeframe 
            })
        ])
        .then(([activityResult, insightsResult]) => {
            this.activityData = activityResult.map(item => ({
                ...item,
                formattedTotalTalkTime: this.formatTime(item.totalTalkTime),
                formattedAverageTalkTime: this.formatTime(item.averageTalkTime),
                channelIcon: this.getChannelIcon(item.channel),
                directionIcon: this.getDirectionIcon(item.direction)
            }));
            
            this.performanceInsights = {
                ...insightsResult,
                formattedTotalTalkTime: this.formatTime(insightsResult.totalTalkTime),
                formattedAvgTalkTime: this.formatTime(insightsResult.avgTalkTime),
                successRateFormatted: insightsResult.successRate ? insightsResult.successRate.toFixed(1) + '%' : '0.0%'
            };
            
            this.isLoading = false;
        })
        .catch(error => {
            this.error = 'Error loading Talkdesk activity data: ' + error.body.message;
            this.isLoading = false;
            console.error('Error getting Talkdesk activity data', error);
        });
    }

    formatTime(seconds) {
        if (!seconds || seconds === 0) return '0:00';
        const totalSeconds = Math.round(seconds);
        const hours = Math.floor(totalSeconds / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        const remainingSeconds = totalSeconds % 60;
        
        if (hours > 0) {
            return `${hours}:${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
        }
        return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
    }

    getChannelIcon(channel) {
        switch (channel?.toLowerCase()) {
            case 'voice': return 'utility:call';
            case 'email': return 'utility:email';
            case 'chat': return 'utility:chat';
            case 'sms': return 'utility:sms';
            default: return 'utility:activity';
        }
    }

    getDirectionIcon(direction) {
        switch (direction?.toLowerCase()) {
            case 'inbound': return 'utility:incoming_call';
            case 'outbound': return 'utility:outbound_call';
            default: return 'utility:call';
        }
    }

    get selectedSalespersonData() {
        if (!this.selectedSalesperson) {
            return {
                salespersonName: 'All Salespeople',
                goalProgress: this.calculateGoalProgress(this.totalCalls)
            };
        }
        
        const selectedPerson = this.salespeople.find(p => p.value === this.selectedSalesperson);
        if (selectedPerson) {
            return {
                salespersonName: selectedPerson.label,
                goalProgress: this.calculateGoalProgress(this.totalCalls)
            };
        }
        
        return null;
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

    get progressOffset() {
        if (!this.selectedSalespersonData) return 282.74;
        
        const progress = Math.min(this.selectedSalespersonData.goalProgress.percentage, 100);
        const circumference = 282.74;
        const offset = circumference - (progress / 100) * circumference;
        
        if (progress > 0 && offset >= circumference) {
            return circumference - 5;
        }
        
        return offset;
    }

    get overflowOffset() {
        if (!this.selectedSalespersonData || !this.selectedSalespersonData.goalProgress.isOverGoal) return 282.74;
        const overflowProgress = Math.min(this.selectedSalespersonData.goalProgress.overflowPercentage, 100);
        const circumference = 282.74;
        return circumference - (overflowProgress / 100) * circumference;
    }

    get progressColor() {
        if (!this.selectedSalespersonData) return '#ef4444';
        
        const progress = this.selectedSalespersonData.goalProgress;

        if (progress.isOverGoal) {
            return '#10b981';
        }
        if (progress.percentage >= 75) {
            return '#10b981';
        }
        if (progress.percentage >= 50) {
            return '#84cc16';
        }
        if (progress.percentage >= 25) {
            return '#f59e0b';
        }
        if (progress.percentage > 0) {
            return '#ef4444';
        }
        return '#ef4444';
    }

    get timeframeLabel() {
        const option = this.timeframeOptions.find(opt => opt.value === this.selectedTimeframe);
        return option ? option.label : 'Today';
    }

    get performanceTrend() {
        if (!this.performanceInsights.totalCalls) return 'stable';
        
        const currentCalls = this.performanceInsights.totalCalls;
        const successRate = parseFloat(this.performanceInsights.successRate);
        
        if (currentCalls >= this.dailyGoal && successRate >= 70) {
            return 'excellent';
        }
        if (currentCalls >= this.dailyGoal * 0.8 && successRate >= 50) {
            return 'good';
        }
        if (currentCalls >= this.dailyGoal * 0.5) {
            return 'improving';
        }
        return 'needs-attention';
    }

    get trendIcon() {
        switch (this.performanceTrend) {
            case 'excellent': return 'utility:success';
            case 'good': return 'utility:trending';
            case 'improving': return 'utility:up';
            case 'needs-attention': return 'utility:warning';
            default: return 'utility:dash';
        }
    }

    get trendColor() {
        switch (this.performanceTrend) {
            case 'excellent': return '#10b981';
            case 'good': return '#84cc16';
            case 'improving': return '#f59e0b';
            case 'needs-attention': return '#ef4444';
            default: return '#6b7280';
        }
    }

    get trendMessage() {
        switch (this.performanceTrend) {
            case 'excellent': return 'Outstanding performance!';
            case 'good': return 'Great work, keep it up!';
            case 'improving': return 'Making good progress';
            case 'needs-attention': return 'Focus on activity goals';
            default: return 'Monitor performance';
        }
    }

    get groupedActivities() {
        const grouped = {};
        
        this.activityData.forEach(activity => {
            const key = activity.salespersonName;
            if (!grouped[key]) {
                grouped[key] = {
                    salespersonName: key,
                    activities: [],
                    totalCalls: 0,
                    totalTalkTime: 0
                };
            }
            
            grouped[key].activities.push(activity);
            grouped[key].totalCalls += activity.totalActivities;
            grouped[key].totalTalkTime += activity.totalTalkTime || 0;
        });
        
        Object.keys(grouped).forEach(key => {
            grouped[key].formattedTotalTalkTime = this.formatTime(grouped[key].totalTalkTime);
            grouped[key].averageTalkTime = grouped[key].totalCalls > 0 ? 
                Math.round(grouped[key].totalTalkTime / grouped[key].totalCalls) : 0;
            grouped[key].formattedAverageTalkTime = this.formatTime(grouped[key].averageTalkTime);
        });
        
        return Object.values(grouped);
    }

    handleExportData() {
        if (!this.hasData) {
            return;
        }

        const csvData = this.generateCSVData();
        const blob = new Blob([csvData], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `talkdesk-activity-${this.selectedTimeframe}-${new Date().toISOString().split('T')[0]}.csv`;
        link.click();
        window.URL.revokeObjectURL(url);
    }

    generateCSVData() {
        const headers = ['Salesperson', 'Channel', 'Direction', 'Account', 'Total Calls', 'Total Talk Time (sec)', 'Average Talk Time (sec)'];
        const rows = this.activityData.map(activity => [
            activity.salespersonName,
            activity.channel,
            activity.direction,
            activity.accountName || 'N/A',
            activity.totalActivities,
            activity.totalTalkTime || 0,
            Math.round(activity.averageTalkTime || 0)
        ]);

        const csvContent = [headers, ...rows]
            .map(row => row.map(field => `"${field}"`).join(','))
            .join('\n');

        return csvContent;
    }

    // Utility method to refresh data
    refreshData() {
        this.loadActivityData();
    }
}
