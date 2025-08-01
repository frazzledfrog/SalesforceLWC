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
            console.log('Account loaded:', data.fields.Name.value);
            // Call findAndLoadAccountDealer with a small delay to ensure other wire methods have executed
            setTimeout(() => this.findAndLoadAccountDealer(), 100);
        } else if (error) {
            this.error = 'Error loading account: ' + (error.body?.message || error.message);
            this.isLoading = false;
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
            console.log('Dealer options loaded:', this.dealerOptions.length, 'dealers');
            // Call findAndLoadAccountDealer with a small delay to ensure other wire methods have executed
            setTimeout(() => this.findAndLoadAccountDealer(), 100);
        } else if (error) {
            this.error = 'Error loading dealer options: ' + (error.body?.message || error.message);
            this.isLoading = false;
            console.error('Error getting dealer options', error);
        }
    }

    connectedCallback() {
        this.loadChartLibrary();
        
        // Start loading timeout - switch to compact mode after 8 seconds
        this.loadingTimeout = setTimeout(() => {
            if (this.isLoading && !this.selectedDealer) {
                console.log('Loading timeout reached, switching to compact mode');
                this.hasTimedOut = true;
                this.isCompactMode = true;
                this.isLoading = false;
                this.error = null; // Don't show error, just go compact
            }
        }, 8000);
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
        
        // Try multiple matching strategies
        let matchingDealer = null;
        
        // Strategy 1: Exact match
        matchingDealer = this.dealerOptions.find(dealer => 
            dealer.name.toLowerCase() === accountName.toLowerCase()
        );
        
        // Strategy 2: Dealer name contains account name
        if (!matchingDealer) {
            matchingDealer = this.dealerOptions.find(dealer => 
                dealer.name.toLowerCase().includes(accountName.toLowerCase())
            );
        }
        
        // Strategy 3: Account name contains dealer name
        if (!matchingDealer) {
            matchingDealer = this.dealerOptions.find(dealer => 
                accountName.toLowerCase().includes(dealer.name.toLowerCase())
            );
        }
        
        // Strategy 4: Partial word matching (remove common words)
        if (!matchingDealer) {
            const cleanAccountName = accountName.toLowerCase()
                .replace(/\b(motor|sales|auto|automotive|ltd|limited|inc|corp|corporation)\b/g, '')
                .trim();
            
            matchingDealer = this.dealerOptions.find(dealer => {
                const cleanDealerName = dealer.name.toLowerCase()
                    .replace(/\b(motor|sales|auto|automotive|ltd|limited|inc|corp|corporation)\b/g, '')
                    .trim();
                
                return cleanDealerName.includes(cleanAccountName) || 
                       cleanAccountName.includes(cleanDealerName);
            });
        }

        if (matchingDealer) {
            console.log('Found matching dealer:', matchingDealer.name);
            this.loadDealerDetails(matchingDealer.id);
        } else {
            console.log('No matching dealer found for:', accountName);
            console.log('Available dealers:', this.dealerOptions.map(d => d.name));
            
            // Set compact mode and stop loading after a short delay
            setTimeout(() => {
                if (!this.selectedDealer) {
                    this.isCompactMode = true;
                    this.isLoading = false;
                    this.error = null; // Don't show error in compact mode
                }
            }, 1000); // Reduced from 2000ms
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

    get chartCanvasStyle() {
        return this.isChartLoading ? 'display: none;' : 'display: block;';
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
        
        console.log('Loading dealer details for ID:', dealerId);
        
        getDealerDetails({ dealerId: dealerId })
            .then(result => {
                console.log('Dealer details loaded successfully:', result);
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
                console.error('Error loading dealer details:', error);
                this.error = 'Error loading dealer details: ' + (error.body?.message || error.message);
                this.isLoading = false;
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
            
            // Set loading to false BEFORE rendering chart so canvas is visible
            this.isChartLoading = false;
            
            // Wait for DOM update then render chart
            setTimeout(() => {
                this.renderChart(chartData);
            }, 100);
            
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
                console.error('Canvas not found - template state:', {
                    hasTemplate: !!this.template,
                    isChartLoading: this.isChartLoading,
                    hasData: !!data
                });
                this.error = 'Chart canvas element not found';
                return;
            }

            console.log('Canvas found, rendering chart with data:', data);

            if (this.chart) {
                this.chart.destroy();
                this.chart = null;
            }

            if (!data?.monthlyData?.length) {
                console.error('Invalid chart data structure:', data);
                this.error = 'Invalid chart data received';
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

            } catch (error) {
                console.error('Chart creation failed:', error);
                this.error = `Chart rendering failed: ${error.message}`;
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
