// Account Assignment View component handles UI logic and data interactions
import { LightningElement, track, wire } from 'lwc';
import getSalesReps from '@salesforce/apex/AccountAssignmentViewController.getSalesReps';
import getAccountsByAssignmentNumber from '@salesforce/apex/AccountAssignmentViewController.getAccountsByAssignmentNumber';

export default class AccountAssignmentView extends LightningElement {
    @track selectedSalesRep = '';
    @track salesRepOptions = [];
    @track groupedAccounts = [];
    @track error;
    @track isLoading = false;

    connectedCallback() {
        this.loadSalesReps();
    }

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

    handleSalesRepChange(event) {
        this.selectedSalesRep = event.detail.value;
        this.loadAccountsForSalesRep();
    }

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

    get hasAccounts() {
        return this.groupedAccounts && this.groupedAccounts.length > 0;
    }

    get selectedSalesRepName() {
        const selectedRep = this.salesRepOptions.find(rep => rep.value === this.selectedSalesRep);
        return selectedRep ? selectedRep.label : '';
    }
}
