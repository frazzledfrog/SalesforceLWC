import { LightningElement, track } from 'lwc';

export default class DailyNotes extends LightningElement {
    @track notes = '';
    todayKey;

    connectedCallback() {
        const today = new Date().toISOString().slice(0, 10);
        this.todayKey = `dailyNotes-${today}`;
        this.notes = localStorage.getItem(this.todayKey) || '';
    }

    handleChange(event) {
        this.notes = event.target.value;
        localStorage.setItem(this.todayKey, this.notes);
    }

    get today() {
        return new Date().toLocaleDateString();
    }
}
