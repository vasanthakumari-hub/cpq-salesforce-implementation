public with sharing class FleetManagementController {

    @TestVisible private static Boolean throwError = false;

    @AuraEnabled(cacheable=true)
    public static List<Fleet_Vehicle__c> getVehicleList() {
        try {
            if (throwError) throw new AuraHandledException('Forced error');
            return [SELECT Id, Name, VIN__c FROM Fleet_Vehicle__c 
                    ORDER BY CreatedDate DESC LIMIT 50];
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving vehicles: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Fleet_Vehicle__c getVehicleById(Id vehicleId) {
        try {
            if (throwError) throw new AuraHandledException('Forced error');
            return [SELECT Id, Name, VIN__c FROM Fleet_Vehicle__c 
                    WHERE Id = :vehicleId LIMIT 1];
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving vehicle: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void deleteVehicle(Id vehicleId) {
        try {
            if (throwError) throw new AuraHandledException('Forced error');
            Fleet_Vehicle__c v = [SELECT Id FROM Fleet_Vehicle__c WHERE Id = :vehicleId];
            delete v;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting vehicle: ' + e.getMessage());
        }
    }
}
