/**
 * @description Test class for AccountAssignmentHelper
 */
@IsTest
private class AccountAssignmentHelperTest {

    @TestSetup
    static void makeData() {
        // Create test users
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testUser1 = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Email = 'testuser1@example.com',
            Username = 'testuser1@accountassignment.test',
            Alias = 'tuser1',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        
        User testUser2 = new User(
            FirstName = 'Test',
            LastName = 'User2',
            Email = 'testuser2@example.com',
            Username = 'testuser2@accountassignment.test',
            Alias = 'tuser2',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        
        insert new List<User>{testUser1, testUser2};
        
        // Create existing accounts with assignments for testUser1
        List<Account> existingAccounts = new List<Account>();
        for (Integer i = 1; i <= 5; i++) {
            Account acc = new Account(
                Name = 'Existing Account ' + i,
                OwnerId = testUser1.Id,
                Index_Call_Assign__c = i
            );
            existingAccounts.add(acc);
        }
        
        // Create duplicate assignments to test least-used logic
        Account duplicateAssignment = new Account(
            Name = 'Duplicate Assignment',
            OwnerId = testUser1.Id,
            Index_Call_Assign__c = 1
        );
        existingAccounts.add(duplicateAssignment);
        
        insert existingAccounts;
    }

    @IsTest
    static void testAssignNumber_NewAccountsWithOwners() {
        List<User> testUsers = [SELECT Id FROM User WHERE Username LIKE '%@accountassignment.test' ORDER BY Username];
        User testUser1 = testUsers[0];
        User testUser2 = testUsers[1];
        
        List<Account> newAccounts = new List<Account>{
            new Account(Name = 'New Account 1', OwnerId = testUser1.Id),
            new Account(Name = 'New Account 2', OwnerId = testUser1.Id),
            new Account(Name = 'New Account 3', OwnerId = testUser2.Id)
        };
        
        insert newAccounts;
        
        Test.startTest();
        AccountAssignmentHelper.assignNumber(new List<Account>());
        Test.stopTest();
        
        // Query the accounts to get their updated values
        List<Account> updatedAccounts = [SELECT Id, Index_Call_Assign__c FROM Account WHERE Id IN :newAccounts ORDER BY Name];
        
        // Verify assignments
        Assert.areEqual(6, updatedAccounts[0].Index_Call_Assign__c, 'First new account should get number 6 (next available)');
        Assert.areEqual(7, updatedAccounts[1].Index_Call_Assign__c, 'Second new account should get number 7');
        Assert.areEqual(1, updatedAccounts[2].Index_Call_Assign__c, 'New user account should get number 1');
    }

    @IsTest
    static void testAssignNumber_AccountsWithoutOwners() {
        List<Account> newAccounts = new List<Account>{
            new Account(Name = 'No Owner Account 1'),
            new Account(Name = 'No Owner Account 2')
        };
        
        Test.startTest();
        AccountAssignmentHelper.assignNumber(newAccounts);
        Test.stopTest();
        
        // Verify no assignments were made
        Assert.isNull(newAccounts[0].Index_Call_Assign__c, 'Account without owner should not be assigned a number');
        Assert.isNull(newAccounts[1].Index_Call_Assign__c, 'Account without owner should not be assigned a number');
    }

    @IsTest
    static void testAssignNumber_AccountsAlreadyAssigned() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE '%@accountassignment.test' LIMIT 1];
        
        List<Account> newAccounts = new List<Account>{
            new Account(Name = 'Pre-assigned Account', OwnerId = testUser.Id, Index_Call_Assign__c = 10)
        };
        
        Test.startTest();
        AccountAssignmentHelper.assignNumber(newAccounts);
        Test.stopTest();
        
