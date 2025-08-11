import { LightningElement, track, wire } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import chartjs from "@salesforce/resourceUrl/chartjs";
import getSalesData from "@salesforce/apex/SalesDataService.getSalesData";
import getRegions from "@salesforce/apex/SalesDataService.getRegions";

const REGION_COLORS = {
  Ontario: "#e6194b",
  Alberta: "#3cb44b",
  Quebec: "#911eb4",
  Atlantic: "#ffe119",
  Western: "#46f0f0"
};

// Helper to convert hex color to rgba with supplied alpha
function hexToRgba(hex, alpha = 0.35) {
  if (!hex || !hex.startsWith('#') || (hex.length !== 7)) return hex;
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

export default class MonthlyGoalChart extends LightningElement {
  @track regionOptions = [];
  @track selectedRegion;
  @track isLoading = true;
  @track cardTitle = `Monthly Goal - ${new Date().toLocaleString("en-US", {
    month: "long"
  })}`;
  chart;
  chartJsInitialized = false;

  @wire(getRegions)
  wiredRegions({ error, data }) {
    if (data) {
      const uniqueRegions = data.filter(
        (r) => r.toLowerCase() !== "national"
      );
      this.regionOptions = [
        { label: "National", value: "National" },
        ...uniqueRegions.map((r) => ({ label: r, value: r }))
      ];
      this.selectedRegion = this.regionOptions[0]?.value;
    } else if (error) {
      // eslint-disable-next-line no-console
      console.error("Error loading regions", error);
      this.isLoading = false;
    }
  }

  renderedCallback() {
    if (this.chartJsInitialized || !this.selectedRegion) {
      return;
    }
    this.chartJsInitialized = true;
    loadScript(this, chartjs)
      .then(() => {
        const ctx = this.template
          .querySelector("canvas.goal-chart")
          .getContext("2d");
        this.chart = new window.Chart(ctx, {
          type: "line",
          data: {
            labels: [],
            datasets: [
              {
                label: "Cumulative",
                data: [],
                borderColor: "#0066CC",
                backgroundColor: "rgba(0,102,204,0.2)",
                fill: true,
                tension: 0.4,
                pointRadius: 0
              },
              {
                label: "Monthly Goal",
                data: [],
                borderColor: "#FF8A00",
                borderDash: [5, 5],
                fill: false,
                pointRadius: 0,
                borderWidth: 2
              }
            ]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
              legend: { position: "bottom" }
            },
            interaction: { mode: "index", intersect: false },
            scales: {
              x: {
                ticks: {
                  maxRotation: 45,
                  minRotation: 45
                }
              },
              y: {
                ticks: {
                  callback: (value) =>
                    "$" + new Intl.NumberFormat("en-US").format(value)
                }
              }
            }
          }
        });
        this.fetchData();
      })
      .catch((error) => {
        // eslint-disable-next-line no-console
        console.error("Error loading Chart.js", error);
        this.isLoading = false;
      });
  }

  handleRegionChange(event) {
    this.selectedRegion = event.detail.value;
    this.fetchData();
  }

  fetchData() {
    if (!this.selectedRegion) {
      return;
    }
    this.isLoading = true;
    // Toggle stacking depending on view
    if (this.chart) {
      if (this.selectedRegion === 'National') {
        this.chart.options.scales.x.stacked = true;
        this.chart.options.scales.y.stacked = true;
      } else {
        this.chart.options.scales.x.stacked = false;
        this.chart.options.scales.y.stacked = false;
      }
    }
    if (this.selectedRegion === "National") {
      // Mirror logic from MonthlyGoal component (stacked cumulative regional areas + goal line)
      const regionNames = this.regionOptions
        .filter(r => r.value !== 'National')
        .map(r => r.value);
      Promise.all(regionNames.map(region => getSalesData({ region })))
        .then(allData => {
          const now = new Date();
          const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
          const labels = Array.from({ length: daysInMonth }, (_, i) => i + 1); // day numbers
          const today = now.getDate();

          const datasets = allData.map((data, idx) => {
            let lastCumulativeValue = 0;
            const cumulativeData = [];
            for (let day = 1; day <= daysInMonth; day++) {
              if (data.cumulativeData && Object.prototype.hasOwnProperty.call(data.cumulativeData, day)) {
                lastCumulativeValue = data.cumulativeData[day];
              }
              cumulativeData.push(day <= today ? lastCumulativeValue : null);
            }
            const region = regionNames[idx];
            const color = REGION_COLORS[region] || '#0070D2';
            return {
              label: region,
              data: cumulativeData,
              borderColor: color,
              backgroundColor: color.replace(')', ', 0.35)').replace('rgb', 'rgba'), // quick alpha if rgb, else same
              fill: true,
              tension: 0.4,
              pointRadius: 0,
              spanGaps: false,
              stack: 'regions'
            };
          });

          const totalGoal = allData.reduce((sum, d) => sum + (d.monthlyGoal || 0), 0);
          datasets.push({
            label: 'National Goal',
            data: Array(daysInMonth).fill(totalGoal),
            borderColor: '#FF8A00',
            borderDash: [5, 5],
            fill: false,
            pointRadius: 0,
            borderWidth: 2,
            stack: undefined
          });

          // Apply datasets
            this.chart.data.labels = labels;
            this.chart.data.datasets = datasets;

          // Tooltip similar to MonthlyGoal formatting
          this.chart.options.plugins.tooltip = {
            callbacks: {
              label: (context) => {
                let lbl = context.dataset.label ? context.dataset.label + ': ' : '';
                if (context.parsed.y != null) {
                  lbl += new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(context.parsed.y);
                }
                return lbl;
              }
            }
          };

          // Optional: improve x-axis labels to show month abbreviation selectively
          this.chart.options.scales.x.ticks.callback = function(value) {
            const dayNum = this.getLabelForValue(value);
            const todayDay = new Date().getDate();
            const monthShort = new Date().toLocaleString('en-US', { month: 'short' });
            if (dayNum === 1 || dayNum === todayDay || (dayNum - 1) % 3 === 0) {
              return `${monthShort} ${dayNum}`;
            }
            return '';
          };

          this.chart.update();
        })
        .catch(error => {
          // eslint-disable-next-line no-console
          console.error('Error getting sales data', error);
        })
        .finally(() => { this.isLoading = false; });
    } else {
      getSalesData({ region: this.selectedRegion })
        .then((result) => {
          const volume = result.volumeData || {};
          const goal = result.monthlyGoal || 0;
          const now = new Date();
          const daysInMonth = new Date(
            now.getFullYear(),
            now.getMonth() + 1,
            0
          ).getDate();
          const labels = Array.from({ length: daysInMonth }, (_, i) => {
            const date = new Date(now.getFullYear(), now.getMonth(), i + 1);
            return date.toLocaleDateString("en-US", {
              month: "short",
              day: "numeric"
            });
          });
          let runningTotal = 0;
          const today = now.getDate();
          const cumulativeData = Array.from({ length: daysInMonth }, (_, i) => {
            const day = i + 1;
            if (day > today) {
              return null;
            }
            runningTotal += volume[day] || 0;
            return runningTotal;
          });
          const goalLineData = Array.from({ length: daysInMonth }, () => goal);
          this.chart.data.labels = labels;
          this.chart.data.datasets = [
            {
              label: "Cumulative",
              data: cumulativeData,
              borderColor: "#0066CC",
              backgroundColor: "rgba(0,102,204,0.2)",
              fill: true,
              tension: 0.4,
              pointRadius: 0
            },
            {
              label: "Monthly Goal",
              data: goalLineData,
              borderColor: "#FF8A00",
              borderDash: [5, 5],
              fill: false,
              pointRadius: 0,
              borderWidth: 2
            }
          ];
          this.chart.options.plugins.tooltip = { mode: 'index', intersect: false }; // reset tooltip
          this.chart.update();
        })
        .catch((error) => {
          // eslint-disable-next-line no-console
          console.error("Error getting sales data", error);
        })
        .finally(() => {
          this.isLoading = false;
        });
    }
  }

  get isNationalView() {
    return this.selectedRegion === 'National';
  }
}
