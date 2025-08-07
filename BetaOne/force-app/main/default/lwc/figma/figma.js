// Figma component handles UI logic and data interactions
import { LightningElement } from 'lwc';
import { loadUnifiedStyles } from 'c/unifiedStylesHelper';

export default class Figma extends LightningElement {
    
    async connectedCallback() {
        // Load unified styles
        await loadUnifiedStyles(this);
    }
}
