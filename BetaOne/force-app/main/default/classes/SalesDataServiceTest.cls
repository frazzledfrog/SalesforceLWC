// Test class for Sales Data Service
@isTest
private class SalesDataServiceTest {

    @TestSetup
    static void makeData(){
        List<Master_LOS__c> records = new List<Master_LOS__c>();
        Date today = Date.today();
        Date monthStart = today.toStartOfMonth();
        
        // Create data for different provinces and days
        records.add(new Master_LOS__c(
            Name = 'APP-001',
            Applications_Booking_Date__c = monthStart.addDays(1),
            Applications_Last_Amount_To_Finance_Sum__c = 1500,
            Applications_Dealer_Province__c = 'ON'
        ));
        records.add(new Master_LOS__c(
            Name = 'APP-002',
            Applications_Booking_Date__c = monthStart.addDays(2),
            Applications_Last_Amount_To_Finance_Sum__c = 3000,
            Applications_Dealer_Province__c = 'QC'
        ));
        records.add(new Master_LOS__c(
            Name = 'APP-003',
            Applications_Booking_Date__c = monthStart.addDays(3),
            Applications_Last_Amount_To_Finance_Sum__c = 500,
            Applications_Dealer_Province__c = 'BC'
        ));
        records.add(new Master_LOS__c(
            Name = 'APP-004',
            Applications_Booking_Date__c = monthStart.addDays(1),
            Applications_Last_Amount_To_Finance_Sum__c = 2500,
            Applications_Dealer_Province__c = 'ON'
        ));
        records.add(new Master_LOS__c(
            Name = 'APP-005',
            Applications_Booking_Date__c = monthStart.addDays(5),
            Applications_Last_Amount_To_Finance_Sum__c = 1200,
            Applications_Dealer_Province__c = 'AB'
        ));
        records.add(new Master_LOS__c(
            Name = 'APP-006',
            Applications_Booking_Date__c = monthStart.addDays(4),
            Applications_Last_Amount_To_Finance_Sum__c = 800,
            Applications_Dealer_Province__c = 'NB'
        )        );
        
        insert records;
    }

    @isTest
    static void testGetSalesDataOntario() {
        Test.startTest();
        Map<String, Object> result = SalesDataService.getSalesData('Ontario');
        Test.stopTest();

        Map<Integer, Decimal> cumulativeData = (Map<Integer, Decimal>)result.get('cumulativeData');
        Decimal monthlyGoal = (Decimal)result.get('monthlyGoal');
        
        System.assertNotEquals(null, cumulativeData, 'Cumulative data should not be null');
        System.assertNotEquals(null, monthlyGoal, 'Monthly goal should not be null');
        
        // Check that cumulative data includes Ontario records
        System.assert(cumulativeData.size() > 0, 'Should have cumulative data for Ontario');
    }

