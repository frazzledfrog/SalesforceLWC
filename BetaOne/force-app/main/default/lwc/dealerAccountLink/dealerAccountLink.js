import { LightningElement, api, wire } from 'lwc';
import { loadUnifiedStyles } from 'c/unifiedStylesHelper';
Unified-Styles---Codex
import findAccountByDealerName from '@salesforce/apex/TopDealersController.findAccountByDealerName';

/**
 * Finds a Salesforce Account record that matches a dealer name and exposes a link.
 */
export default class DealerAccountLink extends withUnifiedStyles(LightningElement) {
    @api dealerName;
    accountId;
    accountName;
    error;

    async connectedCallback() {
        await loadUnifiedStyles(this);
    }

    @wire(findAccountByDealerName, { dealerName: '$dealerName' })
    /**
     * Wire adapter to look up an Account by dealer name.
     */
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

    /**
     * Link to the matched Account record.
     */
    get accountUrl() {
        return this.accountId ? `/lightning/r/Account/${this.accountId}/view` : null;
    }
}
