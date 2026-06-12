# Automated Contracting and Renewal Lifecycle — Technical Architect

# Technical Design Document: Automated CPQ Contracting and Renewal Lifecycle

**Project:** Salesforce CPQ Implementation  
**Architect:** Senior Salesforce Technical Architect  
**Status:** Draft / For Review  

---

## 1. Architecture Overview
The solution leverages the native **Salesforce CPQ (Steelbrick)** engine to automate the transition from Won Opportunities to Contracts and Renewals. To ensure scalability and avoid the common "Contracting Bottleneck" (CPU timeouts during heavy DML), this design utilizes a hybrid of **Record-Triggered Flows** for orchestration and the **CPQ API** (via Apex) for complex edge cases.

### Key Logic Flow:
1.  **Trigger:** Opportunity Stage changes to "Closed Won".
2.  **Action:** Update `SBQQ__Contracted__b` to `TRUE`.
3.  **Process:** CPQ Background Job creates `Contract`, `Subscription`, and `Asset` records based on Quote Lines.
4.  **Renewal:** Contract triggers the "Renewal Forecast" and "Renewal Quoted" logic to automate the follow-up Opportunity.

---

## 2. Data Model

### Existing CPQ Objects (Schema Reference)
*   **Opportunity**: Parent record for sales.
*   **SBQQ__Quote__c**: Finalized quote details.
*   **Contract**: Legal agreement holder.
*   **SBQQ__Subscription__c**: Recurring line items related to Contract.
*   **Asset**: One-time purchase items.

### Custom Fields & Extensions
| Object | API Name | Data Type | Purpose |
| :--- | :--- | :--- | :--- |
| Opportunity | `Auto_Contract_Error__c` | Long Text Area | Captures CPQ API errors during automation. |
| Opportunity | `Contracting_Status__c` | Picklist | Values: `Pending`, `Processing`, `Completed`, `Failed`. |
| Contract | `Contract_External_ID__c` | Text(100) | External ID for ERP synchronization. |

**Record Types:**
*   **Contract**: `Standard_Contract`, `Master_Service_Agreement`.

---

## 3. Apex Architecture

The implementation follows the **Separation of Concerns (SoC)** principle using a Trigger Framework (Handler/Helper pattern).

### Service Layer
*   `ContractingService.cls`: Contains the logic to programmatically check `SBQQ__Contracted__c` and handle CPQ API calls for Quote-to-Contract conversions if standard checkboxes are bypassed.

### Selector Layer
*   `OpportunitySelector.cls`: Standardized SOQL queries for Opportunities and related Quote Lines to ensure `WITH SECURITY_ENFORCED` is respected.

### Trigger Handler Pattern
*   `OpportunityTriggerHandler.cls`: Orchestrates logic execution order.
*   `OpportunityTriggerHelper.cls`: Logic for validating Quote completeness before contracting.

**Deployment File Paths:**
- `force-app/main/default/classes/ContractingService.cls`
- `force-app/main/default/classes/OpportunitySelector.cls`
- `force-app/main/default/classes/OpportunityTriggerHandler.cls`
- `force-app/main/default/triggers/OpportunityTrigger.trigger`

---

## 4. UI Components

### Lightning Web Components (LWC)
*   **`contractingStatusProgressBar`**: Visual indicator on the Opportunity record page showing the progress of Contract/Subscription generation.
    *   *Hierarchy:* `contractingStatusProgressBar` -> `lightning-progress-indicator`.

### Lightning App Builder
*   **Opportunity Record Page**: Addition of the LWC component and a "Contracting" tab for visibility.

**Deployment File Paths:**
- `force-app/main/default/lwc/contractingStatusProgressBar/`
- `force-app/main/default/flexipages/Opportunity_Record_Page.flexipage-meta.xml`

---

## 5. Security Design

### Object-Level & Field-Level Security
*   **Permission Set: `CPQ_Contracting_Automation`**: Grants Edit access to `SBQQ__Contracted__c` on Opportunity and Read/Write on `Contract` and `Subscription` objects.
*   **Org-Wide Defaults (OWD)**:
    *   Contract: Controlled by Parent (Account).
    *   Subscription: Private (Accessible via Account team/Contract owner).

### Sharing Rules
*   Automated sharing rule to provide the "Renewals Team" Read/Write access to Contracts where `Contract_Value__c > 0`.

**Deployment File Paths:**
- `force-app/main/default/permissionsets/CPQ_Contracting_Automation.permissionset-meta.xml`

---

## 6. Integration Design

### Integration with ERP (NetSuite/SAP)
*   **Platform Events**: Upon `Contract` status changing to `Activated`, a Platform Event `Contract_Sync_e` is published.
*   **Subscriber**: A middleware (MuleSoft/Workato) listens to this event to push contract data to the ERP for financial recognition.

**Deployment File Paths:**
- `force-app/main/default/objects/Contract_Sync__e/`

---

## 7. Governor Limits Considerations

1.  **Bulkification**: 
    *   The `OpportunityTriggerHandler` processes Opportunity IDs in sets.
    *   Avoid setting `SBQQ__Contracted__c = true` inside a loop; use a collection for a single DML update.
2.  **CPQ Calculation Engine**: 
    *   CPQ Contracting is an asynchronous process triggered by an update. To avoid **Concurrent Request Limits**, the design ensures only the "Primary Quote" triggers the process.
3.  **SOQL Optimization**:
    *   Using the `OpportunitySelector` to query only required fields and utilizing indexed fields like `AccountId` and `OpptyId`.
4.  **Async Processing**:
    *   If bulk data loads (e.g., 10,000 Opps) are expected, the logic includes a check to route updates through a **Queueable Apex** class to stay within CPU time limits.

---

## 8. Deployment File Paths Checklist

Ensure the following metadata resides in these locations for the CI/CD pipeline:

| Component Type | Path |
| :--- | :--- |
| **Apex Class** | `force-app/main/default/classes/ContractingService.cls` |
| **Apex Trigger** | `force-app/main/default/triggers/OpportunityTrigger.trigger` |
| **LWC Component** | `force-app/main/default/lwc/contractingStatusProgressBar/` |
| **Custom Field** | `force-app/main/default/objects/Opportunity/fields/Auto_Contract_Error__c.field-meta.xml` |
| **Validation Rule** | `force-app/main/default/objects/Opportunity/validationRules/Ensure_Primary_Quote.validationRule-meta.xml` |
| **Flow** | `force-app/main/default/flows/Opportunity_After_Save_Contracting.flow-meta.xml` |
| **Permission Set** | `force-app/main/default/permissionsets/CPQ_Contracting_Automation.permissionset-meta.xml` |

---
**End of Design Document**