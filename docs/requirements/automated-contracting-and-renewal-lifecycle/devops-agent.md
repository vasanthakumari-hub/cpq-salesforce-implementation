# Automated Contracting and Renewal Lifecycle — DevOps Agent

As your Salesforce DevOps Agent, I have prepared the complete deployment package and pipeline configuration for the Automated Contracting and Renewal Lifecycle (CPQ Implementation).

### 1. package.xml
This file defines the metadata scope for the deployment.

**File Path:** `manifest/package.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>ContractingAutomationService</members>
        <members>ContractingAutomationServiceTest</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>OpportunityTrigger</members>
        <name>ApexTrigger</name>
    </types>
    <types>
        <members>Opportunity.Contracting_Status__c</members>
        <members>Opportunity.Renewal_Batch_ID__c</members>
        <name>CustomField</name>
    </types>
    <types>
        <members>Contracting_Permissions</members>
        <name>PermissionSet</name>
    </types>
    <types>
        <members>Contract_Renewal_Automation_Flow</members>
        <name>Flow</name>
    </types>
    <types>
        <members>Contracting_Error_Message</members>
        <name>CustomLabel</name>
    </types>
    <types>
        <members>Opportunity-Opportunity Layout CPQ</members>
        <name>Layout</name>
    </types>
    <version>59.0</version>
</Package>
```

---

### 2. Deployment Scripts
Standard automation scripts for local CLI usage or simple CI/CD environments.

**File Path:** `scripts/deploy.sh`

```bash
#!/bin/bash

# 1. Validation Only (Source Format)
sf project deploy validate \
    --source-dir force-app \
    --test-level RunLocalTests \
    --target-org targetOrgAlias

# 2. Quick Deploy (using ID from validation)
# sf project deploy quick --job-id <JOB_ID> --target-org targetOrgAlias

# 3. Full Deployment (Source Format)
sf project deploy start \
    --source-dir force-app \
    --target-org targetOrgAlias \
    --test-level RunLocalTests \
    --wait 30

# 4. MDAPI Format Deployment (Legacy/Conversion)
# sf project convert source --output-dir mdapi_out
# sf project deploy start --metadata-dir mdapi_out --target-org targetOrgAlias
```

---

### 3. CI/CD Pipeline (GitHub Actions)
Fully automated pipeline focusing on validation for PRs and deployment for Merges.

**File Path:** `.github/workflows/deploy.yml`

```yaml
name: Salesforce CPQ Deployment

on:
  push:
    branches: [ main, develop ]
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
          echo "${{ secrets.SFDX_AUTH_URL_DEV }}" > ./auth_url.txt
          sf org login sfdx-url --sfdx-url-file ./auth_url.txt --set-default --alias dev_org

      - name: Validate Deployment & Run Tests
        run: |
          sf project deploy validate \
            --source-dir force-app \
            --test-level RunLocalTests \
            --target-org dev_org

  deploy-production:
    needs: validate-and-test
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Salesforce CLI
        run: npm install @salesforce/cli --global

      - name: Authenticate Production
        run: |
          echo "${{ secrets.SFDX_AUTH_URL_PROD }}" > ./auth_url.txt
          sf org login sfdx-url --sfdx-url-file ./auth_url.txt --set-default --alias prod_org

      - name: Deploy to Production
        run: |
          sf project deploy start \
            --source-dir force-app \
            --target-org prod_org \
            --test-level RunLocalTests \
            --wait 60
```

---

### 4. Deployment Checklist

#### **Pre-Deployment**
1. **Backup:** Run a full data export of `Opportunity`, `Contract`, `Pricebook2`, and `Product2` records.
2. **CPQ Settings:** Ensure "Contract in Forecast" and "Create Replacement Service" settings are consistent in the target environment.
3. **Muting:** If using a data loader for migration, disable the `OpportunityTrigger` via a Custom Setting/Feature Flag.

#### **Deployment Order**
1. **Custom Fields:** Deploy `Opportunity.Contracting_Status__c` first to avoid Class compilation errors.
2. **Apex Classes:** `ContractingAutomationService`.
3. **Flows:** `Contract_Renewal_Automation_Flow`.
4. **Triggers:** `OpportunityTrigger`.
5. **Permissions:** `Contracting_Permissions` to grant access to the new logic.

#### **Post-Deployment Verification**
1. **Sanity Check:** Close/Win a test Opportunity and verify the `Contract` record is automatically generated.
2. **Flow Check:** Verify the Flow is "Active."
3. **Permissions:** Assign the `Contracting_Permissions` Permission Set to the CPQ Operations user.

#### **Rollback Procedure**
1. **Metadata Rollback:** Use `git revert` on the last merge and deploy the previous state.
2. **Emergency Disable:** Deactivate the `OpportunityTrigger` or the `Contract_Renewal_Automation_Flow` directly in the UI.

---

### 5. Folder Mapping Summary

| Metadata Type | File Name | Repository Path |
| :--- | :--- | :--- |
| **Apex Class** | `ContractingAutomationService.cls` | `force-app/main/default/classes/` |
| **Apex Test** | `ContractingAutomationServiceTest.cls`| `force-app/main/default/classes/` |
| **Apex Trigger** | `OpportunityTrigger.trigger` | `force-app/main/default/triggers/` |
| **Custom Field** | `Contracting_Status__c.field-meta.xml` | `force-app/main/default/objects/Opportunity/fields/` |
| **Custom Field** | `Renewal_Batch_ID__c.field-meta.xml` | `force-app/main/default/objects/Opportunity/fields/` |
| **Flow** | `Contract_Renewal_Automation_Flow.flow` | `force-app/main/default/flows/` |
| **Permission Set**| `Contracting_Permissions.ps` | `force-app/main/default/permissionsets/` |
| **Layout** | `Opportunity-Opportunity Layout CPQ.layout` | `force-app/main/default/objects/Opportunity/layouts/` |
| **Custom Label** | `CustomLabels.labels` | `force-app/main/default/labels/` |
| **Manifest** | `package.xml` | `manifest/package.xml` |