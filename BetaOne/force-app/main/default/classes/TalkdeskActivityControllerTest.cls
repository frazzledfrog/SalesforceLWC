// Test class for Talkdesk Activity Controller
@IsTest
public class TalkdeskActivityControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test user
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@test.com',
            Username = 'testuser@test.com.talkdesktest' + System.currentTimeMillis(),
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id
        );
        insert testUser;
        
        // Create test account and contact
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Email = 'testcontact@test.com'
        );
        insert testContact;
        
        // Create test Talkdesk activities
        List<talkdesk__Talkdesk_Activity__c> activities = new List<talkdesk__Talkdesk_Activity__c>();
        
        // Activity with conversation (talk time > 0)
        activities.add(new talkdesk__Talkdesk_Activity__c(
            OwnerId = testUser.Id,
            talkdesk__Contact__c = testContact.Id,
            talkdesk__Account__c = testAccount.Id,
            talkdesk__Channel__c = 'voice',
            talkdesk__Direction__c = 'inbound',
            talkdesk__Talk_Time_sec__c = 300,
            talkdesk__Talkdesk_Id__c = 'test-activity-1',
            Name = 'Test Activity 1'
        ));
        
        // Activity without conversation (talk time = 0) - should be excluded
        activities.add(new talkdesk__Talkdesk_Activity__c(
            OwnerId = testUser.Id,
            talkdesk__Contact__c = testContact.Id,
            talkdesk__Account__c = testAccount.Id,
            talkdesk__Channel__c = 'voice',
            talkdesk__Direction__c = 'outbound',
            talkdesk__Talk_Time_sec__c = 0,
            talkdesk__Talkdesk_Id__c = 'test-activity-2',
            Name = 'Test Activity 2'
        ));
        
        // Activity without contact - should be excluded
        activities.add(new talkdesk__Talkdesk_Activity__c(
            OwnerId = testUser.Id,
            talkdesk__Account__c = testAccount.Id,
            talkdesk__Channel__c = 'voice',
            talkdesk__Direction__c = 'inbound',
            talkdesk__Talk_Time_sec__c = 200,
            talkdesk__Talkdesk_Id__c = 'test-activity-3',
            Name = 'Test Activity 3'
        ));
        
        // Valid outbound activity
        activities.add(new talkdesk__Talkdesk_Activity__c(
            OwnerId = testUser.Id,
            talkdesk__Contact__c = testContact.Id,
            talkdesk__Account__c = testAccount.Id,
            talkdesk__Channel__c = 'voice',
            talkdesk__Direction__c = 'outbound',
            talkdesk__Talk_Time_sec__c = 180,
            talkdesk__Talkdesk_Id__c = 'test-activity-4',
            Name = 'Test Activity 4'
        ));
        
        insert activities;
    }
    
    @IsTest
    static void testGetSalespeople() {
        Test.startTest();
        List<TalkdeskActivityController.SalespersonInfo> salespeople = TalkdeskActivityController.getSalespeople();
        Test.stopTest();
        
        System.assertNotEquals(null, salespeople, 'Salespeople list should not be null');
        System.assertEquals(1, salespeople.size(), 'Should return one salesperson with valid activities');
        System.assertEquals('Test User', salespeople[0].name, 'Should return the correct user name');
    }
    
    @IsTest
    static void testGetTalkdeskActivityDataWithFilters() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'User' LIMIT 1];
        
        Test.startTest();
        
        // Test with all filters
        List<TalkdeskActivityController.TalkdeskActivityData> activities = 
            TalkdeskActivityController.getTalkdeskActivityData(
                testUser.Id, 
                'voice', 
                'inbound', 
                'today'
            );
        
        Test.stopTest();
        
        System.assertNotEquals(null, activities, 'Activities list should not be null');
        // Should return one inbound voice activity
        for (TalkdeskActivityController.TalkdeskActivityData activity : activities) {
            System.assertEquals('voice', activity.channel.toLowerCase(), 'Channel should be voice');
            System.assertEquals('inbound', activity.direction.toLowerCase(), 'Direction should be inbound');
            System.assert(activity.totalActivities >= 0, 'Should have non-negative activity count');
        }
    }
    
    @IsTest
    static void testGetTalkdeskActivityDataNoFilters() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'User' LIMIT 1];
        
        Test.startTest();
        
        // Test without filters
        List<TalkdeskActivityController.TalkdeskActivityData> activities = 
            TalkdeskActivityController.getTalkdeskActivityData(
                testUser.Id, 
                null, 
                null, 
                'today'
            );
        
        Test.stopTest();
        
        System.assertNotEquals(null, activities, 'Activities list should not be null');
        // Should return activities for valid conversations
        for (TalkdeskActivityController.TalkdeskActivityData activity : activities) {
            System.assert(activity.totalActivities >= 0, 'Should have non-negative activity count');
            System.assertNotEquals(null, activity.channel, 'Channel should not be null');
            System.assertNotEquals(null, activity.direction, 'Direction should not be null');
        }
    }
    
    @IsTest
    static void testGetChannelOptions() {
        Test.startTest();
        List<String> channels = TalkdeskActivityController.getChannelOptions();
        Test.stopTest();
        
        System.assertNotEquals(null, channels, 'Channels list should not be null');
        System.assert(channels.size() > 0, 'Should return at least one channel option');
    }
    
    @IsTest
    static void testGetDirectionOptions() {
        Test.startTest();
        List<String> directions = TalkdeskActivityController.getDirectionOptions();
        Test.stopTest();
        
        System.assertNotEquals(null, directions, 'Directions list should not be null');
        System.assert(directions.size() > 0, 'Should return at least one direction option');
    }
    
    @IsTest
    static void testGetTalkdeskActivityDataDifferentTimeframes() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'User' LIMIT 1];
        
        Test.startTest();
        
        // Test different timeframes
        List<TalkdeskActivityController.TalkdeskActivityData> todayActivities = 
            TalkdeskActivityController.getTalkdeskActivityData(testUser.Id, null, null, 'today');
        
        List<TalkdeskActivityController.TalkdeskActivityData> weekActivities = 
            TalkdeskActivityController.getTalkdeskActivityData(testUser.Id, null, null, 'week');
        
        List<TalkdeskActivityController.TalkdeskActivityData> monthActivities = 
            TalkdeskActivityController.getTalkdeskActivityData(testUser.Id, null, null, 'month');
        
        Test.stopTest();
        
        System.assertNotEquals(null, todayActivities, 'Today activities should not be null');
        System.assertNotEquals(null, weekActivities, 'Week activities should not be null');
        System.assertNotEquals(null, monthActivities, 'Month activities should not be null');
        
        // All timeframes should return the same or more activities (week >= today, month >= week)
        System.assert(weekActivities.size() >= todayActivities.size(), 'Week should have at least as many activities as today');
        System.assert(monthActivities.size() >= weekActivities.size(), 'Month should have at least as many activities as week');
    }
    
    @IsTest
    static void testGetPerformanceInsights() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'User' LIMIT 1];
        
        Test.startTest();
        
        Map<String, Object> insights = TalkdeskActivityController.getPerformanceInsights(testUser.Id, 'today');
        
        Test.stopTest();
        
        System.assertNotEquals(null, insights, 'Insights should not be null');
        System.assert(insights.containsKey('totalCalls'), 'Should contain totalCalls');
        System.assert(insights.containsKey('totalTalkTime'), 'Should contain totalTalkTime');
        System.assert(insights.containsKey('successRate'), 'Should contain successRate');
        System.assert(insights.containsKey('totalAttempts'), 'Should contain totalAttempts');
        
        // Validate data types and ranges
        Integer totalCalls = (Integer) insights.get('totalCalls');
        System.assert(totalCalls >= 0, 'Total calls should be non-negative');
        
        Decimal successRate = (Decimal) insights.get('successRate');
        System.assert(successRate >= 0 && successRate <= 100, 'Success rate should be between 0 and 100');
    }
    
    @IsTest
    static void testErrorHandling() {
        Test.startTest();
        
        try {
            // Test with invalid salesperson ID
            List<TalkdeskActivityController.TalkdeskActivityData> activities = 
                TalkdeskActivityController.getTalkdeskActivityData(
                    'invalid_id', 
                    null, 
                    null, 
                    'today'
                );
            // Should not throw exception but return empty list
            System.assertNotEquals(null, activities, 'Should return empty list for invalid ID');
        } catch (Exception e) {
            // Exception handling test
            System.assert(e instanceof AuraHandledException, 'Should throw AuraHandledException');
        }
        
        Test.stopTest();
    }
}
