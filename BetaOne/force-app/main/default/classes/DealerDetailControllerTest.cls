@isTest
public class DealerDetailControllerTest {
    
    @TestSetup
    static void makeData() {
        List<Master_LOS__c> testRecords = new List<Master_LOS__c>();
        
        Date today = Date.today();
        Date monthStart = today.toStartOfMonth();
        Date lastMonth = monthStart.addMonths(-1);
        Date lastMonthEnd = monthStart.addDays(-1);
        Date lastYear = today.addYears(-1);
        
        // Create recent records - within current month for dealer options
        testRecords.add(new Master_LOS__c(
            Name = 'APP001',
            Applications_Dealer_Name__c = 'Test Motors - Main Branch',
            Applications_Dealer_Province__c = 'ON',
            Applications_Booking_Date__c = monthStart,
            Applications_Last_Amount_To_Finance_Sum__c = 25000
        ));
        
        testRecords.add(new Master_LOS__c(
            Name = 'APP002',
            Applications_Dealer_Name__c = 'Test Motors - North Branch',
            Applications_Dealer_Province__c = 'ON',
            Applications_Booking_Date__c = monthStart,
            Applications_Last_Amount_To_Finance_Sum__c = 30000
        ));
        
        testRecords.add(new Master_LOS__c(
            Name = 'APP003',
            Applications_Dealer_Name__c = 'Alberta Cars Inc',
            Applications_Dealer_Province__c = 'AB',
            Applications_Booking_Date__c = monthStart,
            Applications_Last_Amount_To_Finance_Sum__c = 40000
        ));

        testRecords.add(new Master_LOS__c(
            Name = 'APP004',
            Applications_Dealer_Name__c = 'Alberta Cars Inc',
            Applications_Dealer_Province__c = 'AB',
            Applications_Booking_Date__c = monthStart,
            Applications_Last_Amount_To_Finance_Sum__c = 40000
        ));

        testRecords.add(new Master_LOS__c(
            Name = 'APP005',
            Applications_Dealer_Name__c = 'Alberta Cars Inc',
            Applications_Dealer_Province__c = 'AB',
            Applications_Booking_Date__c = monthStart,
            Applications_Last_Amount_To_Finance_Sum__c = 40000
        ));
        
        // Create last month records
        testRecords.add(new Master_LOS__c(
            Name = 'APP006',
            Applications_Dealer_Name__c = 'Test Motors - Main Branch',
            Applications_Dealer_Province__c = 'ON',
            Applications_Booking_Date__c = lastMonthEnd.addDays(-5),
            Applications_Last_Amount_To_Finance_Sum__c = 20000
        ));
        
        testRecords.add(new Master_LOS__c(
            Name = 'APP007',
            Applications_Dealer_Name__c = 'Alberta Cars Inc',
            Applications_Dealer_Province__c = 'AB',
            Applications_Booking_Date__c = lastMonthEnd.addDays(-10),
            Applications_Last_Amount_To_Finance_Sum__c = 35000
        ));
        
        // Create older records for chart data
        testRecords.add(new Master_LOS__c(
            Name = 'APP008',
            Applications_Dealer_Name__c = 'Alberta Cars Inc',
            Applications_Dealer_Province__c = 'AB',
            Applications_Booking_Date__c = today.addMonths(-3),
            Applications_Last_Amount_To_Finance_Sum__c = 15000
        ));
        
        testRecords.add(new Master_LOS__c(
            Name = 'APP009',
            Applications_Dealer_Name__c = 'Alberta Cars Inc',
            Applications_Dealer_Province__c = 'AB',
            Applications_Booking_Date__c = today.addMonths(-6),
            Applications_Last_Amount_To_Finance_Sum__c = 22000
        ));
        
        testRecords.add(new Master_LOS__c(
            Name = 'APP010',
            Applications_Dealer_Name__c = 'Alberta Cars Inc',
            Applications_Dealer_Province__c = 'AB',
            Applications_Booking_Date__c = lastYear,
            Applications_Last_Amount_To_Finance_Sum__c = 18000
        ));
        
        // Create records with null amounts
        testRecords.add(new Master_LOS__c(
            Name = 'APP011',
            Applications_Dealer_Name__c = 'Test Motors - Main Branch',
            Applications_Dealer_Province__c = 'ON',
            Applications_Booking_Date__c = monthStart,
            Applications_Last_Amount_To_Finance_Sum__c = null
        ));
        
        insert testRecords;
    }
    
