global class BatchQuoteProcessor implements Database.Batchable<SObject>, Database.Stateful {

    public List<Quote_Processing_Error__c> errorLogs = new List<Quote_Processing_Error__c>();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, External_ID_c__c, AccountId__c, Name, QuoteToName__c,QuoteNumber__c,ExpirationDate__c, Status__c
            FROM Healthcare_Quote_Staging__c
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Healthcare_Quote_Staging__c> quoteStagingList) {
        Set<String> extIds = new Set<String>();
        for (Healthcare_Quote_Staging__c s : quoteStagingList) {
            extIds.add(s.External_ID_c__c);
        }

        Map<String, Quote> existingQuotes = new Map<String, Quote>(
            [SELECT Id, External_ID__c FROM Quote WHERE External_ID__c IN :extIds]
        );

        List<Quote> quotesToUpsert = new List<Quote>();
        Map<String, Id> extIdToQuoteId = new Map<String, Id>();

        for (Healthcare_Quote_Staging__c s : quoteStagingList) {
            try {
                Quote q = QuoteProcessingHelper.mapToQuote(s);
                if (existingQuotes.containsKey(s.External_ID_c__c)) {
                    q.Id = existingQuotes.get(s.External_ID_c__c).Id;
                }
                quotesToUpsert.add(q);
            } catch (Exception ex) {
                errorLogs.add(new Quote_Processing_Error__c(
                    Type__c = 'Quote',
                    Staging_Record_Id__c = s.Id,
                    ErrorMessage__c = ex.getMessage(),
                    Status__c = 'New'
                ));
            }
        }

        upsert quotesToUpsert External_ID__c;

        for (Quote q : [SELECT Id, External_ID__c FROM Quote WHERE External_ID__c IN :extIds]) {
            extIdToQuoteId.put(q.External_ID__c, q.Id);
        }

        List<Healthcare_QuoteDetail_Staging__c> details = [
            SELECT Id, External_ID_c__c, Product2IdNew__c,PricebookEntryId__c, Quantity__c, UnitPrice__c,Parent_External_Id__c
            FROM Healthcare_QuoteDetail_Staging__c
            WHERE Parent_External_Id__c IN :extIds
        ];

        List<QuoteLineItem> lineItems = new List<QuoteLineItem>();
        for (Healthcare_QuoteDetail_Staging__c d : details) {
            try {
                Id quoteId = extIdToQuoteId.get(d.Parent_External_Id__c);
                if (quoteId != null) {
                    lineItems.add(QuoteProcessingHelper.mapToQuoteLineItem(d, quoteId));
                }
            } catch (Exception ex) {
                errorLogs.add(new Quote_Processing_Error__c(
                    Type__c = 'QuoteLineItem',
                    Staging_Record_Id__c = d.Id,
                    ErrorMessage__c = ex.getMessage(),
                    Status__c = 'New'
                ));
            }
        }

        insert lineItems;
    }

    global void finish(Database.BatchableContext bc) {
        if (!errorLogs.isEmpty()) {
            insert errorLogs;
        }
    }
}