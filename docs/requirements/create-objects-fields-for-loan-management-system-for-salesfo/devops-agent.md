# create  objects, fields for loan management system for salesforce org. — DevOps Agent

As a Salesforce DevOps Agent, I have generated the complete configuration and pipeline for the Loan Management System within your CPQ Implementation project.

### 1. package.xml
**File Path:** `manifest/package.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>*</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>*</members>
        <name>ApexTrigger</name>
    </types>
    <types>
        <members>Loan_Application__c</members>
        <members>Loan_Payment__c</members>
        <name>CustomObject</name>
    </types>
    <types>
        <members>Loan_Application__c.Amount__c</members>
        <members>Loan_Application__c.Interest_Rate__c</members>
        <members>Loan_Application__c.Status__c</members>
        <members>Loan_Application__c.Term_Months__c</members>
        <members>Loan_Payment__c.Payment_Date__c</members>
        <members>Loan_Payment__c.Payment_Amount__c</members>
        <name>CustomField</name>
    </types>
    <types>
        <members>Loan_Application__c-Loan Layout</members>
        <name>Layout</name>
    </types>
    <types>
        <members>*</members>
        <name>LightningComponentBundle</name>
    </types>
    <types>
        <members>Loan_Management_Permissions</members>
        <name>PermissionSet</name>
    </types>
    <types>
        <members>Validate_Loan_Amount</members>
        <name>ValidationRule</name>
    </types>
    <types>
        <members>Loan_Approval_Process</members>
        <name>Flow</name>
    </types>
    <version>59.0</version>
</Package>
```

---

### 2. Deployment Script
**File Path:** `scripts/deploy.sh`

```bash
#!/bin/bash

# 1. Validate Only (Sandbox/UAT)
# Run tests and check for component conflicts
sf project deploy start --manifest manifest/package.xml --test-level RunLocalTests --dry-run --target-org sandbox_alias

# 2. Quick Deploy (Using Job ID from Validation)
# sf project deploy quick --job-id <JOB_ID> --target-org sandbox_alias

# 3. Full Production Deployment (SFDX Format)
sf project deploy start --manifest manifest/package.xml --target-org prod_alias --test-level RunLocalTests --wait 30

# 4. MDAPI Legacy Deployment (If converting from SFDX to MDAPI)
# sf project convert source --output-dir mdapi_out
# sf project deploy start --metadata-dir mdapi_out --target-org prod_alias --wait 30
```

---

### 3. CI/CD Pipeline (GitHub Actions)
**File Path:** `.github/workflows/deploy.yml`

```yaml
name: Salesforce CD Pipeline

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
        run: npm install -g @salesforce/cli
      - name: Authenticate Sandbox
        run: echo "${{ secrets.SFDX_AUTH_URL_SANDBOX }}" > auth_url.txt && sf org login sfdx-url -f auth_url.txt -a sandbox
      - name: Validate Source and Run Tests
        run: sf project deploy start --source-dir force-app --test-level RunLocalTests --dry-run --target-org sandbox

  deploy-prod:
    needs: validate-and-test
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Salesforce CLI
        run: npm install -g @salesforce/cli
      - name: Authenticate Production
        run: echo "${{ secrets.SFDX_AUTH_URL_PROD }}" > auth_url.txt && sf org login sfdx-url -f auth_url.txt -a prod
      - name: Deploy to Production
        run: sf project deploy start --source-dir force-app --test-level RunLocalTests --target-org prod --wait 60
```

---

### 4. Deployment Checklist

#### Pre-Deployment
1.  **Backup:** Perform a 'Data Export' and 'Metadata Export' of existing Objects.
2.  **Dependencies:** Ensure CPQ base package is installed in the target org.
3.  **Governance:** Check if the new objects (Loan_Application__c) exceed the org’s object limits.

#### Deployment Order (Manual or Scripted)
1.  **Objects & Fields:** `Loan_Application__c`, `Loan_Payment__c`.
2.  **Logic & Code:** Base Apex Classes → Triggers.
3.  **UI & Automation:** LWC Components → Flows → Layouts.
4.  **Security:** Permission Sets and Profiles.

#### Post-Deployment Verification
1.  Assign `Loan_Management_Permissions` to the deployment user.
2.  Verify "New" button on Loan Application object.
3.  Execute a test Loan creation to trigger Flow/Triggers.

#### Rollback Procedure
1.  **Destructive Changes:** If deployment fails partially, use a `destructiveChanges.xml` to remove metadata.
2.  **Git Revert:** Revert the commit in the `main` branch to trigger a clean redeploy of the previous state.

---

### 5. Folder Mapping Summary

| Component | File Path |
| :--- | :--- |
| **Loan Object** | `force-app/main/default/objects/Loan_Application__c/Loan_Application__c.object-meta.xml` |
| **Loan Fields** | `force-app/main/default/objects/Loan_Application__c/fields/*.field-meta.xml` |
| **Loan Trigger** | `force-app/main/default/triggers/LoanTrigger.trigger` |
| **Loan Class** | `force-app/main/default/classes/LoanController.cls` |
| **Loan LWC** | `force-app/main/default/lwc/loanCalculator/` |
| **Loan Workflow** | `force-app/main/default/flows/Loan_Approval_Process.flow-meta.xml` |
| **Permission Set**| `force-app/main/default/permissionsets/Loan_Management_Permissions.permissionset-meta.xml` |
| **Layouts** | `force-app/main/default/objects/Loan_Application__c/layouts/Loan_Layout.layout-meta.xml` |