    @isTest
    static void testGetDealerOptions() {
        Test.startTest();
        
        List<DealerDetailController.DealerOption> options = DealerDetailController.getDealerOptions();
        
        Test.stopTest();
        
        System.assertNotEquals(null, options, 'Options should not be null');
        System.assertNotEquals(0, options.size(), 'Should have dealer options');
        
        // Verify structure of first option
        DealerDetailController.DealerOption firstOption = options[0];
        System.assertNotEquals(null, firstOption.id, 'Option ID should not be null');
        System.assertNotEquals(null, firstOption.name, 'Option name should not be null');
        System.assertNotEquals(null, firstOption.region, 'Option region should not be null');
        
        // Check that we have the expected dealers
        Set<String> dealerNames = new Set<String>();
        for (DealerDetailController.DealerOption option : options) {
            dealerNames.add(option.name);
        }
        
        System.assert(dealerNames.contains('Test Motors - Main Branch'), 'Should contain Test Motors - Main Branch');
        System.assert(dealerNames.contains('Test Motors - North Branch'), 'Should contain Test Motors - North Branch');
        System.assert(dealerNames.contains('Alberta Cars Inc'), 'Should contain Alberta Cars Inc');
    }
    
    @isTest
    static void testGetDealerDetails() {
        Test.startTest();
        
        // Get dealer options first to get a valid ID
        List<DealerDetailController.DealerOption> options = DealerDetailController.getDealerOptions();
        String dealerId = options[0].id;
        
        DealerDetailController.DealerDetails details = DealerDetailController.getDealerDetails(dealerId);
        
        Test.stopTest();
        
        System.assertNotEquals(null, details, 'Details should not be null');
        System.assertNotEquals(null, details.name, 'Name should not be null');
        System.assertNotEquals(null, details.region, 'Region should not be null');
        System.assert(details.monthlyDeals >= 0, 'Monthly deals should be non-negative');
        System.assert(details.totalFinancedAmount >= 0, 'Total financed should be non-negative');
    }
    
    @isTest
    static void testGetDealerDetailsWithInvalidId() {
        Test.startTest();
        
        Boolean exceptionThrown = false;
        try {
            DealerDetailController.getDealerDetails('invalid_id');
        } catch (Exception e) {
            exceptionThrown = true;
            System.assert(e instanceof AuraHandledException, 'Should throw AuraHandledException but got: ' + e.getTypeName());
        }
        
        System.assert(exceptionThrown, 'Should have thrown an exception for invalid dealer ID');
        Test.stopTest();
    }
    
    @isTest
    static void testGetDealerChartData() {
        Test.startTest();
        
        // Get dealer options first to get a valid ID
        List<DealerDetailController.DealerOption> options = DealerDetailController.getDealerOptions();
        String dealerId = options[0].id;
        
        DealerDetailController.ChartData chartData = DealerDetailController.getDealerChartData(dealerId);
        
        Test.stopTest();
        
        System.assertNotEquals(null, chartData, 'Chart data should not be null');
        System.assertNotEquals(null, chartData.monthlyData, 'Monthly data should not be null');
        System.assertEquals(12, chartData.monthlyData.size(), 'Should return 12 months of data');
        
        // Verify data structure
        for (DealerDetailController.MonthlyData monthData : chartData.monthlyData) {
            System.assertNotEquals(null, monthData.month, 'Month should not be null');
            System.assert(monthData.dealCount >= 0, 'Deal count should be non-negative');
            System.assert(monthData.totalFinanced >= 0, 'Total financed should be non-negative');
        }
    }
    
