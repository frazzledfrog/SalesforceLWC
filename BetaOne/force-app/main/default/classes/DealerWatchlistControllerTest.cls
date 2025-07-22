@isTest
private class DealerWatchlistControllerTest {
    
    @TestSetup
    static void setupTestData() {
        Date today = Date.today();
        Date mtdStart = today.toStartOfMonth();
        Date prevMonthStart = mtdStart.addMonths(-1);
        Date prevMonthEnd = mtdStart.addDays(-1);
        
        List<Master_LOS__c> testRecords = new List<Master_LOS__c>();
        
        // Create test data for Ontario region - dealer that should appear in losers
        // Current month data (low performance) - 5000 total
        for (Integer i = 0; i < 5; i++) {
            testRecords.add(new Master_LOS__c(
                Name = 'CURR_ON_' + i,
                Applications_Dealer_Name__c = 'Ontario Underperformer Motors',
                Applications_Dealer_Province__c = 'ON',
                Applications_Booking_Date__c = mtdStart.addDays(i),
                Applications_Last_Amount_To_Finance_Sum__c = 1000,
                Applications_Risk_Tier_Code__c = 'P1',
                Applications_Business_Line__c = 'Recreational'
            ));
        }
        
        // Previous month data (high performance) - 15000 total
        for (Integer i = 0; i < 15; i++) {
            testRecords.add(new Master_LOS__c(
                Name = 'PREV_ON_' + i,
                Applications_Dealer_Name__c = 'Ontario Underperformer Motors',
                Applications_Dealer_Province__c = 'ON',
                Applications_Booking_Date__c = prevMonthStart.addDays(i),
                Applications_Last_Amount_To_Finance_Sum__c = 1000,
                Applications_Risk_Tier_Code__c = 'P1',
                Applications_Business_Line__c = 'Recreational'
            ));
        }
        
        // Create test data for Quebec region - 3000 current vs 12000 previous
        for (Integer i = 0; i < 3; i++) {
            testRecords.add(new Master_LOS__c(
                Name = 'CURR_QC_' + i,
                Applications_Dealer_Name__c = 'Quebec Declining Dealer',
                Applications_Dealer_Province__c = 'QC',
                Applications_Booking_Date__c = mtdStart.addDays(i),
                Applications_Last_Amount_To_Finance_Sum__c = 1000,
                Applications_Risk_Tier_Code__c = 'P2',
                Applications_Business_Line__c = 'Recreational'
            ));
        }
        
        // Previous month Quebec data - 12000 total
        for (Integer i = 0; i < 12; i++) {
            testRecords.add(new Master_LOS__c(
                Name = 'PREV_QC_' + i,
                Applications_Dealer_Name__c = 'Quebec Declining Dealer',
                Applications_Dealer_Province__c = 'QC',
                Applications_Booking_Date__c = prevMonthStart.addDays(i),
                Applications_Last_Amount_To_Finance_Sum__c = 1000,
                Applications_Risk_Tier_Code__c = 'P2',
                Applications_Business_Line__c = 'Recreational'
            ));
        }
        
        // Create test data for Atlantic region - 4000 current vs 13000 previous
        for (Integer i = 0; i < 4; i++) {
            testRecords.add(new Master_LOS__c(
                Name = 'CURR_ATL_' + i,
                Applications_Dealer_Name__c = 'Atlantic Declining Motors',
                Applications_Dealer_Province__c = 'NB',
                Applications_Booking_Date__c = mtdStart.addDays(i),
                Applications_Last_Amount_To_Finance_Sum__c = 1000,
                Applications_Risk_Tier_Code__c = 'P3',
                Applications_Business_Line__c = 'Recreational'
            ));
        }
        
        // Previous month Atlantic data - 13000 total
        for (Integer i = 0; i < 13; i++) {
            testRecords.add(new Master_LOS__c(
                Name = 'PREV_ATL_' + i,
                Applications_Dealer_Name__c = 'Atlantic Declining Motors',
                Applications_Dealer_Province__c = 'NB',
                Applications_Booking_Date__c = prevMonthStart.addDays(i),
                Applications_Last_Amount_To_Finance_Sum__c = 1000,
                Applications_Risk_Tier_Code__c = 'P3',
                Applications_Business_Line__c = 'Recreational'
            ));
        }
        
        // Create test data for Alberta region (year-over-year comparison) - 6000 current vs 18000 previous
        for (Integer i = 0; i < 6; i++) {
            testRecords.add(new Master_LOS__c(
                Name = 'CURR_YOY_' + i,
                Applications_Dealer_Name__c = 'YearOverYear Declining Dealer',
                Applications_Dealer_Province__c = 'AB',
                Applications_Booking_Date__c = mtdStart.addDays(i),
                Applications_Last_Amount_To_Finance_Sum__c = 1000,
                Applications_Risk_Tier_Code__c = 'P1',
                Applications_Business_Line__c = 'Recreational'
            ));
        }
        
        // Previous month data for year-over-year - 18000 total
        for (Integer i = 0; i < 18; i++) {
            testRecords.add(new Master_LOS__c(
                Name = 'PREV_YOY_' + i,
                Applications_Dealer_Name__c = 'YearOverYear Declining Dealer',
                Applications_Dealer_Province__c = 'AB',
                Applications_Booking_Date__c = prevMonthStart.addDays(i),
                Applications_Last_Amount_To_Finance_Sum__c = 1000,
                Applications_Risk_Tier_Code__c = 'P1',
                Applications_Business_Line__c = 'Recreational'
            ));
        }
        
        // Create test data for Prefera exclusion test - 8000 current vs 20000 previous  
        for (Integer i = 0; i < 8; i++) {
            testRecords.add(new Master_LOS__c(
                Name = 'CURR_PREF_' + i,
                Applications_Dealer_Name__c = 'Other Declining Dealer',
                Applications_Dealer_Province__c = 'BC',
                Applications_Booking_Date__c = mtdStart.addDays(i),
                Applications_Last_Amount_To_Finance_Sum__c = 1000,
                Applications_Risk_Tier_Code__c = 'P2',
                Applications_Business_Line__c = 'Recreational'
            ));
        }
        
        // Previous month data for Prefera exclusion - 20000 total
        for (Integer i = 0; i < 20; i++) {
            testRecords.add(new Master_LOS__c(
                Name = 'PREV_PREF_' + i,
                Applications_Dealer_Name__c = 'Other Declining Dealer',
                Applications_Dealer_Province__c = 'BC',
                Applications_Booking_Date__c = prevMonthStart.addDays(i),
                Applications_Last_Amount_To_Finance_Sum__c = 1000,
                Applications_Risk_Tier_Code__c = 'P2',
                Applications_Business_Line__c = 'Recreational'
            ));
        }
        
        // Create test data that should NOT appear (Prefera company) - 5000 current vs 25000 previous
        for (Integer i = 0; i < 5; i++) {
            testRecords.add(new Master_LOS__c(
                Name = 'CURR_PREF_EXCLUDE_' + i,
                Applications_Dealer_Name__c = 'Prefera Finance Test',
                Applications_Dealer_Province__c = 'ON',
                Applications_Booking_Date__c = mtdStart.addDays(i),
                Applications_Last_Amount_To_Finance_Sum__c = 1000,
                Applications_Risk_Tier_Code__c = 'P1',
                Applications_Business_Line__c = 'Recreational'
            ));
        }
        
        for (Integer i = 0; i < 25; i++) {
            testRecords.add(new Master_LOS__c(
                Name = 'PREV_PREF_EXCLUDE_' + i,
                Applications_Dealer_Name__c = 'Prefera Finance Test',
                Applications_Dealer_Province__c = 'ON',
                Applications_Booking_Date__c = prevMonthStart.addDays(i),
                Applications_Last_Amount_To_Finance_Sum__c = 1000,
                Applications_Risk_Tier_Code__c = 'P1',
                Applications_Business_Line__c = 'Recreational'
            ));
        }
        
        // Add 2024 test data for year-over-year comparison testing
        Date year2024Start = Date.newInstance(2024, 1, 1);
        Date year2024End = Date.newInstance(2024, 12, 31);
        
        // 2024 data for Alberta (should be loser in YoY comparison if YTD is lower)
        for (Integer i = 0; i < 20; i++) {
            testRecords.add(new Master_LOS__c(
                Name = 'Y2024_AB_' + i,
                Applications_Dealer_Name__c = 'Alberta Year Over Year Test',
                Applications_Dealer_Province__c = 'AB',
                Applications_Booking_Date__c = year2024Start.addDays(i * 10), // Spread throughout 2024
                Applications_Last_Amount_To_Finance_Sum__c = 2000, // Higher than current YTD
                Applications_Risk_Tier_Code__c = 'P1',
                Applications_Business_Line__c = 'Recreational'
            ));
        }
        
        // Current YTD data for Alberta (lower than 2024 total)
        Date ytdStart = Date.newInstance(Date.today().year(), 1, 1);
        for (Integer i = 0; i < 5; i++) {
            testRecords.add(new Master_LOS__c(
                Name = 'YTD_AB_' + i,
                Applications_Dealer_Name__c = 'Alberta Year Over Year Test',
                Applications_Dealer_Province__c = 'AB',
                Applications_Booking_Date__c = ytdStart.addDays(i * 30), // Spread throughout YTD
                Applications_Last_Amount_To_Finance_Sum__c = 1500, // Lower total than 2024
                Applications_Risk_Tier_Code__c = 'P1',
                Applications_Business_Line__c = 'Recreational'
            ));
        }
        
        insert testRecords;
    }
    
