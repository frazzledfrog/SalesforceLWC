/**
 * @description Controller for the AccountAssignmentView LWC component.
 * Provides methods to fetch sales reps and their assigned accounts grouped by index call assign number.
 */
public with sharing class AccountAssignmentViewController {
    
    /**
     * @description Wrapper class for sales rep data
     */
    public class SalesRepWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String email { get; set; }
        
        public SalesRepWrapper(User salesRep) {
            this.id = salesRep.Id;
            this.name = salesRep.Name;
            this.email = salesRep.Email;
        }
    }
    
    /**
     * @description Wrapper class for account data
     */
    public class AccountWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public Decimal indexCallAssign { get; set; }
        
        public AccountWrapper(Account acc) {
            this.id = acc.Id;
            this.name = acc.Name;
            this.type = acc.Type;
            this.indexCallAssign = acc.Index_Call_Assign__c;
        }
    }
    
    /**
     * @description Wrapper class for grouped account data
     */
    public class GroupedAccountsWrapper {
        @AuraEnabled public Decimal assignmentNumber { get; set; }
        @AuraEnabled public List<AccountWrapper> accounts { get; set; }
        
        public GroupedAccountsWrapper(Decimal assignmentNumber) {
            this.assignmentNumber = assignmentNumber;
            this.accounts = new List<AccountWrapper>();
        }
    }
    
    /**
     * @description Get all sales reps that have accounts assigned to them
     * @return List of SalesRepWrapper objects
     */
    @AuraEnabled(cacheable=true)
    public static List<SalesRepWrapper> getSalesReps() {
        try {
            List<User> salesReps = [
                SELECT Id, Name, Email
                FROM User
                WHERE Id IN (
                    SELECT OwnerId
                    FROM Account
                    WHERE Index_Call_Assign__c != null
                    AND (Type = 'Active Dealer' OR Type = 'Active Broker')
                )
                ORDER BY Name
            ];
            
            List<SalesRepWrapper> result = new List<SalesRepWrapper>();
            for (User salesRep : salesReps) {
                result.add(new SalesRepWrapper(salesRep));
            }
            
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving sales reps: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get accounts grouped by index call assign number for a specific sales rep
     * @param salesRepId The ID of the sales rep
     * @return List of GroupedAccountsWrapper objects
     */
    @AuraEnabled(cacheable=true)
    public static List<GroupedAccountsWrapper> getAccountsByAssignmentNumber(String salesRepId) {
        try {
            List<Account> accounts = [
                SELECT Id, Name, Type, Index_Call_Assign__c
                FROM Account
                WHERE OwnerId = :salesRepId
                AND Index_Call_Assign__c != null
                AND (Type = 'Active Dealer' OR Type = 'Active Broker')
                ORDER BY Index_Call_Assign__c, Name
            ];
            
            Map<Decimal, List<AccountWrapper>> groupedAccounts = new Map<Decimal, List<AccountWrapper>>();
            
            for (Account acc : accounts) {
                if (!groupedAccounts.containsKey(acc.Index_Call_Assign__c)) {
                    groupedAccounts.put(acc.Index_Call_Assign__c, new List<AccountWrapper>());
                }
                groupedAccounts.get(acc.Index_Call_Assign__c).add(new AccountWrapper(acc));
            }
            
            List<GroupedAccountsWrapper> result = new List<GroupedAccountsWrapper>();
            List<Decimal> sortedKeys = new List<Decimal>(groupedAccounts.keySet());
            sortedKeys.sort();
            
            for (Decimal assignmentNumber : sortedKeys) {
                GroupedAccountsWrapper wrapper = new GroupedAccountsWrapper(assignmentNumber);
                wrapper.accounts = groupedAccounts.get(assignmentNumber);
                result.add(wrapper);
            }
            
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving accounts: ' + e.getMessage());
        }
    }
}
