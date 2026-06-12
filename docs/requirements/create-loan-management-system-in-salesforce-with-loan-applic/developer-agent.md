# Create Loan Management System in  Salesforce with Loan Application and Loan Payment objects — Developer Agent

This technical implementation provides a complete, deployable Loan Management System with two core objects: `Loan_Application__c` and `Loan_Payment__c`. It includes the necessary Apex logic to calculate balances and an LWC for payment management.

### 1. Custom Objects & Fields

**force-app/main/default/objects/Loan_Application__c/Loan_Application__c.object-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <deploymentStatus>Deployed</deploymentStatus>
    <label>Loan Application</label>
    <nameField>
        <displayFormat>LA-{0000}</displayFormat>
        <label>Loan Number</label>
        <type>AutoNumber</type>
    </nameField>
    <pluralLabel>Loan Applications</pluralLabel>
    <sharingModel>ReadWrite</sharingModel>
    <visibility>Public</visibility>
</CustomObject>
```

**force-app/main/default/objects/Loan_Application__c/fields/Loan_Amount__c.field-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Loan_Amount__c</fullName>
    <label>Loan Amount</label>
    <precision>18</precision>
    <required>true</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <type>Currency</type>
</CustomField>
```

**force-app/main/default/objects/Loan_Application__c/fields/Total_Paid_Amount__c.field-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Total_Paid_Amount__c</fullName>
    <label>Total Paid Amount</label>
    <summarizedField>Loan_Payment__c.Amount__c</summarizedField>
    <summaryForeignKey>Loan_Payment__c.Loan_Application__c</summaryForeignKey>
    <summaryOperation>sum</summaryOperation>
    <trackHistory>false</trackHistory>
    <type>Summary</type>
</CustomField>
```

**force-app/main/default/objects/Loan_Application__c/fields/Status__c.field-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Status__c</fullName>
    <label>Status</label>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>New</fullName><default>true</default><label>New</label></value>
            <value><fullName>Approved</fullName><default>false</default><label>Approved</label></value>
            <value><fullName>Closed</fullName><default>false</default><label>Closed</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
```

**force-app/main/default/objects/Loan_Payment__c/Loan_Payment__c.object-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <deploymentStatus>Deployed</deploymentStatus>
    <label>Loan Payment</label>
    <nameField>
        <displayFormat>PAY-{0000}</displayFormat>
        <label>Payment ID</label>
        <type>AutoNumber</type>
    </nameField>
    <pluralLabel>Loan Payments</pluralLabel>
    <sharingModel>ControlledByParent</sharingModel>
    <visibility>Public</visibility>
</CustomObject>
```

**force-app/main/default/objects/Loan_Payment__c/fields/Loan_Application__c.field-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Loan_Application__c</fullName>
    <label>Loan Application</label>
    <referenceTo>Loan_Application__c</referenceTo>
    <relationshipLabel>Loan Payments</relationshipLabel>
    <relationshipName>Loan_Payments</relationshipName>
    <relationshipOrder>0</relationshipOrder>
    <reparentableMasterDetail>false</reparentableMasterDetail>
    <type>MasterDetail</type>
    <writeRequiresMasterRead>false</writeRequiresMasterRead>
</CustomField>
```

**force-app/main/default/objects/Loan_Payment__c/fields/Amount__c.field-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Amount__c</fullName>
    <label>Amount</label>
    <precision>18</precision>
    <required>true</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <type>Currency</type>
</CustomField>
```

### 2. Apex Classes

**force-app/main/default/classes/LoanSelector.cls**
```apex
/**
 * @description Selector class for Loan Application queries
 */
public with sharing class LoanSelector {
    public static Loan_Application__c getLoanWithPayments(Id loanId) {
        return [SELECT Id, Name, Loan_Amount__c, Total_Paid_Amount__c, Status__c,
                (SELECT Id, Amount__c, CreatedDate FROM Loan_Payments__r ORDER BY CreatedDate DESC)
                FROM Loan_Application__c WHERE Id = :loanId LIMIT 1];
    }
}
```

**force-app/main/default/classes/LoanSelector.cls-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

**force-app/main/default/classes/LoanController.cls**
```apex
/**
 * @description Controller for Loan Management LWC
 */
