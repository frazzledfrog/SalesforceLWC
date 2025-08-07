// Dealer Watchlist component handles UI logic and data interactions
import { LightningElement, track } from "lwc";
import getDealerWinnersLosers from "@salesforce/apex/DealerWatchlistController.getDealerWinnersLosers";
import findAccountByDealerName from "@salesforce/apex/TopDealersController.findAccountByDealerName";
import getLastRegion from "@salesforce/apex/UserComponentPreferenceService.getLastRegion";
import setLastRegion from "@salesforce/apex/UserComponentPreferenceService.setLastRegion";
import { loadUnifiedStyles } from "c/unifiedStylesHelper";

const COMPONENT_NAME = "dealerWatchlist";

export default class DealerWatchlist extends LightningElement {
  @track watchlistData = [];
  @track isLoading = false;
  @track selectedRegion = "Ontario";
  @track selectedLimit = 10;
  @track comparisonType = "MonthOverMonth"; // New property for comparison type

  regionOptions = [
    { label: "Ontario", value: "Ontario" },
    { label: "Alberta", value: "Alberta" },
    { label: "Quebec", value: "Quebec" },
    { label: "Atlantic", value: "Atlantic" },
    { label: "Western", value: "Western" }
  ];

  limitOptions = [
    { label: "Top 5", value: 5 },
    { label: "Top 10", value: 10 },
    { label: "Top 15", value: 15 },
    { label: "Top 25", value: 25 }
  ];

  // New getter for comparison type toggle
  get isYearOverYear() {
    return this.comparisonType === "YearOverYear";
  }

  get bannerSubtitle() {
    const comparison = this.isYearOverYear
      ? "YTD vs 2024 Comparison"
      : "Month over Month Comparison";
    return `Winners & Losers • Recreational Business Line • ${comparison}`;
  }

  get toggleLabel() {
    return this.isYearOverYear ? "Year over Year" : "Month over Month";
  }

  async connectedCallback() {
    // Load unified styles
    await loadUnifiedStyles(this);

    getLastRegion({ componentName: COMPONENT_NAME })
      .then((result) => {
        if (
          result &&
          this.regionOptions.some((option) => option.value === result)
        ) {
          this.selectedRegion = result;
        } else {
          this.selectedRegion = "Ontario";
        }
        this.fetchWatchlistData();
      })
      .catch((error) => {
        console.error("Error getting last region:", error);
        this.selectedRegion = "Ontario";
        this.fetchWatchlistData();
      });
  }

  handleRegionChange(event) {
    this.selectedRegion = event.detail.value;
    this.fetchWatchlistData(); // Refresh data when region changes
    setLastRegion({
      componentName: COMPONENT_NAME,
      lastRegion: this.selectedRegion
    }).catch((error) => {
      console.error("Error setting last region:", error);
    });
  }

  handleLimitChange(event) {
    this.selectedLimit = parseInt(event.detail.value, 10);
    this.fetchWatchlistData();
  }

  handleComparisonToggle(event) {
    this.comparisonType = event.target.checked
      ? "YearOverYear"
      : "MonthOverMonth";
    this.fetchWatchlistData();
  }

  async fetchWatchlistData() {
    this.isLoading = true;
    try {
      const data = await getDealerWinnersLosers({
        maxResults: this.selectedLimit,
        comparisonType: this.comparisonType
      });
      const processed = this.processWinnersLosersData(data);
      await this.attachAccountLinks(processed);
      this.watchlistData = processed;
    } catch (error) {
      console.error("Error fetching winners/losers data:", error);
    } finally {
      this.isLoading = false;
    }
  }

  processWinnersLosersData(data) {
    // Each region has: { region, winners: [DealerDelta], losers: [DealerDelta] }
    return data.map((regionData) => {
      const processDealer = (dealer, index) => {
        const deltaText =
          dealer.delta != null
            ? `$${dealer.delta.toLocaleString(undefined, { maximumFractionDigits: 0 })}`
            : "N/A";
        const currentText =
          dealer.mtdAmount != null
            ? `$${dealer.mtdAmount.toLocaleString(undefined, { maximumFractionDigits: 0 })}`
            : "N/A";
        const previousText =
          dealer.prevMonthAmount != null
            ? `$${dealer.prevMonthAmount.toLocaleString(undefined, { maximumFractionDigits: 0 })}`
            : "N/A";
        const absDelta = dealer.delta != null ? Math.abs(dealer.delta) : 0;
        const deltaClass =
          dealer.delta > 0
            ? "delta-positive"
            : dealer.delta < 0
              ? "delta-negative"
              : "";

        return {
          ...dealer,
          rank: index + 1,
          deltaText,
          mtdText: currentText,
          prevText: previousText,
          absDelta,
          deltaClass
        };
      };
      const winners = (regionData.winners || []).map(processDealer);
      const losers = (regionData.losers || []).map(processDealer);
      return {
        name: regionData.region,
        region: regionData.region,
        winners,
        losers,
        hasWinners: winners.length > 0,
        hasLosers: losers.length > 0
      };
    });
  }

  async attachAccountLinks(regionDataList) {
    // Collect unique dealer names across all regions
    const uniqueNames = new Set();
    regionDataList.forEach((region) => {
      region.winners.forEach((d) => uniqueNames.add(d.name));
      region.losers.forEach((d) => uniqueNames.add(d.name));
    });

    // Fetch account ids in parallel
    const promises = Array.from(uniqueNames).map((name) =>
      findAccountByDealerName({ dealerName: name })
        .then((result) => ({
          name,
          accountId: result ? result.accountId : null
        }))
        .catch(() => ({ name, accountId: null }))
    );

    const results = await Promise.all(promises);
    const accountMap = new Map();
    results.forEach((r) => accountMap.set(r.name, r.accountId));

    // Attach URLs back to each dealer entry
    regionDataList.forEach((region) => {
      [...region.winners, ...region.losers].forEach((dealer) => {
        const id = accountMap.get(dealer.name);
        dealer.accountId = id;
        dealer.accountUrl = id ? `/lightning/r/Account/${id}/view` : null;
      });
    });
  }

  // Getters for template data
  get currentRegionData() {
    return (
      this.watchlistData.find(
        (region) => region.name === this.selectedRegion
      ) || { winners: [], losers: [] }
    );
  }

  get winners() {
    return this.currentRegionData.winners || [];
  }

  get losers() {
    return this.currentRegionData.losers || [];
  }

  get hasWinners() {
    return this.winners.length > 0;
  }

  get hasLosers() {
    return this.losers.length > 0;
  }

  get winnersCount() {
    return this.winners.length;
  }

  get losersCount() {
    return this.losers.length;
  }

  get currentPeriodLabel() {
    return this.isYearOverYear ? "YTD 2025" : "Current Month";
  }

  get previousPeriodLabel() {
    return this.isYearOverYear ? "YTD 2024" : "Previous Month";
  }

  get hasNoData() {
    return !this.hasWinners && !this.hasLosers;
  }
}
