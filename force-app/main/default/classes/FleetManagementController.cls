public with sharing class FleetManagementController {
    @AuraEnabled(cacheable=true)
    public static List<Fleet_Vehicle__c> getVehicleList() {
        try {
            return [SELECT Id, Name, VIN__c FROM Fleet_Vehicle__c ORDER BY CreatedDate DESC LIMIT 50];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving vehicles: ' + e.getMessage());
        }
    }
}