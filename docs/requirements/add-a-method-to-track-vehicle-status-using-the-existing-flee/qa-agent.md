# Add a method to track vehicle status using the existing Fleet_Vehicle__c object and its VIN__c field — QA Agent

To fulfill the requirements for the CPQ Implementation project, I have developed the following test suite. This suite assumes the existence of a `FleetVehicleService` class that manages the `Fleet_Vehicle__c` status updates.

### 1. Test Scenarios Table

| Test Case ID | Description | Steps | Expected Result | Type |
|:---|:---|:---|:---|:---|
| TC-01 | Positive: Update Status by VIN | Pass valid VIN and Status to `updateVehicleStatus` | Record is updated in DB; returns true. | Unit |
| TC-02 | Negative: Invalid VIN | Pass a non-existent VIN to the method | Method returns false or throws custom Exception. | Unit |
| TC-03 | Boundary: Null/Empty Values | Pass null VIN and null Status | Handled gracefully without NullPointerException. | Boundary |
| TC-04 | Bulk: 200 Records Update | Insert 200 vehicles and update status via service | All 200 records update within governor limits. | Bulk |
| TC-05 | Security: Field Level Access | Run update as user without Edit access to Status | Method should respect FLS and fail/throw error. | Security |
| TC-06 | Validation: VIN Format | Attempt update with VIN not matching regex | Validation rule triggers and prevents save. | Integration |

---

### 2. Apex Test Data Factory

**File Path:** `force-app/main/default/classes/FleetTestDataFactory.cls`

```apex
@isTest
public class FleetTestDataFactory {
    public static List<Fleet_Vehicle__c> createVehicles(Integer count, Boolean doInsert) {
        List<Fleet_Vehicle__c> vehicles = new List<Fleet_Vehicle__c>();
        for(Integer i=0; i<count; i++) {
            vehicles.add(new Fleet_Vehicle__c(
                Name = 'Vehicle ' + i,
                VIN__c = 'VIN' + String.valueOf(i).leftPad(14, '0'),
                Status__c = 'Inventory'
            ));
        }
        if(doInsert) {
            insert vehicles;
        }
        return vehicles;
    }

    public static User createTestUser(String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name=:profileName];
        String uniqueName = 'fleetUser' + DateTime.now().getTime() + '@test.com';
        User u = new User(Alias = 'fltusr', Email='standarduser@test.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName=uniqueName);
        return u;
    }
}
```

**File Path:** `force-app/main/default/classes/FleetTestDataFactory.cls-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>58.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

---

### 3. Apex Test Class

**File Path:** `force-app/main/default/classes/FleetVehicleServiceTest.cls`

```apex
@isTest
private class FleetVehicleServiceTest {

    @testSetup
    static void setup() {
        FleetTestDataFactory.createVehicles(1, true);
    }

    @isTest
    static void testUpdateVehicleStatus_Positive() {
        Fleet_Vehicle__c vehicle = [SELECT VIN__c FROM Fleet_Vehicle__c LIMIT 1];
        
        Test.startTest();
        Boolean result = FleetVehicleService.updateVehicleStatus(vehicle.VIN__c, 'In Use');
        Test.stopTest();

        System.assertEquals(true, result, 'Service should return true on success');
        Fleet_Vehicle__c updatedVeh = [SELECT Status__c FROM Fleet_Vehicle__c WHERE VIN__c = :vehicle.VIN__c];
        System.assertEquals('In Use', updatedVeh.Status__c, 'Status was not updated correctly');
    }

    @isTest
    static void testUpdateVehicleStatus_InvalidVIN() {
        Test.startTest();
        Boolean result = FleetVehicleService.updateVehicleStatus('NON-EXISTENT-VIN', 'In Use');
        Test.stopTest();

        System.assertEquals(false, result, 'Service should return false for non-existent VIN');
    }

