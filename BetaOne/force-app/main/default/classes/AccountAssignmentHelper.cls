/**
 * @description Helper class for the AccountAssignmentTrigger. Contains the logic to assign a number
 * from 1 to 20 to an Account based on the least used number for a given owner.
 */
public with sharing class AccountAssignmentHelper {

    private static final Integer MAX_ASSIGNMENT_NUMBER = 20;

    /**
     * @description Assigns a number to new accounts based on the least frequent number
     * currently assigned to other accounts owned by the same user.
     * @param newAccounts The list of new accounts from Trigger.new
     */
    public static void assignNumber(List<Account> newAccounts) {
        // Find all accounts without assignment numbers that need processing
        // Only process Active Dealers and Active Brokers
        List<Account> accountsToProcess = [
            SELECT Id, OwnerId, Index_Call_Assign__c, Type
            FROM Account
            WHERE Index_Call_Assign__c = null
            AND OwnerId != null
            AND (Type = 'Active Dealer' OR Type = 'Active Broker')
        ];
        
        if (accountsToProcess.isEmpty()) {
            return;
        }

        // Collect all owner IDs from accounts that need assignments
        Set<Id> ownerIds = new Set<Id>();
        for (Account acc : accountsToProcess) {
            ownerIds.add(acc.OwnerId);
        }

        // Build a map to store the counts of each assigned number (1-20) for each owner.
        Map<Id, Map<Decimal, Integer>> ownerNumberCounts = new Map<Id, Map<Decimal, Integer>>();

        for(Id ownerId : ownerIds) {
            ownerNumberCounts.put(ownerId, new Map<Decimal, Integer>());
        }

        // Query existing accounts to get the current distribution of assigned numbers.
        // Only count assignments from Active Dealers and Active Brokers
        List<Account> existingAccounts = [
            SELECT OwnerId, Index_Call_Assign__c
            FROM Account
            WHERE OwnerId IN :ownerIds
            AND Index_Call_Assign__c != null
            AND (Type = 'Active Dealer' OR Type = 'Active Broker')
        ];
        
        // Count the assignments manually
        for (Account existingAcc : existingAccounts) {
            Id ownerId = existingAcc.OwnerId;
            Decimal assignedNumber = existingAcc.Index_Call_Assign__c;
            
            if (ownerNumberCounts.containsKey(ownerId)) {
                Map<Decimal, Integer> numberCounts = ownerNumberCounts.get(ownerId);
                Integer currentCount = numberCounts.containsKey(assignedNumber) ? numberCounts.get(assignedNumber) : 0;
                numberCounts.put(assignedNumber, currentCount + 1);
            }
        }

        // Iterate through each account that needs assignment
        for (Account acc : accountsToProcess) {
            Map<Decimal, Integer> numberCountsForOwner = ownerNumberCounts.get(acc.OwnerId);

            Integer minCount = 999999;
            Decimal leastUsedNumber = 1;

            // Find the number (1-20) with the smallest count for this owner.
            for (Integer i = 1; i <= MAX_ASSIGNMENT_NUMBER; i++) {
                Decimal currentNumber = Decimal.valueOf(i);
                Integer currentCount = numberCountsForOwner.containsKey(currentNumber) ? numberCountsForOwner.get(currentNumber) : 0;

                if (currentCount < minCount) {
                    minCount = currentCount;
                    leastUsedNumber = currentNumber;
                }
            }

            acc.Index_Call_Assign__c = leastUsedNumber;

            // Increment the count in our map for the next account in the same transaction.
            Integer newCount = numberCountsForOwner.containsKey(leastUsedNumber) ? numberCountsForOwner.get(leastUsedNumber) + 1 : 1;
            numberCountsForOwner.put(leastUsedNumber, newCount);
        }
        
        // Update all accounts with their new assignments
        update accountsToProcess;
    }
}
