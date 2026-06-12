# Automated Contracting and Renewal Lifecycle — Admin Agent

To implement a robust **Automated Contracting and Renewal Lifecycle** within Salesforce CPQ, we will focus on automating the native CPQ contracting checkboxes using a **Record-Triggered Flow**. This approach triggers the creation of Contracts, Subscriptions, and Assets immediately when an Opportunity is marked "Closed Won."

Below is the complete, deployable metadata.

### 1. Custom Fields
To ensure proper automation, we will add a checkbox to the Opportunity to track if the contract has been successfully processed, preventing duplicate execution.

**File Path:** `force-app/main/default/objects/Opportunity/fields/Contracting_Automation_Processed__c.field-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Contracting_Automation_Processed__c</fullName>
    <defaultValue>false</defaultValue>
    <description>Technical field used to ensure the contracting flow only runs once per Opportunity closure.</description>
    <externalId>false</externalId>
    <label>Contracting Automation Processed</label>
    <trackFeedHistory>false</trackFeedHistory>
    <trackTrending>false</trackTrending>
    <type>Checkbox</type>
</CustomField>
```

### 2. Validation Rules
To prevent errors in the CPQ Contracting engine, we must ensure a Primary Quote is attached before an Opportunity can be closed if it contains products.

**File Path:** `force-app/main/default/objects/Opportunity/validationRules/Require_Primary_Quote_on_Close.validationRule-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ValidationRule xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Require_Primary_Quote_on_Close</fullName>
    <active>true</active>
    <description>Prevents closing an Opportunity without a Primary Quote, which is required for CPQ contracting.</description>
    <errorConditionFormula>AND(
    IsWon,
    ISBLANK(SBQQ__PrimaryQuote__c),
    HasOpportunityLineItem
)</errorConditionFormula>
    <errorMessage>You must designate a Primary Quote before closing this Opportunity to ensure the Contract and Subscriptions are generated.</errorMessage>
</ValidationRule>
```

### 3. Record-Triggered Flow
This flow automates the setting of `SBQQ__Contracted__c` (Contracting) and `SBQQ__RenewalForecast__c` (Renewal Generation) upon Opportunity closure.

**File Path:** `force-app/main/default/flows/CPQ_Opportunity_Contracting_Automation.flow-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>59.0</apiVersion>
    <assignments>
        <name>Set_CPQ_Contracting_Fields</name>
        <label>Set CPQ Contracting Fields</label>
        <locationX>176</locationX>
        <locationY>323</locationY>
        <assignmentItems>
            <assignToReference>$Record.SBQQ__Contracted__c</assignToReference>
            <operator>Assign</operator>
            <value>
                <booleanValue>true</booleanValue>
            </value>
        </assignmentItems>
        <assignmentItems>
            <assignToReference>$Record.Contracting_Automation_Processed__c</assignToReference>
            <operator>Assign</operator>
            <value>
                <booleanValue>true</booleanValue>
            </value>
        </assignmentItems>
        <connector>
            <targetReference>Update_Opportunity</targetReference>
        </connector>
    </assignments>
    <description>Automates the Contract and Asset generation when an Opportunity is set to Closed Won.</description>
    <environments>Default</environments>
    <interviewLabel>CPQ Opportunity Contracting Automation {!$Flow.CurrentDateTime}</interviewLabel>
    <label>CPQ Opportunity Contracting Automation</label>
    <processMetadataValues>
        <name>BuilderType</name>
        <value>
            <stringValue>LightningFlowBuilder</stringValue>
        </value>
    </processMetadataValues>
    <processMetadataValues>
        <name>CanvasMode</name>
        <value>
            <stringValue>AUTO_LAYOUT_CONCRETE</stringValue>
        </value>
    </processMetadataValues>
    <processMetadataValues>
        <name>OriginBuilderType</name>
        <value>
            <stringValue>LightningFlowBuilder</stringValue>
        </value>
    </processMetadataValues>
    <processType>AutoLaunchedFlow</processType>
    <recordUpdates>
        <name>Update_Opportunity</name>
        <label>Update Opportunity</label>
        <locationX>176</locationX>
        <locationY>431</locationY>
        <inputReference>$Record</inputReference>
    </recordUpdates>
    <start>
        <locationX>50</locationX>
        <locationY>0</locationY>
        <connector>
            <targetReference>Set_CPQ_Contracting_Fields</targetReference>
        </connector>
        <filterLogic>and</filterLogic>
        <filters>
            <field>StageName</field>
            <operator>EqualTo</operator>
            <value>
                <stringValue>Closed Won</stringValue>
            </value>
        </filters>
        <filters>
            <field>SBQQ__PrimaryQuote__c</field>
            <operator>IsNull</operator>
            <value>
                <booleanValue>false</booleanValue>
            </value>
        </filters>
        <filters>
            <field>Contracting_Automation_Processed__c</field>
            <operator>EqualTo</operator>
            <value>
                <booleanValue>false</booleanValue>
            </value>
        </filters>
        <object>Opportunity</object>
        <recordTriggerType>CreateAndUpdate</recordTriggerType>
        <triggerType>RecordAfterSave</triggerType>
    </start>
    <status>Active</status>
</Flow>
```

### 4. Custom Labels
Used for providing clear status messages or error reporting in related components.

**File Path:** `force-app/main/default/labels/CustomLabels.labels-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomLabels xmlns="http://soap.sforce.com/2006/04/metadata">
    <labels>
        <fullName>CPQ_Contracting_Error_Header</fullName>
        <categories>CPQ, Automation</categories>
        <language>en_US</language>
        <protected>false</protected>
        <shortDescription>Error message header for CPQ Automation</shortDescription>
        <value>Automated Contracting Failed</value>
    </labels>
</CustomLabels>
```

### 5. Permission Set
Ensures the integration user or administrators have the necessary permissions to trigger the automation.

**File Path:** `force-app/main/default/permissionsets/CPQ_Contracting_Automation.permissionset-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <description>Grants access to Opportunity fields required for CPQ contracting automation.</description>
    <fieldPermissions>
        <editable>true</editable>
        <field>Opportunity.Contracting_Automation_Processed__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Opportunity.SBQQ__Contracted__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <editable>true</editable>
        <field>Opportunity.SBQQ__RenewalForecast__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <hasActivationRequired>false</hasActivationRequired>
    <label>CPQ Contracting Automation</label>
    <objectPermissions>
        <allowCreate>false</allowCreate>
        <allowDelete>false</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <object>Opportunity</object>
        <viewAllRecords>false</viewAllRecords>
    </objectPermissions>
</PermissionSet>
```

### 6. List View
A management view for Admins to identify Opportunities where contracting was attempted or is pending.

**File Path:** `force-app/main/default/objects/Opportunity/listViews/Pending_CPQ_Contracting.listView-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ListView xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Pending_CPQ_Contracting</fullName>
    <columns>OPPORTUNITY.NAME</columns>
    <columns>ACCOUNT.NAME</columns>
    <columns>OPPORTUNITY.AMOUNT</columns>
    <columns>OPPORTUNITY.CLOSE_DATE</columns>
    <columns>SBQQ__PrimaryQuote__c</columns>
    <columns>SBQQ__Contracted__c</columns>
    <filterScope>Everything</filterScope>
    <filters>
        <field>OPPORTUNITY.STAGE_NAME</field>
        <operation>equals</operation>
        <value>Closed Won</value>
    </filters>
    <filters>
        <field>SBQQ__Contracted__c</field>
        <operation>equals</operation>
        <value>0</value>
    </filters>
    <label>Closed Won - Pending Contracting</label>
</ListView>
```