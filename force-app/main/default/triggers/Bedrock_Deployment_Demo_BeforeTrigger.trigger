trigger Bedrock_Deployment_Demo_BeforeTrigger on Bedrock_Deployment_Demo__c (before update, before insert) {
if(trigger.isInsert){
System.Debug('Demo');
}
}
