@isTest
private class DealerWatchlistControllerTest_Simple {

    @TestSetup
    static void setupTestData() {
        Date currentTestDate = Date.today().addDays(-10);
        Date lastYearTestDate = currentTestDate.addYears(-1);
        List<Master_LOS__c> records = new List<Master_LOS__c>();
        
        // Current year data
        records.add(new Master_LOS__c(
            Applications_Dealer_Name__c = 'LMG Finance - Bowmanville',
            Applications_Booking_Date__c = currentTestDate,
            Applications_Dealer_Province__c = 'ON',
            Applications_Risk_Tier_Code__c = 'P1'
        ));
        
        // Last year data
        records.add(new Master_LOS__c(
            Applications_Dealer_Name__c = 'LMG Finance - Location1',
            Applications_Booking_Date__c = lastYearTestDate,
            Applications_Dealer_Province__c = 'ON',
            Applications_Risk_Tier_Code__c = 'P1'
        ));
        
        insert records;
    }

    @isTest
    static void testGetDealerWinnersLosers() {
        // Call controller
        List<DealerWatchlistController.RegionWinnersLosers> result = DealerWatchlistController.getDealerWinnersLosers(5, 'MonthOverMonth');
        
        // Should return one entry per defined region
        System.assertEquals(5, result.size(), 'Expected 5 regions in winners/losers');
        
        // In this simple scenario, no dealers should be flagged as winners or losers
        for (DealerWatchlistController.RegionWinnersLosers rw : result) {
            System.assertEquals(0, rw.winners.size(), 'No winners should be flagged in simple test');
            System.assertEquals(0, rw.losers.size(), 'No losers should be flagged in simple test');
        }
    }
}
