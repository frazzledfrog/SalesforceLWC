// Dealer Detail controller handling server-side operations
public with sharing class DealerDetailController {
    
    @AuraEnabled(cacheable=true)
    public static List<DealerOption> getDealerOptions() {
        try {
            // Get unique dealers with their regions from a comprehensive historical period
            // Use last 2 years to ensure we capture all dealers, even those who haven't booked recently
            Date historicalStart = Date.today().addYears(-2);
            Date today = Date.today();
            
            List<AggregateResult> dealerResults = [
                SELECT Applications_Dealer_Name__c dealerName, 
                       Applications_Dealer_Province__c province,
                       COUNT(Id) dealCount
                FROM Master_LOS__c
                WHERE Applications_Booking_Date__c >= :historicalStart 
                AND Applications_Booking_Date__c <= :today
                AND Applications_Dealer_Name__c != null
                GROUP BY Applications_Dealer_Name__c, Applications_Dealer_Province__c
                ORDER BY Applications_Dealer_Name__c
            ];
            
            List<DealerOption> options = new List<DealerOption>();
            
            for (AggregateResult ar : dealerResults) {
                String dealerName = (String) ar.get('dealerName');
                String province = (String) ar.get('province');
                Integer dealCount = (Integer) ar.get('dealCount');

                // Map province to region
                String region = mapProvinceToRegion(province);

                // Create unique ID based on dealer name + province
                String dealerId = generateDealerId(dealerName, province);

                options.add(new DealerOption(dealerId, dealerName, region, province, dealCount));
            }
            
            return options;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching dealer options: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static DealerDetails getDealerDetails(String dealerId) {
        try {
            // Parse the dealer ID to get name and province
            DealerInfo info = parseDealerId(dealerId);
            
            // Date ranges
            Date endDate = Date.today();
            Date startDate = endDate.addDays(-120);
            Date monthStart = Date.newInstance(endDate.year(), endDate.month(), 1);
            Date monthEnd = monthStart.addMonths(1).addDays(-1);
            
            // Last month date range
            Date lastMonthStart = monthStart.addMonths(-1);
            Date lastMonthEnd = monthStart.addDays(-1);
            
            // Last year same period
            Date lastYearEnd = endDate.addYears(-1);
            Date lastYearStart = startDate.addYears(-1);
            
            // Current period data (120 days)
            List<AggregateResult> currentData = [
                SELECT COUNT(Id) totalDeals,
                       SUM(Applications_Last_Amount_To_Finance_Sum__c) totalFinanced,
                       AVG(Applications_Last_Amount_To_Finance_Sum__c) avgDealSize
                FROM Master_LOS__c
                WHERE Applications_Booking_Date__c >= :startDate 
                AND Applications_Booking_Date__c <= :endDate
                AND Applications_Dealer_Name__c LIKE :('%' + info.dealerName + '%')
                AND Applications_Dealer_Province__c = :info.province
            ];
            
            // Current month data (similar to SalesDataService pattern)
            List<AggregateResult> monthlyData = [
                SELECT COUNT(Id) monthlyDeals,
                       SUM(Applications_Last_Amount_To_Finance_Sum__c) monthlyAmountFinanced,
                       AVG(Applications_Last_Amount_To_Finance_Sum__c) monthlyAvgDealSize
                FROM Master_LOS__c
                WHERE Applications_Booking_Date__c >= :monthStart 
                AND Applications_Booking_Date__c <= :monthEnd
                AND Applications_Dealer_Name__c LIKE :('%' + info.dealerName + '%')
                AND Applications_Dealer_Province__c = :info.province
            ];
            
            // Last month data
            List<AggregateResult> lastMonthData = [
                SELECT SUM(Applications_Last_Amount_To_Finance_Sum__c) lastMonthAmountFinanced
                FROM Master_LOS__c
                WHERE Applications_Booking_Date__c >= :lastMonthStart 
                AND Applications_Booking_Date__c <= :lastMonthEnd
                AND Applications_Dealer_Name__c LIKE :('%' + info.dealerName + '%')
                AND Applications_Dealer_Province__c = :info.province
            ];
            
            // Last year data for comparison
            List<AggregateResult> lastYearData = [
                SELECT COUNT(Id) lastYearDeals
                FROM Master_LOS__c
                WHERE Applications_Booking_Date__c >= :lastYearStart 
                AND Applications_Booking_Date__c <= :lastYearEnd
                AND Applications_Dealer_Name__c LIKE :('%' + info.dealerName + '%')
                AND Applications_Dealer_Province__c = :info.province
            ];
            
            // Extract data with null safety
            Integer totalDeals = currentData.size() > 0 && currentData[0].get('totalDeals') != null ? 
                               (Integer) currentData[0].get('totalDeals') : 0;
            
            Decimal totalFinanced = currentData.size() > 0 && currentData[0].get('totalFinanced') != null ? 
                                  (Decimal) currentData[0].get('totalFinanced') : 0;
            
            Decimal avgDealSize = currentData.size() > 0 && currentData[0].get('avgDealSize') != null ? 
                                (Decimal) currentData[0].get('avgDealSize') : 0;
            
            // Extract monthly data
            Integer monthlyDeals = monthlyData.size() > 0 && monthlyData[0].get('monthlyDeals') != null ? 
                                 (Integer) monthlyData[0].get('monthlyDeals') : 0;
            
            Decimal monthlyAmountFinanced = monthlyData.size() > 0 && monthlyData[0].get('monthlyAmountFinanced') != null ? 
                                          (Decimal) monthlyData[0].get('monthlyAmountFinanced') : 0;
            
            Decimal monthlyAvgDealSize = monthlyData.size() > 0 && monthlyData[0].get('monthlyAvgDealSize') != null ? 
                                       (Decimal) monthlyData[0].get('monthlyAvgDealSize') : 0;
            
            // Extract last month data
            Decimal lastMonthAmountFinanced = lastMonthData.size() > 0 && lastMonthData[0].get('lastMonthAmountFinanced') != null ? 
                                            (Decimal) lastMonthData[0].get('lastMonthAmountFinanced') : 0;
            
            // Calculate projection for month end
            Integer daysPassed = Date.today().day();
            Integer totalDaysInMonth = monthEnd.day();
            Decimal projectedMonthEndAmount = 0;
            if (daysPassed > 0 && monthlyAmountFinanced > 0) {
                Decimal dailyAverage = monthlyAmountFinanced / daysPassed;
                projectedMonthEndAmount = dailyAverage * totalDaysInMonth;
            }
            
            Integer lastYearDeals = lastYearData.size() > 0 && lastYearData[0].get('lastYearDeals') != null ? 
                                  (Integer) lastYearData[0].get('lastYearDeals') : 0;
            
            // Calculate performance change
            Decimal performanceChange = 0;
            if (lastYearDeals > 0) {
                performanceChange = ((Decimal)(totalDeals - lastYearDeals) / lastYearDeals) * 100;
            }
            
            String region = mapProvinceToRegion(info.province);
            
            return new DealerDetails(
                dealerId,
                info.dealerName,
                region,
                info.province,
                totalDeals,
                totalFinanced,
                monthlyAvgDealSize,
                monthlyDeals,
                monthlyAmountFinanced,
                lastMonthAmountFinanced,
                projectedMonthEndAmount,
                performanceChange
            );
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching dealer details: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static ChartData getDealerChartData(String dealerId) {
        return getDealerChartDataWithPeriod(dealerId, 12);
    }
    
    @AuraEnabled
    public static ChartData getDealerChartDataWithPeriod(String dealerId, Integer monthsBack) {
        try {
            // Parse the dealer ID to get name and province
            DealerInfo info = parseDealerId(dealerId);
            
            // Default to 12 months if not specified or invalid
            Integer lookbackMonths = (monthsBack != null && monthsBack > 0) ? monthsBack : 12;
            
            Date today = Date.today();
            Date startDate = today.toStartOfMonth().addMonths(-(lookbackMonths - 1));
            Date endDate = today;
            
            // Single optimized query: filter by date range first, then dealer, then group by month
            List<AggregateResult> chartResults = [
                SELECT CALENDAR_YEAR(Applications_Booking_Date__c) year,
                       CALENDAR_MONTH(Applications_Booking_Date__c) month,
                       COUNT(Id) dealCount,
                       SUM(Applications_Last_Amount_To_Finance_Sum__c) totalFinanced
                FROM Master_LOS__c
                WHERE Applications_Booking_Date__c >= :startDate 
                AND Applications_Booking_Date__c <= :endDate
                AND Applications_Dealer_Name__c LIKE :('%' + info.dealerName + '%')
                AND Applications_Dealer_Province__c = :info.province
                GROUP BY CALENDAR_YEAR(Applications_Booking_Date__c), CALENDAR_MONTH(Applications_Booking_Date__c)
                ORDER BY CALENDAR_YEAR(Applications_Booking_Date__c), CALENDAR_MONTH(Applications_Booking_Date__c)
            ];
            
            // Create a map of year-month to data for quick lookup
            Map<String, MonthlyData> dataMap = new Map<String, MonthlyData>();
            
            for (AggregateResult ar : chartResults) {
                Integer year = (Integer) ar.get('year');
                Integer month = (Integer) ar.get('month');
                Integer dealCount = (Integer) ar.get('dealCount');
                Decimal totalFinanced = (Decimal) ar.get('totalFinanced');
                
                String key = year + '-' + month;
                String monthLabel = getMonthLabelFromNumbers(month, year);
                
                dataMap.put(key, new MonthlyData(monthLabel, dealCount, totalFinanced != null ? totalFinanced : 0));
            }
            
            // Build the complete month list, filling in zeros for missing months
            List<MonthlyData> monthlyDataList = new List<MonthlyData>();
            
            for (Integer i = lookbackMonths - 1; i >= 0; i--) {
                Date monthDate = today.toStartOfMonth().addMonths(-i);
                String key = monthDate.year() + '-' + monthDate.month();
                String monthLabel = getMonthLabel(monthDate);
                
                if (dataMap.containsKey(key)) {
                    monthlyDataList.add(dataMap.get(key));
                } else {
                    monthlyDataList.add(new MonthlyData(monthLabel, 0, 0));
                }
            }
            
            return new ChartData(monthlyDataList);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching chart data: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getDealerChartDataById(String dealerId) {
        try {
            // Parse the dealer ID to get name and province (consistent with other methods)
            DealerInfo info = parseDealerId(dealerId);
            
            Map<String, Map<String, Object>> monthMap = new Map<String, Map<String, Object>>();
            Date today = Date.today();
            Date firstMonth = today.addMonths(-11).toStartOfMonth();

            // Pre-populate all 12 months with 0s
            for (Integer i = 0; i < 12; i++) {
                Date monthStart = firstMonth.addMonths(i);
                String key = String.valueOf(monthStart.year()) + '-' + String.valueOf(monthStart.month()).leftPad(2, '0');
                monthMap.put(key, new Map<String, Object>{
                    'month' => getMonthLabel(monthStart),
                    'dealCount' => 0,
                    'totalFinanced' => 0
                });
            }

            // Query actual data using LIKE pattern for dealer name
            List<AggregateResult> results = [
                SELECT CALENDAR_YEAR(Applications_Booking_Date__c) year,
                       CALENDAR_MONTH(Applications_Booking_Date__c) month,
                       SUM(Applications_Last_Amount_To_Finance_Sum__c) totalFinanced,
                       COUNT(Id) dealCount
                FROM Master_LOS__c
                WHERE Applications_Dealer_Name__c LIKE :('%' + info.dealerName + '%')
                  AND Applications_Dealer_Province__c = :info.province
                  AND Applications_Booking_Date__c >= :firstMonth
                  AND Applications_Booking_Date__c <= :today
                GROUP BY CALENDAR_YEAR(Applications_Booking_Date__c), CALENDAR_MONTH(Applications_Booking_Date__c)
            ];

            for (AggregateResult ar : results) {
                Integer year = (Integer)ar.get('year');
                Integer month = (Integer)ar.get('month');
                String key = String.valueOf(year) + '-' + String.valueOf(month).leftPad(2, '0');
                if (monthMap.containsKey(key)) {
                    monthMap.get(key).put('dealCount', (Integer)ar.get('dealCount'));
                    monthMap.get(key).put('totalFinanced', (Decimal)ar.get('totalFinanced'));
                }
            }

            // Return sorted by month
            List<Map<String, Object>> data = new List<Map<String, Object>>();
            for (Integer i = 0; i < 12; i++) {
                Date monthStart = firstMonth.addMonths(i);
                String key = String.valueOf(monthStart.year()) + '-' + String.valueOf(monthStart.month()).leftPad(2, '0');
                data.add(monthMap.get(key));
            }
            return data;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching chart data by ID: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static ChartData getDealerChartDataMax(String dealerId) {
        try {
            // Parse the dealer ID to get name and province
            DealerInfo info = parseDealerId(dealerId);
            
            // Find the earliest month with at least one deal for this dealer
            List<AggregateResult> earliestDealResults = [
                SELECT MIN(Applications_Booking_Date__c) earliestDate
                FROM Master_LOS__c
                WHERE Applications_Dealer_Name__c LIKE :('%' + info.dealerName + '%')
                AND Applications_Dealer_Province__c = :info.province
                AND Applications_Booking_Date__c != null
            ];
            
            if (earliestDealResults.isEmpty() || earliestDealResults[0].get('earliestDate') == null) {
                // No deals found, return empty chart data
                return new ChartData(new List<MonthlyData>());
            }
            
            Date earliestDate = (Date) earliestDealResults[0].get('earliestDate');
            Date startDate = earliestDate.toStartOfMonth();
            Date endDate = Date.today();
            
            // Get all monthly data from earliest month to present
            List<AggregateResult> chartResults = [
                SELECT CALENDAR_YEAR(Applications_Booking_Date__c) year,
                       CALENDAR_MONTH(Applications_Booking_Date__c) month,
                       COUNT(Id) dealCount,
                       SUM(Applications_Last_Amount_To_Finance_Sum__c) totalFinanced
                FROM Master_LOS__c
                WHERE Applications_Booking_Date__c >= :startDate 
                AND Applications_Booking_Date__c <= :endDate
                AND Applications_Dealer_Name__c LIKE :('%' + info.dealerName + '%')
                AND Applications_Dealer_Province__c = :info.province
                GROUP BY CALENDAR_YEAR(Applications_Booking_Date__c), CALENDAR_MONTH(Applications_Booking_Date__c)
                ORDER BY CALENDAR_YEAR(Applications_Booking_Date__c), CALENDAR_MONTH(Applications_Booking_Date__c)
            ];
            
            // Create a map of year-month to data for quick lookup
            Map<String, MonthlyData> dataMap = new Map<String, MonthlyData>();
            
            for (AggregateResult ar : chartResults) {
                Integer year = (Integer) ar.get('year');
                Integer month = (Integer) ar.get('month');
                Integer dealCount = (Integer) ar.get('dealCount');
                Decimal totalFinanced = (Decimal) ar.get('totalFinanced');
                
                String key = year + '-' + month;
                String monthLabel = getMonthLabelFromNumbers(month, year);
                
                dataMap.put(key, new MonthlyData(monthLabel, dealCount, totalFinanced != null ? totalFinanced : 0));
            }
            
            // Build the complete month list from earliest to present, filling in zeros for missing months
            List<MonthlyData> monthlyDataList = new List<MonthlyData>();
            Date currentMonth = startDate;
            
            while (currentMonth <= endDate.toStartOfMonth()) {
                String key = currentMonth.year() + '-' + currentMonth.month();
                String monthLabel = getMonthLabel(currentMonth);
                
                if (dataMap.containsKey(key)) {
                    monthlyDataList.add(dataMap.get(key));
                } else {
                    monthlyDataList.add(new MonthlyData(monthLabel, 0, 0));
                }
                
                currentMonth = currentMonth.toStartOfMonth().addMonths(1);
            }
            
            return new ChartData(monthlyDataList);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching max chart data: ' + e.getMessage());
        }
    }

    // Helper methods
    private static String mapProvinceToRegion(String province) {
        if (province == 'ON') return 'Ontario';
        if (province == 'AB') return 'Alberta';
        if (province == 'QC') return 'Quebec';
        if (province == 'NB' || province == 'NS' || province == 'PE' || province == 'NL') return 'Atlantic';
        if (province == 'BC' || province == 'SK' || province == 'MB') return 'Western';
        return 'Unknown';
    }
    
    private static String generateDealerId(String dealerName, String province) {
        return EncodingUtil.base64Encode(Blob.valueOf(dealerName + '|' + province)).replace('=', '');
    }
    
    private static DealerInfo parseDealerId(String dealerId) {
        try {
            String decoded = EncodingUtil.base64Decode(dealerId + '==').toString();
            List<String> parts = decoded.split('\\|');
            return new DealerInfo(parts[0], parts[1]);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid dealer ID format');
        }
    }
    
    private static String getMonthLabel(Date dateValue) {
        String[] months = new String[]{'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
        Integer monthNum = dateValue.month();
        Integer year = dateValue.year();
        return months[monthNum - 1] + ' ' + year;
    }
    
    private static String getMonthLabelFromNumbers(Integer month, Integer year) {
        String[] months = new String[]{'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
        return months[month - 1] + ' ' + year;
    }
    
    // Wrapper classes
    public class DealerOption {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String region;
        @AuraEnabled public String province;
        @AuraEnabled public Integer dealCount;
        
        public DealerOption(String id, String name, String region, String province, Integer dealCount) {
            this.id = id;
            this.name = name;
            this.region = region;
            this.province = province;
            this.dealCount = dealCount;
        }
    }
    
    public class DealerDetails {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String region;
        @AuraEnabled public String province;
        @AuraEnabled public Integer totalDeals;
        @AuraEnabled public Decimal totalFinancedAmount;
        @AuraEnabled public Decimal averageDealSize;
        @AuraEnabled public Integer monthlyDeals;
        @AuraEnabled public Decimal monthlyAmountFinanced;
        @AuraEnabled public Decimal lastMonthAmountFinanced;
        @AuraEnabled public Decimal projectedMonthEndAmount;
        @AuraEnabled public Decimal performanceChange;
        
        public DealerDetails(String id, String name, String region, String province, 
                           Integer totalDeals, Decimal totalFinancedAmount, Decimal averageDealSize,
                           Integer monthlyDeals, Decimal monthlyAmountFinanced, 
                           Decimal lastMonthAmountFinanced, Decimal projectedMonthEndAmount, 
                           Decimal performanceChange) {
            this.id = id;
            this.name = name;
            this.region = region;
            this.province = province;
            this.totalDeals = totalDeals;
            this.totalFinancedAmount = totalFinancedAmount;
            this.averageDealSize = averageDealSize;
            this.monthlyDeals = monthlyDeals;
            this.monthlyAmountFinanced = monthlyAmountFinanced;
            this.lastMonthAmountFinanced = lastMonthAmountFinanced;
            this.projectedMonthEndAmount = projectedMonthEndAmount;
            this.performanceChange = performanceChange;
        }
    }
    
    public class ChartData {
        @AuraEnabled public List<MonthlyData> monthlyData;
        
        public ChartData(List<MonthlyData> monthlyData) {
            this.monthlyData = monthlyData;
        }
    }
    
    public class MonthlyData {
        @AuraEnabled public String month;
        @AuraEnabled public Integer dealCount;
        @AuraEnabled public Decimal totalFinanced;
        
        public MonthlyData(String month, Integer dealCount, Decimal totalFinanced) {
            this.month = month;
            this.dealCount = dealCount;
            this.totalFinanced = totalFinanced;
        }
    }
    
    private class DealerInfo {
        public String dealerName;
        public String province;
        
        public DealerInfo(String dealerName, String province) {
            this.dealerName = dealerName;
            this.province = province;
        }
    }
}
