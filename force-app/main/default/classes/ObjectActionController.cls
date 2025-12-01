public with sharing class ObjectActionController {

    @AuraEnabled(cacheable=true)
public static String getObjectName(Id recordId) {
    return recordId.getSObjectType().getDescribe().getName();
}

@AuraEnabled(cacheable=true)
public static List<Button_Access__c> getAccessForObject(String parentObjectApiName) {
    return [
        SELECT Id,
               Object_Name__c,
               Parent_Object__c,
               View__c,
               Create__c,
               Update__c,
               Order__c
        FROM Button_Access__c
        WHERE Parent_Object__c = :parentObjectApiName
        ORDER BY Order__c
    ];
}

    @AuraEnabled(cacheable=true)
    public static List<Button_Access__c> getButtonAccess() {
        return [
            SELECT Id,
                   Object_Name__c,
                   Parent_Object__c,
                   View__c,
                   Create__c,
                   Update__c,
                   Order__c
            FROM Button_Access__c
            ORDER BY Order__c
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getFieldsForObject(String objectApiName) {
        List<Field_Access__c> fa = [
            SELECT Field_API_Name__c
            FROM Field_Access__c
            WHERE Object_API_Name__c = :objectApiName
            ORDER BY Order__c
        ];

        List<String> fields = new List<String>();
        for (Field_Access__c f : fa) {
            fields.add(f.Field_API_Name__c);
        }
        return fields;
    }

    @AuraEnabled
public static Id createTask(String subject, Date dueDate, Id relatedToId) {
    Task t = new Task(
        Subject = subject,
        ActivityDate = dueDate,
        WhatId = relatedToId
    );
    insert t;
    return t.Id;
}

    @AuraEnabled(cacheable=true)
    public static String getRelatedAccount(Id recordId) {
        String objectName = recordId.getSObjectType().getDescribe().getName();

        if (objectName == 'Opportunity') {
            Opportunity opp = [
                SELECT AccountId
                FROM Opportunity
                WHERE Id = :recordId
                LIMIT 1
            ];
            return opp.AccountId;
        }

        if (objectName == 'Case') {
            Case c = [
                SELECT AccountId
                FROM Case
                WHERE Id = :recordId
                LIMIT 1
            ];
            return c.AccountId;
        }

        return null;
    }
}
