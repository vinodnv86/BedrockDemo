global class BatchQuoteRetryProcessor implements Database.Batchable<SObject>, Database.Stateful {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Type__c, Staging_Record_Id__c FROM Quote_Processing_Error__c
            WHERE Status__c = 'New'
        ]);
    }

global void execute(Database.BatchableContext bc, List<SObject> scope) {
    for (SObject sObj : scope) {
        Quote_Processing_Error__c error = (Quote_Processing_Error__c)sObj;
        try {
            if (error.Type__c == 'Quote') {
                Healthcare_Quote_Staging__c staging = [
                    SELECT Id, External_ID_c__c, AccountId__c, Name__c, ExpirationDate__c, Status__c
                    FROM Healthcare_Quote_Staging__c WHERE Id = :error.Staging_Record_Id__c LIMIT 1
                ];
                Quote q = QuoteProcessingHelper.mapToQuote(staging);
                upsert q External_Id__c;
            } else if (error.Type__c == 'QuoteLineItem') {
                Healthcare_QuoteDetail_Staging__c detail = [
                    SELECT Id, Parent_External_Id__c, Product2IdNew__c, Quantity__c, UnitPrice__c
                    FROM Healthcare_QuoteDetail_Staging__c WHERE Id = :error.Staging_Record_Id__c LIMIT 1
                ];
                Quote parent = [SELECT Id FROM Quote WHERE External_Id__c = :detail.Parent_External_Id__c LIMIT 1];
                QuoteLineItem line = QuoteProcessingHelper.mapToQuoteLineItem(detail, parent.Id);
                insert line;
                }
                error.Status__c = 'Retried';
            } catch (Exception ex) {
                error.Status__c = 'Failed';
                error.ErrorMessage__c = ex.getMessage();
            }
        }
        //update error;
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Retry processing complete');
    }
}