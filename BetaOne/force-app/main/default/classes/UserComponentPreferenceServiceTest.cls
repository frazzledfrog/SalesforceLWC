// Test class for User Component Preference Service
@isTest
private class UserComponentPreferenceServiceTest {
    @isTest 
    static void testGetAndSetLastRegion() {
        // Create a test user with a unique username
        User u = new User(
            Username = 'testuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert u;
        System.runAs(u) {
            String componentName = 'TestComponent';
            // Should return null if no preference exists
            String region = UserComponentPreferenceService.getLastRegion(componentName);
            System.assertEquals(null, region, 'Should be null initially');

            // Set a region
            UserComponentPreferenceService.setLastRegion(componentName, 'EMEA');
            // Should return the set region
            String region2 = UserComponentPreferenceService.getLastRegion(componentName);
            System.assertEquals('EMEA', region2, 'Should return the set region');

            // Update the region
            UserComponentPreferenceService.setLastRegion(componentName, 'APAC');
            String region3 = UserComponentPreferenceService.getLastRegion(componentName);
            System.assertEquals('APAC', region3, 'Should return the updated region');
        }
    }

    @isTest 
    static void testGetAndSetLastDealerId() {
        User u = new User(
            Username = 'testuser2' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser2',
            Email = 'testuser2@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert u;
        System.runAs(u) {
            String componentName = 'TestComponent';
            
            // Should return null if no preference exists
            String dealerId = UserComponentPreferenceService.getLastDealerId(componentName);
            System.assertEquals(null, dealerId, 'Should be null initially');

            // Set a dealer ID
            UserComponentPreferenceService.setLastDealerId(componentName, 'dealer123');
            String dealerId2 = UserComponentPreferenceService.getLastDealerId(componentName);
            System.assertEquals('dealer123', dealerId2, 'Should return the set dealer ID');

            // Update the dealer ID
            UserComponentPreferenceService.setLastDealerId(componentName, 'dealer456');
            String dealerId3 = UserComponentPreferenceService.getLastDealerId(componentName);
            System.assertEquals('dealer456', dealerId3, 'Should return the updated dealer ID');
        }
    }

    @isTest 
    static void testGetAndSetLastSalesperson() {
        User u = new User(
            Username = 'testuser3' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser3',
            Email = 'testuser3@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test3',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert u;
        System.runAs(u) {
            String componentName = 'TestSalespersonComponent';
            
            // Should return null if no preference exists
            String salesperson = UserComponentPreferenceService.getLastSalesperson(componentName);
            System.assertEquals(null, salesperson, 'Should be null initially');

            // Set a salesperson
            UserComponentPreferenceService.setLastSalesperson(componentName, 'salesperson123');
            String salesperson2 = UserComponentPreferenceService.getLastSalesperson(componentName);
            System.assertEquals('salesperson123', salesperson2, 'Should return the set salesperson');

            // Update the salesperson
            UserComponentPreferenceService.setLastSalesperson(componentName, 'salesperson456');
            String salesperson3 = UserComponentPreferenceService.getLastSalesperson(componentName);
            System.assertEquals('salesperson456', salesperson3, 'Should return the updated salesperson');
        }
    }

    @isTest 
    static void testMultipleComponents() {
        User u = new User(
            Username = 'testuser4' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser4',
            Email = 'testuser4@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test4',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert u;
        System.runAs(u) {
            String component1 = 'Component1';
            String component2 = 'Component2';
            
            // Set preferences for different components using region
            UserComponentPreferenceService.setLastRegion(component1, 'EMEA');
            UserComponentPreferenceService.setLastRegion(component2, 'AMERICAS');
            
            // Verify each component has its own preferences
            String region1 = UserComponentPreferenceService.getLastRegion(component1);
            String region2 = UserComponentPreferenceService.getLastRegion(component2);
            
            System.assertEquals('EMEA', region1, 'Component1 should have EMEA region');
            System.assertEquals('AMERICAS', region2, 'Component2 should have AMERICAS region');
            
            // Test dealer ID methods on different components
            UserComponentPreferenceService.setLastDealerId(component1, 'dealer111');
            UserComponentPreferenceService.setLastDealerId(component2, 'dealer222');
            
            String dealer1 = UserComponentPreferenceService.getLastDealerId(component1);
            String dealer2 = UserComponentPreferenceService.getLastDealerId(component2);
            
            System.assertEquals('dealer111', dealer1, 'Component1 should have dealer111');
            System.assertEquals('dealer222', dealer2, 'Component2 should have dealer222');
        }
    }

    @isTest 
    static void testNullAndBlankInputs() {
        User u = new User(
            Username = 'testuser5' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser5',
            Email = 'testuser5@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test5',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert u;
        System.runAs(u) {
            // Test with null component name
            String nullRegion = UserComponentPreferenceService.getLastRegion(null);
            System.assertEquals(null, nullRegion, 'Should handle null component name');
            
            // Test with blank component name  
            String blankRegion = UserComponentPreferenceService.getLastRegion('');
            System.assertEquals(null, blankRegion, 'Should handle blank component name');
            
            // Test setting null values
            UserComponentPreferenceService.setLastRegion('TestComponent', null);
            String regionAfterNull = UserComponentPreferenceService.getLastRegion('TestComponent');
            System.assertEquals(null, regionAfterNull, 'Should handle setting null region');
        }
    }

    @isTest 
    static void testPreferenceOverwrite() {
        User u = new User(
            Username = 'testuser6' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser6',
            Email = 'testuser6@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test6',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert u;
        System.runAs(u) {
            String componentName = 'OverwriteTest';
            
            // Test region overwrite
            UserComponentPreferenceService.setLastRegion(componentName, 'Initial');
            System.assertEquals('Initial', UserComponentPreferenceService.getLastRegion(componentName));
            
            UserComponentPreferenceService.setLastRegion(componentName, 'Updated');
            System.assertEquals('Updated', UserComponentPreferenceService.getLastRegion(componentName));
            
            // Test dealer ID overwrite on different component
            String dealerComponent = 'DealerTest';
            UserComponentPreferenceService.setLastDealerId(dealerComponent, 'initialDealer');
            System.assertEquals('initialDealer', UserComponentPreferenceService.getLastDealerId(dealerComponent));
            
            UserComponentPreferenceService.setLastDealerId(dealerComponent, 'updatedDealer');
            System.assertEquals('updatedDealer', UserComponentPreferenceService.getLastDealerId(dealerComponent));
            
            // Test salesperson overwrite on different component
            String salespersonComponent = 'SalespersonTest';
            UserComponentPreferenceService.setLastSalesperson(salespersonComponent, 'initialSalesperson');
            System.assertEquals('initialSalesperson', UserComponentPreferenceService.getLastSalesperson(salespersonComponent));
            
            UserComponentPreferenceService.setLastSalesperson(salespersonComponent, 'updatedSalesperson');
            System.assertEquals('updatedSalesperson', UserComponentPreferenceService.getLastSalesperson(salespersonComponent));
        }
    }
}
