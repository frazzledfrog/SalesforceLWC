// Top Dealers Compact component handles UI logic and data interactions
import { LightningElement, wire, track } from 'lwc';
import getTopDealers from '@salesforce/apex/TopDealersController.getTopDealers';
import getRegions from '@salesforce/apex/TopDealersController.getRegions';
import { loadUnifiedStyles } from 'c/unifiedStylesHelper';

export default class TopDealersCompact extends LightningElement {
    @track dealers;
    @track error;
    @track region = 'Ontario';
    @track regionOptions = [];

    async connectedCallback() {
        // Load unified styles
        await loadUnifiedStyles(this);
        
        getRegions()
            .then((result) => {
                this.regionOptions = result.map(region => ({ label: region, value: region }));
            })
            .catch(() => {
                this.regionOptions = [
                    { label: 'Ontario', value: 'Ontario' },
                    { label: 'Alberta', value: 'Alberta' },
                    { label: 'Quebec', value: 'Quebec' },
                    { label: 'Atlantic', value: 'Atlantic' },
                    { label: 'British Columbia', value: 'British Columbia' },
                    { label: 'Saskatchewan', value: 'Saskatchewan' },
                    { label: 'Manitoba', value: 'Manitoba' }
                ];
            });
    }

    @wire(getTopDealers, { region: '$region' })
    wiredDealers({ error, data }) {
        if (data) {
            this.dealers = data.map((dealer, idx) => ({
                ...dealer,
                rank: idx + 1,
                Name: dealer.accountName,
                Metric: dealer.totalAmount,
                MetricFormatted: this.formatCurrency(dealer.totalAmount)
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.dealers = undefined;
        }
    }

    handleRegionChange(event) {
        this.region = event.detail.value;
    }

    formatCurrency(amount) {
        if (amount === null || amount === undefined) return '';
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 2 }).format(amount);
    }
}
