# Fleet & Vehicle Management System — Admin Agent

This production-ready Fleet & Vehicle Management System is configured using API version 60.0, following all strict naming and dependency rules.

### 1. Custom Objects

**force-app/main/default/objects/Fleet_Vehicle__c/Fleet_Vehicle__c.object-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <deploymentStatus>Deployed</deploymentStatus>
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

**force-app/main/default/objects/Vehicle_Maintenance__c/Vehicle_Maintenance__c.object-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <deploymentStatus>Deployed</deploymentStatus>
    <enableActivities>true</enableActivities>
    <enableReports>true</enableReports>
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

### 2. Custom Fields

**force-app/main/default/objects/Fleet_Vehicle__c/fields/VIN__c.field-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>VIN__c</fullName>
    <externalId>false</externalId>
    <label>VIN</label>
    <length>17</length>
    <required>true</required>
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
    <required>false</required>
    <trackHistory>false</trackHistory>
    <type>Picklist</type>
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
    <trackHistory>false</trackHistory>
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

### 3. Apex Controller & Test Class

**force-app/main/default/classes/FleetManagementController.cls**
```java
public with sharing class FleetManagementController {
    @AuraEnabled(cacheable=true)
    public static List<Fleet_Vehicle__c> getActiveVehicles() {
        try {
            return [SELECT Id, Name, VIN__c, Status__c 
                    FROM Fleet_Vehicle__c 
                    WHERE Status__c = 'Active' 
                    WITH SECURITY_ENFORCED 
                    LIMIT 100];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving vehicles: ' + e.getMessage());
        }
    }
}
```

**force-app/main/default/classes/FleetManagementController.cls-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

**force-app/main/default/classes/FleetManagementTest.cls**
```java
@isTest
public class FleetManagementTest {
    @isTest
    static void testGetActiveVehicles() {
        Fleet_Vehicle__c vehicle = new Fleet_Vehicle__c(
            Name = 'Test Car',
            VIN__c = 'TEST1234567890ABC',
            Status__c = 'Active'
        );
        insert vehicle;

        Test.startTest();
        List<Fleet_Vehicle__c> results = FleetManagementController.getActiveVehicles();
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one active vehicle');
        System.assertEquals('Test Car', results[0].Name, 'Name should match');
    }
}
```

### 4. LWC Component

**force-app/main/default/lwc/vehicleList/vehicleList.html**
```html
<template>
    <lightning-card title="Active Fleet Vehicles" icon-name="custom:custom31">
        <div class="slds-m-around_medium">
            <template if:true={vehicles}>
                <lightning-datatable
                    key-field="Id"
                    data={vehicles}
                    columns={columns}
                    hide-checkbox-column>
                </lightning-datatable>
            </template>
            <template if:true={error}>
                <div class="slds-text-color_error">{error}</div>
            </template>
        </div>
    </lightning-card>
</template>
```

**force-app/main/default/lwc/vehicleList/vehicleList.js**
```javascript
import { LightningElement, wire, track } from 'lwc';
import getActiveVehicles from '@salesforce/apex/FleetManagementController.getActiveVehicles';

const COLUMNS = [
    { label: 'Vehicle Name', fieldName: 'Name', type: 'text' },
    { label: 'VIN', fieldName: 'VIN__c', type: 'text' },
    { label: 'Status', fieldName: 'Status__c', type: 'text' }
];

export default class VehicleList extends LightningElement {
    @track vehicles;
    @track error;
    columns = COLUMNS;

    @wire(getActiveVehicles)
    wiredVehicles({ error, data }) {
        if (data) {
            this.vehicles = data;
            this.error = undefined;
        } else if (error) {
            this.error = 'Error loading vehicles';
            this.vehicles = undefined;
        }
    }
}
```

**force-app/main/default/lwc/vehicleList/vehicleList.js-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__AppPage</target>
        <target>lightning__RecordPage</target>
        <target>lightning__HomePage</target>
    </targets>
</LightningComponentBundle>
```

### 5. Permission Set

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
        <field>Fleet_Vehicle__c.Status__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Vehicle_Maintenance__c.Maintenance_Date__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <classAccesses>
        <apexClass>FleetManagementController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
</PermissionSet>
```

### 6. Deployment Manifest

**package.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>FleetManagementController</members>
        <members>FleetManagementTest</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>vehicleList</members>
        <name>LightningComponentBundle</name>
    </types>
    <types>
        <members>Fleet_Vehicle__c</members>
        <members>Vehicle_Maintenance__c</members>
        <name>CustomObject</name>
    </types>
    <types>
        <members>Fleet_Vehicle__c.VIN__c</members>
        <members>Fleet_Vehicle__c.Status__c</members>
        <members>Vehicle_Maintenance__c.Fleet_Vehicle__c</members>
        <members>Vehicle_Maintenance__c.Maintenance_Date__c</members>
        <name>CustomField</name>
    </types>
    <types>
        <members>Fleet_Manager</members>
        <name>PermissionSet</name>
    </types>
    <version>60.0</version>
</Package>
```