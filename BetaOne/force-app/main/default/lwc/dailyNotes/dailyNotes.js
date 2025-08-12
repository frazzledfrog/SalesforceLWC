import { LightningElement, track } from 'lwc';
import { loadUnifiedStyles } from 'c/unifiedStylesHelper';

export default class DailyNotes extends LightningElement {
    @track notes = '';
    todayKey;

    async connectedCallback() {
        try { await loadUnifiedStyles(this); } catch(e) { /* noop */ }
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
