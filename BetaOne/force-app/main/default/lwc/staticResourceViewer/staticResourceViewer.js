// Static Resource Viewer component handles UI logic and data interactions
import { LightningElement } from 'lwc';
import recrateSheetResource from '@salesforce/resourceUrl/recratesheet';
import { loadUnifiedStyles } from 'c/unifiedStylesHelper';

export default class StaticResourceViewer extends LightningElement {
    
    get pdfUrl() {
        return recrateSheetResource;
    }

    connectedCallback() {
        loadUnifiedStyles(this);
    }
}

