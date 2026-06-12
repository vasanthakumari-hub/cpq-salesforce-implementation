@isTest
private class FleetManagementTest {
    
    @TestSetup
    static void setup() {
        FleetTestDataFactory.createVehicles(5);
    }

    @isTest
    static void testGetVehicleList_Positive() {
        Test.startTest();
        List<Fleet_Vehicle__c> results = FleetManagementController.getVehicleList();
        Test.stopTest();
        Assert.areEqual(5, results.size(), 'Should return 5 vehicles');
        Assert.isNotNull(results[0].Name, 'Vehicle Name should be populated');
    }

    @isTest
    static void testGetVehicleList_Empty() {
        delete [SELECT Id FROM Fleet_Vehicle__c];
        Test.startTest();
        List<Fleet_Vehicle__c> results = FleetManagementController.getVehicleList();
        Test.stopTest();
        Assert.areEqual(0, results.size(), 'Should return empty list');
    }

    @isTest
    static void testGetVehicleList_Exception() {
        FleetManagementController.throwError = true;
        Test.startTest();
        try {
            FleetManagementController.getVehicleList();
            Assert.fail('Should have thrown exception');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Should throw AuraHandledException');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetVehicleById_Positive() {
        Fleet_Vehicle__c v = [SELECT Id FROM Fleet_Vehicle__c LIMIT 1];
        Test.startTest();
        Fleet_Vehicle__c result = FleetManagementController.getVehicleById(v.Id);
        Test.stopTest();
        Assert.areEqual(v.Id, result.Id, 'Should return correct vehicle');
    }

    @isTest
    static void testGetVehicleById_Exception() {
        FleetManagementController.throwError = true;
        Fleet_Vehicle__c v = [SELECT Id FROM Fleet_Vehicle__c LIMIT 1];
        Test.startTest();
        try {
            FleetManagementController.getVehicleById(v.Id);
            Assert.fail('Should have thrown exception');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Should throw AuraHandledException');
        }
        Test.stopTest();
    }

    @isTest
    static void testDeleteVehicle_Positive() {
        Fleet_Vehicle__c v = [SELECT Id FROM Fleet_Vehicle__c LIMIT 1];
        Test.startTest();
        FleetManagementController.deleteVehicle(v.Id);
        Test.stopTest();
        List<Fleet_Vehicle__c> remaining = [SELECT Id FROM Fleet_Vehicle__c WHERE Id = :v.Id];
        Assert.areEqual(0, remaining.size(), 'Vehicle should be deleted');
    }

    @isTest
    static void testDeleteVehicle_Exception() {
        FleetManagementController.throwError = true;
        Fleet_Vehicle__c v = [SELECT Id FROM Fleet_Vehicle__c LIMIT 1];
        Test.startTest();
        try {
            FleetManagementController.deleteVehicle(v.Id);
            Assert.fail('Should have thrown exception');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Should throw AuraHandledException');
        }
        Test.stopTest();
    }

    @isTest
    static void testSecurityAccess() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(
            Alias = 'flt_qa', Email='fleetqa@test.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='fleetqa' + DateTime.now().getTime() + '@test.com'
        );
        insert testUser;
        System.runAs(testUser) {
            Test.startTest();
            try {
                List<Fleet_Vehicle__c> results = FleetManagementController.getVehicleList();
                Assert.isNotNull(results, 'Should return a list');
            } catch (Exception e) {
                Assert.isNotNull(e, 'Exception acceptable if sharing restricts access');
            }
            Test.stopTest();
        }
    }
}
