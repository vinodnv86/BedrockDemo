public with sharing class ProcessDefinitionService {

    @AuraEnabled(cacheable=true)
    public static List<ProcessDefDTO> getDefinitions(Id recordId, String objectApiName) {
        if (String.isBlank(recordId) || String.isBlank(objectApiName)) {
            return new List<ProcessDefDTO>();
        }

        // Fetch process definitions for this object
        List<Process_Definition__c> definitions = [
            SELECT Id, Label__c, Icon_Name__c, Modal_Component_Name__c,
                   Target_Object__c, Filter_JSON__c, Variation_Id__c,
                   Field_Names__c, Object_API_Name__c
            FROM Process_Definition__c
            WHERE Is_Active__c = true AND Target_Object__c = :objectApiName
            ORDER BY Sort_Order__c ASC
        ];

        if (definitions.isEmpty()) {
            return new List<ProcessDefDTO>();
        }

        // Collect all fields from filters
        Set<String> requiredFields = new Set<String>();
        for (Process_Definition__c def : definitions) {
            Map<String, Object> filterMap = parseJsonFilter(def.Filter_JSON__c);
            if (filterMap != null) {
                requiredFields.addAll(filterMap.keySet());
            }
        }

        // Validate fields exist on the object
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe()
            .get(objectApiName)
            .getDescribe()
            .fields.getMap();

        List<String> validFields = new List<String>();
        for (String fieldName : requiredFields) {
            if (fieldMap.containsKey(fieldName)) {
                if (fieldMap.get(fieldName).getDescribe().isAccessible()) {
                    validFields.add(fieldName);
                }
            }
        }

        // Build SOQL to query those fields
        String soql = 'SELECT Id';
        for (String field : validFields) {
            soql += ', ' + field;
        }
        soql += ' FROM ' + objectApiName + ' WHERE Id = :recordId';

        SObject record;
        try {
            record = Database.query(soql);
        } catch (Exception e) {
            System.debug('Dynamic SOQL failed: ' + e.getMessage());
            return new List<ProcessDefDTO>();
        }

        // Match filters and build result list
        List<ProcessDefDTO> results = new List<ProcessDefDTO>();
        for (Process_Definition__c def : definitions) {
            Map<String, Object> filterMap = parseJsonFilter(def.Filter_JSON__c);
            if (filterMap == null || matchesFilter(record, filterMap)) {
                results.add(new ProcessDefDTO(
                    def.Id,
                    def.Variation_Id__c,
                    def.Label__c,
                    def.Icon_Name__c,
                    def.Modal_Component_Name__c,
                    def.Field_Names__c,
                    def.Object_API_Name__c
                ));
            }
        }

        return results;
    }

    private static Boolean matchesFilter(SObject record, Map<String, Object> filterMap) {
        for (String field : filterMap.keySet()) {
            Object expected = filterMap.get(field);
            Object actual = record.get(field);

            if (expected instanceof Map<String, Object>) {
                Map<String, Object> cond = (Map<String, Object>) expected;
                for (String op : cond.keySet()) {
                    Object filterValue = cond.get(op);
                    if (!evaluateCondition(actual, op, filterValue)) {
                        return false;
                    }
                }
            } else {
                if (actual == null || !String.valueOf(actual).equalsIgnoreCase(String.valueOf(expected))) {
                    return false;
                }
            }
        }
        return true;
    }

    private static Boolean evaluateCondition(Object actual, String operator, Object expected) {
        if (actual == null || expected == null) return false;

        try {
            Decimal actualDecimal;
            Decimal expectedDecimal;

            if (actual instanceof Decimal) {
                actualDecimal = (Decimal) actual;
            } else {
                actualDecimal = Decimal.valueOf(String.valueOf(actual));
            }

            if (expected instanceof Decimal) {
                expectedDecimal = (Decimal) expected;
            } else {
                expectedDecimal = Decimal.valueOf(String.valueOf(expected));
            }

            if (operator == 'eq') return actualDecimal == expectedDecimal;
            if (operator == 'neq') return actualDecimal != expectedDecimal;
            if (operator == 'gte') return actualDecimal >= expectedDecimal;
            if (operator == 'lte') return actualDecimal <= expectedDecimal;
            if (operator == 'gt') return actualDecimal > expectedDecimal;
            if (operator == 'lt') return actualDecimal < expectedDecimal;

        } catch (Exception e) {
            System.debug('Error evaluating condition: ' + e.getMessage());
        }

        return false;
    }

    private static Map<String, Object> parseJsonFilter(String jsonStr) {
        try {
            if (String.isNotBlank(jsonStr)) {
                return (Map<String, Object>) JSON.deserializeUntyped(jsonStr);
            }
        } catch (Exception e) {
            System.debug('Invalid JSON in Filter_JSON__c: ' + e.getMessage());
        }
        return null;
    }

    // DTO returned to LWC
    public class ProcessDefDTO {
        @AuraEnabled public String label;
        @AuraEnabled public String iconName;
        @AuraEnabled public String modalComponentName;
        @AuraEnabled public Id id;
        @AuraEnabled public String variationId;
        @AuraEnabled public String fieldNames; // NEW
        @AuraEnabled public String objectApiName; // NEW

        public ProcessDefDTO(Id id, String variationId, String label, String iconName, String modalComponentName, String fieldNames, String objectApiName) {
            this.variationId = variationId;
            this.label = label;
            this.iconName = iconName;
            this.modalComponentName = modalComponentName;
            this.id = id;
            this.fieldNames = fieldNames;
            this.objectApiName = objectApiName;
        }
    }
}
