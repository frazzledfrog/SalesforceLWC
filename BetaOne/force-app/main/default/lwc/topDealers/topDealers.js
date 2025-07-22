import { LightningElement, wire, track } from 'lwc';
import getRegions from '@salesforce/apex/TopDealersController.getRegions';
import getTopDealers from '@salesforce/apex/TopDealersController.getTopDealers';
import getLastRegion from '@salesforce/apex/UserComponentPreferenceService.getLastRegion';
import setLastRegion from '@salesforce/apex/UserComponentPreferenceService.setLastRegion';

const COMPONENT_NAME = 'topDealers';

export default class TopDealers extends LightningElement {
    @track selectedRegion = '';
    @track regionOptions = [];
    @track dealers = [];
    @track error;
    isLoading = false;

    connectedCallback() {
        this.loadLastRegion();
    }

    async loadLastRegion() {
        try {
            const result = await getLastRegion({ componentName: COMPONENT_NAME });
            if (result) {
                this.selectedRegion = result;
                this.loadTopDealers();
            }
        } catch (error) {
            console.error('Error getting last region:', error);
        }
    }

    @wire(getRegions)
    wiredRegions({ error, data }) {
        if (data) {
            this.regionOptions = data.map(region => ({ label: region, value: region }));
            // If no region selected yet, select the first one
            if (!this.selectedRegion && data.length > 0) {
                this.selectedRegion = data[0];
                this.loadTopDealers();
            }
        } else if (error) {
            this.error = 'Error loading regions';
            this.regionOptions = [];
        }
    }

    handleRegionChange(event) {
        this.selectedRegion = event.detail.value;
        this.loadTopDealers();
        this.saveLastRegion();
    }

    async saveLastRegion() {
        try {
            await setLastRegion({ componentName: COMPONENT_NAME, lastRegion: this.selectedRegion });
        } catch (error) {
            console.error('Error setting last region:', error);
        }
    }

    async loadTopDealers() {
        if (!this.selectedRegion) return;
        
        this.isLoading = true;
        this.error = undefined;
        
        try {
            const result = await getTopDealers({ region: this.selectedRegion });
            this.dealers = this.processDealerData(result);
        } catch (error) {
            this.error = 'Error loading top dealers data';
            this.dealers = [];
            console.error('Error loading dealers:', error);
        } finally {
            this.isLoading = false;
        }
    }

    processDealerData(dealers) {
        if (!dealers || dealers.length === 0) return [];

        // Find the maximum amount for percentage calculation
        const maxAmount = Math.max(...dealers.map(d => d.totalAmount || 0));
        
        return dealers.map((dealer, index) => {
            const rank = index + 1;
            const percentage = maxAmount > 0 ? ((dealer.totalAmount || 0) / maxAmount * 100) : 0;
            
            return {
                ...dealer,
                rank,
                isTop3: rank <= 3,
                isTrophy: rank === 1,
                rankLabel: this.getRankLabel(rank),
                region: dealer.region || this.selectedRegion,
                performancePercentage: percentage,
                performanceLabel: `${Math.round(percentage)}% of top performer`,
                performanceBarStyle: `width: ${percentage}%`,
                isGrowthLeader: this.determineGrowthLeader(dealer, dealers),
                dealCount: dealer.dealCount || null,
                avgDealSize: dealer.totalAmount && dealer.dealCount ? 
                    Math.round(dealer.totalAmount / dealer.dealCount) : null
            };
        });
    }

    getRankLabel(rank) {
        const labels = {
            1: 'Champion',
            2: 'Runner-up',
            3: 'Third Place'
        };
        return labels[rank] || '';
    }

    determineGrowthLeader(dealer, allDealers) {
        // Simple logic - could be enhanced with actual growth data
        if (!dealer.dealCount || allDealers.length < 2) return false;
        
        const avgDeals = allDealers.reduce((sum, d) => sum + (d.dealCount || 0), 0) / allDealers.length;
        return dealer.dealCount > avgDeals * 1.2; // 20% above average
    }

    get hasDealers() {
        return this.dealers && this.dealers.length > 0;
    }

    get top5Dealers() {
        return this.dealers ? this.dealers.slice(0, 5) : [];
    }

    get componentTitle() {
        return this.selectedRegion ? `Top Performers - ${this.selectedRegion}` : 'Top Performers';
    }

    renderedCallback() {
        // Set performance bar widths after render
        const performanceBars = this.template.querySelectorAll('.performance-bar');
        performanceBars.forEach((bar, index) => {
            const dealer = this.dealers[index];
            if (dealer) {
                bar.style.width = `${dealer.performancePercentage}%`;
            }
        });
    }
}
