# Create Loan Management System in  Salesforce with Loan Application and Loan Payment objects — Technical Architect

# Loan Management System Technical Design Document

This document outlines the technical architecture and metadata configuration for the Loan Management System on Salesforce.

---

## 1. Architecture Overview
The solution leverages a decoupled architecture using a **Trigger Framework**, **Service Layer**, and **Selector Layer**. The UI is built using **Lightning Web Components** communicating with Apex Controllers via the Service Layer.

- **Storage**: Custom Objects (`Loan_Application__c`, `Loan_Payment__c`).
- **Logic**: Apex Trigger Handlers (Domain Pattern) and Service Classes.
- **UI**: LWC for Loan Summary and Payment Entry.

---

## 2. Data Model

### Loan_Application__c (Custom Object)
| Field Label | API Name | Data Type | Details |
| :--- | :--- | :--- | :--- |
| Loan Amount | `Loan_Amount__c` | Number(16, 2) | Required |
| Interest Rate | `Interest_Rate__c` | Percent(5, 2) | |
| Status | `Status__c` | Picklist | New, Approved, Funded, Closed |
| Total Paid | `Total_Paid__c` | Roll-up Summary | SUM(Loan_Payment__r.Amount__c) |

### Loan_Payment__c (Custom Object)
| Field Label | API Name | Data Type | Details |
| :--- | :--- | :--- | :--- |
| Loan Application | `Loan_Application__c` | Master-Detail | Parent: Loan_Application__c |
| Amount | `Amount__c` | Number(16, 2) | Required |
| Payment Date | `Payment_Date__c` | Date | Default: Today |

---

## 3. Deployment Metadata (SFDX Format)

### Object Metadata

**File: `force-app/main/default/objects/Loan_Application__c/Loan_Application__c.object-meta.xml`**
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

**File: `force-app/main/default/objects/Loan_Application__c/fields/Loan_Amount__c.field-meta.xml`**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Loan_Amount__c</fullName>
    <label>Loan Amount</label>
    <precision>18</precision>
    <scale>2</scale>
    <type>Number</type>
    <required>true</required>
    <trackHistory>false</trackHistory>
</CustomField>
```

**File: `force-app/main/default/objects/Loan_Payment__c/fields/Loan_Application__c.field-meta.xml`**
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

---

## 4. Apex Architecture

### Service Layer

**File: `force-app/main/default/classes/LoanService.cls`**
```java
public with sharing class LoanService {
    @AuraEnabled
    public static List<Loan_Payment__c> getPaymentsByLoanId(Id loanId) {
        try {
            return [SELECT Id, Amount__c, Payment_Date__c 
                    FROM Loan_Payment__c 
                    WHERE Loan_Application__c = :loanId 
                    ORDER BY Payment_Date__c DESC];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void createPayment(Id loanId, Decimal amount) {
        try {
            Loan_Payment__c payment = new Loan_Payment__c(
                Loan_Application__c = loanId,
                Amount__c = amount,
                Payment_Date__c = Date.today()
            );
            insert payment;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
```

---

## 5. UI Components (LWC)

### Loan Payment LWC

**File: `force-app/main/default/lwc/loanPaymentManager/loanPaymentManager.js`**
```javascript
import { LightningElement, api, wire, track } from 'lwc';
import getPaymentsByLoanId from '@salesforce/apex/LoanService.getPaymentsByLoanId';
import createPayment from '@salesforce/apex/LoanService.createPayment';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LoanPaymentManager extends LightningElement {
    @api recordId;
    @track payments;
    @track amount = 0;
    wiredPaymentsResult;

    @wire(getPaymentsByLoanId, { loanId: '$recordId' })
    wiredPayments(result) {
        this.wiredPaymentsResult = result;
        if (result.data) {
            this.payments = result.data;
        }
    }

    handleAmountChange(event) {
        this.amount = event.target.value;
    }

    handlePayment() {
        createPayment({ loanId: this.recordId, amount: this.amount })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Payment Recorded',
                    variant: 'success'
                }));
                return refreshApex(this.wiredPaymentsResult);
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                }));
            });
    }
}
```

---

## 6. Security & Permissions

**File: `force-app/main/default/permissionsets/Loan_Management_User.permissionset-meta.xml`**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <hasActivationRequired>false</hasActivationRequired>
    <label>Loan Management User</label>
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>true</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <object>Loan_Application__c</object>
        <viewAllRecords>false</viewAllRecords>
    </objectPermissions>
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>true</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <object>Loan_Payment__c</object>
        <viewAllRecords>false</viewAllRecords>
    </objectPermissions>
</PermissionSet>
```

---

## 7. Deployment Readiness (package.xml)

**File: `package.xml`**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>LoanService</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>loanPaymentManager</members>
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

---

## 8. Governor Limits & Validation
- **Bulkification**: All queries in `LoanService` are focused on single-record context for UI, but trigger patterns (if added) will use Set-based filtering.
- **Sharing**: All classes use `with sharing` to enforce FLS and Sharing Rules.
- **Quality**: Test classes (e.g., `LoanServiceTest`) must achieve 75%+ coverage referencing only these specific objects.