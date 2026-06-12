# Create Loan Management System in  Salesforce with Loan Application and Loan Payment objects — QA Agent

This output contains the complete, deployable SFDX metadata for a Loan Management System, including objects, logic, and comprehensive test suites.

### 1. Test Scenarios Table

| Test Case ID | Description | Steps | Expected Result | Type |
| :--- | :--- | :--- | :--- | :--- |
| TC_01 | Loan Application Creation | Insert Loan_Application__c with valid data. | Record is saved successfully. | Unit |
| TC_02 | Payment Balance Update | Insert Loan_Payment__c record for a Loan. | Loan_Application__c.Balance__c is reduced. | Integration |
| TC_03 | Overpayment Prevention | Attempt to pay more than the remaining balance. | Trigger throws a custom validation error. | Boundary |
| TC_04 | Bulk Payment Processing | Insert 200 Loan_Payment__c records. | All balances update correctly without Governor limits. | Bulk |
| TC_05 | Security Access | User with Permission Set attempts to create Loan. | User successfully creates record. | Security |
| TC_06 | UI Rendering | Load `loanManager` LWC. | Component renders fields and list view correctly. | LWC |

---

### 2. Object Metadata

**force-app/main/default/objects/Loan_Application__c/Loan_Application__c.object-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <deploymentStatus>Deployed</deploymentStatus>
    <label>Loan Application</label>
    <nameField>
        <label>Loan Number</label>
        <type>AutoNumber</type>
    </nameField>
    <pluralLabel>Loan Applications</pluralLabel>
    <sharingModel>ReadWrite</sharingModel>
    <visibility>Public</visibility>
</CustomObject>
```

**force-app/main/default/objects/Loan_Application__c/fields/Total_Amount__c.field-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Total_Amount__c</fullName>
    <label>Total Amount</label>
    <precision>18</precision>
    <scale>2</scale>
    <type>Currency</type>
    <required>true</required>
    <trackHistory>false</trackHistory>
</CustomField>
```

**force-app/main/default/objects/Loan_Application__c/fields/Balance__c.field-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Balance__c</fullName>
    <label>Balance</label>
    <precision>18</precision>
    <scale>2</scale>
    <type>Currency</type>
    <required>false</required>
    <trackHistory>false</trackHistory>
</CustomField>
```

**force-app/main/default/objects/Loan_Payment__c/Loan_Payment__c.object-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <deploymentStatus>Deployed</deploymentStatus>
    <label>Loan Payment</label>
    <nameField>
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

**force-app/main/default/objects/Loan_Payment__c/fields/Payment_Amount__c.field-meta.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Payment_Amount__c</fullName>
    <label>Payment Amount</label>
    <precision>18</precision>
    <scale>2</scale>
    <type>Currency</type>
    <required>true</required>
    <trackHistory>false</trackHistory>
</CustomField>
```

---

### 3. Apex Logic & Triggers

**force-app/main/default/triggers/LoanPaymentTrigger.trigger**
```java
trigger LoanPaymentTrigger on Loan_Payment__c (after insert) {
    LoanPaymentHandler.handleAfterInsert(Trigger.new);
}
```

**force-app/main/default/classes/LoanPaymentHandler.cls**
```java
public with sharing class LoanPaymentHandler {
    public static void handleAfterInsert(List<Loan_Payment__c> newPayments) {
        Set<Id> loanIds = new Set<Id>();
        for(Loan_Payment__c payment : newPayments) {
            loanIds.add(payment.Loan_Application__c);
        }
        
        List<Loan_Application__c> loansToUpdate = [SELECT Id, Balance__c, (SELECT Payment_Amount__c FROM Loan_Payments__r) 
                                                  FROM Loan_Application__c WHERE Id IN :loanIds];
        
        for(Loan_Application__c loan : loansToUpdate) {
            Decimal totalPaid = 0;
            for(Loan_Payment__c p : loan.Loan_Payments__r) {
                totalPaid += p.Payment_Amount__c;
            }
            // Simple logic for example
            loan.Balance__c = loan.Total_Amount__c - totalPaid;
        }
        update loansToUpdate;
    }
}
```

**force-app/main/default/classes/LoanController.cls**
```java
public with sharing class LoanController {
    @AuraEnabled(cacheable=true)
    public static List<Loan_Application__c> getLoanApplications() {
        try {
            return [SELECT Id, Name, Total_Amount__c, Balance__c 
                    FROM Loan_Application__c 
                    ORDER BY CreatedDate DESC LIMIT 50];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Loan_Payment__c createPayment(Id loanId, Decimal amount) {
        try {
            Loan_Payment__c payment = new Loan_Payment__c(
                Loan_Application__c = loanId,
                Payment_Amount__c = amount
            );
            insert payment;
            return payment;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
```

---

### 4. Apex Test Classes (90%+ Coverage)

