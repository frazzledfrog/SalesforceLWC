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
        @AuraEnabled public Integer totalActivities { get; set; }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<SalespersonInfo> getSalespeople() {
        try {
            List<SalespersonInfo> salespeople = new List<SalespersonInfo>();
            
            List<User> users = [
                SELECT Id, Name
                FROM User 
                WHERE IsActive = true
                AND (Name LIKE 'Gianluca%' OR Name LIKE 'Ricky%' OR Name LIKE 'Sophie%' OR Name LIKE 'Corine%')
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
            
            // Build dynamic SOQL query for Task object (today only, all task types)
            String query = 'SELECT OwnerId, Owner.Name, Type, COUNT(Id) activityCount ' +
                          'FROM Task ' +
                          'WHERE CreatedDate = TODAY ';
            
            // Add filters
            if (String.isNotBlank(salespersonId)) {
                query += 'AND OwnerId = :salespersonId ';
            }
            
            if (String.isNotBlank(eventType)) {
                query += 'AND Type = :eventType ';
            }
            
            query += 'GROUP BY OwnerId, Owner.Name, Type ORDER BY Owner.Name, Type';
            
            List<AggregateResult> results = Database.query(query);
            
            for (AggregateResult result : results) {
                ActivityData activity = new ActivityData();
                activity.id = (String) result.get('OwnerId') + '_' + (String) result.get('Type');
                activity.salespersonId = (String) result.get('OwnerId');
                activity.salespersonName = (String) result.get('Name');
                activity.eventType = (String) result.get('Type');
                activity.totalActivities = (Integer) result.get('activityCount');
                activityList.add(activity);
            }
            
            return activityList;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving activity data: ' + e.getMessage());
        }
    }
}
