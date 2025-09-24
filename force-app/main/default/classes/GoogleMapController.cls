public with sharing class GoogleMapController 
{
  
    @AuraEnabled(cacheable=true)
    public static List<Organization> getCompanyLocations(String accountNameInitial){
    //   String str = accountNameInitial + '%';
       return [SELECT Name, 
       InstanceName, 
       OrganizationType, 
       Street, 
       City, 
       State, 
       Country, 
       PostalCode, 
       Phone 
FROM Organization];       
   }
   
}