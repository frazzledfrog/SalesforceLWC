import { LightningElement, track } from 'lwc';
import getDealerWinnersLosers from '@salesforce/apex/DealerWatchlistController.getDealerWinnersLosers';
import getLastRegion from '@salesforce/apex/UserComponentPreferenceService.getLastRegion';
import setLastRegion from '@salesforce/apex/UserComponentPreferenceService.setLastRegion';

const COMPONENT_NAME = 'dealerWatchlist';

export default class DealerWatchlist extends LightningElement {
    @track watchlistData = [];
    @track isLoading = false;
    @track selectedRegion = 'Ontario';
    @track selectedLimit = 10;
    @track comparisonType = 'MonthOverMonth'; // New property for comparison type
    
    regionOptions = [
        { label: 'Ontario', value: 'Ontario' },
        { label: 'Alberta', value: 'Alberta' },
        { label: 'Quebec', value: 'Quebec' },
        { label: 'Atlantic', value: 'Atlantic' },
        { label: 'Western', value: 'Western' }
    ];
    
    limitOptions = [
        { label: 'Top 5', value: 5 },
        { label: 'Top 10', value: 10 },
        { label: 'Top 15', value: 15 },
        { label: 'Top 25', value: 25 },
        { label: 'All', value: 999 }
    ];
    
    // New getter for comparison type toggle
    get isYearOverYear() {
        return this.comparisonType === 'YearOverYear';
    }
    
    get bannerSubtitle() {
        const comparison = this.isYearOverYear ? 'YTD vs 2024 Comparison' : 'Month over Month Comparison';
        return `Winners & Losers • Recreational Business Line • ${comparison}`;
    }
    
    get toggleLabel() {
        return this.isYearOverYear ? 'Year over Year' : 'Month over Month';
    }    connectedCallback() {
        getLastRegion({ componentName: COMPONENT_NAME })
            .then(result => {
                if (result && this.regionOptions.some(option => option.value === result)) {
                    this.selectedRegion = result;
                } else {
                    this.selectedRegion = 'Ontario';
                }
                this.fetchWatchlistData();
            })
            .catch(error => {
                console.error('Error getting last region:', error);
                this.selectedRegion = 'Ontario';
                this.fetchWatchlistData();
            });
    }

    handleRegionChange(event) {
        this.selectedRegion = event.detail.value;
        setLastRegion({ componentName: COMPONENT_NAME, lastRegion: this.selectedRegion })
            .catch(error => {
                console.error('Error setting last region:', error);
            });
    }

    handleLimitChange(event) {
        this.selectedLimit = parseInt(event.detail.value);
        this.fetchWatchlistData();
    }
    
    handleComparisonToggle(event) {
        this.comparisonType = event.target.checked ? 'YearOverYear' : 'MonthOverMonth';
        this.fetchWatchlistData();
    }

    async fetchWatchlistData() {
        this.isLoading = true;
        try {
            const data = await getDealerWinnersLosers({ 
                maxResults: this.selectedLimit,
                comparisonType: this.comparisonType
            });
            this.watchlistData = this.processWinnersLosersData(data);
        } catch (error) {
            console.error('Error fetching winners/losers data:', error);
        } finally {
            this.isLoading = false;
        }
    }

    processWinnersLosersData(data) {
        // Each region has: { region, winners: [DealerDelta], losers: [DealerDelta] }
        return data.map(regionData => {
            const processDealer = dealer => {
                const deltaText = dealer.delta != null ? `$${dealer.delta.toLocaleString(undefined, {maximumFractionDigits: 0})}` : 'N/A';
                const currentText = dealer.mtdAmount != null ? `$${dealer.mtdAmount.toLocaleString(undefined, {maximumFractionDigits: 0})}` : 'N/A';
                const previousText = dealer.prevMonthAmount != null ? `$${dealer.prevMonthAmount.toLocaleString(undefined, {maximumFractionDigits: 0})}` : 'N/A';
                const absDelta = dealer.delta != null ? Math.abs(dealer.delta) : 0;
                const deltaClass = dealer.delta > 0 ? 'delta-positive' : (dealer.delta < 0 ? 'delta-negative' : '');
                
                // Dynamic labels based on comparison type
                const currentLabel = this.isYearOverYear ? 'YTD' : 'MTD';
                const previousLabel = this.isYearOverYear ? '2024' : 'Prev';
                
                return {
                    ...dealer,
                    deltaText,
                    mtdText: currentText, // Keep same property name for template compatibility
                    prevText: previousText, // Keep same property name for template compatibility
                    currentLabel,
                    previousLabel,
                    absDelta,
                    deltaClass
                };
            };
            const winners = (regionData.winners || []).map(processDealer);
            const losers = (regionData.losers || []).map(processDealer);
            return {
                name: regionData.region, // Map 'region' property to 'name'
                region: regionData.region,
                winners,
                losers,
                hasWinners: winners.length > 0,
                hasLosers: losers.length > 0
            };
        });
    }

    get filteredRegions() {
        if (this.selectedRegion === 'All') {
            return this.watchlistData;
        }
        return this.watchlistData.filter(region => region.name === this.selectedRegion);
    }

    get hasNoData() {
        // No winners or losers in any region
        return this.filteredRegions.every(region => !region.hasWinners && !region.hasLosers);
    }
}
