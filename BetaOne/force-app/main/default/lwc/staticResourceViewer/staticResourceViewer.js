import { LightningElement } from 'lwc';
import { withUnifiedStyles } from 'c/unifiedStylesHelper';
import recrateSheetResource from '@salesforce/resourceUrl/recratesheet';

/**
 * Displays a PDF static resource in an iframe with shared styling.
 */
export default class StaticResourceViewer extends withUnifiedStyles(LightningElement) {
    /**
     * URL of the static resource to display.
     */
    get pdfUrl() {
        return recrateSheetResource;
    }
}

