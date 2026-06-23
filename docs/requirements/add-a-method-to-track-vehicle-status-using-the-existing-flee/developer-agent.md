# Add a method to track vehicle status using the existing Fleet_Vehicle__c object and its VIN__c field — Developer Agent

To implement the requirement for tracking vehicle status using the `Fleet_Vehicle__c` object and its `VIN__c` field, I have designed a modular solution following best practices: a Selector class for queries, a Service class for business logic, and a LWC for the user interface.

### 1. Apex Classes

#### `force-app/main/default/classes/FleetVehicleSelector.cls`
```apex
/**
 * @description Selector class for querying Fleet_Vehicle__c records
 * @author Salesforce Developer Agent
 * @date 2023-11-20
 */
public with sharing class FleetVehicleSelector {
    
    /**
     * @description Fetches a vehicle record by its VIN
     * @param vin The Unique Vehicle Identification Number
     * @return Fleet_Vehicle__c record or null
     */
    public static Fleet_Vehicle__c getVehicleByVin(String vin) {
        if (String.isBlank(vin)) {
            return null;
        }
        
        List<Fleet_Vehicle__c> vehicles = [
            SELECT Id, Name, VIN__c, Status__c, Last_Status_Update__c
            FROM Fleet_Vehicle__c
            WHERE VIN__c = :vin
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        return vehicles.isEmpty() ? null : vehicles[0];
    }
}
```

#### `force-app/main/default/classes/FleetVehicleSelector.cls-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>58.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

#### `force-app/main/default/classes/VehicleStatusService.cls`
```apex
/**
 * @description Service class to handle logic for Vehicle Status tracking
 * @author Salesforce Developer Agent
 */
public with sharing class VehicleStatusService {

    /**
     * @description Updates the status of a vehicle based on VIN
     * @param vin The VIN of the vehicle
     * @param newStatus The new status to apply
     * @return The updated Fleet_Vehicle__c record
     */
    @AuraEnabled
    public static Fleet_Vehicle__c updateVehicleStatus(String vin, String newStatus) {
        try {
            Fleet_Vehicle__c vehicle = FleetVehicleSelector.getVehicleByVin(vin);
            
            if (vehicle == null) {
                throw new AuraHandledException('No vehicle found with VIN: ' + vin);
            }
            
            vehicle.Status__c = newStatus;
            vehicle.Last_Status_Update__c = System.now();
            
            update vehicle;
            return vehicle;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error updating status: ' + e.getMessage());
        }
    }

    /**
     * @description Retrieves current status for a VIN
     * @param vin The VIN to look up
     * @return Fleet_Vehicle__c record
     */
    @AuraEnabled(cacheable=true)
    public static Fleet_Vehicle__c getVehicleStatus(String vin) {
        Fleet_Vehicle__c vehicle = FleetVehicleSelector.getVehicleByVin(vin);
        if (vehicle == null) {
            throw new AuraHandledException('Vehicle not found');
        }
        return vehicle;
    }
}
```

#### `force-app/main/default/classes/VehicleStatusService.cls-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>58.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

---

### 2. Lightning Web Component

#### `force-app/main/default/lwc/vehicleStatusTracker/vehicleStatusTracker.html`
```html
<template>
    <lightning-card title="Vehicle Status Tracker" icon-name="standard:delivery_truck">
        <div class="slds-p-around_medium">
            <div class="slds-form-element slds-m-bottom_medium">
                <lightning-input 
                    type="text" 
                    label="Enter VIN" 
                    value={vin} 
                    onchange={handleVinChange}
                    placeholder="Enter 17-character VIN...">
                </lightning-input>
            </div>

            <lightning-button 
                label="Track Status" 
                variant="brand" 
                onclick={handleTrackStatus} 
                class="slds-m-right_x-small"
                disabled={isSearchDisabled}>
            </lightning-button>

            <template if:true={vehicle}>
                <div class="slds-m-top_large slds-box slds-theme_shade">
                    <p><strong>Vehicle Name:</strong> {vehicle.Name}</p>
                    <p><strong>Current Status:</strong> 
                        <span class="slds-badge slds-m-left_small">{vehicle.Status__c}</span>
                    </p>
                    <p class="slds-m-top_small"><strong>Last Updated:</strong> {vehicle.Last_Status_Update__c}</p>
                    
                    <div class="slds-m-top_medium">
                        <lightning-combobox
                            name="status"
                            label="Update Status"
                            value={newStatus}
                            placeholder="Select New Status"
                            options={statusOptions}
                            onchange={handleStatusChange} >
                        </lightning-combobox>
                        <lightning-button 
                            label="Update" 
                            variant="success" 
                            onclick={handleUpdateStatus}
                            class="slds-m-top_small"
                            disabled={isUpdateDisabled}>
                        </lightning-button>
                    </div>
                </div>
            </template>

            <template if:true={error}>
                <div class="slds-text-color_error slds-m-top_medium">
                    {error}
                </div>
            </template>
        </div>
    </lightning-card>
</template>
```

#### `force-app/main/default/lwc/vehicleStatusTracker/vehicleStatusTracker.js`
```javascript
import { LightningElement, track } from 'lwc';
import getVehicleStatus from '@salesforce/apex/VehicleStatusService.getVehicleStatus';
import updateVehicleStatus from '@salesforce/apex/VehicleStatusService.updateVehicleStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class VehicleStatusTracker extends LightningElement {
    @track vin = '';
    @track vehicle;
    @track error;
    @track newStatus = '';

    statusOptions = [
        { label: 'In Transit', value: 'In Transit' },
        { label: 'Delivered', value: 'Delivered' },
        { label: 'Maintenance', value: 'Maintenance' },
        { label: 'Available', value: 'Available' }
    ];

    handleVinChange(event) {
        this.vin = event.target.value;
    }

    handleStatusChange(event) {
        this.newStatus = event.target.value;
    }

    get isSearchDisabled() {
        return !this.vin;
    }

    get isUpdateDisabled() {
        return !this.newStatus;
    }

    handleTrackStatus() {
        getVehicleStatus({ vin: this.vin })
            .then(result => {
                this.vehicle = result;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error.body.message;
                this.vehicle = undefined;
            });
    }

    handleUpdateStatus() {
        updateVehicleStatus({ vin: this.vin, newStatus: this.newStatus })
            .then(result => {
                this.vehicle = result;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Vehicle status updated successfully',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
}
```

#### `force-app/main/default/lwc/vehicleStatusTracker/vehicleStatusTracker.js-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>58.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__AppPage</target>
        <target>lightning__RecordPage</target>
        <target>lightning__HomePage</target>
    </targets>
</LightningComponentBundle>
```

### 3. Permission Set (Recommended)
This ensures the fields and classes are accessible to users.

#### `force-app/main/default/permissionsets/Fleet_Management_User.permissionset`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <hasActivationRequired>false</hasActivationRequired>
    <label>Fleet Management User</label>
    <classAccesses>
        <apexClass>VehicleStatusService</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <classAccesses>
        <apexClass>FleetVehicleSelector</apexClass>
        <enabled>true</enabled>
    </classAccesses>
    <fieldPermissions>
        <editable>true</editable>
        <field>Fleet_Vehicle__c.Status__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Fleet_Vehicle__c.VIN__c</field>
        <readable>true</readable>
    </fieldPermissions>
</PermissionSet>
```