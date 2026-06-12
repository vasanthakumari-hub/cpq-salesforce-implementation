public with sharing class FleetManagementController {

    @AuraEnabled(cacheable=true)
    public static List<Fleet_Vehicle__c> getVehicleList() {
        try {
            return [SELECT Id, Name, VIN__c FROM Fleet_Vehicle__c 
                    ORDER BY CreatedDate DESC LIMIT 50];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving vehicles: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Fleet_Vehicle__c getVehicleById(Id vehicleId) {
        try {
            return [SELECT Id, Name, VIN__c FROM Fleet_Vehicle__c 
                    WHERE Id = :vehicleId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving vehicle: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void deleteVehicle(Id vehicleId) {
        try {
            Fleet_Vehicle__c v = [SELECT Id FROM Fleet_Vehicle__c WHERE Id = :vehicleId];
            delete v;
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting vehicle: ' + e.getMessage());
        }
    }
}
