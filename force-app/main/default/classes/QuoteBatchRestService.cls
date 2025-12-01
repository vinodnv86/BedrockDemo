@RestResource(urlMapping='/quoteBatch/start')
global with sharing class QuoteBatchRestService {

    @HttpPost
    global static ResponseWrapper startBatch() {
        ResponseWrapper response = new ResponseWrapper();

        try {
            // Start the batch
            BatchQuoteProcessor batchJob = new BatchQuoteProcessor();
            Id jobId = Database.executeBatch(batchJob, 200); 

            response.status = 'SUCCESS';
            response.message = 'Batch started successfully';
            response.batchJobId = jobId;

        } catch (Exception ex) {
            response.status = 'ERROR';
            response.message = ex.getMessage();
            response.batchJobId = null;
        }

        return response;
    }

    // Wrapper response to return JSON
    global class ResponseWrapper {
        global String status;
        global String message;
        global Id batchJobId;
    }
}