    @isTest
    static void testGetDealerWinnersLosers() {
        Test.startTest();
        List<DealerWatchlistController.RegionWinnersLosers> regions = DealerWatchlistController.getDealerWinnersLosers(5, 'MonthOverMonth');
        Test.stopTest();
        System.assertNotEquals(null, regions, 'Result should not be null');
        System.assertEquals(5, regions.size(), 'Should have 5 regions (Ontario, Alberta, Quebec, Atlantic, Western)');

        // Ontario region: should have a winner or loser for Ontario Underperformer Motors
        DealerWatchlistController.RegionWinnersLosers ontario = null;
        for (DealerWatchlistController.RegionWinnersLosers region : regions) {
            if (region.region == 'Ontario') {
                ontario = region;
                break;
            }
        }
        System.assertNotEquals(null, ontario, 'Ontario region should exist');
        Boolean found = false;
        for (DealerWatchlistController.DealerDelta d : ontario.losers) {
            if (d.name == 'Ontario Underperformer Motors') found = true;
        }
        System.assert(found, 'Ontario Underperformer Motors should be in losers');
    }

    @isTest
    static void testAtlanticRegionMapping() {
        Test.startTest();
        List<DealerWatchlistController.RegionWinnersLosers> regions = DealerWatchlistController.getDealerWinnersLosers(5, 'MonthOverMonth');
        Test.stopTest();
        DealerWatchlistController.RegionWinnersLosers atlantic = null;
        for (DealerWatchlistController.RegionWinnersLosers region : regions) {
            if (region.region == 'Atlantic') {
                atlantic = region;
                break;
            }
        }
        System.assertNotEquals(null, atlantic, 'Atlantic region should exist');
        Boolean found = false;
        for (DealerWatchlistController.DealerDelta d : atlantic.losers) {
            if (d.name == 'Atlantic Declining Motors') found = true;
        }
        System.assert(found, 'Atlantic Declining Motors should be in losers');
    }

