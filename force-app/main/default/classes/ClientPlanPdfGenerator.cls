public with sharing class ClientPlanPdfGenerator {

    @AuraEnabled
    public static void generatePdf(Id accountId) {
        // Step 1: Get the latest map image for this Account
        ContentVersion mapImage = [
            SELECT Id, Title 
            FROM ContentVersion
            WHERE ContentDocumentId IN (
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :accountId
            )
            AND Title LIKE 'ClientPlanMap_%'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if(mapImage == null) {
            throw new AuraHandledException('No map image found for this Account.');
        }

        // Step 2: Call the VF Page
        PageReference pdfPage = Page.ClientPlanPDF;
        pdfPage.getParameters().put('accountId', accountId);
        pdfPage.getParameters().put('imageId', mapImage.Id);

        Blob pdfBlob = pdfPage.getContentAsPDF();

        // Step 3: Save PDF as ContentVersion
        ContentVersion pdfCv = new ContentVersion(
            Title = 'ClientPlanPDF_' + System.now().format(),
            PathOnClient = 'ClientPlan.pdf',
            VersionData = pdfBlob
        );
        insert pdfCv;

        Id pdfDocId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :pdfCv.Id
        ].ContentDocumentId;

        insert new ContentDocumentLink(
            ContentDocumentId = pdfDocId,
            LinkedEntityId = accountId,
            ShareType = 'V'
        );
    }
}