public with sharing class LoanController {
    
    @AuraEnabled(cacheable=true)
    public static Loan_Application__c getLoanDetails(Id loanId) {
        try {
            return LoanSelector.getLoanWithPayments(loanId);
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching loan details: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void postPayment(Id loanId, Decimal amount) {
        try {
            if (amount <= 0) {
                throw new AuraHandledException('Payment amount must be greater than zero.');
            }
            Loan_Payment__c payment = new Loan_Payment__c(
                Loan_Application__c = loanId,
                Amount__c = amount
            );
            insert payment;
        } catch (Exception e) {
            throw new AuraHandledException('Error posting payment: ' + e.getMessage());
        }
    }
}
```

**force-app/main/default/classes/LoanController.cls-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

### 3. Apex Tests

**force-app/main/default/classes/LoanManagementTest.cls**
```apex
@isTest
private class LoanManagementTest {
    @isTest
    static void testPaymentCreation() {
        Loan_Application__c loan = new Loan_Application__c(
            Loan_Amount__c = 1000,
            Status__c = 'Approved'
        );
        insert loan;

        Test.startTest();
        LoanController.postPayment(loan.Id, 200);
        Test.stopTest();

        Loan_Application__c updatedLoan = [SELECT Total_Paid_Amount__c FROM Loan_Application__c WHERE Id = :loan.Id];
        System.assertEquals(200, updatedLoan.Total_Paid_Amount__c, 'Summary field should reflect payment');
    }

    @isTest
    static void testGetLoanDetails() {
        Loan_Application__c loan = new Loan_Application__c(Loan_Amount__c = 5000);
        insert loan;
        
        Test.startTest();
        Loan_Application__c result = LoanController.getLoanDetails(loan.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(5000, result.Loan_Amount__c);
    }
}
```

**force-app/main/default/classes/LoanManagementTest.cls-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

### 4. Lightning Web Components

**force-app/main/default/lwc/loanPaymentManager/loanPaymentManager.html**
```html
<template>
    <lightning-card title="Loan Payment Manager" icon-name="custom:custom17">
        <div class="slds-p-around_medium">
            <template lwc:if={loan.data}>
                <div class="slds-grid slds-gutters slds-m-bottom_medium">
                    <div class="slds-col">
                        <p class="slds-text-title">Total Loan</p>
                        <p class="slds-text-heading_small">{loan.data.Loan_Amount__c}</p>
                    </div>
                    <div class="slds-col">
                        <p class="slds-text-title">Total Paid</p>
                        <p class="slds-text-heading_small">{loan.data.Total_Paid_Amount__c}</p>
                    </div>
                </div>

                <div class="slds-form-element">
                    <lightning-input 
                        type="number" 
                        label="Payment Amount" 
                        value={paymentAmount} 
                        formatter="currency" 
                        onchange={handleAmountChange}
                        step="0.01">
                    </lightning-input>
                    <lightning-button 
                        class="slds-m-top_small" 
                        variant="brand" 
                        label="Make Payment" 
                        onclick={handlePayment} 
                        disabled={isLoading}>
                    </lightning-button>
                </div>
            </template>
            <template lwc:if={isLoading}>
                <lightning-spinner alt-text="Processing..."></lightning-spinner>
            </template>
        </div>
    </lightning-card>
</template>
```

**force-app/main/default/lwc/loanPaymentManager/loanPaymentManager.js**
```javascript
import { LightningElement, api, wire, track } from 'lwc';
import getLoanDetails from '@salesforce/apex/LoanController.getLoanDetails';
import postPayment from '@salesforce/apex/LoanController.postPayment';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LoanPaymentManager extends LightningElement {
    @api recordId;
    @track paymentAmount = 0;
    isLoading = false;

    @wire(getLoanDetails, { loanId: '$recordId' })
    loan;

    handleAmountChange(event) {
        this.paymentAmount = event.target.value;
    }

    async handlePayment() {
        if (this.paymentAmount <= 0) {
            this.showToast('Error', 'Please enter a valid amount', 'error');
            return;
        }

        this.isLoading = true;
        try {
            await postPayment({ loanId: this.recordId, amount: this.paymentAmount });
            this.showToast('Success', 'Payment recorded successfully', 'success');
            this.paymentAmount = 0;
            await refreshApex(this.loan);
        } catch (error) {
            this.showToast('Error', error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
```

**force-app/main/default/lwc/loanPaymentManager/loanPaymentManager.js-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__RecordPage</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__RecordPage">
            <objects>
                <object>Loan_Application__c</object>
            </objects>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

### 5. Permission Set

**force-app/main/default/permissionsets/Loan_Management_User.permissionset-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <hasActivationRequired>false</hasActivationRequired>
    <label>Loan Management User</label>
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>false</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <object>Loan_Application__c</object>
        <viewAllRecords>false</viewAllRecords>
    </objectPermissions>
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>false</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <object>Loan_Payment__c</object>
        <viewAllRecords>false</viewAllRecords>
    </objectPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Loan_Application__c.Status__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <classAccesses>
        <apexClass>LoanController</apexClass>
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
        <members>LoanController</members>
        <members>LoanSelector</members>
        <members>LoanManagementTest</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>Loan_Application__c</members>
        <members>Loan_Payment__c</members>
        <name>CustomObject</name>
    </types>
    <types>
        <members>loanPaymentManager</members>
        <name>LightningComponentBundle</name>
    </types>
    <types>
        <members>Loan_Management_User</members>
        <name>PermissionSet</name>
    </types>
    <version>60.0</version>
</Package>
```

### 7. Deployment Script

**scripts/deploy.sh**
```bash
#!/bin/bash
# Deploy to Salesforce
sf project deploy start --manifest package.xml --target-org my-org-alias --api-version 60.0
```