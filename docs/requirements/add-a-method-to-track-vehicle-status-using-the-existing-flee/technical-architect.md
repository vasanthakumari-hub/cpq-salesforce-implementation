# Add a method to track vehicle status using the existing Fleet_Vehicle__c object and its VIN__c field — Technical Architect

# Technical Design Document: Vehicle Status Tracking System

**Project:** CPQ Implementation  
**Architect:** Salesforce Technical Architect  
**Date:** October 2023  
**Status:** Draft / For Review

---

## 1. Architecture Overview
The solution introduces a centralized mechanism to track and update the status of fleet vehicles using the unique Vehicle Identification Number (VIN). To maintain a decoupled architecture within the CPQ ecosystem, the design utilizes a **Service-Layer Pattern**. This ensures that status updates can be triggered via UI (LWC), REST API (Integrations), or internal logic (Triggers/Flows) through a unified Apex service.

---

## 2. Data Model
The implementation utilizes the existing `Fleet_Vehicle__c` object and introduces a new status field and tracking history.

### Custom Fields
| Object | Field Label | API Name | Data Type | Requirement |
| :--- | :--- | :--- | :--- | :--- |
| `Fleet_Vehicle__c` | Vehicle Status | `Vehicle_Status__c` | Picklist | Active, In Maintenance, Out of Service, Sold |
| `Fleet_Vehicle__c` | VIN | `VIN__c` | Text (17) | **External ID, Unique (Case Insensitive)** |
| `Fleet_Vehicle__c` | Last Status Change | `Last_Status_Change__c` | DateTime | System Timestamp |

### Record Types
*   **Standard Vehicle**: Default vehicle lifecycle.
*   **Leased Vehicle**: Specifically for CPQ-related leasing contracts.

---

## 3. Apex Architecture
We will implement the **Separation of Concerns (SoC)** following the standard Trigger Framework pattern.

### Service Layer (`FleetVehicleService.cls`)
Contains the business logic: `updateVehicleStatusByVIN(String vin, String newStatus)`.

### Selector Layer (`FleetVehicleSelector.cls`)
Contains optimized SOQL queries to prevent inline SOQL throughout the codebase.

### Trigger Handler (`FleetVehicleTriggerHandler.cls`)
Manages execution order and bulkification logic.

---

## 4. UI Components
A Lightning Web Component (LWC) will be developed to allow operations staff to quickly update a vehicle status by searching for a VIN without navigating through complex CPQ quote lines.

*   **Component Name:** `vehicleStatusManager`
*   **Functionality:** 
    *   Search input for VIN.
    *   Combobox for status selection.
    *   Lightning Data Service (`updateRecord`) or Apex call for submission.

---

## 5. Security Design
*   **Permission Set:** `Fleet_Operations_Manager` - Grant Edit access to `Vehicle_Status__c` and Read access to `VIN__c`.
*   **OWD:** Public Read/Write (or according to existing Fleet Management visibility).
*   **Field Level Security:** `VIN__c` should be Read-Only for standard users after record creation to maintain data integrity.

---

## 6. Governor Limits Considerations
*   **Bulkification:** The Service layer method will accept `Map<String, String>` (VIN to Status) to support bulk updates from integration middleware.
*   **SOQL Optimization:** The `VIN__c` field is marked as an **External ID/Indexed**, ensuring queries filter by VIN perform an Index Scan rather than a Full Table Scan.
*   **DML:** All status updates will be collected into a List and committed in a single DML statement.

---

## 7. Deployment File Paths

| Component | SFDX Project File Path |
| :--- | :--- |
| **Custom Field (Status)** | `force-app/main/default/objects/Fleet_Vehicle__c/fields/Vehicle_Status__c.field-meta.xml` |
| **Custom Field (VIN Update)** | `force-app/main/default/objects/Fleet_Vehicle__c/fields/VIN__c.field-meta.xml` |
| **Apex Service Class** | `force-app/main/default/classes/FleetVehicleService.cls` |
| **Apex Selector Class** | `force-app/main/default/classes/FleetVehicleSelector.cls` |
| **Apex Trigger Handler** | `force-app/main/default/classes/FleetVehicleTriggerHandler.cls` |
| **Apex Trigger** | `force-app/main/default/triggers/FleetVehicleTrigger.trigger` |
| **LWC (HTML)** | `force-app/main/default/lwc/vehicleStatusManager/vehicleStatusManager.html` |
| **LWC (JS)** | `force-app/main/default/lwc/vehicleStatusManager/vehicleStatusManager.js` |
| **LWC (XML)** | `force-app/main/default/lwc/vehicleStatusManager/vehicleStatusManager.js-meta.xml` |
| **Permission Set** | `force-app/main/default/permissionsets/Fleet_Operations_Manager.permissionset-meta.xml` |

---

## 8. Logic Implementation (Snippet)

```java
/**
 * Example Method within FleetVehicleService.cls
 * Updates vehicle status using VIN as key
 */
public static List<Database.SaveResult> updateStatusByVin(Map<String, String> vinToStatusMap) {
    List<Fleet_Vehicle__c> vehiclesToUpdate = [
        SELECT Id, VIN__c, Vehicle_Status__c 
        FROM Fleet_Vehicle__c 
        WHERE VIN__c IN :vinToStatusMap.keySet()
    ];
    
    for(Fleet_Vehicle__c vehicle : vehiclesToUpdate) {
        vehicle.Vehicle_Status__c = vinToStatusMap.get(vehicle.VIN__c);
        vehicle.Last_Status_Change__c = System.now();
    }
    
    return Database.update(vehiclesToUpdate, false);
}
```