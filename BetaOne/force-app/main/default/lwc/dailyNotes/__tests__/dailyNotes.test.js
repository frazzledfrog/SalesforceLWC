import { createElement } from 'lwc';
import DailyNotes from 'c/dailyNotes';

describe('c-daily-notes', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        localStorage.clear();
    });

    it('saves notes to localStorage on change', () => {
        const element = createElement('c-daily-notes', { is: DailyNotes });
        document.body.appendChild(element);

        const textarea = element.shadowRoot.querySelector('lightning-textarea');
        textarea.value = 'Test note';
        textarea.dispatchEvent(new CustomEvent('change'));

        const todayKey = `dailyNotes-${new Date().toISOString().slice(0, 10)}`;
        expect(localStorage.getItem(todayKey)).toBe('Test note');
    });
});
