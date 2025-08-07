import { LightningElement } from 'lwc';
import { loadUnifiedStyles } from 'c/unifiedStylesHelper';

export default class CallGoalDashboard extends LightningElement {
    totalCalls = 30;
    completedCalls = 13;
    radius = 85;

    connectedCallback() {
        loadUnifiedStyles(this);
    }

    get percentage() {
        return Math.round((this.completedCalls / this.totalCalls) * 100);
    }

    get remaining() {
        return this.totalCalls - this.completedCalls;
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
        return `width:${this.percentage}%`;
    }

    get percentageGreaterEqual50() {
        return this.percentage >= 50;
    }
}