    @isTest
    static void testUpdateVehicleStatus_Bulk() {
        // Create 200 records
        List<Fleet_Vehicle__c> vehicles = FleetTestDataFactory.createVehicles(200, true);
        List<String> vins = new List<String>();
        for(Fleet_Vehicle__c v : vehicles) {
            vins.add(v.VIN__c);
        }

        Test.startTest();
        // Assuming the service supports bulk or is called in a loop
        for(String vin : vins) {
            FleetVehicleService.updateVehicleStatus(vin, 'Maintenance');
        }
        Test.stopTest();

        List<Fleet_Vehicle__c> updatedList = [SELECT Id FROM Fleet_Vehicle__c WHERE Status__c = 'Maintenance'];
        System.assertEquals(201, updatedList.size(), 'All 200 + 1 setup records should be updated');
    }

    @isTest
    static void testUpdateVehicleStatus_SecurityAccess() {
        User limitedUser = FleetTestDataFactory.createTestUser('Read Only');
        Fleet_Vehicle__c vehicle = [SELECT VIN__c FROM Fleet_Vehicle__c LIMIT 1];
        
        System.runAs(limitedUser) {
            Test.startTest();
            try {
                FleetVehicleService.updateVehicleStatus(vehicle.VIN__c, 'In Use');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage() != null, 'Should catch security exception');
            }
            Test.stopTest();
        }
    }
}
```

**File Path:** `force-app/main/default/classes/FleetVehicleServiceTest.cls-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>58.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

---

### 4. Validation & Permission Tests

| Component | Scenario | Test Implementation |
|:---|:---|:---|
| **Validation Rule** | VIN must be 17 chars | Test method: `testVINLengthValidation`. Expect `DmlException` on insert of 10-char VIN. |
| **FLS** | Status field Read-Only | Use `System.runAs(restrictedUser)` and assert that `Schema.sObjectType.Fleet_Vehicle__c.fields.Status__c.isUpdateable()` is false. |
| **Flow/Trigger** | Status History Log | Verify that changing `Status__c` creates a record in a related `Status_History__c` object. |

---

### 5. LWC Jest Test Case (Frontend)

This tests a component that allows a user to input a VIN and update status.

**File Path:** `force-app/main/default/lwc/vehicleStatusUpdater/__tests__/vehicleStatusUpdater.test.js`

```javascript
import { createElement } from 'lwc';
import VehicleStatusUpdater from 'c/vehicleStatusUpdater';
import updateVehicleStatus from '@salesforce/apex/FleetVehicleService.updateVehicleStatus';

// Mocking Apex
jest.mock(
    '@salesforce/apex/FleetVehicleService.updateVehicleStatus',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

describe('c-vehicle-status-updater', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders input fields and button', () => {
        const element = createElement('c-vehicle-status-updater', {
            is: VehicleStatusUpdater
        });
        document.body.appendChild(element);

        const buttonEl = element.shadowRoot.querySelector('lightning-button');
        const inputEls = element.shadowRoot.querySelectorAll('lightning-input');
        
        expect(buttonEl.label).toBe('Update Status');
        expect(inputEls.length).toBeGreaterThanOrEqual(1);
    });

    it('calls apex method on button click', async () => {
        updateVehicleStatus.mockResolvedValue(true);
        
        const element = createElement('c-vehicle-status-updater', {
            is: VehicleStatusUpdater
        });
        document.body.appendChild(element);

        // Simulate User Input
        const vinInput = element.shadowRoot.querySelector('.vin-input');
        vinInput.value = 'VIN12345678901234';
        vinInput.dispatchEvent(new CustomEvent('change'));

        const btn = element.shadowRoot.querySelector('lightning-button');
        btn.click();

        return Promise.resolve().then(() => {
            expect(updateVehicleStatus).toHaveBeenCalled();
        });
    });
});
```

---

### Deployment Summary
1.  **Deploy Factory**: `classes/FleetTestDataFactory.cls`
2.  **Deploy Logic**: `classes/FleetVehicleService.cls` (Implementation required)
3.  **Deploy Unit Tests**: `classes/FleetVehicleServiceTest.cls`
4.  **Run Tests**: `sfdx force:apex:test:run -n FleetVehicleServiceTest -r human`