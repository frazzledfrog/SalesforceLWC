@isTest
private class TopDealersControllerTest {
    @isTest static void testGetTopDealers() {
        // Arrange: Create test data
        // No need to insert Account records, as TopDealersController queries Master_LOS__c
        // Insert Master_LOS__c records with required fields
        Master_LOS__c los1 = new Master_LOS__c(
            Applications_Dealer_Name__c = 'Dealer One',
            Applications_Dealer_Province__c = 'ON',
            Applications_Booking_Date__c = Date.today(),
            Applications_Last_Amount_To_Finance_Sum__c = 1000,
            Applications_Risk_Tier_Code__c = 'P1'
        );
        insert los1;

        // Act: Call the method under test
        Test.startTest();
        List<TopDealersController.AccountWrapper> result = TopDealersController.getTopDealers('Ontario');
        Test.stopTest();

        // Assert: Validate the results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Result should contain at least one dealer');
        System.assertEquals('Dealer One', result[0].accountName);
        System.assertEquals(1000, result[0].totalAmount);
    }

    @isTest 
    static void testGetTopDealersWithBlankRegion() {
        Test.startTest();
        List<TopDealersController.AccountWrapper> result = TopDealersController.getTopDealers('');
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return empty list for blank region');
    }

    @isTest 
    static void testGetTopDealersWithNullRegion() {
        Test.startTest();
        List<TopDealersController.AccountWrapper> result = TopDealersController.getTopDealers(null);
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return empty list for null region');
    }

    @isTest 
    static void testGetRegions() {
        Test.startTest();
        List<String> regions = TopDealersController.getRegions();
        Test.stopTest();
        
        System.assertNotEquals(null, regions, 'Regions should not be null');
        System.assertEquals(7, regions.size(), 'Should return 7 regions');
        System.assert(regions.contains('Ontario'), 'Should contain Ontario');
        System.assert(regions.contains('Alberta'), 'Should contain Alberta');
        System.assert(regions.contains('Quebec'), 'Should contain Quebec');
        System.assert(regions.contains('Atlantic'), 'Should contain Atlantic');
        System.assert(regions.contains('British Columbia'), 'Should contain British Columbia');
        System.assert(regions.contains('Saskatchewan'), 'Should contain Saskatchewan');
        System.assert(regions.contains('Manitoba'), 'Should contain Manitoba');
    }

    @isTest 
    static void testGetTopDealersMultipleRegions() {
        // Create test data for multiple regions
        List<Master_LOS__c> testRecords = new List<Master_LOS__c>();
        
        // Alberta data
        testRecords.add(new Master_LOS__c(
            Applications_Dealer_Name__c = 'Alberta Motors',
            Applications_Dealer_Province__c = 'AB',
            Applications_Booking_Date__c = Date.today(),
            Applications_Last_Amount_To_Finance_Sum__c = 2000,
            Applications_Risk_Tier_Code__c = 'P2'
        ));
        
        // Quebec data
        testRecords.add(new Master_LOS__c(
            Applications_Dealer_Name__c = 'Quebec Dealer',
            Applications_Dealer_Province__c = 'QC',
            Applications_Booking_Date__c = Date.today(),
            Applications_Last_Amount_To_Finance_Sum__c = 3000,
            Applications_Risk_Tier_Code__c = 'P1'
        ));
        
        // Atlantic data
        testRecords.add(new Master_LOS__c(
            Applications_Dealer_Name__c = 'Atlantic Dealer',
            Applications_Dealer_Province__c = 'NB',
            Applications_Booking_Date__c = Date.today(),
            Applications_Last_Amount_To_Finance_Sum__c = 1500,
            Applications_Risk_Tier_Code__c = 'P3'
        ));
        
        insert testRecords;
        
        Test.startTest();
        List<TopDealersController.AccountWrapper> albertaResult = TopDealersController.getTopDealers('Alberta');
        List<TopDealersController.AccountWrapper> quebecResult = TopDealersController.getTopDealers('Quebec');
        List<TopDealersController.AccountWrapper> atlanticResult = TopDealersController.getTopDealers('Atlantic');
        Test.stopTest();
        
        System.assertEquals(1, albertaResult.size(), 'Alberta should have 1 dealer');
        System.assertEquals('Alberta Motors', albertaResult[0].accountName);
        
        System.assertEquals(1, quebecResult.size(), 'Quebec should have 1 dealer');
        System.assertEquals('Quebec Dealer', quebecResult[0].accountName);
        
        System.assertEquals(1, atlanticResult.size(), 'Atlantic should have 1 dealer');
        System.assertEquals('Atlantic Dealer', atlanticResult[0].accountName);
    }

