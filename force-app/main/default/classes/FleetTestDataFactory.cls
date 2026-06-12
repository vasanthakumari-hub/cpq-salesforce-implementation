@isTest
public class FleetTestDataFactory {
    public static List<Fleet_Vehicle__c> createVehicles(Integer count) {
        List<Fleet_Vehicle__c> vehicles = new List<Fleet_Vehicle__c>();
        for(Integer i=0; i<count; i++) {
            vehicles.add(new Fleet_Vehicle__c(
                Name = 'Vehicle ' + i,
                VIN__c = 'VIN' + String.valueOf(i).leftPad(14, '0')
            ));
        }
        insert vehicles;
        return vehicles;
    }
}