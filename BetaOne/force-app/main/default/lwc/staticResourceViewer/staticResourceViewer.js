import { LightningElement } from 'lwc';
import { loadUnifiedStyles } from 'c/unifiedStylesHelper';
import recrateSheetResource from '@salesforce/resourceUrl/recratesheet';

export default class StaticResourceViewer extends LightningElement {
    async connectedCallback() {
        await loadUnifiedStyles(this);
    }

    Unified-Styles---Codex
    get pdfUrl() {
        return recrateSheetResource;
    }
}