    @isTest
    static void testQuebecRegionMapping() {
        Test.startTest();
        List<DealerWatchlistController.RegionWinnersLosers> regions = DealerWatchlistController.getDealerWinnersLosers(5, 'MonthOverMonth');
        Test.stopTest();
        DealerWatchlistController.RegionWinnersLosers quebec = null;
        for (DealerWatchlistController.RegionWinnersLosers region : regions) {
            if (region.region == 'Quebec') {
                quebec = region;
                break;
            }
        }
        System.assertNotEquals(null, quebec, 'Quebec region should exist');
        Boolean found = false;
        for (DealerWatchlistController.DealerDelta d : quebec.losers) {
            if (d.name == 'Quebec Declining Dealer') found = true;
        }
        System.assert(found, 'Quebec Declining Dealer should be in losers');
    }

    @isTest
    static void testYearOverYearComparison() {
        Test.startTest();
        List<DealerWatchlistController.RegionWinnersLosers> regions = DealerWatchlistController.getDealerWinnersLosers(5, 'YearOverYear');
        Test.stopTest();
        
        // Find Alberta region to verify year-over-year comparison
        DealerWatchlistController.RegionWinnersLosers alberta = null;
        for (DealerWatchlistController.RegionWinnersLosers region : regions) {
            if (region.region == 'Alberta') {
                alberta = region;
                break;
            }
        }
        System.assertNotEquals(null, alberta, 'Alberta region should exist');
        
        // Verify that Alberta Year Over Year Test dealer appears in losers 
        // (YTD total: 5 * 1500 = 7500, 2024 total: 20 * 2000 = 40000, delta = -32500)
        Boolean found = false;
        for (DealerWatchlistController.DealerDelta d : alberta.losers) {
            if (d.name == 'Alberta Year Over Year Test') {
                found = true;
                System.assert(d.delta < 0, 'Dealer should have negative delta for YoY comparison');
                System.assertEquals(7500, d.mtdAmount, 'YTD amount should be 7500');
                System.assertEquals(40000, d.prevMonthAmount, '2024 amount should be 40000');
                break;
            }
        }
        System.assert(found, 'Alberta Year Over Year Test dealer should be found in losers');
    }

    @isTest
    static void testPreferaDealerExclusion() {
        Test.startTest();
        List<DealerWatchlistController.RegionWinnersLosers> regions = DealerWatchlistController.getDealerWinnersLosers(5, 'MonthOverMonth');
        Test.stopTest();
        for (DealerWatchlistController.RegionWinnersLosers region : regions) {
            for (DealerWatchlistController.DealerDelta d : region.winners) {
                System.assert(!d.name.toLowerCase().contains('prefera'), 'Prefera dealers should be excluded');
            }
            for (DealerWatchlistController.DealerDelta d : region.losers) {
                System.assert(!d.name.toLowerCase().contains('prefera'), 'Prefera dealers should be excluded');
            }
        }
    }

    @isTest
    static void testEmptyWinnersLosers() {
        delete [SELECT Id FROM Master_LOS__c];
        Test.startTest();
        List<DealerWatchlistController.RegionWinnersLosers> regions = DealerWatchlistController.getDealerWinnersLosers(5, 'MonthOverMonth');
        Test.stopTest();
        System.assertNotEquals(null, regions, 'Result should not be null');
        System.assertEquals(5, regions.size(), 'Should have 5 regions');
        for (DealerWatchlistController.RegionWinnersLosers region : regions) {
            System.assertEquals(0, region.winners.size(), 'No winners in empty test');
            System.assertEquals(0, region.losers.size(), 'No losers in empty test');
        }
    }
}
