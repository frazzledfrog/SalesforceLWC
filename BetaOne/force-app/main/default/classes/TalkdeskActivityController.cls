// Talkdesk Activity controller handling server-side operations
public with sharing class TalkdeskActivityController {
    
    public class SalespersonInfo {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
    }
    
    public class TalkdeskActivityData {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String salespersonId { get; set; }
        @AuraEnabled public String salespersonName { get; set; }
        @AuraEnabled public String channel { get; set; }
        @AuraEnabled public String direction { get; set; }
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public Integer totalActivities { get; set; }
        @AuraEnabled public Integer totalTalkTime { get; set; }
        @AuraEnabled public Decimal averageTalkTime { get; set; }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<SalespersonInfo> getSalespeople() {
        try {
            List<SalespersonInfo> salespeople = new List<SalespersonInfo>();
            
            // Get unique owners from Talkdesk Activities with actual conversation data
            Set<Id> ownerIds = new Set<Id>();
            List<AggregateResult> ownerResults = [
                SELECT OwnerId
                FROM talkdesk__Talkdesk_Activity__c 
                WHERE talkdesk__Talk_Time_sec__c > 0
                AND talkdesk__Contact__c != null
                AND talkdesk__Account__c != null
                AND CreatedDate = LAST_N_DAYS:30
                GROUP BY OwnerId
            ];
            
            for (AggregateResult result : ownerResults) {
                ownerIds.add((Id) result.get('OwnerId'));
            }
            
            if (!ownerIds.isEmpty()) {
                List<User> users = [
                    SELECT Id, Name
                    FROM User 
                    WHERE Id IN :ownerIds
                    AND IsActive = true
                    ORDER BY Name
                ];
                
                for (User user : users) {
                    SalespersonInfo person = new SalespersonInfo();
                    person.id = user.Id;
                    person.name = user.Name;
                    salespeople.add(person);
                }
            }
            
            return salespeople;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving salespeople: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<TalkdeskActivityData> getTalkdeskActivityData(String salespersonId, String channel, String direction, String timeframe) {
        try {
            List<TalkdeskActivityData> activityList = new List<TalkdeskActivityData>();
            
            // Use a simpler approach - get the raw data first, then aggregate in Apex
            String query = 'SELECT Id, OwnerId, Owner.Name, talkdesk__Channel__c, talkdesk__Direction__c, ' +
                          'talkdesk__Talk_Time_sec__c, talkdesk__Account__c, talkdesk__Contact__c ' +
                          'FROM talkdesk__Talkdesk_Activity__c ' +
                          'WHERE talkdesk__Talk_Time_sec__c > 0 ' +
                          'AND talkdesk__Contact__c != null ' +
                          'AND talkdesk__Account__c != null ';
            
            // Add timeframe filter
            if (timeframe == 'today') {
                query += 'AND CreatedDate = TODAY ';
            } else if (timeframe == 'week') {
                query += 'AND CreatedDate = THIS_WEEK ';
            } else if (timeframe == 'month') {
                query += 'AND CreatedDate = THIS_MONTH ';
            }
            
            // Add filters
            if (String.isNotBlank(salespersonId)) {
                query += 'AND OwnerId = :salespersonId ';
            }
            
            if (String.isNotBlank(channel)) {
                query += 'AND talkdesk__Channel__c = :channel ';
            }
            
            if (String.isNotBlank(direction)) {
                query += 'AND talkdesk__Direction__c = :direction ';
            }
            
            query += 'ORDER BY Owner.Name, talkdesk__Channel__c, talkdesk__Direction__c';
            
            List<talkdesk__Talkdesk_Activity__c> rawActivities = Database.query(query);
            
            // Group and aggregate the data in Apex
            Map<String, TalkdeskActivityData> groupedData = new Map<String, TalkdeskActivityData>();
            
            for (talkdesk__Talkdesk_Activity__c activity : rawActivities) {
                String groupKey = activity.OwnerId + '_' + activity.talkdesk__Channel__c + '_' + activity.talkdesk__Direction__c;
                
                if (!groupedData.containsKey(groupKey)) {
                    TalkdeskActivityData groupedActivity = new TalkdeskActivityData();
                    groupedActivity.id = groupKey;
                    groupedActivity.salespersonId = activity.OwnerId;
                    groupedActivity.salespersonName = activity.Owner.Name;
                    groupedActivity.channel = activity.talkdesk__Channel__c;
                    groupedActivity.direction = activity.talkdesk__Direction__c;
                    groupedActivity.accountName = 'Account Data';
                    groupedActivity.totalActivities = 0;
                    groupedActivity.totalTalkTime = 0;
                    groupedActivity.averageTalkTime = 0;
                    groupedData.put(groupKey, groupedActivity);
                }
                
                TalkdeskActivityData groupedActivity = groupedData.get(groupKey);
                groupedActivity.totalActivities++;
                groupedActivity.totalTalkTime += Integer.valueOf(activity.talkdesk__Talk_Time_sec__c);
            }
            
            // Calculate averages
            for (TalkdeskActivityData activity : groupedData.values()) {
                if (activity.totalActivities > 0) {
                    activity.averageTalkTime = Decimal.valueOf(activity.totalTalkTime) / activity.totalActivities;
                }
                activityList.add(activity);
            }
            
            return activityList;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving Talkdesk activity data: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getChannelOptions() {
        try {
            List<String> channels = new List<String>();
            Schema.DescribeFieldResult fieldResult = talkdesk__Talkdesk_Activity__c.talkdesk__Channel__c.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
            
            for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.isActive()) {
                    channels.add(entry.getValue());
                }
            }
            
            return channels;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving channel options: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getDirectionOptions() {
        try {
            List<String> directions = new List<String>();
            Schema.DescribeFieldResult fieldResult = talkdesk__Talkdesk_Activity__c.talkdesk__Direction__c.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
            
            for (Schema.PicklistEntry entry : picklistValues) {
                if (entry.isActive()) {
                    directions.add(entry.getValue());
                }
            }
            
            return directions;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving direction options: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPerformanceInsights(String salespersonId, String timeframe) {
        try {
            Map<String, Object> insights = new Map<String, Object>();
            
            // Build base where clause
            String baseWhere = 'talkdesk__Talk_Time_sec__c > 0 AND talkdesk__Contact__c != null AND talkdesk__Account__c != null';
            
            // Add timeframe filter
            if (timeframe == 'today') {
                baseWhere += ' AND CreatedDate = TODAY';
            } else if (timeframe == 'week') {
                baseWhere += ' AND CreatedDate = THIS_WEEK';
            } else if (timeframe == 'month') {
                baseWhere += ' AND CreatedDate = THIS_MONTH';
            }
            
            // Add salesperson filter if specified
            if (String.isNotBlank(salespersonId)) {
                baseWhere += ' AND OwnerId = \'' + String.escapeSingleQuotes(salespersonId) + '\'';
            }
            
            // Get successful calls (those with talk time)
            String successQuery = 'SELECT COUNT() FROM talkdesk__Talkdesk_Activity__c WHERE ' + baseWhere;
            Integer totalCalls = Database.countQuery(successQuery);
            
            if (totalCalls == 0) {
                insights.put('totalCalls', 0);
                insights.put('totalTalkTime', 0);
                insights.put('avgTalkTime', 0);
                insights.put('successRate', 0);
                insights.put('totalAttempts', 0);
                return insights;
            }
            
            // Get total talk time using individual query
            String talkTimeWhere = baseWhere;
            String talkTimeQuery = 'SELECT talkdesk__Talk_Time_sec__c FROM talkdesk__Talkdesk_Activity__c WHERE ' + talkTimeWhere;
            List<talkdesk__Talkdesk_Activity__c> talkTimeResults = Database.query(talkTimeQuery);
            
            Integer totalTalkTime = 0;
            for (talkdesk__Talkdesk_Activity__c activity : talkTimeResults) {
                if (activity.talkdesk__Talk_Time_sec__c != null) {
                    totalTalkTime += Integer.valueOf(activity.talkdesk__Talk_Time_sec__c);
                }
            }
            
            Decimal avgTalkTime = totalCalls > 0 ? Decimal.valueOf(totalTalkTime) / totalCalls : 0;
            
            // Get total attempts (all contacts with accounts, regardless of talk time)
            String attemptWhere = 'talkdesk__Contact__c != null AND talkdesk__Account__c != null';
            if (timeframe == 'today') {
                attemptWhere += ' AND CreatedDate = TODAY';
            } else if (timeframe == 'week') {
                attemptWhere += ' AND CreatedDate = THIS_WEEK';
            } else if (timeframe == 'month') {
                attemptWhere += ' AND CreatedDate = THIS_MONTH';
            }
            if (String.isNotBlank(salespersonId)) {
                attemptWhere += ' AND OwnerId = \'' + String.escapeSingleQuotes(salespersonId) + '\'';
            }
            
            String attemptQuery = 'SELECT COUNT() FROM talkdesk__Talkdesk_Activity__c WHERE ' + attemptWhere;
            Integer totalAttempts = Database.countQuery(attemptQuery);
            
            Decimal successRate = totalAttempts > 0 ? (Decimal.valueOf(totalCalls) / Decimal.valueOf(totalAttempts)) * 100 : 0;
            
            insights.put('totalCalls', totalCalls);
            insights.put('totalTalkTime', totalTalkTime);
            insights.put('avgTalkTime', avgTalkTime.setScale(1));
            insights.put('successRate', successRate.setScale(1));
            insights.put('totalAttempts', totalAttempts);
            
            return insights;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving performance insights: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getTeamSummary(String timeframe) {
        try {
            Map<String, Object> summary = new Map<String, Object>();
            
            String whereClause = 'talkdesk__Talk_Time_sec__c > 0 AND talkdesk__Contact__c != null AND talkdesk__Account__c != null';
            
            if (timeframe == 'today') {
                whereClause += ' AND CreatedDate = TODAY';
            } else if (timeframe == 'week') {
                whereClause += ' AND CreatedDate = THIS_WEEK';
            } else if (timeframe == 'month') {
                whereClause += ' AND CreatedDate = THIS_MONTH';
            }
            
            // Get total calls count
            String callCountQuery = 'SELECT COUNT() FROM talkdesk__Talkdesk_Activity__c WHERE ' + whereClause;
            Integer totalCalls = Database.countQuery(callCountQuery);
            
            if (totalCalls == 0) {
                summary.put('totalCalls', 0);
                summary.put('totalTalkTime', 0);
                summary.put('avgTalkTime', 0);
                summary.put('activeUsers', 0);
                return summary;
            }
            
            // Get activities for further processing
            String detailQuery = 'SELECT OwnerId, talkdesk__Talk_Time_sec__c FROM talkdesk__Talkdesk_Activity__c WHERE ' + whereClause;
            List<talkdesk__Talkdesk_Activity__c> activities = Database.query(detailQuery);
            
            Integer totalTalkTime = 0;
            Set<Id> uniqueOwners = new Set<Id>();
            
            for (talkdesk__Talkdesk_Activity__c activity : activities) {
                if (activity.talkdesk__Talk_Time_sec__c != null) {
                    totalTalkTime += Integer.valueOf(activity.talkdesk__Talk_Time_sec__c);
                }
                uniqueOwners.add(activity.OwnerId);
            }
            
            Decimal avgTalkTime = totalCalls > 0 ? Decimal.valueOf(totalTalkTime) / totalCalls : 0;
            
            summary.put('totalCalls', totalCalls);
            summary.put('totalTalkTime', totalTalkTime);
            summary.put('avgTalkTime', avgTalkTime.setScale(1));
            summary.put('activeUsers', uniqueOwners.size());
            
            return summary;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving team summary: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getRecentActivities(Integer limitCount) {
        try {
            if (limitCount == null || limitCount <= 0) {
                limitCount = 10;
            }
            
            List<Map<String, Object>> recentActivities = new List<Map<String, Object>>();
            
            List<talkdesk__Talkdesk_Activity__c> activities = [
                SELECT Id, Name, Owner.Name, talkdesk__Channel__c, talkdesk__Direction__c,
                       talkdesk__Talk_Time_sec__c, talkdesk__Account__r.Name, 
                       talkdesk__Contact__r.Name, CreatedDate
                FROM talkdesk__Talkdesk_Activity__c
                WHERE talkdesk__Talk_Time_sec__c > 0
                AND talkdesk__Contact__c != null
                AND talkdesk__Account__c != null
                ORDER BY CreatedDate DESC
                LIMIT :limitCount
            ];
            
            for (talkdesk__Talkdesk_Activity__c activity : activities) {
                Map<String, Object> activityMap = new Map<String, Object>();
                activityMap.put('id', activity.Id);
                activityMap.put('name', activity.Name);
                activityMap.put('ownerName', activity.Owner.Name);
                activityMap.put('channel', activity.talkdesk__Channel__c);
                activityMap.put('direction', activity.talkdesk__Direction__c);
                activityMap.put('talkTime', activity.talkdesk__Talk_Time_sec__c);
                activityMap.put('accountName', activity.talkdesk__Account__r?.Name);
                activityMap.put('contactName', activity.talkdesk__Contact__r?.Name);
                activityMap.put('createdDate', activity.CreatedDate);
                recentActivities.add(activityMap);
            }
            
            return recentActivities;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving recent activities: ' + e.getMessage());
        }
    }
}
