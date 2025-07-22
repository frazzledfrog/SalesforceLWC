public with sharing class DealerWatchlistController {    // --- WINNERS AND LOSERS OVERHAUL ---
    @AuraEnabled
    public static List<RegionWinnersLosers> getDealerWinnersLosers(Integer maxResults, String comparisonType) {
        if (comparisonType == 'YearOverYear') {
            return getDealerWinnersLosersYearOverYear(maxResults);
        } else {
            return getDealerWinnersLosersMonthOverMonth(maxResults);
        }
    }
    
    @AuraEnabled
    public static List<RegionWinnersLosers> getDealerWinnersLosersMonthOverMonth(Integer maxResults) {
        Date mtdStart = Date.today().toStartOfMonth();
        Date mtdEnd = Date.today();
        Date prevMonthStart = mtdStart.addMonths(-1);
        Date prevMonthEnd = mtdStart.addDays(-1);

        List<String> regions = new List<String>{'Ontario', 'Alberta', 'Quebec', 'Atlantic', 'Western'};
        Map<String, Map<String, DealerDelta>> regionDealerMap = new Map<String, Map<String, DealerDelta>>();
        for (String region : regions) {
            regionDealerMap.put(region, new Map<String, DealerDelta>());
        }

        // Query all relevant Master_LOS__c records for both periods
        List<Master_LOS__c> allRecords = [
            SELECT Applications_Dealer_Name__c, Applications_Dealer_Province__c, Applications_Last_Amount_To_Finance_Sum__c, Applications_Booking_Date__c
            FROM Master_LOS__c
            WHERE (Applications_Booking_Date__c >= :prevMonthStart AND Applications_Booking_Date__c <= :mtdEnd)
            AND Applications_Dealer_Name__c != null
            AND Applications_Dealer_Province__c != null
            AND Applications_Last_Amount_To_Finance_Sum__c != null
            AND Applications_Business_Line__c = 'Recreational'
        ];

        // Aggregate by region+dealer
        Map<String, Map<String, Decimal>> mtdTotals = new Map<String, Map<String, Decimal>>();
        Map<String, Map<String, Decimal>> prevMonthTotals = new Map<String, Map<String, Decimal>>();
        for (String region : regions) {
            mtdTotals.put(region, new Map<String, Decimal>());
            prevMonthTotals.put(region, new Map<String, Decimal>());
        }

        for (Master_LOS__c rec : allRecords) {
            String region = mapProvinceToRegion(rec.Applications_Dealer_Province__c);
            if (!regions.contains(region)) continue;
            String dealerName = rec.Applications_Dealer_Name__c;
            // Exclude "Prefera"
            if (dealerName != null && dealerName.toLowerCase().contains('prefera')) continue;

            // MTD
            if (rec.Applications_Booking_Date__c >= mtdStart && rec.Applications_Booking_Date__c <= mtdEnd) {
                Decimal amt = rec.Applications_Last_Amount_To_Finance_Sum__c;
                if (!mtdTotals.get(region).containsKey(dealerName)) mtdTotals.get(region).put(dealerName, 0);
                mtdTotals.get(region).put(dealerName, mtdTotals.get(region).get(dealerName) + amt);
            }
            // Previous month
            if (rec.Applications_Booking_Date__c >= prevMonthStart && rec.Applications_Booking_Date__c <= prevMonthEnd) {
                Decimal amt = rec.Applications_Last_Amount_To_Finance_Sum__c;
                if (!prevMonthTotals.get(region).containsKey(dealerName)) prevMonthTotals.get(region).put(dealerName, 0);
                prevMonthTotals.get(region).put(dealerName, prevMonthTotals.get(region).get(dealerName) + amt);
            }
        }

        // Build winners/losers lists
        List<RegionWinnersLosers> result = new List<RegionWinnersLosers>();
        for (String region : regions) {
            List<DealerDelta> winners = new List<DealerDelta>();
            List<DealerDelta> losers = new List<DealerDelta>();
            for (String dealer : prevMonthTotals.get(region).keySet()) {
                Decimal prev = prevMonthTotals.get(region).get(dealer);
                Decimal curr = mtdTotals.get(region).containsKey(dealer) ? mtdTotals.get(region).get(dealer) : 0;
                if (prev == null || prev == 0) continue; // must have at least 1 deal last month
                Decimal delta = curr - prev;
                DealerDelta d = new DealerDelta(null, dealer, delta, curr, prev);
                if (delta >= 0) {
                    winners.add(d);
                } else {
                    losers.add(d);
                }
            }
            // Sort by absolute delta descending
            if (!winners.isEmpty()) {
                winners.sort();
                // Limit winners to maxResults
                if (winners.size() > maxResults) {
                    List<DealerDelta> limitedWinners = new List<DealerDelta>();
                    for (Integer i = 0; i < maxResults; i++) {
                        limitedWinners.add(winners[i]);
                    }
                    winners = limitedWinners;
                }
            }
            if (!losers.isEmpty()) {
                losers.sort();
                // Limit losers to maxResults
                if (losers.size() > maxResults) {
                    List<DealerDelta> limitedLosers = new List<DealerDelta>();
                    for (Integer i = 0; i < maxResults; i++) {
                        limitedLosers.add(losers[i]);
                    }
                    losers = limitedLosers;
                }
            }
            result.add(new RegionWinnersLosers(region, winners, losers));
        }
        return result;
    }
    
    @AuraEnabled
    public static List<RegionWinnersLosers> getDealerWinnersLosersYearOverYear(Integer maxResults) {
        Date ytdStart = Date.newInstance(Date.today().year(), 1, 1);
        Date ytdEnd = Date.today();
        Date prevYearStart = Date.newInstance(2024, 1, 1);
        Date prevYearEnd = Date.newInstance(2024, 12, 31);

        List<String> regions = new List<String>{'Ontario', 'Alberta', 'Quebec', 'Atlantic', 'Western'};
        Map<String, Map<String, DealerDelta>> regionDealerMap = new Map<String, Map<String, DealerDelta>>();
        for (String region : regions) {
            regionDealerMap.put(region, new Map<String, DealerDelta>());
        }

        // Query all relevant Master_LOS__c records for both periods
        List<Master_LOS__c> allRecords = [
            SELECT Applications_Dealer_Name__c, Applications_Dealer_Province__c, Applications_Last_Amount_To_Finance_Sum__c, Applications_Booking_Date__c
            FROM Master_LOS__c
            WHERE ((Applications_Booking_Date__c >= :ytdStart AND Applications_Booking_Date__c <= :ytdEnd)
                   OR (Applications_Booking_Date__c >= :prevYearStart AND Applications_Booking_Date__c <= :prevYearEnd))
            AND Applications_Dealer_Name__c != null
            AND Applications_Dealer_Province__c != null
            AND Applications_Last_Amount_To_Finance_Sum__c != null
            AND Applications_Business_Line__c = 'Recreational'
        ];

        // Aggregate by region+dealer
        Map<String, Map<String, Decimal>> ytdTotals = new Map<String, Map<String, Decimal>>();
        Map<String, Map<String, Decimal>> prevYearTotals = new Map<String, Map<String, Decimal>>();
        for (String region : regions) {
            ytdTotals.put(region, new Map<String, Decimal>());
            prevYearTotals.put(region, new Map<String, Decimal>());
        }

        for (Master_LOS__c rec : allRecords) {
            String region = mapProvinceToRegion(rec.Applications_Dealer_Province__c);
            if (!regions.contains(region)) continue;
            String dealerName = rec.Applications_Dealer_Name__c;
            // Exclude "Prefera"
            if (dealerName != null && dealerName.toLowerCase().contains('prefera')) continue;

            // YTD
            if (rec.Applications_Booking_Date__c >= ytdStart && rec.Applications_Booking_Date__c <= ytdEnd) {
                Decimal amt = rec.Applications_Last_Amount_To_Finance_Sum__c;
                if (!ytdTotals.get(region).containsKey(dealerName)) ytdTotals.get(region).put(dealerName, 0);
                ytdTotals.get(region).put(dealerName, ytdTotals.get(region).get(dealerName) + amt);
            }
            // Previous year (2024)
            if (rec.Applications_Booking_Date__c >= prevYearStart && rec.Applications_Booking_Date__c <= prevYearEnd) {
                Decimal amt = rec.Applications_Last_Amount_To_Finance_Sum__c;
                if (!prevYearTotals.get(region).containsKey(dealerName)) prevYearTotals.get(region).put(dealerName, 0);
                prevYearTotals.get(region).put(dealerName, prevYearTotals.get(region).get(dealerName) + amt);
            }
        }

        // Build winners/losers lists
        List<RegionWinnersLosers> result = new List<RegionWinnersLosers>();
        for (String region : regions) {
            List<DealerDelta> winners = new List<DealerDelta>();
            List<DealerDelta> losers = new List<DealerDelta>();
            for (String dealer : prevYearTotals.get(region).keySet()) {
                Decimal prev = prevYearTotals.get(region).get(dealer);
                Decimal curr = ytdTotals.get(region).containsKey(dealer) ? ytdTotals.get(region).get(dealer) : 0;
                if (prev == null || prev == 0) continue; // must have at least some business in 2024
                Decimal delta = curr - prev;
                DealerDelta d = new DealerDelta(null, dealer, delta, curr, prev);
                if (delta >= 0) {
                    winners.add(d);
                } else {
                    losers.add(d);
                }
            }
            // Sort by absolute delta descending
            if (!winners.isEmpty()) {
                winners.sort();
                // Limit winners to maxResults
                if (winners.size() > maxResults) {
                    List<DealerDelta> limitedWinners = new List<DealerDelta>();
                    for (Integer i = 0; i < maxResults; i++) {
                        limitedWinners.add(winners[i]);
                    }
                    winners = limitedWinners;
                }
            }
            if (!losers.isEmpty()) {
                losers.sort();
                // Limit losers to maxResults
                if (losers.size() > maxResults) {
                    List<DealerDelta> limitedLosers = new List<DealerDelta>();
                    for (Integer i = 0; i < maxResults; i++) {
                        limitedLosers.add(losers[i]);
                    }
                    losers = limitedLosers;
                }
            }
            result.add(new RegionWinnersLosers(region, winners, losers));
        }
        return result;
    }

    // --- WINNERS AND LOSERS OVERHAUL ---
    @AuraEnabled
    public static String debugDataAvailability(String comparisonType) {
        if (comparisonType == 'YearOverYear') {
            Date ytdStart = Date.newInstance(Date.today().year(), 1, 1);
            Date ytdEnd = Date.today();
            Date prevYearStart = Date.newInstance(2024, 1, 1);
            Date prevYearEnd = Date.newInstance(2024, 12, 31);
            
            Integer totalRecords = [SELECT COUNT() FROM Master_LOS__c WHERE ((Applications_Booking_Date__c >= :ytdStart AND Applications_Booking_Date__c <= :ytdEnd) OR (Applications_Booking_Date__c >= :prevYearStart AND Applications_Booking_Date__c <= :prevYearEnd)) AND Applications_Business_Line__c = 'Recreational'];
            Integer ytdRecords = [SELECT COUNT() FROM Master_LOS__c WHERE Applications_Booking_Date__c >= :ytdStart AND Applications_Booking_Date__c <= :ytdEnd AND Applications_Business_Line__c = 'Recreational'];
            Integer prevYearRecords = [SELECT COUNT() FROM Master_LOS__c WHERE Applications_Booking_Date__c >= :prevYearStart AND Applications_Booking_Date__c <= :prevYearEnd AND Applications_Business_Line__c = 'Recreational'];
            
            return 'YoY Range: ' + ytdStart + ' to ' + ytdEnd + ' vs ' + prevYearStart + ' to ' + prevYearEnd + 
                   ' | Total Records: ' + totalRecords + 
                   ' | YTD Records: ' + ytdRecords + 
                   ' | 2024 Records: ' + prevYearRecords;
        } else {
            Date mtdStart = Date.today().toStartOfMonth();
            Date mtdEnd = Date.today();
            Date prevMonthStart = mtdStart.addMonths(-1);
            Date prevMonthEnd = mtdStart.addDays(-1);
            
            Integer totalRecords = [SELECT COUNT() FROM Master_LOS__c WHERE Applications_Booking_Date__c >= :prevMonthStart AND Applications_Booking_Date__c <= :mtdEnd AND Applications_Business_Line__c = 'Recreational'];
            Integer mtdRecords = [SELECT COUNT() FROM Master_LOS__c WHERE Applications_Booking_Date__c >= :mtdStart AND Applications_Booking_Date__c <= :mtdEnd AND Applications_Business_Line__c = 'Recreational'];
            Integer prevMonthRecords = [SELECT COUNT() FROM Master_LOS__c WHERE Applications_Booking_Date__c >= :prevMonthStart AND Applications_Booking_Date__c <= :prevMonthEnd AND Applications_Business_Line__c = 'Recreational'];
            
            return 'MoM Range: ' + prevMonthStart + ' to ' + mtdEnd + 
                   ' | Total Records: ' + totalRecords + 
                   ' | MTD Records: ' + mtdRecords + 
                   ' | Prev Month Records: ' + prevMonthRecords;
        }
    }

    public class RegionWinnersLosers {
        @AuraEnabled public String region;
        @AuraEnabled public List<DealerDelta> winners;
        @AuraEnabled public List<DealerDelta> losers;
        public RegionWinnersLosers(String region, List<DealerDelta> winners, List<DealerDelta> losers) {
            this.region = region;
            this.winners = winners;
            this.losers = losers;
        }
    }
    public class DealerDelta implements Comparable {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal delta;
        @AuraEnabled public Decimal mtdAmount;
        @AuraEnabled public Decimal prevMonthAmount;
        public DealerDelta(Id id, String name, Decimal delta, Decimal mtdAmount, Decimal prevMonthAmount) {
            this.id = id;
            this.name = name;
            this.delta = delta;
            this.mtdAmount = mtdAmount;
            this.prevMonthAmount = prevMonthAmount;
        }
        public Integer compareTo(Object o) {
            DealerDelta other = (DealerDelta)o;
            Decimal thisAbs = this.delta != null ? this.delta.abs() : 0;
            Decimal otherAbs = other.delta != null ? other.delta.abs() : 0;
            if (otherAbs > thisAbs) return 1;
            if (otherAbs < thisAbs) return -1;
            // If absolute deltas are equal, sort by name for stability
            if (this.name != null && other.name != null) {
                return this.name.compareTo(other.name);
            }
            return 0;
        }
    }

    private static String mapProvinceToRegion(String province) {
        if (province == 'ON') return 'Ontario';
        if (province == 'AB') return 'Alberta';
        if (province == 'QC') return 'Quebec';
        if (province == 'NB' || province == 'NS' || province == 'PE' || province == 'NL') return 'Atlantic';
        if (province == 'BC' || province == 'SK' || province == 'MB') return 'Western';
        return 'Unknown';
    }
}