    @isTest 
    static void testIndividualDealers() {
        // Test that dealers with branches are treated as separate entities
        List<Master_LOS__c> testRecords = new List<Master_LOS__c>();
        
        testRecords.add(new Master_LOS__c(
            Applications_Dealer_Name__c = 'Test Motors - Main Branch',
            Applications_Dealer_Province__c = 'ON',
            Applications_Booking_Date__c = Date.today(),
            Applications_Last_Amount_To_Finance_Sum__c = 1000,
            Applications_Risk_Tier_Code__c = 'P1'
        ));
        
        testRecords.add(new Master_LOS__c(
            Applications_Dealer_Name__c = 'Test Motors - North Branch',
            Applications_Dealer_Province__c = 'ON',
            Applications_Booking_Date__c = Date.today(),
            Applications_Last_Amount_To_Finance_Sum__c = 1500,
            Applications_Risk_Tier_Code__c = 'P2'
        ));
        
        insert testRecords;
        
        Test.startTest();
        List<TopDealersController.AccountWrapper> result = TopDealersController.getTopDealers('Ontario');
        Test.stopTest();
        
        System.assertEquals(2, result.size(), 'Should treat dealers as separate entities');
        // Results are sorted by amount descending, so North Branch (1500) should be first
        System.assertEquals('Test Motors - North Branch', result[0].accountName);
        System.assertEquals(1500, result[0].totalAmount);
        System.assertEquals('Test Motors - Main Branch', result[1].accountName);
        System.assertEquals(1000, result[1].totalAmount);
    }

    @isTest 
    static void testFindAccountByDealerName() {
        // Create test Account
        Account testAccount = new Account(Name = 'Test Account Motor Sales');
        insert testAccount;
        
        Test.startTest();
        
        // Test exact match (via SOSL)
        TopDealersController.AccountLinkWrapper result1 = TopDealersController.findAccountByDealerName('Test Account Motor Sales');
        
        // Test partial match
        TopDealersController.AccountLinkWrapper result2 = TopDealersController.findAccountByDealerName('Test Account');
        
        // Test no match
        TopDealersController.AccountLinkWrapper result3 = TopDealersController.findAccountByDealerName('Non Existent Dealer');
        
        // Test blank input
        TopDealersController.AccountLinkWrapper result4 = TopDealersController.findAccountByDealerName('');
        
        Test.stopTest();
        
        System.assertNotEquals(null, result1, 'Should find exact match');
        System.assertEquals(testAccount.Id, result1.accountId, 'Should return correct account ID');
        
        System.assertNotEquals(null, result2, 'Should find partial match');
        System.assertEquals(testAccount.Id, result2.accountId, 'Should return correct account ID for partial match');
        
        System.assertNotEquals(null, result3, 'Should return wrapper even for no match');
        System.assertEquals(null, result3.accountId, 'Should have null ID for no match');
        System.assert(result3.accountName.contains('account not found'), 'Should indicate account not found');
        
        System.assertEquals(null, result4, 'Should return null for blank input');
    }

