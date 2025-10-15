public class QuoteProcessingHelper {

    public static Quote mapToQuote(Healthcare_Quote_Staging__c staging) {
        Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        Quote q = new Quote();
        q.External_ID__c  = staging.External_ID_c__c;
        q.Name = String.valueOf(staging.QuoteNumber__c);
       // q.AccountId = staging.AccountId__c;
        q.ExpirationDate = staging.ExpirationDate__c;
        q.Status = staging.Status__c;
        q.Pricebook2Id = standardPricebook.Id;
        return q;
    }

    public static QuoteLineItem mapToQuoteLineItem(Healthcare_QuoteDetail_Staging__c detail, Id quoteId) {
        QuoteLineItem line = new QuoteLineItem();
        line.QuoteId = quoteId;
        line.Quantity = detail.Quantity__c;
        line.UnitPrice = detail.UnitPrice__c;
      //  line.PricebookEntryId = getPricebookEntryId(detail.Product2IdNew__c);
        line.PricebookEntryId = detail.PricebookEntryId__c;
        line.Product2Id = detail.Product2IdNew__c;
        return line;
    }

    private static Id getPricebookEntryId(Id productId) {
        List<PricebookEntry> entries = [
            SELECT Id FROM PricebookEntry
            WHERE Product2Id = :productId AND IsActive = TRUE AND Pricebook2.IsStandard = TRUE LIMIT 1
        ];
        return entries.isEmpty() ? null : entries[0].Id;
    }
}