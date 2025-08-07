// Dealer Detail component handles UI logic and data interactions
import { LightningElement, track, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { loadUnifiedStyles } from 'c/unifiedStylesHelper';
import getDealerOptions from '@salesforce/apex/DealerDetailController.getDealerOptions';
import getDealerDetails from '@salesforce/apex/DealerDetailController.getDealerDetails';
import getDealerChartDataWithPeriod from '@salesforce/apex/DealerDetailController.getDealerChartDataWithPeriod';
import getDealerChartDataMax from '@salesforce/apex/DealerDetailController.getDealerChartDataMax';
import getLastDealerId from '@salesforce/apex/UserComponentPreferenceService.getLastDealerId';
import setLastDealerId from '@salesforce/apex/UserComponentPreferenceService.setLastDealerId';
import chartjs from '@salesforce/resourceUrl/chartjs';

export default class DealerDetail extends LightningElement {
    @track selectedDealerId = '';
    @track dealerOptions = [];
    @track selectedDealer = null;
    @track isLoading = false;
    @track isChartLoading = false;
    @track error = null;
    @track searchTerm = '';
    @track filteredDealers = [];
    @track showResults = false;
    @track selectedLookbackPeriod = '12';
    chartJsInitialized = false;
    chart;
    componentName = 'dealerDetail';

    lookbackPeriodOptions = [
        { label: '3 Months', value: '3' },
        { label: '6 Months', value: '6' },
        { label: '12 Months', value: '12' },
        { label: '18 Months', value: '18' },
        { label: '24 Months', value: '24' },
        { label: 'Max', value: 'max' }
    ];

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
            // Add empty option at the beginning for "Choose a dealer"
            this.dealerOptions.unshift({
                label: '-- Select a Dealer --',
                value: '',
                id: '',
                name: '',
                region: ''
            });
            this.loadLastSelectedDealer();
        } else if (error) {
            this.error = 'Error loading dealer options: ' + error.body.message;
            console.error('Error getting dealer options', error);
        }
    }

    async connectedCallback() {
        await loadUnifiedStyles(this);
        this.loadChartLibrary();
    }

    loadLastSelectedDealer() {
        getLastDealerId({ componentName: this.componentName })
            .then(dealerId => {
                if (dealerId && this.dealerOptions.length > 0) {
                    const savedDealer = this.dealerOptions.find(dealer => dealer.id === dealerId);
                    if (savedDealer) {
                        this.selectedDealerId = dealerId;
                        this.loadDealerDetails(dealerId);
                    }
                }
            })
            .catch(error => {
                console.error('Error loading last dealer preference:', error);
            });
    }

    get hasSelectedDealer() {
        return this.selectedDealer !== null && !this.isLoading && !this.error;
    }

    get hasFilteredResults() {
        return this.filteredDealers && this.filteredDealers.length > 0;
    }

    get searchResults() {
        return this.filteredDealers || [];
    }

    get showChart() {
        return this.selectedDealer !== null;
    }

    get showChartLoading() {
        return this.isChartLoading && this.selectedDealer !== null;
    }

    handleSearchInput(event) {
        this.searchTerm = event.target.value;
        this.filterDealers();
    }

    handleInputFocus() {
        if (this.searchTerm && this.searchTerm.length >= 1) {
            this.filterDealers();
        }
    }

    handleInputBlur() {
        setTimeout(() => {
            this.showResults = false;
        }, 300);
    }

    filterDealers() {
        try {
            if (!this.searchTerm || this.searchTerm.length < 1) {
                this.filteredDealers = [];
                this.showResults = false;
                return;
            }

            if (!this.dealerOptions || this.dealerOptions.length === 0) {
                this.filteredDealers = [];
                this.showResults = false;
                return;
            }

            const searchTermLower = this.searchTerm.toLowerCase();
            this.filteredDealers = this.dealerOptions.filter(dealer => {
                const nameMatch = dealer.name && dealer.name.toLowerCase().includes(searchTermLower);
                const labelMatch = dealer.label && dealer.label.toLowerCase().includes(searchTermLower);
                const regionMatch = dealer.region && dealer.region.toLowerCase().includes(searchTermLower);
                return nameMatch || labelMatch || regionMatch;
            }).slice(0, 10);

            this.showResults = this.filteredDealers.length > 0;
        } catch (error) {
            console.error('Error filtering dealers:', error);
            this.filteredDealers = [];
            this.showResults = false;
        }
    }

    handleDealerSelect(event) {
        event.preventDefault();
        const dealerId = event.currentTarget.dataset.dealerId;
        const selectedDealer = this.dealerOptions.find(dealer => dealer.id === dealerId);
        
        if (selectedDealer) {
            this.searchTerm = '';
            this.selectedDealerId = dealerId;
            this.showResults = false;
            this.filteredDealers = [];
            this.loadDealerDetails(dealerId);
            this.saveLastSelectedDealer(dealerId);
        }
    }

    handleLookbackPeriodChange(event) {
        this.selectedLookbackPeriod = event.detail.value;
        if (this.selectedDealerId) {
            this.loadChartData(this.selectedDealerId);
        }
    }

    handleDealerSelection(event) {
        const dealerId = event.detail.value;
        this.selectedDealerId = dealerId;
        
        if (dealerId) {
            this.searchTerm = '';
            this.showResults = false;
            this.filteredDealers = [];
            this.loadDealerDetails(dealerId);
            this.saveLastSelectedDealer(dealerId);
        } else {
            this.selectedDealer = null;
        }
    }

    loadDealerDetails(dealerId) {
        this.isLoading = true;
        this.error = null;
        
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
        // Wait for the next tick to ensure DOM is updated
        setTimeout(() => {
            // Set loading to false first so canvas is available
            this.isChartLoading = false;
            
            // Wait another tick for template to re-render
            setTimeout(() => {
                const canvas = this.template.querySelector('canvas.chart-canvas');
                if (!canvas) {
                    console.error('Canvas not found');
                    this.error = 'Chart canvas element not found';
                    return;
                }

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
                                legend: { display: false }
                            }
                        }
                    });

                } catch (error) {
                    console.error('Chart creation failed:', error);
                    this.error = `Chart rendering failed: ${error.message}`;
                }
            }, 100); // Second timeout to ensure template re-renders
        }, 50); // First timeout for DOM update
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

    saveLastSelectedDealer(dealerId) {
        setLastDealerId({ componentName: this.componentName, dealerId: dealerId })
            .catch(error => {
                console.error('Error saving dealer preference:', error);
            });
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
