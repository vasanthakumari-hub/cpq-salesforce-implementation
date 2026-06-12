# Fleet & Vehicle Management System — Developer Agent

This solution provides a complete, deployable Fleet & Vehicle Management System based on your specific rules and the 60.0 API version.

### 1. Data Model (Objects & Fields)

**force-app/main/default/objects/Fleet_Vehicle__c/Fleet_Vehicle__c.object-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <deploymentStatus>Deployed</deploymentStatus>
    <description>Represents a vehicle in the fleet.</description>
    <enableActivities>true</enableActivities>
    <enableReports>true</enableReports>
    <label>Fleet Vehicle</label>
    <nameField>
        <label>Vehicle Name</label>
        <type>Text</type>
    </nameField>
    <pluralLabel>Fleet Vehicles</pluralLabel>
    <sharingModel>ReadWrite</sharingModel>
</CustomObject>
```

**force-app/main/default/objects/Fleet_Vehicle__c/fields/VIN__c.field-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>VIN__c</fullName>
    <externalId>false</externalId>
    <label>VIN</label>
    <length>17</length>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <type>Text</type>
    <unique>true</unique>
</CustomField>
```

**force-app/main/default/objects/Fleet_Vehicle__c/fields/Status__c.field-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Status__c</fullName>
    <label>Status</label>
    <type>Picklist</type>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <valueSet>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Active</fullName><default>true</default><label>Active</label></value>
            <value><fullName>In Maintenance</fullName><default>false</default><label>In Maintenance</label></value>
            <value><fullName>Retired</fullName><default>false</default><label>Retired</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
```

**force-app/main/default/objects/Vehicle_Maintenance__c/Vehicle_Maintenance__c.object-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <deploymentStatus>Deployed</deploymentStatus>
    <label>Vehicle Maintenance</label>
    <nameField>
        <displayFormat>MNT-{0000}</displayFormat>
        <label>Maintenance Number</label>
        <type>AutoNumber</type>
    </nameField>
    <pluralLabel>Vehicle Maintenances</pluralLabel>
    <sharingModel>ControlledByParent</sharingModel>
</CustomObject>
```

**force-app/main/default/objects/Vehicle_Maintenance__c/fields/Fleet_Vehicle__c.field-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Fleet_Vehicle__c</fullName>
    <label>Fleet Vehicle</label>
    <referenceTo>Fleet_Vehicle__c</referenceTo>
    <relationshipLabel>Maintenances</relationshipLabel>
    <relationshipName>Maintenances</relationshipName>
    <relationshipOrder>0</relationshipOrder>
    <reparentableMasterDetail>false</reparentableMasterDetail>
    <type>MasterDetail</type>
    <writeRequiresMasterRead>false</writeRequiresMasterRead>
</CustomField>
```

**force-app/main/default/objects/Vehicle_Maintenance__c/fields/Maintenance_Date__c.field-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Maintenance_Date__c</fullName>
    <label>Maintenance Date</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <type>Date</type>
</CustomField>
```

---

### 2. Apex Layer

**force-app/main/default/classes/FleetVehicleController.cls**
```java
/**
 * @description Controller for Fleet Vehicle Management LWC components
 */
public with sharing class FleetVehicleController {
    
    @AuraEnabled(cacheable=true)
    public static List<Fleet_Vehicle__c> getAllVehicles() {
        try {
            return [
                SELECT Id, Name, VIN__c, Status__c, 
                       (SELECT Id, Maintenance_Date__c FROM Maintenances__r ORDER BY Maintenance_Date__c DESC LIMIT 1)
                FROM Fleet_Vehicle__c 
                WITH USER_MODE
                ORDER BY Name ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving vehicles: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateVehicleStatus(Id vehicleId, String newStatus) {
        try {
            Fleet_Vehicle__c vehicle = new Fleet_Vehicle__c(
                Id = vehicleId,
                Status__c = newStatus
            );
            update as user vehicle;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating status: ' + e.getMessage());
        }
    }
}
```

**force-app/main/default/classes/FleetVehicleController.cls-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

**force-app/main/default/classes/FleetVehicleControllerTest.cls**
```java
@isTest
private class FleetVehicleControllerTest {
    @TestSetup
    static void makeData(){
        Fleet_Vehicle__c v = new Fleet_Vehicle__c(
            Name = 'Test Truck',
            VIN__c = '12345678901234567',
            Status__c = 'Active'
        );
        insert v;
    }

    @isTest
    static void testGetAllVehicles() {
        Test.startTest();
        List<Fleet_Vehicle__c> results = FleetVehicleController.getAllVehicles();
        Test.stopTest();
        Assert.areEqual(1, results.size(), 'Should return one vehicle');
    }

    @isTest
    static void testUpdateStatus() {
        Fleet_Vehicle__c v = [SELECT Id FROM Fleet_Vehicle__c LIMIT 1];
        Test.startTest();
        FleetVehicleController.updateVehicleStatus(v.Id, 'In Maintenance');
        Test.stopTest();
        
        Fleet_Vehicle__c updatedV = [SELECT Status__c FROM Fleet_Vehicle__c WHERE Id = :v.Id];
        Assert.areEqual('In Maintenance', updatedV.Status__c);
    }
}
```

