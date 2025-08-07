// Dealer Account Link component handles UI logic and data interactions
import { LightningElement, api, wire } from 'lwc';
import findAccountByDealerName from '@salesforce/apex/TopDealersController.findAccountByDealerName';

export default class DealerAccountLink extends LightningElement {
    @api dealerName;
    accountId;
    accountName;
    error;

    @wire(findAccountByDealerName, { dealerName: '$dealerName' })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountId = data.accountId;
            this.accountName = data.accountName;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.accountId = undefined;
            this.accountName = undefined;
        }
    }

    get accountUrl() {
        return this.accountId ? `/lightning/r/Account/${this.accountId}/view` : null;
    }
}
