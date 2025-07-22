import { LightningElement, track, api, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { getRecord } from 'lightning/uiRecordApi';
import getDealerOptions from '@salesforce/apex/DealerDetailController.getDealerOptions';
import getDealerDetails from '@salesforce/apex/DealerDetailController.getDealerDetails';
import getDealerChartDataWithPeriod from '@salesforce/apex/DealerDetailController.getDealerChartDataWithPeriod';
import getDealerChartDataMax from '@salesforce/apex/DealerDetailController.getDealerChartDataMax';
import chartjs from '@salesforce/resourceUrl/chartjs';

const ACCOUNT_FIELDS = ['Account.Name'];

export default class DealerDetailAccount extends LightningElement {
    @api recordId; // Account ID from the record page
    @track selectedDealer = null;
    @track isLoading = true; // Start with loading state
    @track isChartLoading = false;
    @track error = null;
    @track selectedLookbackPeriod = '12';
    @track dealerOptions = [];
    @track account = null;
    @track isCompactMode = false; // New property for compact mode
    @track hasTimedOut = false; // Track if loading has timed out
    chartJsInitialized = false;
    chart;
    loadingTimeout; // Store timeout reference

    lookbackPeriodOptions = [
        { label: '3 Months', value: '3' },
        { label: '6 Months', value: '6' },
        { label: '12 Months', value: '12' },
        { label: '18 Months', value: '18' },
        { label: '24 Months', value: '24' },
        { label: 'Max', value: 'max' }
    ];

    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.account = { data };
            this.findAndLoadAccountDealer();
        } else if (error) {
            this.error = 'Error loading account: ' + error.body.message;
            console.error('Error getting account', error);
        }
    }

    @wire(getDealerOptions)
    wiredDealerOptions({ error, data }) {
        if (data) {
            this.dealerOptions = data.map(dealer => ({
                label: `${dealer.name} (${dealer.region})`,
                value: dealer.id,
                id: dealer.id,
                name: dealer.name,
                region: dealer.region
            }));
            this.findAndLoadAccountDealer();
        } else if (error) {
            this.error = 'Error loading dealer options: ' + error.body.message;
            console.error('Error getting dealer options', error);
        }
    }

    connectedCallback() {
        this.loadChartLibrary();
        
        // Start loading timeout - switch to compact mode after 8 seconds
        this.loadingTimeout = setTimeout(() => {
            if (this.isLoading) {
                this.hasTimedOut = true;
                this.isCompactMode = true;
                this.isLoading = false;
                if (!this.selectedDealer && !this.error) {
                    this.error = null; // Don't show error, just go compact
                }
            }
        }, 8000);
        
        // Add a small delay to ensure all wired data is processed
        setTimeout(() => {
            this.findAndLoadAccountDealer();
        }, 500);
    }

    disconnectedCallback() {
        // Clean up timeout when component is destroyed
        if (this.loadingTimeout) {
            clearTimeout(this.loadingTimeout);
        }
    }

    findAndLoadAccountDealer() {
        // Ensure both account data and dealer options are loaded
        if (!this.account?.data?.fields?.Name?.value || !this.dealerOptions.length) {
            console.log('Waiting for data...', {
                hasAccount: !!this.account?.data?.fields?.Name?.value,
                hasDealerOptions: this.dealerOptions.length > 0,
                accountName: this.account?.data?.fields?.Name?.value
            });
            return;
        }

        const accountName = this.account.data.fields.Name.value;
        console.log('Attempting to match account:', accountName, 'with dealers:', this.dealerOptions.length);
        
        // Try to find a matching dealer by account name
        const matchingDealer = this.dealerOptions.find(dealer => 
            dealer.name.toLowerCase().includes(accountName.toLowerCase()) ||
            accountName.toLowerCase().includes(dealer.name.toLowerCase())
        );

        if (matchingDealer) {
            console.log('Found matching dealer:', matchingDealer.name);
            this.loadDealerDetails(matchingDealer.id);
        } else {
            console.log('No matching dealer found for:', accountName);
            // Set compact mode and stop loading after timeout
            setTimeout(() => {
                if (!this.selectedDealer) {
                    this.isCompactMode = true;
                    this.isLoading = false;
                    this.error = null; // Don't show error in compact mode
                }
            }, 2000);
        }
    }

    retryFindDealer(accountName) {
        const matchingDealer = this.dealerOptions.find(dealer => 
            dealer.name.toLowerCase().includes(accountName.toLowerCase()) ||
            accountName.toLowerCase().includes(dealer.name.toLowerCase())
        );

        if (matchingDealer) {
            console.log('Found matching dealer on retry:', matchingDealer.name);
            this.loadDealerDetails(matchingDealer.id);
        } else {
            this.error = `No dealer data found for account: ${accountName}. Available dealers: ${this.dealerOptions.map(d => d.name).join(', ')}`;
        }
    }

    get hasDealer() {
        return this.selectedDealer !== null && !this.isLoading && !this.error;
    }

    get showChart() {
        return this.selectedDealer !== null;
    }

    get showChartLoading() {
        return this.isChartLoading && this.selectedDealer !== null;
    }

    get showCompactMode() {
        return this.isCompactMode && !this.selectedDealer;
    }

    get showFullContent() {
        return !this.isCompactMode && this.hasDealer;
    }

    get containerClass() {
        let classes = 'card';
        if (this.isCompactMode) {
            classes += ' compact-mode';
        }
        return classes;
    }

    handleLookbackPeriodChange(event) {
        this.selectedLookbackPeriod = event.detail.value;
        if (this.selectedDealer) {
            this.loadChartData(this.selectedDealer.id);
        }
    }

    loadDealerDetails(dealerId) {
        this.isLoading = true;
        this.error = null;
        this.isCompactMode = false; // Exit compact mode when data is found
        
        // Clear the loading timeout since we found data
        if (this.loadingTimeout) {
            clearTimeout(this.loadingTimeout);
        }
        
        if (this.chart) {
            this.chart.destroy();
            this.chart = null;
        }
        
        getDealerDetails({ dealerId: dealerId })
            .then(result => {
                this.selectedDealer = {
                    ...result,
                    totalFinancedAmount: this.formatCurrency(result.totalFinancedAmount),
                    averageDealSize: this.formatCurrency(result.averageDealSize),
                    monthlyAmountFinanced: this.formatCurrency(result.monthlyAmountFinanced),
                    lastMonthAmountFinanced: this.formatCurrency(result.lastMonthAmountFinanced),
                    projectedMonthEndAmount: this.formatCurrency(result.projectedMonthEndAmount),
                    performanceChange: this.formatPercentage(result.performanceChange)
                };
                this.isLoading = false;
                this.loadChartData(dealerId);
            })
            .catch(error => {
                this.error = 'Error loading dealer details: ' + error.body.message;
                this.isLoading = false;
                console.error('Error getting dealer details', error);
            });
    }

    async loadChartData(dealerId) {
        this.isChartLoading = true;
        
        try {
            if (!this.chartJsInitialized) {
                await loadScript(this, chartjs);
                this.chartJsInitialized = true;
            }
            
            await new Promise(resolve => setTimeout(resolve, 100));
            
            let chartData;
            if (this.selectedLookbackPeriod === 'max') {
                chartData = await getDealerChartDataMax({ dealerId: dealerId });
            } else {
                const monthsBack = parseInt(this.selectedLookbackPeriod, 10);
                chartData = await getDealerChartDataWithPeriod({ 
                    dealerId: dealerId, 
                    monthsBack: monthsBack 
                });
            }
            
            if (!chartData || !chartData.monthlyData || chartData.monthlyData.length === 0) {
                console.error('No chart data available');
                this.error = 'No chart data available for this dealer';
                this.isChartLoading = false;
                return;
            }
            
            this.renderChart(chartData);
            
        } catch (error) {
            console.error('Chart loading failed:', error);
            this.error = `Chart error: ${error.body?.message || error.message}`;
            this.isChartLoading = false;
        }
    }

    renderChart(data) {
        setTimeout(() => {
            const canvas = this.template.querySelector('canvas.chart-canvas');
            if (!canvas) {
                console.error('Canvas not found');
                this.error = 'Chart canvas element not found';
                this.isChartLoading = false;
                return;
            }

            if (this.chart) {
                this.chart.destroy();
                this.chart = null;
            }

            if (!data?.monthlyData?.length) {
                console.error('Invalid chart data structure:', data);
                this.error = 'Invalid chart data received';
                this.isChartLoading = false;
                return;
            }

            const months = data.monthlyData.map(item => item.month || 'Unknown');
            const deals = data.monthlyData.map(item => item.dealCount || 0);
            const amounts = data.monthlyData.map(item => item.totalFinanced || 0);

            try {
                this.chart = new window.Chart(canvas, {
                    type: 'bar',
                    data: {
                        labels: months,
                        datasets: [{
                            label: 'Number of Deals',
                            data: deals,
                            backgroundColor: '#0066CC80',
                            borderColor: '#0066CC',
                            borderWidth: 1,
                            yAxisID: 'y'
                        }, {
                            label: 'Amount Financed ($)',
                            data: amounts,
                            type: 'line',
                            borderColor: '#FF8A00',
                            backgroundColor: '#FF8A0020',
                            borderWidth: 2,
                            fill: false,
                            yAxisID: 'y1',
                            tension: 0.1
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        animation: { duration: 300 },
                        scales: {
                            y: {
                                beginAtZero: true,
                                position: 'left',
                                title: { display: true, text: 'Deals' }
                            },
                            y1: {
                                beginAtZero: true,
                                position: 'right',
                                title: { display: true, text: 'Amount ($)' },
                                grid: { drawOnChartArea: false },
                                ticks: {
                                    callback: function(value) {
                                        return '$' + new Intl.NumberFormat('en-US').format(value);
                                    }
                                }
                            }
                        },
                        plugins: {
                            legend: { display: true, position: 'top' }
                        }
                    }
                });

                this.isChartLoading = false;

            } catch (error) {
                console.error('Chart creation failed:', error);
                this.error = `Chart rendering failed: ${error.message}`;
                this.isChartLoading = false;
            }
        }, 50);
    }

    formatCurrency(value) {
        if (value === null || value === undefined) return '$0';
        return new Intl.NumberFormat('en-CA', {
            style: 'currency',
            currency: 'CAD',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(value);
    }

    formatPercentage(value) {
        if (value === null || value === undefined) return '0';
        return Math.round(value * 100) / 100;
    }

    async loadChartLibrary() {
        try {
            await loadScript(this, chartjs);
            this.chartJsInitialized = true;
        } catch (error) {
            console.error('Error loading Chart.js', error);
        }
    }
}
