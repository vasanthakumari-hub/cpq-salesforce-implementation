# Automated Contracting and Renewal Lifecycle — Developer Agent

To implement an automated contracting and renewal lifecycle in a CPQ-like environment, we will use a **Trigger Handler Pattern**. This solution automates the setting of the `Contracted` checkbox on the Opportunity when it is "Closed Won," which triggers the native Salesforce CPQ (or custom) contracting engine to create Contracts, Subscriptions, and Assets.

### 1. Apex Trigger Handler (Domain Layer)

**File Path:** `force-app/main/default/classes/OpportunityTriggerHandler.cls`
```apex
/**
 * @description Handler for Opportunity Trigger events. 
 * Manages the transition of Opportunities to Contracted state.
 * @author Salesforce Developer Agent
 */
public with sharing class OpportunityTriggerHandler {
    
    /**
     * @description Processes Before Update logic.
     * @param newMap Map of new Opportunity records
     * @param oldMap Map of old Opportunity records
     */
    public void onAfterUpdate(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap) {
        Set<Id> oppsToContract = new Set<Id>();

        for (Opportunity newOpp : newMap.values()) {
            Opportunity oldOpp = oldMap.get(newOpp.Id);
            
            // Logic: If Stage changes to Closed Won and Contracted is not yet true
            if (newOpp.IsWon && !oldOpp.IsWon && !newOpp.Contracted__c) {
                oppsToContract.add(newOpp.Id);
            }
        }

        if (!oppsToContract.isEmpty()) {
            ContractingService.autoContractOpportunities(oppsToContract);
        }
    }
}
```

**File Path:** `force-app/main/default/classes/OpportunityTriggerHandler.cls-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>58.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

---

### 2. Service Class (Business Logic Layer)

**File Path:** `force-app/main/default/classes/ContractingService.cls`
```apex
/**
 * @description Service class handling business logic for Contracting and Renewals.
 * Performs DML operations in a separate transaction via @future if needed, 
 * or synchronously for immediate processing.
 */
public with sharing class ContractingService {

    /**
     * @description Marks Opportunities as 'Contracted' to trigger CPQ background processes.
     * @param oppIds Set of Opportunity IDs to process
     */
    public static void autoContractOpportunities(Set<Id> oppIds) {
        List<Opportunity> updates = new List<Opportunity>();
        
        for (Id oppId : oppIds) {
            updates.add(new Opportunity(
                Id = oppId,
                Contracted__c = true // CPQ native field to trigger Contract/Subscription generation
            ));
        }

        if (!updates.isEmpty()) {
            try {
                update updates;
            } catch (DmlException e) {
                System.debug('Error updating contracting status: ' + e.getMessage());
                // In a production environment, use a Logger framework here
            }
        }
    }
}
```

**File Path:** `force-app/main/default/classes/ContractingService.cls-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>58.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

---

### 3. Apex Trigger

**File Path:** `force-app/main/default/triggers/OpportunityTrigger.trigger`
```apex
/**
 * @description Entry point for Opportunity Trigger events.
 */
trigger OpportunityTrigger on Opportunity (after update) {
    OpportunityTriggerHandler handler = new OpportunityTriggerHandler();

    if (Trigger.isAfter && Trigger.isUpdate) {
        handler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
    }
}
```

**File Path:** `force-app/main/default/triggers/OpportunityTrigger.trigger-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexTrigger xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>58.0</apiVersion>
    <status>Active</status>
</ApexTrigger>
```

---

### 4. LWC: Contracting Status Monitor
Provides sales reps with a visual indicator of the contracting status on the Opportunity page.

**File Path:** `force-app/main/default/lwc/contractingStatus/contractingStatus.html`
```html
<template>
    <lightning-card title="Contracting Lifecycle" icon-name="standard:contract">
        <div class="slds-p-horizontal_medium">
            <template if:true={isContracted}>
                <div class="slds-scoped-notification slds-media slds-media_center slds-theme_success" role="status">
                    <div class="slds-media__figure">
                        <lightning-icon icon-name="utility:check" variant="inverse" size="small"></lightning-icon>
                    </div>
                    <div class="slds-media__body">
                        <p>Contracting has been initiated. Subscriptions and Assets are being generated.</p>
                    </div>
                </div>
            </template>
            <template if:false={isContracted}>
                <div class="slds-scoped-notification slds-media slds-media_center slds-theme_info" role="status">
                    <div class="slds-media__figure">
                        <lightning-icon icon-name="utility:info" variant="inverse" size="small"></lightning-icon>
                    </div>
                    <div class="slds-media__body">
                        <p>Opportunity is not yet contracted. Close the Opportunity as 'Won' to start the process.</p>
                    </div>
                </div>
            </template>
        </div>
    </lightning-card>
</template>
```

**File Path:** `force-app/main/default/lwc/contractingStatus/contractingStatus.js`
```javascript
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CONTRACTED_FIELD from '@salesforce/schema/Opportunity.Contracted__c';

const FIELDS = [CONTRACTED_FIELD];

export default class ContractingStatus extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    opportunity;

    get isContracted() {
        return getFieldValue(this.opportunity.data, CONTRACTED_FIELD);
    }
}
```

**File Path:** `force-app/main/default/lwc/contractingStatus/contractingStatus.js-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>58.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__RecordPage</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__RecordPage">
            <objects>
                <object>Opportunity</object>
            </objects>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

---

### 5. Custom Field (Contracted Checkbox)
*Note: If CPQ is already installed, this field exists as `SBQQ__Contracted__c`. For this generic implementation, we use `Contracted__c`.*

**File Path:** `force-app/main/default/objects/Opportunity/fields/Contracted__c.field-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Contracted__c</fullName>
    <defaultValue>false</defaultValue>
    <description>When checked, triggers the generation of Contract and Subscription records.</description>
    <externalId>false</externalId>
    <label>Contracted</label>
    <trackTrending>false</trackTrending>
    <type>Checkbox</type>
</CustomField>
```

### Deployment Instructions:
1.  Deploy the `Contracted__c` field to the Opportunity object.
2.  Deploy the `ContractingService` and `OpportunityTriggerHandler` classes.
3.  Deploy the `OpportunityTrigger`.
4.  Add the `contractingStatus` LWC to the Opportunity Lightning Record Page via App Builder.