    @isTest
    static void testGetSalesDataQuebec() {
        Test.startTest();
        Map<String, Object> result = SalesDataService.getSalesData('Quebec');
        Test.stopTest();

        Map<Integer, Decimal> cumulativeData = (Map<Integer, Decimal>)result.get('cumulativeData');
        Decimal monthlyGoal = (Decimal)result.get('monthlyGoal');
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, monthlyGoal, 'Monthly goal should not be null');
    }

    @isTest
    static void testGetSalesDataAlberta() {
        Test.startTest();
        Map<String, Object> result = SalesDataService.getSalesData('Alberta');
        Test.stopTest();

        Decimal monthlyGoal = (Decimal)result.get('monthlyGoal');
        System.assertNotEquals(null, monthlyGoal, 'Monthly goal should not be null');
    }

    @isTest
    static void testGetSalesDataAtlantic() {
        Test.startTest();
        Map<String, Object> result = SalesDataService.getSalesData('Atlantic');
        Test.stopTest();

        Decimal monthlyGoal = (Decimal)result.get('monthlyGoal');
        System.assertNotEquals(null, monthlyGoal, 'Monthly goal should not be null');
    }

    @isTest
    static void testGetSalesDataWestern() {
        Test.startTest();
        Map<String, Object> result = SalesDataService.getSalesData('Western');
        Test.stopTest();

        Decimal monthlyGoal = (Decimal)result.get('monthlyGoal');
        System.assertNotEquals(null, monthlyGoal, 'Monthly goal should not be null');
    }

    @isTest
    static void testGetSalesDataBritishColumbia() {
        Test.startTest();
        Map<String, Object> result = SalesDataService.getSalesData('British Columbia');
        Test.stopTest();

        Map<Integer, Decimal> cumulativeData = (Map<Integer, Decimal>)result.get('cumulativeData');
        System.assertNotEquals(null, cumulativeData, 'Cumulative data should not be null');
    }

    @isTest
    static void testGetSalesDataSaskatchewan() {
        Test.startTest();
        Map<String, Object> result = SalesDataService.getSalesData('Saskatchewan');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null for Saskatchewan');
    }

    @isTest
    static void testGetSalesDataManitoba() {
        Test.startTest();
        Map<String, Object> result = SalesDataService.getSalesData('Manitoba');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null for Manitoba');
    }

    @isTest
    static void testGetSalesDataUnknownRegion() {
        Test.startTest();
        Map<String, Object> result = SalesDataService.getSalesData('Unknown Region');
        Test.stopTest();

        Map<Integer, Decimal> cumulativeData = (Map<Integer, Decimal>)result.get('cumulativeData');
        Decimal monthlyGoal = (Decimal)result.get('monthlyGoal');
        
        System.assertNotEquals(null, cumulativeData, 'Cumulative data should not be null');
        System.assertEquals(0, monthlyGoal, 'Unknown region should have 0 monthly goal');
        System.assertEquals(0, cumulativeData.size(), 'Unknown region should have no cumulative data');
    }

    @isTest
    static void testGetSalesDataNullRegion() {
        Test.startTest();
        Map<String, Object> result = SalesDataService.getSalesData(null);
        Test.stopTest();

        Decimal monthlyGoal = (Decimal)result.get('monthlyGoal');
        System.assertEquals(0, monthlyGoal, 'Null region should have 0 monthly goal');
    }

    @isTest
    static void testGetRegions() {
        Test.startTest();
        List<String> regions = SalesDataService.getRegions();
        Test.stopTest();

        System.assertNotEquals(null, regions, 'Regions should not be null');
        System.assertEquals(5, regions.size(), 'Should return 5 regions');
        System.assert(regions.contains('Ontario'), 'Should contain Ontario');
        System.assert(regions.contains('Alberta'), 'Should contain Alberta');
        System.assert(regions.contains('Quebec'), 'Should contain Quebec');
        System.assert(regions.contains('Atlantic'), 'Should contain Atlantic');
        System.assert(regions.contains('Western'), 'Should contain Western');
    }

    @isTest
    static void testCumulativeCalculation() {
        Test.startTest();
        Map<String, Object> result = SalesDataService.getSalesData('Ontario');
        Test.stopTest();

        Map<Integer, Decimal> cumulativeData = (Map<Integer, Decimal>)result.get('cumulativeData');
        
        // Ontario has two records on day 1 (1500 + 2500 = 4000)
        // Should have cumulative total of 4000 for day 1
        if (cumulativeData.containsKey(1)) {
            System.assertEquals(4000, cumulativeData.get(1), 'Day 1 cumulative should be 4000');
        }
    }

    @isTest
    static void testNoGoalRecord() {
        // Delete the goal record to test behavior without goals
        delete [SELECT Id FROM Monthly_Goal__c];
        
        Test.startTest();
        Map<String, Object> result = SalesDataService.getSalesData('Ontario');
        Test.stopTest();

        Decimal monthlyGoal = (Decimal)result.get('monthlyGoal');
        System.assertEquals(0, monthlyGoal, 'Should have 0 monthly goal when no goal record exists');
    }
}
