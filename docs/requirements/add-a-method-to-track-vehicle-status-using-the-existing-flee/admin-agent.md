# Add a method to track vehicle status using the existing Fleet_Vehicle__c object and its VIN__c field — Admin Agent

To address the requirement of tracking vehicle status on the existing `Fleet_Vehicle__c` object using the `VIN__c` field, we will implement a status picklist, a history tracking mechanism, a validation rule to ensure VIN integrity, and a Permission Set to manage access.

### 1. Custom Field: Status__c
This field tracks the current state of the vehicle.

**File Path:** `force-app/main/default/objects/Fleet_Vehicle__c/fields/Status__c.field-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Status__c</fullName>
    <description>Tracks the current lifecycle status of the fleet vehicle.</description>
    <externalId>false</externalId>
    <label>Status</label>
    <required>false</required>
    <trackHistory>true</trackHistory>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>false</sorted>
            <value>
                <fullName>In Inventory</fullName>
                <default>true</default>
                <label>In Inventory</label>
            </value>
            <value>
                <fullName>Assigned</fullName>
                <default>false</default>
                <label>Assigned</label>
            </value>
            <value>
                <fullName>In Maintenance</fullName>
                <default>false</default>
                <label>In Maintenance</label>
            </value>
            <value>
                <fullName>Retired</fullName>
                <default>false</default>
                <label>Retired</label>
            </value>
        </valueSetDefinition>
    </valueSet>
</CustomField>
```

### 2. Validation Rule: Valid_VIN_Format
Ensures the `VIN__c` field follows standard 17-character alphanumeric formatting if populated.

**File Path:** `force-app/main/default/objects/Fleet_Vehicle__c/validationRules/Valid_VIN_Format.validationRule-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ValidationRule xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Valid_VIN_Format</fullName>
    <active>true</active>
    <description>Ensures the VIN is exactly 17 characters and alphanumeric.</description>
    <errorConditionFormula>AND(
    NOT(ISBLANK(VIN__c)),
    NOT(REGEX(VIN__c, "^[A-HJ-NPR-Z0-9]{17}$"))
)</errorConditionFormula>
    <errorDisplayField>VIN__c</errorDisplayField>
    <errorMessage>The VIN must be exactly 17 alphanumeric characters (excluding I, O, and Q).</errorMessage>
</ValidationRule>
```

### 3. Page Layout (Update)
Adds the Status field to the Fleet Vehicle layout.

**File Path:** `force-app/main/default/objects/Fleet_Vehicle__c/layouts/Fleet_Vehicle_Layout.layout-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Layout xmlns="http://soap.sforce.com/2006/04/metadata">
    <layoutSections>
        <customLabel>false</customLabel>
        <detailHeading>true</detailHeading>
        <editHeading>true</editHeading>
        <label>Vehicle Information</label>
        <layoutColumns>
            <layoutItems>
                <behavior>Required</behavior>
                <field>Name</field>
            </layoutItems>
            <layoutItems>
                <behavior>Required</behavior>
                <field>VIN__c</field>
            </layoutItems>
        </layoutColumns>
        <layoutColumns>
            <layoutItems>
                <behavior>Edit</behavior>
                <field>Status__c</field>
            </layoutItems>
            <layoutItems>
                <behavior>Edit</behavior>
                <field>OwnerId</field>
            </layoutItems>
        </layoutColumns>
    </layoutSections>
    <showEmailCheckbox>false</showEmailCheckbox>
    <showHighlightsPanel>false</showHighlightsPanel>
    <showInteractionLogPanel>false</showInteractionLogPanel>
    <showRunAssignmentRulesCheckbox>false</showRunAssignmentRulesCheckbox>
    <showSubmitAndAttachButton>false</showSubmitAndAttachButton>
    <summaryLayout>
        <masterLabel>00h000000000000</masterLabel>
        <sizeX>4</sizeX>
        <sizeY>0</sizeY>
        <summaryLayoutStyle>Default</summaryLayoutStyle>
    </summaryLayout>
</Layout>
```

### 4. Permission Set: Fleet_Management
Grants access to the new Status field and the VIN field for relevant users.

**File Path:** `force-app/main/default/permissionsets/Fleet_Management.permissionset-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <hasActivationRequired>false</hasActivationRequired>
    <label>Fleet Management</label>
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
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>true</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <object>Fleet_Vehicle__c</object>
        <viewAllRecords>false</viewAllRecords>
    </objectPermissions>
</PermissionSet>
```

### 5. List View: All_Vehicles_Status
A view to monitor vehicles by their status and VIN.

**File Path:** `force-app/main/default/objects/Fleet_Vehicle__c/listViews/All_Vehicles_Status.listView-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ListView xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>All_Vehicles_Status</fullName>
    <columns>NAME</columns>
    <columns>VIN__c</columns>
    <columns>Status__c</columns>
    <columns>LAST_UPDATE</columns>
    <filterScope>Everything</filterScope>
    <label>All Vehicles by Status</label>
</ListView>
```

### 6. Custom Label: Vehicle_Status_Help_Text
Used if status-related help components are built in the future (UI best practice).

**File Path:** `force-app/main/default/labels/CustomLabels.labels-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomLabels xmlns="http://soap.sforce.com/2006/04/metadata">
    <labels>
        <fullName>Fleet_Status_Track_Msg</fullName>
        <categories>Fleet Management</categories>
        <language>en_US</language>
        <protected>false</protected>
        <shortDescription>Fleet Status Track Message</shortDescription>
        <value>Please ensure the Vehicle Status is updated whenever the assignment changes.</value>
    </labels>
</CustomLabels>
```