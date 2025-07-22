import { LightningElement } from 'lwc';
import recrateSheetResource from '@salesforce/resourceUrl/recratesheet';

export default class StaticResourceViewer extends LightningElement {
    get resourceUrl() {
        // Add PDF parameters to fit the content to page width
        return `${recrateSheetResource}#zoom=page-fit&toolbar=0&navpanes=0&scrollbar=0&view=FitH`;
    }
}
