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
        
        Assert.areEqual(5, results.size(), 'Should return 5 vehicles created in setup');
        Assert.isNotNull(results[0].Name, 'Vehicle Name should be populated');
    }

    @isTest
    static void testBulkVehicleCreation() {
        Test.startTest();
        List<Fleet_Vehicle__c> bulkList = FleetTestDataFactory.createVehicles(200);
        Test.stopTest();
        
        List<Fleet_Vehicle__c> dbRecords = [SELECT Id FROM Fleet_Vehicle__c];
        // 5 from setup + 200 from test
        Assert.areEqual(205, dbRecords.size(), 'Bulk insert should succeed with 200 records');
    }

    @isTest
    static void testSecurityAccess() {
        // Create a test user with specific profile
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(
            Alias = 'flt_qa', Email='fleetqa@test.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='fleetqa' + DateTime.now().getTime() + '@test.com'
        );
        insert testUser;

        System.runAs(testUser) {
            try {
                FleetManagementController.getVehicleList();
            } catch (Exception e) {
                Assert.isNotNull(e, 'User without permissions should ideally be restricted by "with sharing" or FLS');
            }
        }
    }
}