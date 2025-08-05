import { LightningElement, track } from 'lwc';
import getDealerWinnersLosers from '@salesforce/apex/DealerWatchlistController.getDealerWinnersLosers';
import getLastRegion from '@salesforce/apex/UserComponentPreferenceService.getLastRegion';
import setLastRegion from '@salesforce/apex/UserComponentPreferenceService.setLastRegion';
import { withUnifiedStyles } from 'c/unifiedStylesHelper';

const COMPONENT_NAME = 'dealerWatchlist';

/**
 * Shows top winning and losing dealers with region filtering.
 */
export default class DealerWatchlist extends withUnifiedStyles(LightningElement) {
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
        { label: 'Top 25', value: 25 }
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
    }
    
    /**
     * Restore last region preference after styles are applied.
     */
    async connectedCallback() {
        await super.connectedCallback();
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

    /**
     * Update selected region and persist preference.
     */
    handleRegionChange(event) {
        this.selectedRegion = event.detail.value;
        this.fetchWatchlistData(); // Refresh data when region changes
        setLastRegion({ componentName: COMPONENT_NAME, lastRegion: this.selectedRegion })
            .catch(error => {
                console.error('Error setting last region:', error);
            });
    }

    /**
     * Change the number of dealers to display.
     */
    handleLimitChange(event) {
        this.selectedLimit = parseInt(event.detail.value, 10);
        this.fetchWatchlistData();
    }
    
    /**
     * Toggle comparison type between Month-over-Month and Year-over-Year.
     */
    handleComparisonToggle(event) {
        this.comparisonType = event.target.checked ? 'YearOverYear' : 'MonthOverMonth';
        this.fetchWatchlistData();
    }

    /**
     * Retrieve winners and losers data from Apex.
     */
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

    /**
     * Normalize Apex data for template consumption.
     * Each region has: { region, winners: [DealerDelta], losers: [DealerDelta] }
     */
    processWinnersLosersData(data) {
        return data.map(regionData => {
            const processDealer = (dealer, index) => {
                const deltaText = dealer.delta != null ? `$${dealer.delta.toLocaleString(undefined, {maximumFractionDigits: 0})}` : 'N/A';
                const currentText = dealer.mtdAmount != null ? `$${dealer.mtdAmount.toLocaleString(undefined, {maximumFractionDigits: 0})}` : 'N/A';
                const previousText = dealer.prevMonthAmount != null ? `$${dealer.prevMonthAmount.toLocaleString(undefined, {maximumFractionDigits: 0})}` : 'N/A';
                const absDelta = dealer.delta != null ? Math.abs(dealer.delta) : 0;
                const deltaClass = dealer.delta > 0 ? 'delta-positive' : (dealer.delta < 0 ? 'delta-negative' : '');
                
                return {
                    ...dealer,
                    rank: index + 1,
                    deltaText,
                    mtdText: currentText,
                    prevText: previousText,
                    absDelta,
                    deltaClass
                };
            };
            const winners = (regionData.winners || []).map(processDealer);
            const losers = (regionData.losers || []).map(processDealer);
            return {
                name: regionData.region,
                region: regionData.region,
                winners,
                losers,
                hasWinners: winners.length > 0,
                hasLosers: losers.length > 0
            };
        });
    }

    // Getters for template data
    /**
     * Data for the currently selected region.
     */
    get currentRegionData() {
        return this.watchlistData.find(region => region.name === this.selectedRegion) || 
               { winners: [], losers: [] };
    }

    /** List of winning dealers for current region. */
    get winners() {
        return this.currentRegionData.winners || [];
    }

    /** List of losing dealers for current region. */
    get losers() {
        return this.currentRegionData.losers || [];
    }

    /** Whether there are winning dealers to display. */
    get hasWinners() {
        return this.winners.length > 0;
    }

    /** Whether there are losing dealers to display. */
    get hasLosers() {
        return this.losers.length > 0;
    }

    /** Count of winning dealers shown. */
    get winnersCount() {
        return this.winners.length;
    }

    /** Count of losing dealers shown. */
    get losersCount() {
        return this.losers.length;
    }

    get currentPeriodLabel() {
        return this.isYearOverYear ? 'YTD 2025' : 'Current Month';
    }

    get previousPeriodLabel() {
        return this.isYearOverYear ? 'YTD 2024' : 'Previous Month';
    }

    get hasNoData() {
        return !this.hasWinners && !this.hasLosers;
    }
}
