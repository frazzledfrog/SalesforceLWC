// Top Dealers Compact component handles UI logic and data interactions
import { LightningElement, wire, track } from 'lwc';
import getTopDealersWithLimit from '@salesforce/apex/TopDealersController.getTopDealersWithLimit';
import getRegions from '@salesforce/apex/TopDealersController.getRegions';
import findAccountByDealerName from '@salesforce/apex/TopDealersController.findAccountByDealerName';
import { loadUnifiedStyles } from 'c/unifiedStylesHelper';

export default class TopDealersCompact extends LightningElement {
    @track dealers;
    @track error;
    @track region = 'Ontario';
    @track regionOptions = [];
    @track viewLimit = 5; // 5,10 or null for all
    viewOptions = [
        { label: 'Top 5', value: '5' },
        { label: 'Top 10', value: '10' },
        { label: 'All', value: 'all' }
    ];

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

    @wire(getTopDealersWithLimit, { region: '$region', limitCount: '$computedLimit' })
    async wiredDealers({ error, data }) {
        if (data) {
            await this.populateDealers(data);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.dealers = undefined;
        }
    }

    get computedLimit() {
        return this.viewLimit === null ? null : this.viewLimit; // reactive param
    }

    get viewLimitDisplay() {
        return this.viewLimit === null ? 'all' : String(this.viewLimit);
    }

    async populateDealers(data) {
        const regionTotal = data.length ? data[0].regionTotal : 0;
        const dealersWithLinks = await Promise.all(
            data.map(async (dealer, idx) => {
                let accountLink;
                try {
                    const account = await findAccountByDealerName({ dealerName: dealer.accountName });
                    if (account && account.accountId) {
                        accountLink = `/lightning/r/Account/${account.accountId}/view`;
                    }
                } catch (e) {}
                const share = regionTotal ? (dealer.totalAmount / regionTotal) * 100 : 0;
                const shareFixed = share.toFixed(1);
                return {
                    rank: idx + 1,
                    Name: dealer.accountName,
                    Metric: dealer.totalAmount,
                    MetricFormatted: this.abbreviateCurrency(dealer.totalAmount),
                    MetricFull: this.formatCurrency(dealer.totalAmount),
                    SharePercent: shareFixed,
                    ShareTooltip: shareFixed + '% of region total',
                    accountLink
                };
            })
        );
        this.dealers = dealersWithLinks;
    }

    handleRegionChange(event) {
        this.region = event.detail.value;
    }

    handleViewChange(event) {
        const val = event.detail.value;
        if (val === 'all') {
            this.viewLimit = null; // null means all
        } else {
            this.viewLimit = parseInt(val, 10);
        }
    }

    abbreviateCurrency(amount) {
        if (amount === null || amount === undefined) return '';
        const abs = Math.abs(amount);
        if (abs >= 1_000_000_000) return (amount / 1_000_000_000).toFixed(1) + 'B';
        if (abs >= 1_000_000) return (amount / 1_000_000).toFixed(1) + 'M';
        if (abs >= 1_000) return (amount / 1_000).toFixed(1) + 'k';
        return this.formatCurrency(amount);
    }

    formatCurrency(amount) {
        if (amount === null || amount === undefined) return '';
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 2 }).format(amount);
    }
}
