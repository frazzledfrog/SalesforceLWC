import { LightningElement, track } from 'lwc';
import { withUnifiedStyles } from 'c/unifiedStylesHelper';
import getSalesReps from '@salesforce/apex/AccountAssignmentViewController.getSalesReps';
import getAccountsByAssignmentNumber from '@salesforce/apex/AccountAssignmentViewController.getAccountsByAssignmentNumber';

/**
 * Displays accounts grouped by assignment for a selected sales representative.
 */
export default class AccountAssignmentView extends withUnifiedStyles(LightningElement) {
    @track selectedSalesRep = '';
    @track salesRepOptions = [];
    @track groupedAccounts = [];
    @track error;
    @track isLoading = false;

    /**
     * Initialize component after styles load.
     */
    async connectedCallback() {
        await super.connectedCallback();
        this.loadSalesReps();
    }

    /**
     * Retrieve sales representative options for the picklist.
     */
    loadSalesReps() {
        getSalesReps()
            .then(result => {
                this.salesRepOptions = result.map(rep => ({
                    label: rep.name,
                    value: rep.id
                }));
                // Auto-select first sales rep if available
                if (this.salesRepOptions.length > 0 && !this.selectedSalesRep) {
                    this.selectedSalesRep = this.salesRepOptions[0].value;
                    this.loadAccountsForSalesRep();
                }
            })
            .catch(error => {
                this.error = 'Error loading sales reps: ' + error.body.message;
                console.error('Error loading sales reps:', error);
            });
    }

    /**
     * Handle changes to the selected sales representative.
     *
     * @param {Event} event - Change event from the picklist.
     */
    handleSalesRepChange(event) {
        this.selectedSalesRep = event.detail.value;
        this.loadAccountsForSalesRep();
    }

    /**
     * Load accounts for the currently selected sales representative.
     */
    loadAccountsForSalesRep() {
        if (!this.selectedSalesRep) return;

        this.isLoading = true;
        this.error = null;

        getAccountsByAssignmentNumber({ salesRepId: this.selectedSalesRep })
            .then(result => {
                // Add record URLs to each account
                this.groupedAccounts = result.map(group => ({
                    ...group,
                    accounts: group.accounts.map(account => ({
                        ...account,
                        recordUrl: `/lightning/r/Account/${account.id}/view`
                    }))
                }));
                this.isLoading = false;
            })
            .catch(error => {
                this.error = 'Error loading accounts: ' + error.body.message;
                this.isLoading = false;
                console.error('Error loading accounts:', error);
            });
    }

    /**
     * Whether any account groups exist for rendering.
     */
    get hasAccounts() {
        return this.groupedAccounts && this.groupedAccounts.length > 0;
    }

    /**
     * Friendly label for the currently selected sales representative.
     */
    get selectedSalesRepName() {
        const selectedRep = this.salesRepOptions.find(rep => rep.value === this.selectedSalesRep);
        return selectedRep ? selectedRep.label : '';
    }
}
