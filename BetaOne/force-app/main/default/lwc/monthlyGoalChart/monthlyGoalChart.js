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
    if (this.selectedRegion === "National") {
      const regionNames = this.regionOptions
        .filter((r) => r.value !== "National")
        .map((r) => r.value);
      const promises = [
        getSalesData({ region: "National" }),
        ...regionNames.map((r) => getSalesData({ region: r }))
      ];
      Promise.all(promises)
        .then(([nationalResult, ...regionResults]) => {
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
          const today = now.getDate();

          const buildCumulative = (volume) => {
            let runningTotal = 0;
            return Array.from({ length: daysInMonth }, (_, i) => {
              const day = i + 1;
              if (day > today) {
                return null;
              }
              runningTotal += volume[day] || 0;
              return runningTotal;
            });
          };

          const nationalVolume = nationalResult.volumeData || {};
          const nationalGoal = nationalResult.monthlyGoal || 0;
          const nationalData = buildCumulative(nationalVolume);
          const goalLineData = Array.from({ length: daysInMonth }, () => nationalGoal);

          const regionDatasets = regionResults.map((res, idx) => {
            const region = regionNames[idx];
            const volume = res.volumeData || {};
            return {
              label: region,
              data: buildCumulative(volume),
              borderColor: REGION_COLORS[region] || "#000000",
              fill: false,
              tension: 0.4,
              pointRadius: 0
            };
          });

          this.chart.data.labels = labels;
          this.chart.data.datasets = [
            {
              label: "Cumulative",
              data: nationalData,
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
            },
            ...regionDatasets
          ];
          this.chart.update();
        })
        .catch((error) => {
          // eslint-disable-next-line no-console
          console.error("Error getting sales data", error);
        })
        .finally(() => {
          this.isLoading = false;
        });
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
}