    @isTest 
    static void testAccountWrapperComparable() {
        // Test the Comparable implementation for sorting
        TopDealersController.AccountWrapper wrapper1 = new TopDealersController.AccountWrapper('Dealer A', 1000);
        TopDealersController.AccountWrapper wrapper2 = new TopDealersController.AccountWrapper('Dealer B', 2000);
        TopDealersController.AccountWrapper wrapper3 = new TopDealersController.AccountWrapper('Dealer C', 1000);
        
        List<TopDealersController.AccountWrapper> wrappers = new List<TopDealersController.AccountWrapper>{wrapper1, wrapper2, wrapper3};
        wrappers.sort();
        
        // Should be sorted by totalAmount descending
        System.assertEquals('Dealer B', wrappers[0].accountName, 'Highest amount should be first');
        System.assertEquals(2000, wrappers[0].totalAmount);
        
        // Dealers with same amount should maintain relative order
        System.assert(wrappers[1].totalAmount == 1000, 'Second should have 1000');
        System.assert(wrappers[2].totalAmount == 1000, 'Third should have 1000');
    }

    @isTest 
    static void testTopDealersLimit() {
        // Test that only top 5 dealers are returned
        List<Master_LOS__c> testRecords = new List<Master_LOS__c>();
        
        for (Integer i = 1; i <= 7; i++) {
            testRecords.add(new Master_LOS__c(
                Applications_Dealer_Name__c = 'Dealer ' + i,
                Applications_Dealer_Province__c = 'ON',
                Applications_Booking_Date__c = Date.today(),
                Applications_Last_Amount_To_Finance_Sum__c = 1000 * i,
                Applications_Risk_Tier_Code__c = 'P1'
            ));
        }
        
        insert testRecords;
        
        Test.startTest();
        List<TopDealersController.AccountWrapper> result = TopDealersController.getTopDealers('Ontario');
        Test.stopTest();
        
        System.assertEquals(5, result.size(), 'Should return maximum of 5 dealers');
        System.assertEquals('Dealer 7', result[0].accountName, 'Highest amount dealer should be first');
        System.assertEquals(7000, result[0].totalAmount);
    }

    @isTest 
    static void testRiskTierFiltering() {
        // Test that only valid risk tiers are included
        List<Master_LOS__c> testRecords = new List<Master_LOS__c>();
        
        testRecords.add(new Master_LOS__c(
            Applications_Dealer_Name__c = 'Valid Risk Dealer',
            Applications_Dealer_Province__c = 'ON',
            Applications_Booking_Date__c = Date.today(),
            Applications_Last_Amount_To_Finance_Sum__c = 1000,
            Applications_Risk_Tier_Code__c = 'P1'
        ));
        
        testRecords.add(new Master_LOS__c(
            Applications_Dealer_Name__c = 'Invalid Risk Dealer',
            Applications_Dealer_Province__c = 'ON',
            Applications_Booking_Date__c = Date.today(),
            Applications_Last_Amount_To_Finance_Sum__c = 2000,
            Applications_Risk_Tier_Code__c = 'INVALID'
        ));
        
        insert testRecords;
        
        Test.startTest();
        List<TopDealersController.AccountWrapper> result = TopDealersController.getTopDealers('Ontario');
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Should only include valid risk tiers');
        System.assertEquals('Valid Risk Dealer', result[0].accountName);
    }

    @isTest 
    static void testDateFiltering() {
        // Test that only records from current month are included
        List<Master_LOS__c> testRecords = new List<Master_LOS__c>();
        
        testRecords.add(new Master_LOS__c(
            Applications_Dealer_Name__c = 'Recent Dealer',
            Applications_Dealer_Province__c = 'ON',
            Applications_Booking_Date__c = Date.today(),
            Applications_Last_Amount_To_Finance_Sum__c = 1000,
            Applications_Risk_Tier_Code__c = 'P1'
        ));
        
        testRecords.add(new Master_LOS__c(
            Applications_Dealer_Name__c = 'Old Dealer',
            Applications_Dealer_Province__c = 'ON',
            Applications_Booking_Date__c = Date.today().addMonths(-1),
            Applications_Last_Amount_To_Finance_Sum__c = 2000,
            Applications_Risk_Tier_Code__c = 'P1'
        ));
        
        insert testRecords;
        
        Test.startTest();
        List<TopDealersController.AccountWrapper> result = TopDealersController.getTopDealers('Ontario');
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Should only include records from current month');
        System.assertEquals('Recent Dealer', result[0].accountName);
    }
}
