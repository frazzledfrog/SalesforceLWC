import { LightningElement, track, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import chartjs from '@salesforce/resourceUrl/chartjs';
import getDealerOptions from '@salesforce/apex/DealerDetailController.getDealerOptions';
import getDealerDetails from '@salesforce/apex/DealerDetailController.getDealerDetails';
import getDealerChartDataWithPeriod from '@salesforce/apex/DealerDetailController.getDealerChartDataWithPeriod';

export default class DealerDetailApp extends LightningElement {
    @track dealerOptions = [];
    selectedDealerId = '';
    @track selectedDealer;
    chart;
    chartJsInitialized = false;

    @wire(getDealerOptions)
    wiredDealerOptions({ error, data }) {
        if (data) {
            this.dealerOptions = data.map((d) => ({
                label: `${d.name} (${d.region})`,
                value: d.id
            }));
        } else if (error) {
            // eslint-disable-next-line no-console
            console.error('Error loading dealer options', error);
        }
    }

    renderedCallback() {
        if (this.chartJsInitialized) {
            return;
        }
        loadScript(this, chartjs)
            .then(() => {
                this.chartJsInitialized = true;
            })
            .catch((error) => {
                // eslint-disable-next-line no-console
                console.error('ChartJS failed to load', error);
            });
    }

    handleDealerChange(event) {
        this.selectedDealerId = event.detail.value;
        if (!this.selectedDealerId) {
            this.selectedDealer = undefined;
            return;
        }
        getDealerDetails({ dealerId: this.selectedDealerId })
            .then((result) => {
                this.selectedDealer = result;
                return getDealerChartDataWithPeriod({
                    dealerId: this.selectedDealerId,
                    monthsBack: 12
                });
            })
            .then((chartData) => {
                this.renderChart(chartData);
            })
            .catch((error) => {
                // eslint-disable-next-line no-console
                console.error('Error loading dealer details', error);
                this.selectedDealer = undefined;
            });
    }

    renderChart(data) {
        if (!this.chartJsInitialized) {
            return;
        }
        const canvas = this.template.querySelector('canvas.chart-canvas');
        if (!canvas) {
            return;
        }
        if (this.chart) {
            this.chart.destroy();
        }
        const months = data.monthlyData.map((item) => item.month);
        const deals = data.monthlyData.map((item) => item.dealCount);
        const amounts = data.monthlyData.map((item) => item.totalFinanced);
        this.chart = new window.Chart(canvas, {
            type: 'bar',
            data: {
                labels: months,
                datasets: [
                    {
                        label: 'Deals',
                        data: deals,
                        backgroundColor: '#0066CC80',
                        borderColor: '#0066CC',
                        borderWidth: 1,
                        yAxisID: 'y'
                    },
                    {
                        label: 'Amount',
                        data: amounts,
                        type: 'line',
                        borderColor: '#FF8A00',
                        backgroundColor: '#FF8A0020',
                        borderWidth: 2,
                        yAxisID: 'y1',
                        tension: 0.1
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        position: 'left'
                    },
                    y1: {
                        beginAtZero: true,
                        position: 'right',
                        grid: {
                            drawOnChartArea: false
                        }
                    }
                },
                plugins: {
                    legend: {
                        display: false
                    }
                }
            }
        });
    }

    formatCurrency(value) {
        if (value === null || value === undefined) {
            return '$0';
        }
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0
        }).format(value);
    }

    get formattedTotalFinanced() {
        if (!this.selectedDealer) {
            return '$0';
        }
        return this.formatCurrency(this.selectedDealer.totalFinanced);
    }
}
