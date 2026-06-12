# Fleet & Vehicle Management System — Technical Architect

### 1. Architecture Overview
The Fleet & Vehicle Management System is designed as a modular solution on the Salesforce platform to manage the lifecycle of corporate assets. It utilizes an event-driven architecture for maintenance scheduling and a decoupled UI layer using Lightning Web Components.

**Core Components:**
- **Data Layer:** Schema defined to track assets (Fleet_Vehicle__c) and their service history (Vehicle_Maintenance__c).
- **Logic Layer:** Trigger Framework (Handler Pattern) and Service Layer for business logic (e.g., calculating maintenance due dates).
- **UI Layer:** Reactive LWC for real-time fleet status overview and maintenance logging.

---

### 2. Data Model

#### Object: `Fleet_Vehicle__c`
| Field API Name | Data Type | Details |
| :--- | :--- | :--- |
| `VIN__c` | Text(17) | Unique Identifier (External ID) |
| `Model__c` | Text(100) | Vehicle Model name |
| `Year__c` | Number(4,0) | Manufacturing Year |
| `Status__c` | Picklist | Active, In Repair, Retired |
| `Last_Service_Date__c` | Date | Automated from Maintenance records |

#### Object: `Vehicle_Maintenance__c`
| Field API Name | Data Type | Details |
| :--- | :--- | :--- |
| `Fleet_Vehicle__c` | Master-Detail | Parent: Fleet_Vehicle__c |
| `Service_Date__c` | Date | Date of service |
| `Cost__c` | Currency(12, 2) | Maintenance cost |
| `Service_Type__c` | Picklist | Oil Change, Tire Rotation, Engine Repair |
| `Description__c` | Long TextArea(32000) | Detailed notes |

---

### 3. Apex Architecture

**Trigger Handler Pattern:**
- `FleetVehicleTriggerHandler.cls`: Manages logic for vehicle status changes.
- `VehicleMaintenanceTriggerHandler.cls`: Roll-up logic to update `Last_Service_Date__c` on the parent vehicle.

**Service Layer:**
- `FleetManagementService.cls`: Centralized business logic for maintenance scheduling and fleet KPIs.

---

### 4. Implementation Metadata

#### force-app/main/default/objects/Fleet_Vehicle__c/Fleet_Vehicle__c.object-meta.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <deploymentStatus>Deployed</deploymentStatus>
    <label>Fleet Vehicle</label>
    <nameField>
        <label>Vehicle Name</label>
        <type>Text</type>
    </nameField>
    <pluralLabel>Fleet Vehicles</pluralLabel>
    <sharingModel>ReadWrite</sharingModel>
    <visibility>Public</visibility>
</CustomObject>
```

#### force-app/main/default/objects/Fleet_Vehicle__c/fields/VIN__c.field-meta.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>VIN__c</fullName>
    <externalId>true</externalId>
    <label>VIN</label>
    <length>17</length>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <type>Text</type>
    <unique>true</unique>
</CustomField>
```

#### force-app/main/default/classes/FleetController.cls
```java
public with sharing class FleetController {
    @AuraEnabled(cacheable=true)
    public static List<Fleet_Vehicle__c> getActiveVehicles() {
        try {
            return [SELECT Id, Name, VIN__c, Model__c, Status__c, Last_Service_Date__c 
                    FROM Fleet_Vehicle__c 
                    WHERE Status__c = 'Active' 
                    WITH SECURITY_ENFORCED 
                    LIMIT 100];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving fleet: ' + e.getMessage());
        }
    }
}
```

#### force-app/main/default/classes/FleetController.cls-meta.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

---

### 5. UI Components (LWC)

#### force-app/main/default/lwc/fleetList/fleetList.html
```html
<template>
    <lightning-card title="Active Fleet" icon-name="standard:fleet">
        <div class="slds-m-around_medium">
            <template if:true={vehicles}>
                <lightning-datatable
                    key-field="Id"
                    data={vehicles}
                    columns={columns}>
                </lightning-datatable>
            </template>
            <template if:true={error}>
                <p class="slds-text-color_error">Error loading fleet data.</p>
            </template>
        </div>
    </lightning-card>
</template>
```

#### force-app/main/default/lwc/fleetList/fleetList.js
```javascript
import { LightningElement, wire, track } from 'lwc';
import getActiveVehicles from '@salesforce/apex/FleetController.getActiveVehicles';

export default class FleetList extends LightningElement {
    @track vehicles;
    @track error;
    columns = [
        { label: 'Vehicle Name', fieldName: 'Name' },
        { label: 'VIN', fieldName: 'VIN__c' },
        { label: 'Model', fieldName: 'Model__c' },
        { label: 'Status', fieldName: 'Status__c' }
    ];

    @wire(getActiveVehicles)
    wiredVehicles({ error, data }) {
        if (data) {
            this.vehicles = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.vehicles = undefined;
        }
    }
}
```

#### force-app/main/default/lwc/fleetList/fleetList.js-meta.xml
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

### 6. Security Design

#### force-app/main/default/permissionsets/Fleet_Manager.permissionset-meta.xml
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
        <viewAllRecords>false</viewAllRecords>
        <modifyAllRecords>false</modifyAllRecords>
        <object>Fleet_Vehicle__c</object>
    </objectPermissions>
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>true</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <viewAllRecords>false</viewAllRecords>
        <modifyAllRecords>false</modifyAllRecords>
        <object>Vehicle_Maintenance__c</object>
    </objectPermissions>
</PermissionSet>
```

---

### 7. Deployment Readiness

#### package.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>FleetController</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>fleetList</members>
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

#### scripts/deploy.sh
```bash
#!/bin/bash
# Deploy to Sandbox
sf project deploy start --target-org fleet-sandbox --api-version 60.0
```

#### .github/workflows/deploy.yml
```yaml
name: Deploy to Salesforce
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Salesforce CLI
        run: npm install @salesforce/cli --global
      - name: Deploy Metadata
        run: sf project deploy start --api-version 60.0
```