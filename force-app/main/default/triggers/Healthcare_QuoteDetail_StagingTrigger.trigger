trigger Healthcare_QuoteDetail_StagingTrigger on Healthcare_QuoteDetail_Staging__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Healthcare_QuoteDetail_StagingHandler.populatePricebookEntryIds(Trigger.new);
        }
    }
}