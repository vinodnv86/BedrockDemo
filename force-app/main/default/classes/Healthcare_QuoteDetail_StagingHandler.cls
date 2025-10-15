public class Healthcare_QuoteDetail_StagingHandler {

    public static void populatePricebookEntryIds(List<Healthcare_QuoteDetail_Staging__c> newRecords) {
        Set<String> productExternalIds = new Set<String>();
        // Collect all product external IDs
        for (Healthcare_QuoteDetail_Staging__c rec : newRecords) {
            if (String.isNotBlank(rec.Product2Id__c)) {
                productExternalIds.add(rec.Product2Id__c.trim());
            }
        }
        if (productExternalIds.isEmpty()) return;

        // Query Product2 using its External ID field (replace External_ID__c with your actual API name)
        Map<String, Id> externalIdToProductId = new Map<String, Id>();
        for (Product2 prod : [
            SELECT Id, External_ID__c
            FROM Product2
            WHERE External_ID__c IN :productExternalIds
        ]) {
            externalIdToProductId.put(prod.External_ID__c, prod.Id);
        }

        if (externalIdToProductId.isEmpty()) return;

        // Query PricebookEntries for those Products (Standard Price Book)
        Map<Id, Id> productToPbeId = new Map<Id, Id>();
        for (PricebookEntry pbe : [
            SELECT Id, Product2Id, Pricebook2Id
            FROM PricebookEntry
            WHERE Product2Id IN :externalIdToProductId.values()
            AND Pricebook2.IsStandard = true
        ]) {
            productToPbeId.put(pbe.Product2Id, pbe.Id);
        }

        // Stamp the PricebookEntryId__c
        for (Healthcare_QuoteDetail_Staging__c rec : newRecords) {
            String prodExtId = rec.Product2Id__c;
            if (String.isNotBlank(prodExtId) && externalIdToProductId.containsKey(prodExtId)) {
                Id prodId = externalIdToProductId.get(prodExtId);
                if (productToPbeId.containsKey(prodId)) {
                    rec.PricebookEntryId__c = productToPbeId.get(prodId);
                } else {
                    rec.PricebookEntryId__c = null; // or keep old value if needed
                }
            }
        }
    }
}