// Sales Data service providing reusable logic
public with sharing class SalesDataService {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getSalesData(String region) {
        Date today = Date.today();
        Date startDate = today.toStartOfMonth();
        Date endDate = today.toStartOfMonth().addMonths(1).addDays(-1);

        // Convert region to province codes
        Set<String> provinces = getProvincesForRegion(region);
        
        List<AggregateResult> results = [
            SELECT
                DAY_IN_MONTH(Applications_Booking_Date__c) day,
                SUM(Applications_Last_Amount_To_Finance_Sum__c) total
            FROM Master_LOS__c
            WHERE Applications_Dealer_Province__c IN :provinces
            AND Applications_Booking_Date__c >= :startDate
            AND Applications_Booking_Date__c <= :endDate
            GROUP BY DAY_IN_MONTH(Applications_Booking_Date__c)
            ORDER BY DAY_IN_MONTH(Applications_Booking_Date__c)
        ];

        Map<Integer, Decimal> cumulativeData = new Map<Integer, Decimal>();
        Map<Integer, Decimal> volumeData = new Map<Integer, Decimal>();
        Decimal cumulativeTotal = 0;
        for (AggregateResult ar : results) {
            Integer day = (Integer) ar.get('day');
            Decimal total = (Decimal) ar.get('total');
            cumulativeTotal += total;
            cumulativeData.put(day, cumulativeTotal);
            volumeData.put(day, total);
        }

        Decimal monthlyGoal = 0;
        List<Monthly_Goal__c> goals = [
            SELECT Region_Target_Alberta__c, Region_Target_Quebec__c, Region_Target_Eastern__c, Region_Target_Ontario__c, Region_Target_Western__c
            FROM Monthly_Goal__c
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        if (!goals.isEmpty() && region != null) {
            Monthly_Goal__c firstGoal = goals[0];
            String regionLower = region != null ? region.toLowerCase() : '';
            if (regionLower.contains('national')) {
                monthlyGoal =
                    (firstGoal.Region_Target_Alberta__c != null ? firstGoal.Region_Target_Alberta__c : 0) +
                    (firstGoal.Region_Target_Quebec__c != null ? firstGoal.Region_Target_Quebec__c : 0) +
                    (firstGoal.Region_Target_Eastern__c != null ? firstGoal.Region_Target_Eastern__c : 0) +
                    (firstGoal.Region_Target_Ontario__c != null ? firstGoal.Region_Target_Ontario__c : 0) +
                    (firstGoal.Region_Target_Western__c != null ? firstGoal.Region_Target_Western__c : 0);
            } else if (regionLower.contains('alberta')) {
                monthlyGoal = firstGoal.Region_Target_Alberta__c;
            } else if (regionLower.contains('quebec')) {
                monthlyGoal = firstGoal.Region_Target_Quebec__c;
            } else if (regionLower.contains('atlantic')) {
                monthlyGoal = firstGoal.Region_Target_Eastern__c;
            } else if (regionLower.contains('ontario')) {
                monthlyGoal = firstGoal.Region_Target_Ontario__c;
            } else if (regionLower.contains('western') || regionLower.contains('british columbia') || regionLower.contains('saskatchewan') || regionLower.contains('manitoba')) {
                monthlyGoal = firstGoal.Region_Target_Western__c;
            }
        }

        Map<String, Object> data = new Map<String, Object>();
        data.put('cumulativeData', cumulativeData);
        data.put('volumeData', volumeData);
        data.put('monthlyGoal', monthlyGoal);

        return data;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getRegions() {
        return new List<String>{
            'National',
            'Ontario',
            'Alberta',
            'Quebec',
            'Atlantic',
            'Western'
        };
    }

    private static Set<String> getProvincesForRegion(String region) {
        Set<String> provinces = new Set<String>();
        String regionLower = region != null ? region.toLowerCase() : '';

        if (regionLower == 'national') {
            provinces.addAll(new Set<String>{'ON','AB','QC','NB','NS','PE','NL','BC','SK','MB'});
        } else if (regionLower == 'ontario') {
            provinces.add('ON');
        } else if (regionLower == 'alberta') {
            provinces.add('AB');
        } else if (regionLower == 'quebec') {
            provinces.add('QC');
        } else if (regionLower == 'atlantic') {
            provinces.addAll(new Set<String>{'NB', 'NS', 'PE', 'NL'});
        } else if (regionLower == 'western' || regionLower == 'british columbia' || regionLower == 'saskatchewan' || regionLower == 'manitoba') {
            provinces.addAll(new Set<String>{'BC', 'SK', 'MB'});
        }

        return provinces;
    }
}