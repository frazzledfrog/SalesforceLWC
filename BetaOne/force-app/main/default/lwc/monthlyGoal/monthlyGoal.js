import { LightningElement, track, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { withUnifiedStyles } from 'c/unifiedStylesHelper';
import chartjs from '@salesforce/resourceUrl/chartjs';
import getSalesData from '@salesforce/apex/SalesDataService.getSalesData';
import getRegions from '@salesforce/apex/SalesDataService.getRegions';
import getLastRegion from '@salesforce/apex/UserComponentPreferenceService.getLastRegion';
import setLastRegion from '@salesforce/apex/UserComponentPreferenceService.setLastRegion';

/**
 * Renders a chart showing monthly sales progress by region.
 */
export default class MonthlyGoal extends withUnifiedStyles(LightningElement) {
    @track selectedRegion;
    @track regionOptions = [];
    @track isLoading = true;
    @track cardTitle = '';
    chart;
    chartjsInitialized = false;
    pulseInterval;

    /**
     * Set up component after styles are loaded.
     */
    async connectedCallback() {
        await super.connectedCallback();
        this.cardTitle = `${this.getCurrentMonth()} Target Progress`;
    }

    get showDropdown() {
        return this.regionOptions && this.regionOptions.length > 0;
    }

    /**
     * Clean up chart timers when component is destroyed.
     */
    disconnectedCallback() {
        if (this.pulseInterval) {
            clearInterval(this.pulseInterval);
        }
        if (this.chart) {
            this.chart.destroy();
            this.chart = null;
        }
    }

    @wire(getRegions)
    /**
     * Populate region options from Apex and load last preference.
     */
    wiredRegions({ error, data }) {
        if (data) {
            this.regionOptions = [
                { label: 'Total', value: 'Total' },
                ...data.map(region => ({ label: region, value: region }))
            ];
            getLastRegion({ componentName: 'MonthlyGoal' })
                .then(region => {
                    this.selectedRegion = (region && this.regionOptions.some(opt => opt.value === region)) 
                        ? region 
                        : this.regionOptions[0]?.value;
                    this.initializeChartIfReady();
                })
                .catch(() => {
                    this.selectedRegion = this.regionOptions[0]?.value;
                    this.initializeChartIfReady();
                });
        } else if (error) {
            console.error('Error getting regions', error);
            this.isLoading = false;
        }
    }

    /**
     * Initialize chart once component has rendered and region is set.
     */
    renderedCallback() {
        if (this.selectedRegion && !this.chartjsInitialized) {
            this.initializeChartIfReady();
        }
    }

    /**
     * Load Chart.js and create chart when prerequisites are met.
     */
    initializeChartIfReady() {
        if (this.chartjsInitialized || !this.selectedRegion) {
            return;
        }
        
        this.chartjsInitialized = true;
        loadScript(this, chartjs)
            .then(() => {
                console.log('Chart.js loaded successfully');
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(() => this.initializeChart(), 100);
            })
            .catch(error => {
                console.error('Error loading chartjs', error);
                this.isLoading = false;
            });
    }

    /**
     * Build the chart using loaded data.
     */
    initializeChart() {
        const canvas = this.template.querySelector('canvas.chart-canvas');
        if (!canvas) {
            console.error('Chart canvas not found');
            this.isLoading = false;
            return;
        }
        
        if (this.chart) {
            this.chart.destroy();
        }
        
        const ctx = canvas.getContext('2d');
        
        if (!window.Chart) {
            console.error('Chart.js not loaded');
            this.isLoading = false;
            return;
        }
        
        const gradient = ctx.createLinearGradient(0, 0, 0, 400);
        gradient.addColorStop(0, 'rgba(0, 102, 204, 0.4)');
        gradient.addColorStop(1, 'rgba(0, 102, 204, 0)');

        this.chart = new window.Chart(ctx, {
            type: 'line',
            data: {
                labels: [],
                datasets: [{
                    label: 'Cumulative Amount Financed',
                    data: [],
                    borderColor: '#0066CC',
                    backgroundColor: gradient,
                    fill: true,
                    tension: 0.4,
                    pointRadius: 0,
                    pointHoverRadius: 6,
                    spanGaps: false,
                }, {
                    label: 'Monthly Goal',
                    data: [],
                    borderColor: '#FF8A00',
                    borderDash: [5, 5],
                    fill: false,
                    pointRadius: 0,
                    borderWidth: 3,
                }],
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                layout: {
                    padding: {
                        top: 10,
                        right: 15,
                        bottom: 5,
                        left: 15
                    }
                },
                scales: {
                    x: {
                        title: { display: false },
                        ticks: {
                            autoSkip: false,
                            maxRotation: 45,
                            minRotation: 45,
                            padding: 5,
                             callback: function(value) {
                                 const dayOfMonth = this.getLabelForValue(value);
                                 const today = new Date().getDate();
                                 const monthShort = new Date().toLocaleString('en-US', { month: 'short' });
                                 if (dayOfMonth === 1 || dayOfMonth === today || (dayOfMonth - 1) % 3 === 0) {
                                     return `${monthShort} ${dayOfMonth}`;
                                 }
                                 return '';
                             },
                        },
                        grid: {
                            display: true,
                            drawTicks: true,
                            color: '#e5e5e5',
                            lineWidth: 1,
                        },
                    },
                    y: {
                        title: { display: true, text: 'Amount' },
                        ticks: { 
                            callback: value => '$' + new Intl.NumberFormat('en-US').format(value),
                            padding: 5
                        },
                    },
                },
                plugins: {
                    legend: { 
                        position: 'top', 
                        align: 'end',
                        labels: {
                            padding: 10,
                            boxWidth: 12
                        }
                    },
                    tooltip: {
                        callbacks: {
                            label: context => {
                                let label = context.dataset.label || '';
                                if (label) { label += ': '; }
                                if (context.parsed.y !== null) {
                                    label += new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(context.parsed.y);
                                }
                                return label;
                            },
                        },
                    },
                },
            },
        });
        
        console.log('Chart created successfully');
        
        try {
            this.chart.data.labels = ['Day 1', 'Day 2', 'Day 3', 'Day 4', 'Day 5'];
            this.chart.data.datasets[0].data = [1000, 2000, 3000, 4000, 5000];
            this.chart.data.datasets[1].data = [10000, 10000, 10000, 10000, 10000];
            this.chart.update();
            console.log('Test chart rendered successfully');
        } catch (testError) {
            console.error('Error rendering test chart:', testError);
        }
        
        this.updateChart();
    }

    handleRegionChange(event) {
        if (this.pulseInterval) {
            clearInterval(this.pulseInterval);
        }
        this.selectedRegion = event.detail.value;
        setLastRegion({ componentName: 'MonthlyGoal', lastRegion: this.selectedRegion });
        this.updateChart();
    }

    updateChart() {
        if (!this.selectedRegion || !this.chart) {
            console.log('Chart or region not ready for update');
            return;
        }
        this.isLoading = true;

        if (this.selectedRegion === 'Total') {
            const regionNames = this.regionOptions.filter(opt => opt.value !== 'Total').map(opt => opt.value);
            Promise.all(regionNames.map(region => getSalesData({ region })))
                .then(allData => {
                    const daysInMonth = new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0).getDate();
                    const labels = Array.from({ length: daysInMonth }, (_, i) => i + 1);
                    const today = new Date().getDate();
                    const regionColors = [
                        'rgba(0, 102, 204, 0.8)',      // Blue - primary brand color
                        'rgba(255, 138, 0, 0.8)',      // Orange - accent color
                        'rgba(0, 180, 160, 0.8)',      // Teal - complementary
                        'rgba(95, 102, 141, 0.8)',     // Purple - neutral
                        'rgba(255, 170, 0, 0.8)',      // Amber - warm variant
                        'rgba(0, 140, 200, 0.8)'       // Light blue - cool variant
                    ];
                    const datasets = allData.map((data, idx) => {
                        let lastCumulativeValue = 0;
                        const cumulativeData = [];
                        for (let i = 1; i <= daysInMonth; i++) {
                             if (Object.prototype.hasOwnProperty.call(data.cumulativeData, i)) {
                                 lastCumulativeValue = data.cumulativeData[i];
                             }
                            cumulativeData.push(i <= today ? lastCumulativeValue : null);
                        }
                        return {
                            label: regionNames[idx],
                            data: cumulativeData,
                            borderColor: regionColors[idx % regionColors.length],
                            backgroundColor: regionColors[idx % regionColors.length],
                            fill: true,
                            tension: 0.4,
                            pointRadius: 0,
                            pointHoverRadius: 6,
                            spanGaps: false,
                            stack: 'regions',
                        };
                    });
                    const totalGoal = allData.reduce((sum, d) => sum + (d.monthlyGoal || 0), 0);
                    datasets.push({
                        label: 'Total Goal',
                        data: Array(daysInMonth).fill(totalGoal),
                        borderColor: '#FF8A00',
                        borderDash: [5, 5],
                        fill: false,
                        pointRadius: 0,
                        tension: 0.4,
                        borderWidth: 3,
                        stack: undefined
                    });
                    try {
                        this.chart.data.labels = labels;
                        this.chart.data.datasets = datasets;
                        this.chart.options.scales.y.stacked = true;
                        this.chart.options.scales.x.stacked = true;
                        this.chart.update();
                        console.log('Chart updated successfully (Total view)');
                    } catch (updateError) {
                        console.error('Error updating chart:', updateError);
                    }
                })
                .catch(error => { 
                    console.error('Error getting sales data', error);
                    this.isLoading = false;
                })
                .finally(() => { this.isLoading = false; });
        } else {
            getSalesData({ region: this.selectedRegion })
                .then(data => {
                    const daysInMonth = new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0).getDate();
                    const labels = Array.from({ length: daysInMonth }, (_, i) => i + 1);
                    const today = new Date().getDate();

                    const cumulativeData = [];
                    let lastCumulativeValue = 0;
                    for (let i = 1; i <= daysInMonth; i++) {
                         if (Object.prototype.hasOwnProperty.call(data.cumulativeData, i)) {
                             lastCumulativeValue = data.cumulativeData[i];
                         }
                        cumulativeData.push(i <= today ? lastCumulativeValue : null);
                    }

                    try {
                        this.chart.data.labels = labels;
                        this.chart.data.datasets = [
                            {
                                label: 'Cumulative Amount Financed',
                                data: cumulativeData,
                                borderColor: '#0070D2',
                                backgroundColor: 'rgba(0, 112, 210, 0.4)',
                                fill: true,
                                tension: 0.4,
                                pointRadius: 0,
                                pointHoverRadius: 6,
                                spanGaps: false,
                            },
                            {
                                label: 'Monthly Goal',
                                data: Array(daysInMonth).fill(data.monthlyGoal),
                                borderColor: '#FF8A00',
                                borderDash: [5, 5],
                                fill: false,
                                pointRadius: 0,
                                borderWidth: 3,
                            }
                        ];
                        this.chart.options.scales.y.stacked = false;
                        this.chart.options.scales.x.stacked = false;
                        this.chart.update();
                        console.log('Chart updated successfully (Single region view)');
                        this.setupPulseAnimation(today - 1);
                    } catch (updateError) {
                        console.error('Error updating chart:', updateError);
                    }
                })
                .catch(error => { 
                    console.error('Error getting sales data', error);
                    this.isLoading = false;
                })
                .finally(() => { this.isLoading = false; });
        }
    }

    setupPulseAnimation(todayIndex) {
        if (this.pulseInterval) {
            clearInterval(this.pulseInterval);
        }

        if (this.selectedRegion === 'Total') return;

        let pulseScale = 1;
        let growing = true;

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.pulseInterval = setInterval(() => {
            pulseScale = growing ? pulseScale + 0.1 : pulseScale - 0.1;
            if (pulseScale >= 2) growing = false;
            if (pulseScale <= 1) growing = true;

            if (this.chart && this.chart.data.datasets[0]) {
                const dataset = this.chart.data.datasets[0];
                
                dataset.pointRadius = Array(dataset.data.length).fill(0);
                
                if (todayIndex >= 0 && todayIndex < dataset.data.length) {
                    dataset.pointRadius[todayIndex] = 3 * pulseScale;
                    dataset.pointBackgroundColor = Array(dataset.data.length).fill('transparent');
                    dataset.pointBackgroundColor[todayIndex] = '#0070D2';
                    dataset.pointBorderColor = Array(dataset.data.length).fill('transparent');
                    dataset.pointBorderColor[todayIndex] = '#ffffff';
                    dataset.pointBorderWidth = Array(dataset.data.length).fill(0);
                    dataset.pointBorderWidth[todayIndex] = 2;
                }
                
                this.chart.update('none');
            }
        }, 100);
    }

    getCurrentMonth() {
        return new Date().toLocaleString('default', { month: 'long' });
    }
}