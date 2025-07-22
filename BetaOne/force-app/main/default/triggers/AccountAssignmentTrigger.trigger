/**
 * @description Trigger for Account object to assign Index_Call_Assign__c numbers
 */
trigger AccountAssignmentTrigger on Account (after insert, after update) {
    
    // Call the helper to assign numbers to any accounts that need them
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        AccountAssignmentHelper.assignNumber(Trigger.new);
    }
}
