public with sharing class ActivityController {
    
    public class SalespersonInfo {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
    }
    
    public class ActivityData {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String salespersonId { get; set; }
        @AuraEnabled public String salespersonName { get; set; }
        @AuraEnabled public String eventType { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String subject { get; set; }
        @AuraEnabled public Integer totalActivities { get; set; }
        @AuraEnabled public Integer completedActivities { get; set; }
        @AuraEnabled public Integer pendingActivities { get; set; }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<SalespersonInfo> getSalespeople() {
        try {
            List<SalespersonInfo> salespeople = new List<SalespersonInfo>();
            
            List<User> users = [
                SELECT Id, Name, Email
                FROM User 
                WHERE IsActive = true
                AND (Name LIKE 'Gianluca%' OR Name LIKE 'Ricky%' OR Name LIKE 'Sophie%' OR Name LIKE 'Corine%'
                     OR Email = 'sophie.ahyam@preferafinance.com'
                     OR Email = 'corine.vanstone@preferafinance.com')
                ORDER BY Name
            ];
            
            for (User user : users) {
                SalespersonInfo person = new SalespersonInfo();
                person.id = user.Id;
                person.name = user.Name;
                salespeople.add(person);
            }
            
            return salespeople;        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving salespeople: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<ActivityData> getActivityData(String salespersonId, String eventType, String timeframe) {
        try {
            List<ActivityData> activityList = new List<ActivityData>();

            // Build dynamic SOQL query for Talkdesk Activity object with enhanced grouping
            String baseQuery = 'SELECT talkdesk__User__c, talkdesk__User__r.Name, talkdesk__Type__c, talkdesk__Status__c, COUNT(Id) totalCount ' +
                               'FROM talkdesk__Talkdesk_Activity__c WHERE talkdesk__Start_Date__c = TODAY ' +
                               'AND (talkdesk__Type__c != \'Voicemail\') ' +
                               'AND talkdesk__User__c != null ';

            // Add filters
            if (String.isNotBlank(salespersonId)) {
                baseQuery += 'AND talkdesk__User__c = :salespersonId ';
            }

            if (String.isNotBlank(eventType)) {
                baseQuery += 'AND talkdesk__Type__c = :eventType ';
            }

            baseQuery += 'GROUP BY talkdesk__User__c, talkdesk__User__r.Name, talkdesk__Type__c, talkdesk__Status__c ORDER BY talkdesk__User__r.Name, talkdesk__Type__c, talkdesk__Status__c';

            List<AggregateResult> results = Database.query(baseQuery);

            for (AggregateResult result : results) {
                ActivityData activity = new ActivityData();
                activity.id = (String) result.get('talkdesk__User__c') + '_' + (String) result.get('talkdesk__Type__c') + '_' + (String) result.get('talkdesk__Status__c');
                activity.salespersonId = (String) result.get('talkdesk__User__c');
                activity.salespersonName = (String) result.get('Name');
                activity.eventType = (String) result.get('talkdesk__Type__c');
                activity.status = (String) result.get('talkdesk__Status__c');
                activity.totalActivities = (Integer) result.get('totalCount');

                // Calculate completed vs pending based on status
                String status = (String) result.get('talkdesk__Status__c');
                Integer count = (Integer) result.get('totalCount');
                if (status != null && status.equalsIgnoreCase('Completed')) {
                    activity.completedActivities = count;
                    activity.pendingActivities = 0;
                } else {
                    activity.completedActivities = 0;
                    activity.pendingActivities = count;
                }

                activityList.add(activity);
            }

            return activityList;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving activity data: ' + e.getMessage());
        }
    }
}
