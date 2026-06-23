# Add a method to track vehicle status using the existing Fleet_Vehicle__c object and its VIN__c field — DevOps Agent

As a Salesforce DevOps Agent, I have generated the complete deployment configuration for the **CPQ Implementation** project, specifically for the Fleet Tracking enhancement.

### 1. package.xml
**File Path:** `manifest/package.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>FleetVehicleController</members>
        <members>FleetVehicleControllerTest</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>FleetVehicleTrigger</members>
        <name>ApexTrigger</name>
    </types>
    <types>
        <members>Fleet_Vehicle__c.VIN__c</members>
        <members>Fleet_Vehicle__c.Status__c</members>
        <members>Fleet_Vehicle__c.Last_Status_Update__c</members>
        <name>CustomField</name>
    </types>
    <types>
        <members>Fleet_Vehicle_Management</members>
        <name>PermissionSet</name>
    </types>
    <types>
        <members>Fleet_Vehicle_Record_Page</members>
        <name>FlexiPage</name>
    </types>
    <version>59.0</version>
</Package>
```

---

### 2. Deployment Script
**File Path:** `scripts/deploy.sh`

```bash
#!/bin/bash

# 1. Validate Deployment (Dry Run) - Run all local tests
echo "Validating deployment against target org..."
sf project deploy start --manifest manifest/package.xml --target-org targetOrgAlias --dry-run --test-level RunLocalTests

# 2. Production Deployment (If validation passes)
echo "Executing production deployment..."
sf project deploy start --manifest manifest/package.xml --target-org targetOrgAlias --wait 30 --test-level RunLocalTests

# 3. Quick Deploy (If a previous validation was successful and provided a Job ID)
# sf project deploy resume --job-id <JOB_ID>
```

---

### 3. CI/CD Pipeline (GitHub Actions)
**File Path:** `.github/workflows/deploy.yml`

```yaml
name: Salesforce CPQ Deployment Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  validate-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Install Salesforce CLI
        run: npm install @salesforce/cli --global

      - name: Authenticate Sandbox
        run: |
          echo "${{ secrets.SFDX_AUTH_URL_SANDBOX }}" > sfdx_auth.txt
          sf org login sfdx-url --sfdx-url-file sfdx_auth.txt --alias sandbox --set-default

      - name: Validate Source & Run Tests
        run: |
          sf project deploy validate --manifest manifest/package.xml --target-org sandbox --test-level RunLocalTests --wait 30

  deploy-production:
    needs: validate-and-test
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Salesforce CLI
        run: npm install @salesforce/cli --global

      - name: Authenticate Production
        run: |
          echo "${{ secrets.SFDX_AUTH_URL_PROD }}" > sfdx_auth.txt
          sf org login sfdx-url --sfdx-url-file sfdx_auth.txt --alias prod --set-default-dev-hub

      - name: Deploy to Production
        run: |
          sf project deploy start --manifest manifest/package.xml --target-org prod --wait 60 --test-level RunLocalTests
```

---

### 4. Deployment Checklist

#### Pre-Deployment
1.  **Backup:** Perform a Full Sandbox refresh or export `Fleet_Vehicle__c` data.
2.  **Audit:** Ensure `VIN__c` field is unique and indexed in the target environment.
3.  **Dependency Check:** Verify if any existing CPQ Logic/Price Rules conflict with the new `Status__c` updates.

#### Deployment Order (Automated via SFDX)
1.  **Custom Fields:** `VIN__c`, `Status__c` (required for Apex references).
2.  **Apex Classes:** `FleetVehicleController` (Logic).
3.  **Apex Triggers:** `FleetVehicleTrigger` (Events).
4.  **Permission Sets:** Assigning access to new fields and classes.

#### Post-Deployment Verification
1.  Run the following Anonymous Apex to verify the specific requirement:
    ```apex
    String status = FleetVehicleController.getVehicleStatus('EXPECTED_VIN_HERE');
    System.assertNotEquals(null, status);
    ```
2.  Assign the `Fleet_Vehicle_Management` Permission Set to relevant users.

#### Rollback Procedure
1.  **Code Rollback:** Revert to previous Git commit and force-deploy the old state.
2.  **Destructive Changes:** If deployment added fields that break logic, use a `destructiveChanges.xml` to remove the new fields.

---

### 5. Folder Mapping Summary

| File Metadata | Exact Deployment Path |
| :--- | :--- |
| **Apex Class** | `force-app/main/default/classes/FleetVehicleController.cls` |
| **Apex Class Metadata**| `force-app/main/default/classes/FleetVehicleController.cls-meta.xml` |
| **Apex Test Class** | `force-app/main/default/classes/FleetVehicleControllerTest.cls` |
| **Apex Trigger** | `force-app/main/default/triggers/FleetVehicleTrigger.trigger` |
| **VIN Field** | `force-app/main/default/objects/Fleet_Vehicle__c/fields/VIN__c.field-meta.xml` |
| **Status Field** | `force-app/main/default/objects/Fleet_Vehicle__c/fields/Status__c.field-meta.xml` |
| **Permission Set** | `force-app/main/default/permissionsets/Fleet_Vehicle_Management.permissionset-meta.xml` |
| **Deployment Manifest**| `manifest/package.xml` |
| **CI/CD Workflow** | `.github/workflows/deploy.yml` |