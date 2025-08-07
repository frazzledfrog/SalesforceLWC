import { LightningElement, track, wire } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import chartjs from "@salesforce/resourceUrl/chartjs";
import getSalesData from "@salesforce/apex/SalesDataService.getSalesData";
import getRegions from "@salesforce/apex/SalesDataService.getRegions";

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
      this.regionOptions = data.map((r) => ({ label: r, value: r }));
      this.selectedRegion = this.regionOptions[0]?.value;
    } else if (error) {
      // eslint-disable-next-line no-console
      console.error("Error loading regions", error);
      this.isLoading = false;
    }
  }

  renderedCallback() {
    if (this.chartJsInitialized) {
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
                label: "Volume",
                data: [],
                type: "bar",
                backgroundColor: "#90caf9",
                borderColor: "#90caf9"
              },
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
                label: "Goal",
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
            scales: {
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
    getSalesData({ region: this.selectedRegion })
      .then((result) => {
        const volume = result.volumeData || {};
        const cumulative = result.cumulativeData || {};
        const goal = result.monthlyGoal || 0;
        const now = new Date();
        const daysInMonth = new Date(
          now.getFullYear(),
          now.getMonth() + 1,
          0
        ).getDate();
        const labels = Array.from({ length: daysInMonth }, (_, i) => i + 1);
        const volumeData = labels.map((day) => volume[day] || 0);
        const cumulativeData = labels.map((day) => cumulative[day] || null);
        this.chart.data.labels = labels;
        this.chart.data.datasets[0].data = volumeData;
        this.chart.data.datasets[1].data = cumulativeData;
        this.chart.data.datasets[2].data = Array(daysInMonth).fill(goal);
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
