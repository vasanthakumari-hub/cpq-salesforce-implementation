# create  objects, fields for loan management system for salesforce org. — Technical Architect

# Technical Design Document: Loan Management System (LMS)

**Project Name:** CPQ Implementation (Loan Extension)  
**Architect:** Salesforce Technical Architect  
**Repository:** [vasanthakumari-hub/cpq-salesforce-implementation](https://github.com/vasanthakumari-hub/cpq-salesforce-implementation)  
**Structure:** SFDX Standard Layout  

---

## 1. Architecture Overview
The Loan Management System (LMS) is designed as an extension of the Salesforce CPQ framework. It handles the lifecycle of a loan from application (linked to a Quote) to disbursement and repayment. The architecture follows a **Service-Oriented Design** on the Salesforce platform, ensuring scalability and strict adherence to financial compliance.

---

## 2. Data Model

### Custom Objects

#### A. Loan Application (`Loan_Application__c`)
*Parent: Account (Lookup), Quote (Lookup)*
| Field Label | API Name | Data Type | Details |
| :--- | :--- | :--- | :--- |
| Loan Amount | `Amount__c` | Currency(16, 2) | Required |
| Loan Term | `Term_Months__c` | Number(3, 0) | Default: 12 |
| Interest Rate | `Interest_Rate__c` | Percent(5, 2) | |
| Application Status | `Status__c` | Picklist | Draft, In Review, Approved, Funded, Defaulted |
| Quote | `Quote__c` | Lookup(SBQQ__Quote__c) | Link to CPQ Quote |

#### B. Loan Disbursement (`Loan_Disbursement__c`)
*Parent: Loan Application (Master-Detail)*
| Field Label | API Name | Data Type | Details |
| :--- | :--- | :--- | :--- |
| Disbursement Date | `Disbursement_Date__c` | Date | Today() |
| Amount Paid | `Amount_Paid__c` | Currency(16, 2) | |
| Status | `Status__c` | Picklist | Pending, Scheduled, Completed |

#### C. Repayment Schedule (`Repayment_Schedule__c`)
*Parent: Loan Application (Master-Detail)*
| Field Label | API Name | Data Type | Details |
| :--- | :--- | :--- | :--- |
| Due Date | `Due_Date__c` | Date | |
| Principal Amount | `Principal_Amount__c` | Currency(16, 2) | |
| Interest Amount | `Interest_Amount__c` | Currency(16, 2) | |
| Total Payment | `Total_Payment__c` | Formula (Currency) | `Principal__c + Interest__c` |
| Paid Date | `Paid_Date__c` | Date | |

### File Paths:
- `force-app/main/default/objects/Loan_Application__c/Loan_Application__c.object-meta.xml`
- `force-app/main/default/objects/Loan_Application__c/fields/Amount__c.field-meta.xml`
- `force-app/main/default/objects/Repayment_Schedule__c/fields/Loan_Application__c.field-meta.xml`

---

## 3. Apex Architecture
The project utilizes the **Trigger Handler Pattern** and **Service Layer** to separate concerns.

### Components:
- **Trigger Handler:** `LoanApplicationTriggerHandler.cls` (Logic for status transitions).
- **Service Layer:** `LoanService.cls` (Calculates Amortization Schedules).
- **Selector Layer:** `LoanSelector.cls` (Centralized SOQL for loan records).

### File Paths:
- `force-app/main/default/classes/LoanApplicationTriggerHandler.cls`
- `force-app/main/default/classes/LoanService.cls`
- `force-app/main/default/classes/LoanSelector.cls`
- `force-app/main/default/triggers/LoanApplicationTrigger.trigger`

---

## 4. UI Components (LWC)
Two primary LWCs are required for the Loan Management experience:

1. **`loanCalculator`**: A reactive component on the Quote page to preview monthly repayments before creating the Loan record.
2. **`repaymentTracker`**: A data table component on the Loan Application record page to visualize upcoming and completed payments.

### File Paths:
- `force-app/main/default/lwc/loanCalculator/`
- `force-app/main/default/lwc/repaymentTracker/`

---

## 5. Security Design

### Object-Level Security (Permission Sets)
- **LMS_Manager**: Full CRUD on all Loan objects.
- **LMS_Agent**: Read/Create on Loan Applications; Read-only on Repayments.

### Sharing Settings (OWD)
- **Loan Application**: Private (Access via Role Hierarchy).
- **Repayment Schedule**: Controlled by Parent (Master-Detail).

### File Paths:
- `force-app/main/default/permissionsets/LMS_Manager.permissionset-meta.xml`

---

## 6. Integration Design
To sync loan data with an external "Core Banking System":
- **Outbound**: A `LoanSyncService` sends JSON payloads via REST when a Loan is marked "Funded".
- **Inbound**: A REST Resource `LoanAPI` allows the banking system to update `Repayment_Schedule__c` status.

### File Paths:
- `force-app/main/default/classes/LoanSyncService.cls` (Callout logic)
- `force-app/main/default/classes/LoanRestResource.cls` (`@RestResource` for updates)

---

## 7. Governor Limits Considerations
1. **Bulkification**: All triggers and services accept `List<SObject>` to handle bulk data uploads via Data Loader.
2. **Async Processing**: Calculating 360 monthly repayment records for a 30-year loan is offloaded to a `@future` or `Queueable` method to prevent heap size issues.
3. **SOQL Optimization**: The `LoanSelector.cls` enforces `WITH SECURITY_ENFORCED` and ensures no SOQL is ever executed inside a loop.

---

## 8. Deployment File Paths Checklist

| Metadata Type | File Path |
| :--- | :--- |
| **Loan App Object** | `force-app/main/default/objects/Loan_Application__c/Loan_Application__c.object-meta.xml` |
| **Loan Status Field** | `force-app/main/default/objects/Loan_Application__c/fields/Status__c.field-meta.xml` |
| **Validation Rule** | `force-app/main/default/objects/Loan_Application__c/validationRules/Prevent_Amount_Changes.validationRule-meta.xml` |
| **Trigger** | `force-app/main/default/triggers/LoanApplicationTrigger.trigger` |
| **LWC HTML** | `force-app/main/default/lwc/loanCalculator/loanCalculator.html` |
| **Record Page** | `force-app/main/default/flexipages/Loan_Record_Page.flexipage-meta.xml` |
| **Repayment Flow**| `force-app/main/default/flows/Auto_Create_Repayment_Schedules.flow-meta.xml` |

---
**Approval Status:** Pending Review by Lead Architect.