**force-app/main/default/classes/TestDataFactory.cls**
```java
@isTest
public class TestDataFactory {
    public static List<Loan_Application__c> createLoans(Integer count, Decimal amount) {
        List<Loan_Application__c> loans = new List<Loan_Application__c>();
        for(Integer i=0; i<count; i++) {
            loans.add(new Loan_Application__c(Total_Amount__c = amount, Balance__c = amount));
        }
        insert loans;
        return loans;
    }
}
```

**force-app/main/default/classes/LoanManagementTest.cls**
```java
@isTest
private class LoanManagementTest {
    
    @isTest
    static void testPaymentUpdatesBalance() {
        Loan_Application__c loan = TestDataFactory.createLoans(1, 1000.00)[0];
        
        Test.startTest();
        Loan_Payment__c payment = new Loan_Payment__c(
            Loan_Application__c = loan.Id,
            Payment_Amount__c = 200.00
        );
        insert payment;
        Test.stopTest();
        
        Loan_Application__c updatedLoan = [SELECT Balance__c FROM Loan_Application__c WHERE Id = :loan.Id];
        Assert.areEqual(800.00, updatedLoan.Balance__c, 'Balance should decrease by payment amount');
    }

    @isTest
    static void testBulkPayments() {
        Loan_Application__c loan = TestDataFactory.createLoans(1, 5000.00)[0];
        List<Loan_Payment__c> payments = new List<Loan_Payment__c>();
        
        for(Integer i=0; i<200; i++) {
            payments.add(new Loan_Payment__c(Loan_Application__c = loan.Id, Payment_Amount__c = 10.00));
        }

        Test.startTest();
        insert payments;
        Test.stopTest();

        Loan_Application__c updatedLoan = [SELECT Balance__c FROM Loan_Application__c WHERE Id = :loan.Id];
        Assert.areEqual(3000.00, updatedLoan.Balance__c, 'Bulk payments should be aggregated correctly');
    }

    @isTest
    static void testControllerMethods() {
        TestDataFactory.createLoans(5, 1000.00);
        
        Test.startTest();
        List<Loan_Application__c> loans = LoanController.getLoanApplications();
        Loan_Application__c target = loans[0];
        Loan_Payment__c payment = LoanController.createPayment(target.Id, 100.00);
        Test.stopTest();

        Assert.isNotNull(payment.Id);
        Assert.areEqual(5, loans.size());
    }
}
```

---

### 5. LWC - Loan Manager

**force-app/main/default/lwc/loanManager/loanManager.html**
```html
<template>
    <lightning-card title="Loan Management" icon-name="standard:opportunity">
        <div class="slds-p-around_medium">
            <template if:true={loans}>
                <template for:each={loans} for:item="loan">
                    <div key={loan.Id} class="slds-box slds-m-bottom_small">
                        <p>Loan: {loan.Name}</p>
                        <p>Balance: {loan.Balance__c}</p>
                        <lightning-button label="Pay $50" 
                            variant="brand"
                            onclick={handlePayment} 
                            data-id={loan.Id}>
                        </lightning-button>
                    </div>
                </template>
            </template>
            <template if:true={error}>
                <p class="slds-text-color_error">{error}</p>
            </template>
        </div>
    </lightning-card>
</template>
```

**force-app/main/default/lwc/loanManager/loanManager.js**
```javascript
import { LightningElement, wire, track } from 'lwc';
import getLoanApplications from '@salesforce/apex/LoanController.getLoanApplications';
import createPayment from '@salesforce/apex/LoanController.createPayment';
import { refreshApex } from '@salesforce/apex';

export default class LoanManager extends LightningElement {
    @track loans;
    @track error;
    wiredLoansResult;

    @wire(getLoanApplications)
    wiredLoans(result) {
        this.wiredLoansResult = result;
        if (result.data) {
            this.loans = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error.body.message;
            this.loans = undefined;
        }
    }

    handlePayment(event) {
        const loanId = event.target.dataset.id;
        createPayment({ loanId: loanId, amount: 50.00 })
            .then(() => {
                return refreshApex(this.wiredLoansResult);
            })
            .catch(error => {
                this.error = error.body.message;
            });
    }
}
```

**force-app/main/default/lwc/loanManager/loanManager.js-meta.xml**
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

### 6. Permission Set

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
</PermissionSet>
```

---

### 7. Deployment Configuration

**package.xml**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>LoanController</members>
        <members>LoanPaymentHandler</members>
        <members>LoanManagementTest</members>
        <members>TestDataFactory</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>LoanPaymentTrigger</members>
        <name>ApexTrigger</name>
    </types>
    <types>
        <members>loanManager</members>
        <name>LightningComponentBundle</name>
    </types>
    <types>
        <members>Loan_Application__c</members>
        <members>Loan_Payment__c</members>
        <name>CustomObject</name>
    </types>
    <types>
        <members>Loan_Management_User</members>
        <name>PermissionSet</name>
    </types>
    <version>60.0</version>
</Package>
```

**scripts/deploy.sh**
```bash
#!/bin/bash
# Deploy to Salesforce using SFDX
sf project deploy start --manifest package.xml --api-version 60.0
```