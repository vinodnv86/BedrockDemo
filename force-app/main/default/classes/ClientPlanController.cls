public with sharing class ClientPlanController {

    @AuraEnabled
    public static void saveMapImage(Id accountId, String base64Image) {
        if (String.isBlank(base64Image)) {
            throw new AuraHandledException('No image received.');
        }

        Blob imageBlob = EncodingUtil.base64Decode(base64Image);
        ContentVersion cv = new ContentVersion(
            Title = 'ClientPlanMap_' + Datetime.now().getTime(),
            PathOnClient = 'ClientPlanMap.png',
            VersionData = imageBlob
        );
        insert cv;

        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        insert new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = accountId,
            ShareType = 'V'
        );
    }
}
