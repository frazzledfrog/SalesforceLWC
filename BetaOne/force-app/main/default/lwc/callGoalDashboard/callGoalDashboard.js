import { LightningElement, track } from 'lwc';
import { loadUnifiedStyles } from 'c/unifiedStylesHelper';
import getSalespeople from '@salesforce/apex/ActivityController.getSalespeople';
import getActivityData from '@salesforce/apex/ActivityController.getActivityData';

export default class CallGoalDashboard extends LightningElement {
    @track salespeople = [];
    @track selectedSalesperson = '';
    @track salespersonName = '';

    dailyGoal = 30;
    totalCalls = 30;
    completedCalls = 0;
    radius = 85;

    connectedCallback() {
        loadUnifiedStyles(this);
        this.loadSalespeople();
    }

    loadSalespeople() {
        getSalespeople()
            .then(result => {
                this.salespeople = result;
                if (result && result.length > 0) {
                    this.selectedSalesperson = result[0].id;
                    this.salespersonName = result[0].name;
                    this.loadActivityData();
                }
            })
            .catch(error => {
                // eslint-disable-next-line no-console
                console.error('Error loading salespeople', error);
            });
    }

    loadActivityData() {
        if (!this.selectedSalesperson) return;
        const params = {
            salespersonId: this.selectedSalesperson,
            eventType: null,
            timeframe: 'today'
        };

        getActivityData(params)
            .then(result => {
                const total = result.reduce(
                    (sum, item) => sum + (item.totalActivities || 0),
                    0
                );
                this.completedCalls = total;
                this.totalCalls = this.dailyGoal;
                if (result.length > 0) {
                    this.salespersonName = result[0].salespersonName;
                }
            })
            .catch(error => {
                // eslint-disable-next-line no-console
                console.error('Error loading activity data', error);
            });
    }

    get percentage() {
        return Math.round((this.completedCalls / this.totalCalls) * 100);
    }

    get remaining() {
        return Math.max(this.totalCalls - this.completedCalls, 0);
    }

    get circumference() {
        return 2 * Math.PI * this.radius;
    }

    get strokeDashoffset() {
        return this.circumference - (this.percentage / 100) * this.circumference;
    }

    get progressStyle() {
        return `stroke-dasharray:${this.circumference}; stroke-dashoffset:${this.strokeDashoffset};`;
    }

    get progressBarStyle() {
        return `width:${Math.min(this.percentage, 100)}%`;
    }

    get percentageGreaterEqual50() {
        return this.percentage >= 50;
    }
}
