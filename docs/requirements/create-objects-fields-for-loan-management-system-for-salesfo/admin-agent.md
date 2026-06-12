# create  objects, fields for loan management system for salesforce org. — Admin Agent

To implement a robust Loan Management System within your Salesforce CPQ environment, we will establish two primary objects: **Loan Application** (the header/process record) and **Loan Term** (to define specific financial conditions).

### 1. Custom Object: Loan Application

**File Path:** `force-app/main/default/objects/Loan_Application__c/Loan_Application__c.object-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <deploymentStatus>Deployed</deploymentStatus>
    <description>Stores personal and financial information for loan requests.</description>
    <enableActivities>true</enableActivities>
    <enableHistory>true</enableHistory>
    <enableReports>true</enableReports>
    <label>Loan Application</label>
    <nameField>
        <displayFormat>LA-{00000}</displayFormat>
        <label>Loan Application Number</label>
        <type>AutoNumber</type>
    </nameField>
    <pluralLabel>Loan Applications</pluralLabel>
    <sharingModel>ReadWrite</sharingModel>
    <visibility>Public</visibility>
</CustomObject>
```

### 2. Custom Fields for Loan Application

**File Path:** `force-app/main/default/objects/Loan_Application__c/fields/Loan_Amount__c.field-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Loan_Amount__c</fullName>
    <description>The total principal amount requested by the applicant.</description>
    <externalId>false</externalId>
    <label>Loan Amount</label>
    <precision>18</precision>
    <required>true</required>
    <scale>2</scale>
    <trackHistory>true</trackHistory>
    <type>Currency</type>
</CustomField>
```

**File Path:** `force-app/main/default/objects/Loan_Application__c/fields/Loan_Status__c.field-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Loan_Status__c</fullName>
    <description>The current lifecycle stage of the loan application.</description>
    <externalId>false</externalId>
    <label>Loan Status</label>
    <required>false</required>
    <trackHistory>true</trackHistory>
    <type>Picklist</type>
    <valueSet>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value><fullName>Draft</fullName><default>true</default><label>Draft</label></value>
            <value><fullName>Submitted</fullName><default>false</default><label>Submitted</label></value>
            <value><fullName>Under Review</fullName><default>false</default><label>Under Review</label></value>
            <value><fullName>Approved</fullName><default>false</default><label>Approved</label></value>
            <value><fullName>Rejected</fullName><default>false</default><label>Rejected</label></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
```

**File Path:** `force-app/main/default/objects/Loan_Application__c/fields/Applicant_Contact__c.field-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Applicant_Contact__c</fullName>
    <deleteConstraint>SetNull</deleteConstraint>
    <description>Link to the Contact applying for the loan.</description>
    <externalId>false</externalId>
    <label>Applicant Contact</label>
    <referenceTo>Contact</referenceTo>
    <relationshipLabel>Loan Applications</relationshipLabel>
    <relationshipName>Loan_Applications</relationshipName>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <type>Lookup</type>
</CustomField>
```

### 3. Validation Rule

**File Path:** `force-app/main/default/objects/Loan_Application__c/validationRules/Min_Loan_Amount.validationRule-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ValidationRule xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Min_Loan_Amount</fullName>
    <active>true</active>
    <description>Ensures the loan amount is at least $1,000.</description>
    <errorConditionFormula>Loan_Amount__c &lt; 1000</errorConditionFormula>
    <errorDisplayField>Loan_Amount__c</errorDisplayField>
    <errorMessage>The minimum loan amount allowed is $1,000.00.</errorMessage>
</ValidationRule>
```

### 4. Custom Labels

**File Path:** `force-app/main/default/labels/CustomLabels.labels-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomLabels xmlns="http://soap.sforce.com/2006/04/metadata">
    <labels>
        <fullName>Loan_App_Header</fullName>
        <language>en_US</language>
        <protected>false</protected>
        <shortDescription>Loan Application Header</shortDescription>
        <value>Lending Management System - Create New Application</value>
    </labels>
</CustomLabels>
```

### 5. Custom Object: Loan Term

**File Path:** `force-app/main/default/objects/Loan_Term__c/Loan_Term__c.object-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <deploymentStatus>Deployed</deploymentStatus>
    <description>Defines the specific terms (Interest, Duration) for a loan application.</description>
    <enableActivities>false</enableActivities>
    <enableReports>true</enableReports>
    <label>Loan Term</label>
    <nameField>
        <label>Term Name</label>
        <type>Text</type>
    </nameField>
    <pluralLabel>Loan Terms</pluralLabel>
    <sharingModel>ControlledByParent</sharingModel>
    <visibility>Public</visibility>
</CustomObject>
```

**File Path:** `force-app/main/default/objects/Loan_Term__c/fields/Loan_Application__c.field-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Loan_Application__c</fullName>
    <externalId>false</externalId>
    <label>Loan Application</label>
    <referenceTo>Loan_Application__c</referenceTo>
    <relationshipLabel>Loan Terms</relationshipLabel>
    <relationshipName>Loan_Terms</relationshipName>
    <relationshipOrder>0</relationshipOrder>
    <reparentableMasterDetail>false</reparentableMasterDetail>
    <trackTrending>false</trackTrending>
    <type>MasterDetail</type>
    <writeRequiresMasterRead>false</writeRequiresMasterRead>
</CustomField>
```

**File Path:** `force-app/main/default/objects/Loan_Term__c/fields/Interest_Rate__c.field-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Interest_Rate__c</fullName>
    <description>Annual interest rate for the loan.</description>
    <externalId>false</externalId>
    <label>Interest Rate</label>
    <precision>5</precision>
    <required>true</required>
    <scale>2</scale>
    <type>Percent</type>
</CustomField>
```

### 6. Permission Set

**File Path:** `force-app/main/default/permissionsets/Loan_Manager.permissionset-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <hasActivationRequired>false</hasActivationRequired>
    <label>Loan Manager</label>
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>true</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <object>Loan_Application__c</object>
        <viewAllRecords>false</viewAllRecords>
    </objectPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Loan_Application__c.Loan_Amount__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Loan_Application__c.Loan_Status__c</field>
        <readable>true</readable>
    </fieldPermissions>
</PermissionSet>
```

### 7. List View

**File Path:** `force-app/main/default/objects/Loan_Application__c/listViews/All_Submitted_Loans.listView-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ListView xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>All_Submitted_Loans</fullName>
    <columns>NAME</columns>
    <columns>Applicant_Contact__c</columns>
    <columns>Loan_Amount__c</columns>
    <columns>Loan_Status__c</columns>
    <columns>CREATED_DATE</columns>
    <filterScope>Everything</filterScope>
    <filters>
        <field>Loan_Status__c</field>
        <operation>equals</operation>
        <value>Submitted,Under Review</value>
    </filters>
    <label>All Submitted Loans</label>
</ListView>
```

### Deployment Instructions:
1. Ensure your `sfdx-project.json` is set to API version `59.0`.
2. Push the files using SFDX: `sf project deploy start` or `sfdx force:source:push`.
3. After deployment, assign the **Loan Manager** Permission Set to your users to view the objects.