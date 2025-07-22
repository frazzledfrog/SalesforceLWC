import { LightningElement, wire, track } from 'lwc';
import getRegions from '@salesforce/apex/TopDealersController.getRegions';
import getTopDealers from '@salesforce/apex/TopDealersController.getTopDealers';
import getLastRegion from '@salesforce/apex/UserComponentPreferenceService.getLastRegion';
import setLastRegion from '@salesforce/apex/UserComponentPreferenceService.setLastRegion';
import DealerAccountLink from 'c/dealerAccountLink';

const COMPONENT_NAME = 'topDealers';

export default class TopDealers extends LightningElement {
    @track selectedRegion = '';
    @track regionOptions = [];
    @track dealers = [];
    @track error;
    isLoading = false;

    connectedCallback() {
        getLastRegion({ componentName: COMPONENT_NAME })
            .then(result => {
                if (result) {
                    this.selectedRegion = result;
                    this.loadTopDealers();
                }
            })
            .catch(error => {
                console.error('Error getting last region:', error);
            });
    }

    @wire(getRegions)
    wiredRegions({ error, data }) {
        if (data) {
            this.regionOptions = data.map(region => ({ label: region, value: region }));
        } else if (error) {
            this.error = 'Error loading regions';
            this.regionOptions = [];
        }
    }

    handleRegionChange(event) {
        this.selectedRegion = event.detail.value;
        this.loadTopDealers();
        setLastRegion({ componentName: COMPONENT_NAME, lastRegion: this.selectedRegion })
            .catch(error => {
                console.error('Error setting last region:', error);
            });
    }

    loadTopDealers() {
        this.isLoading = true;
        getTopDealers({ region: this.selectedRegion })
            .then(result => {
                this.dealers = result.map((dealer, index) => ({ ...dealer, rank: index + 1 }));
                this.error = undefined;
            })
            .catch(error => {
                this.error = 'Error loading top dealers';
                this.dealers = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    get hasDealers() {
        return this.dealers && this.dealers.length > 0;
    }
}
