# Create Loan Management System in  Salesforce with Loan Application and Loan Payment objects — Admin Agent

### 1. Custom Objects

**File Path:** `force-app/main/default/objects/Loan_Application__c/Loan_Application__c.object-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <deploymentStatus>Deployed</deploymentStatus>
    <enableActivities>true</enableActivities>
    <enableReports>true</enableReports>
    <label>Loan Application</label>
    <nameField>
        <displayFormat>LA-{0000}</displayFormat>
        <label>Loan Application Number</label>
        <type>AutoNumber</type>
    </nameField>
    <pluralLabel>Loan Applications</pluralLabel>
    <sharingModel>ReadWrite</sharingModel>
    <visibility>Public</visibility>
</CustomObject>
```

**File Path:** `force-app/main/default/objects/Loan_Payment__c/Loan_Payment__c.object-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <deploymentStatus>Deployed</deploymentStatus>
    <enableActivities>true</enableActivities>
    <enableReports>true</enableReports>
    <label>Loan Payment</label>
    <nameField>
        <displayFormat>PAY-{0000}</displayFormat>
        <label>Payment Number</label>
        <type>AutoNumber</type>
    </nameField>
    <pluralLabel>Loan Payments</pluralLabel>
    <sharingModel>ControlledByParent</sharingModel>
    <visibility>Public</visibility>
</CustomObject>
```

### 2. Custom Fields

**File Path:** `force-app/main/default/objects/Loan_Application__c/fields/Loan_Amount__c.field-meta.xml`
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

**File Path:** `force-app/main/default/objects/Loan_Application__c/fields/Status__c.field-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Status__c</fullName>
    <label>Status</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Draft</fullName><default>true</default><label>Draft</label></value>
            <value><fullName>Submitted</fullName><default>false</default><label>Submitted</label></value>
            <value><fullName>Approved</fullName><default>false</default><label>Approved</label></value>
            <value><fullName>Closed</fullName><default>false</default><label>Closed</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
```

**File Path:** `force-app/main/default/objects/Loan_Payment__c/fields/Loan_Application__c.field-meta.xml`
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
    <required>false</required>
    <trackHistory>false</trackHistory>
    <type>MasterDetail</type>
    <writeRequiresMasterRead>false</writeRequiresMasterRead>
</CustomField>
```

**File Path:** `force-app/main/default/objects/Loan_Payment__c/fields/Payment_Amount__c.field-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Payment_Amount__c</fullName>
    <label>Payment Amount</label>
    <precision>18</precision>
    <required>true</required>
    <scale>2</scale>
    <trackHistory>false</trackHistory>
    <type>Currency</type>
</CustomField>
```

**File Path:** `force-app/main/default/objects/Loan_Payment__c/fields/Payment_Date__c.field-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Payment_Date__c</fullName>
    <label>Payment Date</label>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <type>Date</type>
</CustomField>
```

### 3. Apex Controller

**File Path:** `force-app/main/default/classes/LoanController.cls`
```java
public with sharing class LoanController {
    @AuraEnabled(cacheable=true)
    public static List<Loan_Application__c> getLoanApplications() {
        try {
            return [SELECT Id, Name, Loan_Amount__c, Status__c FROM Loan_Application__c ORDER BY CreatedDate DESC];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void createPayment(Id loanId, Decimal amount, Date paymentDate) {
        try {
            Loan_Payment__c payment = new Loan_Payment__c();
            payment.Loan_Application__c = loanId;
            payment.Payment_Amount__c = amount;
            payment.Payment_Date__c = paymentDate;
            insert payment;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
```

**File Path:** `force-app/main/default/classes/LoanController.cls-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

### 4. Apex Test Class

**File Path:** `force-app/main/default/classes/LoanControllerTest.cls`
```java
@isTest
public class LoanControllerTest {
    @isTest
    static void testLoanOperations() {
        Loan_Application__c app = new Loan_Application__c(Loan_Amount__c = 5000, Status__c = 'Draft');
        insert app;

        Test.startTest();
        List<Loan_Application__c> apps = LoanController.getLoanApplications();
        LoanController.createPayment(app.Id, 500, Date.today());
        Test.stopTest();

        System.assertEquals(1, apps.size(), 'Should return one application');
        List<Loan_Payment__c> payments = [SELECT Id FROM Loan_Payment__c WHERE Loan_Application__c = :app.Id];
        System.assertEquals(1, payments.size(), 'Payment should be created');
    }
}
```

### 5. LWC - Loan Management

**File Path:** `force-app/main/default/lwc/loanManager/loanManager.html`
```html
<template>
    <lightning-card title="Loan Management" icon-name="standard:opportunity">
        <div class="slds-p-around_medium">
            <template if:true={isLoading}>
                <lightning-spinner alt-aria="Loading..."></lightning-spinner>
            </template>
            
            <template if:true={loans}>
                <table class="slds-table slds-table_bordered">
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th>Amount</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <template for:each={loans} for:item="loan">
                            <tr key={loan.Id}>
                                <td>{loan.Name}</td>
                                <td>{loan.Loan_Amount__c}</td>
                                <td>{loan.Status__c}</td>
                            </tr>
                        </template>
                    </tbody>
                </table>
            </template>

            <template if:true={error}>
                <div class="slds-text-color_error">{error}</div>
            </template>
        </div>
    </lightning-card>
</template>
```

**File Path:** `force-app/main/default/lwc/loanManager/loanManager.js`
```javascript
import { LightningElement, wire, track } from 'lwc';
import getLoanApplications from '@salesforce/apex/LoanController.getLoanApplications';

export default class LoanManager extends LightningElement {
    @track loans;
    @track error;
    @track isLoading = true;

    @wire(getLoanApplications)
    wiredLoans({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.loans = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body.message;
            this.loans = undefined;
        }
    }
}
```

**File Path:** `force-app/main/default/lwc/loanManager/loanManager.js-meta.xml`
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

### 6. Permission Set

**File Path:** `force-app/main/default/permissionsets/Loan_Management_User.permissionset-meta.xml`
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
    <fieldPermissions>
        <editable>true</editable>
        <field>Loan_Application__c.Status__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Loan_Payment__c.Payment_Date__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <classAccesses>
        <apexClass>LoanController</apexClass>
        <enabled>true</enabled>
    </classAccesses>
</PermissionSet>
```

### 7. Deployment Package

**File Path:** `package.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>LoanController</members>
        <members>LoanControllerTest</members>
        <name>ApexClass</name>
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