        // Verify assignment wasn't changed
        Assert.areEqual(10, newAccounts[0].Index_Call_Assign__c, 'Pre-assigned account should keep its assignment');
    }

    @IsTest
    static void testAssignNumber_EmptyList() {
        List<Account> emptyList = new List<Account>();
        
        Test.startTest();
        AccountAssignmentHelper.assignNumber(emptyList);
        Test.stopTest();
        
        // Should complete without error
        Assert.areEqual(0, emptyList.size(), 'Empty list should remain empty');
    }

    @IsTest
    static void testAssignNumber_LeastUsedLogic() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE '%@accountassignment.test' LIMIT 1];
        
        // Number 1 appears twice in test data, others appear once
        // So the next assignment should be 2 (or another single-occurrence number)
        List<Account> newAccounts = new List<Account>{
            new Account(Name = 'Least Used Test', OwnerId = testUser.Id)
        };
        
        insert newAccounts;
        
        Test.startTest();
        AccountAssignmentHelper.assignNumber(new List<Account>());
        Test.stopTest();
        
        // Query the account to get its updated value
        Account updatedAccount = [SELECT Index_Call_Assign__c FROM Account WHERE Id = :newAccounts[0].Id];
        
        // Should assign 2, 3, 4, 5, or 6 (numbers with count of 1) before assigning 1 again
        Assert.areNotEqual(1, updatedAccount.Index_Call_Assign__c, 'Should not assign number 1 since it appears twice');
        Assert.isTrue(updatedAccount.Index_Call_Assign__c >= 2 && updatedAccount.Index_Call_Assign__c <= 6, 
                     'Should assign a number from 2-6 range');
    }

    @IsTest
    static void testAssignNumber_BulkInsertion() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE '%@accountassignment.test' LIMIT 1];
        
        List<Account> bulkAccounts = new List<Account>();
        for (Integer i = 1; i <= 50; i++) {
            bulkAccounts.add(new Account(Name = 'Bulk Account ' + i, OwnerId = testUser.Id));
        }
        
        insert bulkAccounts;
        
        Test.startTest();
        AccountAssignmentHelper.assignNumber(new List<Account>());
        Test.stopTest();
        
        // Query the accounts to get their updated values
        List<Account> updatedAccounts = [SELECT Index_Call_Assign__c FROM Account WHERE Id IN :bulkAccounts];
        
        // Verify all accounts got assignments
        Set<Decimal> assignedNumbers = new Set<Decimal>();
        for (Account acc : updatedAccounts) {
            Assert.isNotNull(acc.Index_Call_Assign__c, 'Each bulk account should be assigned a number');
            Assert.isTrue(acc.Index_Call_Assign__c >= 1 && acc.Index_Call_Assign__c <= 20, 
                         'Assigned number should be between 1 and 20');
            assignedNumbers.add(acc.Index_Call_Assign__c);
        }
        
        // With 50 accounts and 20 possible numbers, some numbers will be reused
        Assert.isTrue(assignedNumbers.size() <= 20, 'Should not exceed 20 different numbers');
    }

    @IsTest
    static void testAssignNumber_MaxRange() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE '%@accountassignment.test' LIMIT 1];
        
        // Create accounts to fill up numbers 1-27 (6 already exist from setup)
        List<Account> fillUpAccounts = new List<Account>();
        for (Integer i = 6; i <= 20; i++) {
            fillUpAccounts.add(new Account(
                Name = 'Fill Account ' + i, 
                OwnerId = testUser.Id,
                Index_Call_Assign__c = i
            ));
        }
        insert fillUpAccounts;
        
        // Now create a new account
        List<Account> newAccounts = new List<Account>{
            new Account(Name = 'New After Fill', OwnerId = testUser.Id)
        };
        
        insert newAccounts;
        
        Test.startTest();
        AccountAssignmentHelper.assignNumber(new List<Account>());
        Test.stopTest();
        
        // Query the account to get its updated value
        Account updatedAccount = [SELECT Index_Call_Assign__c FROM Account WHERE Id = :newAccounts[0].Id];
        
        // Should assign number 1 again (since it has count of 2, others have count of 1)
        Assert.areEqual(2, updatedAccount.Index_Call_Assign__c, 'Should assign number 2 (least used after 1)');
    }
}
