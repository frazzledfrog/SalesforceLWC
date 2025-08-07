// User Component Preference service providing reusable logic
public with sharing class UserComponentPreferenceService {
    @AuraEnabled(cacheable=true)
    public static String getLastRegion(String componentName) {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        List<User_Component_Preference__c> prefs = [
            SELECT Last_Region__c
            FROM User_Component_Preference__c
            WHERE User__c = :currentUser.Id AND Component_Name__c = :componentName
            LIMIT 1
        ];
        if (!prefs.isEmpty()) {
            return prefs[0].Last_Region__c;
        }
        return null;
    }

    @AuraEnabled
    public static void setLastRegion(String componentName, String lastRegion) {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        List<User_Component_Preference__c> prefs = [
            SELECT Id, Last_Region__c
            FROM User_Component_Preference__c
            WHERE User__c = :currentUser.Id AND Component_Name__c = :componentName
            LIMIT 1
        ];
        if (!prefs.isEmpty()) {
            User_Component_Preference__c pref = prefs[0];
            pref.Last_Region__c = lastRegion;
            update pref;
        } else {
            User_Component_Preference__c pref = new User_Component_Preference__c(
                User__c = currentUser.Id,
                Component_Name__c = componentName,
                Last_Region__c = lastRegion
            );
            insert pref;
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getLastDealerId(String componentName) {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        List<User_Component_Preference__c> prefs = [
            SELECT Last_Region__c
            FROM User_Component_Preference__c
            WHERE User__c = :currentUser.Id AND Component_Name__c = :componentName
            LIMIT 1
        ];
        if (!prefs.isEmpty()) {
            return prefs[0].Last_Region__c;
        }
        return null;
    }

    @AuraEnabled
    public static void setLastDealerId(String componentName, String dealerId) {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        List<User_Component_Preference__c> prefs = [
            SELECT Id, Last_Region__c
            FROM User_Component_Preference__c
            WHERE User__c = :currentUser.Id AND Component_Name__c = :componentName
            LIMIT 1
        ];
        if (!prefs.isEmpty()) {
            User_Component_Preference__c pref = prefs[0];
            pref.Last_Region__c = dealerId;
            update pref;
        } else {
            User_Component_Preference__c pref = new User_Component_Preference__c(
                User__c = currentUser.Id,
                Component_Name__c = componentName,
                Last_Region__c = dealerId
            );
            insert pref;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String getLastSalesperson(String componentName) {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        List<User_Component_Preference__c> prefs = [
            SELECT Last_Region__c
            FROM User_Component_Preference__c
            WHERE User__c = :currentUser.Id AND Component_Name__c = :componentName
            LIMIT 1
        ];
        if (!prefs.isEmpty()) {
            return prefs[0].Last_Region__c;
        }
        return null;
    }

    @AuraEnabled
    public static void setLastSalesperson(String componentName, String salespersonId) {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        List<User_Component_Preference__c> prefs = [
            SELECT Id, Last_Region__c
            FROM User_Component_Preference__c
            WHERE User__c = :currentUser.Id AND Component_Name__c = :componentName
            LIMIT 1
        ];
        if (!prefs.isEmpty()) {
            User_Component_Preference__c pref = prefs[0];
            pref.Last_Region__c = salespersonId;
            update pref;
        } else {
            User_Component_Preference__c pref = new User_Component_Preference__c(
                User__c = currentUser.Id,
                Component_Name__c = componentName,
                Last_Region__c = salespersonId
            );
            insert pref;
        }
    }
}
