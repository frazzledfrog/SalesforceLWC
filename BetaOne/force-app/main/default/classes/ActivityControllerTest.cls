@isTest
public class ActivityControllerTest {
    
    @testSetup
    static void makeData() {
        // Create test tasks with standard Type field
        List<Task> testTasks = new List<Task>();
        
        // Create tasks for different call types and owners
        testTasks.add(new Task(
            Subject = 'Test Call Back',
            Type = 'Call',
            ActivityDate = Date.today().addDays(-5),
            OwnerId = UserInfo.getUserId(),
            Status = 'Completed'
        ));
        
        testTasks.add(new Task(
            Subject = 'Test Email',
            Type = 'Email',
            ActivityDate = Date.today().addDays(-10),
            OwnerId = UserInfo.getUserId(),
            Status = 'Completed'
        ));
        
        testTasks.add(new Task(
            Subject = 'Test Meeting',
            Type = 'Meeting',
            ActivityDate = Date.today().addDays(-15),
            OwnerId = UserInfo.getUserId(),
            Status = 'Completed'
        ));
        
        insert testTasks;
    }
    
    @isTest
    static void testGetSalespeople() {
        Test.startTest();
        
        List<ActivityController.SalespersonInfo> salespeople = ActivityController.getSalespeople();
        
        Test.stopTest();
        
        System.assertNotEquals(null, salespeople, 'Salespeople list should not be null');
        // Note: May be empty if no tasks exist in test context
    }
    
    @isTest
    static void testGetActivityData() {
        Test.startTest();
        
        List<ActivityController.ActivityData> activityData = ActivityController.getActivityData(null, null, '30');
        
        Test.stopTest();
        
        System.assertNotEquals(null, activityData, 'Activity data should not be null');
    }
    
    @isTest
    static void testGetActivityDataWithFilters() {
        Test.startTest();
        
        // Test with specific salesperson and task type
        String currentUserId = UserInfo.getUserId();
        List<ActivityController.ActivityData> activityData = ActivityController.getActivityData(currentUserId, 'Call', '30');
        
        Test.stopTest();
        
        System.assertNotEquals(null, activityData, 'Activity data should not be null');
    }
    
    @isTest
    static void testGetActivityDataWithDifferentTimeframes() {
        Test.startTest();
        
        // Test different timeframes
        List<ActivityController.ActivityData> data7Days = ActivityController.getActivityData(null, null, '7');
        List<ActivityController.ActivityData> data90Days = ActivityController.getActivityData(null, null, '90');
        List<ActivityController.ActivityData> dataQuarter = ActivityController.getActivityData(null, null, 'quarter');
        List<ActivityController.ActivityData> dataYear = ActivityController.getActivityData(null, null, 'year');
        
        Test.stopTest();
        
        System.assertNotEquals(null, data7Days, '7-day data should not be null');
        System.assertNotEquals(null, data90Days, '90-day data should not be null');
        System.assertNotEquals(null, dataQuarter, 'Quarter data should not be null');
        System.assertNotEquals(null, dataYear, 'Year data should not be null');
    }
    
    @isTest
    static void testGetActivityDataWithInvalidTimeframe() {
        Test.startTest();
        
        // Test with invalid timeframe - should default to 30 days
        List<ActivityController.ActivityData> activityData = ActivityController.getActivityData(null, null, 'invalid');
        
        Test.stopTest();
        
        System.assertNotEquals(null, activityData, 'Activity data should not be null');
    }

    @isTest
    static void testGetActivityDataEdgeCases() {
        Test.startTest();
        
        // Test with specific user that doesn't exist
        List<ActivityController.ActivityData> noUserData = ActivityController.getActivityData('fakeuserid', null, '30');
        
        // Test with specific task type
        List<ActivityController.ActivityData> callData = ActivityController.getActivityData(null, 'Call', '30');
        
        // Test with combination of filters
        List<ActivityController.ActivityData> combinedData = ActivityController.getActivityData(UserInfo.getUserId(), 'Email', '7');
        
        Test.stopTest();
        
        System.assertNotEquals(null, noUserData, 'Data should not be null even for non-existent user');
        System.assertNotEquals(null, callData, 'Call data should not be null');
        System.assertNotEquals(null, combinedData, 'Combined filter data should not be null');
    }

    @isTest
    static void testGetSalespeopleWithNoMatchingUsers() {
        Test.startTest();
        
        // Since test context may not have users with specific names, test the method works
        List<ActivityController.SalespersonInfo> salespeople = ActivityController.getSalespeople();
        
        Test.stopTest();
        
        System.assertNotEquals(null, salespeople, 'Salespeople list should not be null');
        // Note: May be empty if no users match the criteria in test context
    }

    @isTest
    static void testActivityDataWrapperClass() {
        // Test the ActivityData wrapper class properties
        ActivityController.ActivityData activity = new ActivityController.ActivityData();
        activity.id = 'test_id';
        activity.salespersonId = UserInfo.getUserId();
        activity.salespersonName = 'Test User';
        activity.eventType = 'Call';
        activity.totalActivities = 5;
        
        System.assertEquals('test_id', activity.id, 'ID should be set correctly');
        System.assertEquals(UserInfo.getUserId(), activity.salespersonId, 'Salesperson ID should be set correctly');
        System.assertEquals('Test User', activity.salespersonName, 'Salesperson name should be set correctly');
        System.assertEquals('Call', activity.eventType, 'Event type should be set correctly');
        System.assertEquals(5, activity.totalActivities, 'Total activities should be set correctly');
    }

    @isTest
    static void testSalespersonInfoWrapperClass() {
        // Test the SalespersonInfo wrapper class properties
        ActivityController.SalespersonInfo person = new ActivityController.SalespersonInfo();
        person.id = UserInfo.getUserId();
        person.name = 'Test Person';
        
        System.assertEquals(UserInfo.getUserId(), person.id, 'ID should be set correctly');
        System.assertEquals('Test Person', person.name, 'Name should be set correctly');
    }

    @isTest
    static void testGetActivityDataWithBlankFilters() {
        Test.startTest();
        
        // Test with blank/empty string filters
        List<ActivityController.ActivityData> blankUserData = ActivityController.getActivityData('', '', '');
        List<ActivityController.ActivityData> nullFilterData = ActivityController.getActivityData(null, null, null);
        
        Test.stopTest();
        
        System.assertNotEquals(null, blankUserData, 'Blank filter data should not be null');
        System.assertNotEquals(null, nullFilterData, 'Null filter data should not be null');
    }
}
