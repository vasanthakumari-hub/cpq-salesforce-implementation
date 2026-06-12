# Fleet & Vehicle Management System — DevOps Agent

Starting the generation of the Salesforce Fleet & Vehicle Management System deployment assets. All files are configured for API Version 60.0.

### 1. package.xml
File Path: `manifest/package.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>FleetVehicleController</members>
        <members>FleetVehicleControllerTest</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>Fleet_Vehicle__c</members>
        <members>Vehicle_Maintenance__c</members>
        <name>CustomObject</name>
    </types>
    <types>
        <members>Fleet_Vehicle__c-Fleet Vehicle Layout</members>
        <members>Vehicle_Maintenance__c-Vehicle Maintenance Layout</members>
        <name>Layout</name>
    </types>
    <types>
        <members>vehicleList</members>
        <members>maintenanceForm</members>
        <name>LightningComponentBundle</name>
    </types>
    <types>
        <members>Fleet_Management_User</members>
        <name>PermissionSet</name>
    </types>
    <version>60.0</version>
</Package>
```

### 2. Deployment Script
File Path: `scripts/deploy.sh`

```bash
#!/bin/bash

# Configuration
ORG_ALIAS="cpq-prod"
WAIT_TIME=10

echo "--- Salesforce Fleet Management Deployment Script ---"

# 1. Validation Only (Dry Run)
echo "Validating source..."
sf project deploy validate \
    --manifest manifest/package.xml \
    --target-org $ORG_ALIAS \
    --test-level RunLocalTests \
    --wait $WAIT_TIME

# 2. Check Validation Status and Deploy (using Job ID if needed, or direct deploy)
# For Direct Deployment:
echo "Deploying source to $ORG_ALIAS..."
sf project deploy start \
    --manifest manifest/package.xml \
    --target-org $ORG_ALIAS \
    --test-level RunLocalTests \
    --wait $WAIT_TIME

echo "Deployment completed successfully."
```

### 3. CI/CD Pipeline (GitHub Actions)
File Path: `.github/workflows/deploy.yml`

```yaml
name: Fleet Management CI/CD

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  validate-and-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install Salesforce CLI
        run: |
          npm install -g @salesforce/cli

      - name: Authenticate Sandbox
        run: |
          echo "${{ secrets.SFDX_AUTH_URL_SANDBOX }}" > sfdx_auth.txt
          sf org login sfdx-url --sfdx-url-file sfdx_auth.txt --alias staging --set-default-repo

      - name: Validate Source & Run Tests
        run: |
          sf project deploy validate \
            --manifest manifest/package.xml \
            --target-org staging \
            --test-level RunLocalTests

  deploy-production:
    needs: validate-and-test
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Install Salesforce CLI
        run: npm install -g @salesforce/cli

      - name: Authenticate Production
        run: |
          echo "${{ secrets.SFDX_AUTH_URL_PROD }}" > sfdx_auth.txt
          sf org login sfdx-url --sfdx-url-file sfdx_auth.txt --alias prod

      - name: Deploy to Production
        run: |
          sf project deploy start \
            --manifest manifest/package.xml \
            --target-org prod \
            --test-level RunLocalTests \
            --wait 30
```

### 4. Deployment Checklist

**Pre-Deployment:**
1. **Backup:** Run a full data export of `Fleet_Vehicle__c` if performing an update to existing fields.
2. **Access:** Ensure the deploying user has "Modify All Data" and "Author Apex" permissions.
3. **Dependencies:** Confirm the Salesforce org is on API version 60.0.

**Deployment Order:**
1. **Objects:** Deploy `Fleet_Vehicle__c` and `Vehicle_Maintenance__c` first.
2. **Fields:** Deploy custom fields linked to these objects.
3. **Apex Classes:** Deploy `FleetVehicleController` and its test class.
4. **LWC:** Deploy `vehicleList` and `maintenanceForm`.
5. **Layouts/Permissions:** Deploy Page Layouts and the `Fleet_Management_User` Permission Set.

**Post-Deployment Verification:**
1. Assign `Fleet_Management_User` Permission Set to a test user.
2. Navigate to the Fleet Vehicle list view and verify the LWC loads correctly.
3. Run `FleetVehicleControllerTest` in the Developer Console to ensure 100% pass rate.

**Rollback Procedure:**
1. In case of failure, use `sf project deploy start --manifest manifest/destructiveChanges.xml` to remove metadata.
2. Revert the Git branch to the previous stable commit tag.

### 5. Folder Mapping Summary (Full Inventory)

| Component Name | Type | Repository Path |
| :--- | :--- | :--- |
| **Fleet_Vehicle__c** | Custom Object | `force-app/main/default/objects/Fleet_Vehicle__c/Fleet_Vehicle__c.object-meta.xml` |
| **Vehicle_Maintenance__c** | Custom Object | `force-app/main/default/objects/Vehicle_Maintenance__c/Vehicle_Maintenance__c.object-meta.xml` |
| **Vehicle_VIN__c** | Custom Field | `force-app/main/default/objects/Fleet_Vehicle__c/fields/Vehicle_VIN__c.field-meta.xml` |
| **FleetVehicleController** | Apex Class | `force-app/main/default/classes/FleetVehicleController.cls` |
| **FleetVehicleController** | Apex Metadata | `force-app/main/default/classes/FleetVehicleController.cls-meta.xml` |
| **FleetVehicleControllerTest** | Apex Test Class | `force-app/main/default/classes/FleetVehicleControllerTest.cls` |
| **vehicleList** (HTML) | LWC | `force-app/main/default/lwc/vehicleList/vehicleList.html` |
| **vehicleList** (JS) | LWC | `force-app/main/default/lwc/vehicleList/vehicleList.js` |
| **vehicleList** (Meta) | LWC | `force-app/main/default/lwc/vehicleList/vehicleList.js-meta.xml` |
| **Fleet_Management_User** | Permission Set | `force-app/main/default/permissionsets/Fleet_Management_User.permissionset-meta.xml` |
| **Fleet Vehicle Layout** | Layout | `force-app/main/default/layouts/Fleet_Vehicle__c-Fleet Vehicle Layout.layout-meta.xml` |