---

### 3. Lighting Web Component (LWC)

**force-app/main/default/lwc/fleetVehicleList/fleetVehicleList.html**
```html
<template>
    <lightning-card title="Fleet Inventory" icon-name="standard:shipping_and_receiving">
        <div class="slds-p-around_medium">
            <template lwc:if={isLoading}>
                <lightning-spinner alternative-text="Loading..."></lightning-spinner>
            </template>

            <template lwc:if={error}>
                <div class="slds-notify slds-notify_alert slds-theme_alert-texture slds-theme_error" role="alert">
                    <h2>{error}</h2>
                </div>
            </template>

            <template lwc:if={vehicles}>
                <table class="slds-table slds-table_cell-buffer slds-table_bordered">
                    <thead>
                        <tr class="slds-line-height_reset">
                            <th scope="col"><div class="slds-truncate" title="Name">Name</div></th>
                            <th scope="col"><div class="slds-truncate" title="VIN">VIN</div></th>
                            <th scope="col"><div class="slds-truncate" title="Status">Status</div></th>
                            <th scope="col"><div class="slds-truncate" title="Action">Action</div></th>
                        </tr>
                    </thead>
                    <tbody>
                        <template for:each={vehicles} for:item="v">
                            <tr key={v.Id}>
                                <td>{v.Name}</td>
                                <td>{v.VIN__c}</td>
                                <td>
                                    <lightning-badge label={v.Status__c}></lightning-badge>
                                </td>
                                <td>
                                    <lightning-button-menu alternative-text="Show menu" onselect={handleMenuSelect} value={v.Id}>
                                        <lightning-menu-item value="Active" label="Set Active"></lightning-menu-item>
                                        <lightning-menu-item value="In Maintenance" label="Set In Maintenance"></lightning-menu-item>
                                    </lightning-button-menu>
                                </td>
                            </tr>
                        </template>
                    </tbody>
                </table>
            </template>

            <template lwc:elseif={noData}>
                <p class="slds-text-align_center">No vehicles found in fleet.</p>
            </template>
        </div>
    </lightning-card>
</template>
```

**force-app/main/default/lwc/fleetVehicleList/fleetVehicleList.js**
```javascript
import { LightningElement, wire, track } from 'lwc';
import getAllVehicles from '@salesforce/apex/FleetVehicleController.getAllVehicles';
import updateVehicleStatus from '@salesforce/apex/FleetVehicleController.updateVehicleStatus';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FleetVehicleList extends LightningElement {
    @track vehicles;
    @track error;
    @track isLoading = false;
    wiredVehicleResult;

    @wire(getAllVehicles)
    wiredVehicles(result) {
        this.wiredVehicleResult = result;
        if (result.data) {
            this.vehicles = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error.body.message;
            this.vehicles = undefined;
        }
    }

    get noData() {
        return !this.isLoading && (!this.vehicles || this.vehicles.length === 0);
    }

    handleMenuSelect(event) {
        const vehicleId = event.target.value;
        const newStatus = event.detail.value;
        this.isLoading = true;

        updateVehicleStatus({ vehicleId: vehicleId, newStatus: newStatus })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Vehicle status updated',
                        variant: 'success'
                    })
                );
                return refreshApex(this.wiredVehicleResult);
            })
            .catch(error => {
                this.error = error.body.message;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}
```

**force-app/main/default/lwc/fleetVehicleList/fleetVehicleList.js-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__AppPage</target>
        <target>lightning__HomePage</target>
    </targets>
</LightningComponentBundle>
```

---

### 4. Permission Set

**force-app/main/default/permissionsets/Fleet_Manager.permissionset-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <hasActivationRequired>false</hasActivationRequired>
    <label>Fleet Manager</label>
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>true</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <object>Fleet_Vehicle__c</object>
        <viewAllRecords>false</viewAllRecords>
    </objectPermissions>
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>true</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <object>Vehicle_Maintenance__c</object>
        <viewAllRecords>false</viewAllRecords>
    </objectPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Fleet_Vehicle__c.VIN__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Fleet_Vehicle__c.Status__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Vehicle_Maintenance__c.Maintenance_Date__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <classAccesses>
        <apexClass>FleetVehicleController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
</PermissionSet>
```

---

### 5. Deployment Package

**package.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>FleetVehicleController</members>
        <members>FleetVehicleControllerTest</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>fleetVehicleList</members>
        <name>LightningComponentBundle</name>
    </types>
    <types>
        <members>Fleet_Vehicle__c</members>
        <members>Vehicle_Maintenance__c</members>
        <name>CustomObject</name>
    </types>
    <types>
        <members>Fleet_Manager</members>
        <name>PermissionSet</name>
    </types>
    <version>60.0</version>
</Package>
```

**scripts/deploy.sh**
```bash
#!/bin/bash
# Deploy to the default org using API 60.0
sf project deploy start --api-version 60.0
```