    @isTest
    static void testGetDealerChartDataWithPeriod() {
        Test.startTest();
        
        // Get dealer options first to get a valid ID
        List<DealerDetailController.DealerOption> options = DealerDetailController.getDealerOptions();
        String dealerId = options[0].id;
        
        // Test with 3 months
        DealerDetailController.ChartData chartData3 = DealerDetailController.getDealerChartDataWithPeriod(dealerId, 3);
        
        // Test with 6 months
        DealerDetailController.ChartData chartData6 = DealerDetailController.getDealerChartDataWithPeriod(dealerId, 6);
        
        // Test with 24 months
        DealerDetailController.ChartData chartData24 = DealerDetailController.getDealerChartDataWithPeriod(dealerId, 24);
        
        Test.stopTest();
        
        // Verify 3 months data
        System.assertNotEquals(null, chartData3, '3 month chart data should not be null');
        System.assertNotEquals(null, chartData3.monthlyData, '3 month monthly data should not be null');
        System.assertEquals(3, chartData3.monthlyData.size(), 'Should return 3 months of data');
        
        // Verify 6 months data
        System.assertNotEquals(null, chartData6, '6 month chart data should not be null');
        System.assertEquals(6, chartData6.monthlyData.size(), 'Should return 6 months of data');
        
        // Verify 24 months data
        System.assertNotEquals(null, chartData24, '24 month chart data should not be null');
        System.assertEquals(24, chartData24.monthlyData.size(), 'Should return 24 months of data');
        
        // Verify data structure for each period
        for (DealerDetailController.MonthlyData monthData : chartData3.monthlyData) {
            System.assertNotEquals(null, monthData.month, 'Month should not be null');
            System.assert(monthData.dealCount >= 0, 'Deal count should be non-negative');
            System.assert(monthData.totalFinanced >= 0, 'Total financed should be non-negative');
        }
    }
    
    @isTest
    static void testGetDealerChartDataMax() {
        Test.startTest();
        
        // Get dealer options first to get a valid ID
        List<DealerDetailController.DealerOption> options = DealerDetailController.getDealerOptions();
        String dealerId = options[0].id;
        
        DealerDetailController.ChartData chartData = DealerDetailController.getDealerChartDataMax(dealerId);
        
        Test.stopTest();
        
        System.assertNotEquals(null, chartData, 'Max chart data should not be null');
        System.assertNotEquals(null, chartData.monthlyData, 'Max monthly data should not be null');
        System.assert(chartData.monthlyData.size() >= 1, 'Should return at least 1 month of data');
        
        // Verify data structure
        for (DealerDetailController.MonthlyData monthData : chartData.monthlyData) {
            System.assertNotEquals(null, monthData.month, 'Month should not be null');
            System.assert(monthData.dealCount >= 0, 'Deal count should be non-negative');
            System.assert(monthData.totalFinanced >= 0, 'Total financed should be non-negative');
        }
    }
    
    @isTest
    static void testGetDealerChartDataMaxWithNoDealHistory() {
        Test.startTest();
        
        // Test with a dealer that has no historical deals by using a valid format
        // but nonexistent dealer name
        String fakeDealerId = EncodingUtil.base64Encode(Blob.valueOf('NonExistentDealer|XX'));
        
        DealerDetailController.ChartData chartData = DealerDetailController.getDealerChartDataMax(fakeDealerId);
        
        Test.stopTest();
        
        System.assertNotEquals(null, chartData, 'Chart data should not be null even with no history');
        System.assertNotEquals(null, chartData.monthlyData, 'Monthly data should not be null');
        System.assertEquals(0, chartData.monthlyData.size(), 'Should return empty data for dealer with no history');
    }
    
    @isTest
    static void testGetDealerChartDataWithPeriodEdgeCases() {
        Test.startTest();
        
        // Get dealer options first to get a valid ID
        List<DealerDetailController.DealerOption> options = DealerDetailController.getDealerOptions();
        String dealerId = options[0].id;
        
        // Test with null monthsBack (should default to 12)
        DealerDetailController.ChartData chartDataNull = DealerDetailController.getDealerChartDataWithPeriod(dealerId, null);
        
        // Test with zero monthsBack (should default to 12)
        DealerDetailController.ChartData chartDataZero = DealerDetailController.getDealerChartDataWithPeriod(dealerId, 0);
        
        // Test with negative monthsBack (should default to 12)
        DealerDetailController.ChartData chartDataNegative = DealerDetailController.getDealerChartDataWithPeriod(dealerId, -5);
        
        Test.stopTest();
        
        // All should default to 12 months
        System.assertEquals(12, chartDataNull.monthlyData.size(), 'Null months should default to 12');
        System.assertEquals(12, chartDataZero.monthlyData.size(), 'Zero months should default to 12');
        System.assertEquals(12, chartDataNegative.monthlyData.size(), 'Negative months should default to 12');
    }
}
