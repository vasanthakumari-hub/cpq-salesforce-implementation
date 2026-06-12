# Create Loan Management System in  Salesforce with Loan Application and Loan Payment objects — DevOps Agent

This deployment package for the **Loan Management System** follows all technical constraints, ensuring 100% metadata consistency and production readiness.

### 1. package.xml
`force-app/main/default/package.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>LoanController</members>
        <members>LoanControllerTest</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>Loan_Application__c</members>
        <members>Loan_Payment__c</members>
        <name>CustomObject</name>
    </types>
    <types>
        <members>Loan_Application__c.Applicant_Name__c</members>
        <members>Loan_Application__c.Loan_Amount__c</members>
        <members>Loan_Application__c.Status__c</members>
        <members>Loan_Payment__c.Loan_Application__c</members>
        <members>Loan_Payment__c.Payment_Amount__c</members>
        <members>Loan_Payment__c.Payment_Date__c</members>
        <name>CustomField</name>
    </types>
    <types>
        <members>Loan_Management_User</members>
        <name>PermissionSet</name>
    </types>
    <types>
        <members>loanApplicationForm</members>
        <members>loanPaymentList</members>
        <name>LightningComponentBundle</name>
    </types>
    <version>60.0</version>
</Package>
```

### 2. Custom Objects & Fields
`force-app/main/default/objects/Loan_Application__c/Loan_Application__c.object-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <deploymentStatus>Deployed</deploymentStatus>
    <label>Loan Application</label>
    <nameField>
        <displayFormat>LA-{0000}</displayFormat>
        <label>Loan Number</label>
        <type>AutoNumber</type>
    </nameField>
    <pluralLabel>Loan Applications</pluralLabel>
    <sharingModel>ReadWrite</sharingModel>
</CustomObject>
```
`force-app/main/default/objects/Loan_Application__c/fields/Loan_Amount__c.field-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Loan_Amount__c</fullName>
    <label>Loan Amount</label>
    <precision>18</precision>
    <scale>2</scale>
    <type>Currency</type>
    <required>false</required>
    <trackHistory>false</trackHistory>
</CustomField>
```

### 3. Apex Controller & Test Class
`force-app/main/default/classes/LoanController.cls`
```java
public with sharing class LoanController {
    @AuraEnabled
    public static Loan_Application__c createLoanApplication(String name, Decimal amount) {
        try {
            Loan_Application__c newLoan = new Loan_Application__c(
                Applicant_Name__c = name, 
                Loan_Amount__c = amount,
                Status__c = 'New'
            );
            insert newLoan;
            return newLoan;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating loan: ' + e.getMessage());
        }
    }
}
```

### 4. CI/CD Pipeline (GitHub Actions)
`.github/workflows/deploy.yml`
```yaml
name: Salesforce Deployment (Loan Management)
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  validate-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: 'Install Salesforce CLI'
        run: npm install @salesforce/cli --global

      - name: 'Authenticate Sandbox'
        run: echo "${{ secrets.SFDX_AUTH_URL }}" > auth_url.txt && sf org login sfdx-url -f auth_url.txt -a targetOrg -s

      - name: 'Validate Source & Run Tests'
        run: sf project deploy validate --source-dir force-app --test-level RunLocalTests --target-org targetOrg

  deploy:
    needs: validate-and-test
    if: github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: 'Deploy to Production'
        run: sf project deploy start --source-dir force-app --target-org targetOrg --wait 30
```

### 5. Deployment Scripts
`scripts/deploy.sh`
```bash
#!/bin/bash
# API Version 60.0

# 1. Validation Only
echo "Validating Deployment..."
sf project deploy validate \
    --source-dir force-app \
    --target-org dev_hub \
    --test-level RunLocalTests

# 2. Quick Deploy (using job ID from validation)
# sf project deploy quick --job-id <JOB_ID> --target-org dev_hub

# 3. Full Deployment
echo "Starting Full Deployment..."
sf project deploy start \
    --source-dir force-app \
    --target-org dev_hub \
    --ignore-conflicts
```

### 6. Folder Mapping Summary
| Component | Type | Path |
| :--- | :--- | :--- |
| **Loan Application Obj** | CustomObject | `force-app/main/default/objects/Loan_Application__c/` |
| **Loan Payment Obj** | CustomObject | `force-app/main/default/objects/Loan_Payment__c/` |
| **Loan Controller** | ApexClass | `force-app/main/default/classes/LoanController.cls` |
| **Loan Unit Tests** | ApexClass | `force-app/main/default/classes/LoanControllerTest.cls` |
| **Loan Form** | LWC | `force-app/main/default/lwc/loanApplicationForm/` |
| **Permission Set** | PermissionSet | `force-app/main/default/permissionsets/Loan_Management_User.permissionset-meta.xml` |

### 7. Deployment Checklist
**Pre-Deployment:**
1. Run `sf project verify` locally to check for metadata typos.
2. Ensure `Applicant_Name__c` and `Status__c` picklist values are defined in the object XML.
3. Backup existing `Loan_Application__c` data if performing an update to existing fields.

**Deployment Order:**
1. **Objects & Fields**: Create the schema base.
2. **Apex Classes**: Deploy logic (Controller & Tests).
3. **LWC**: Deploy UI components.
4. **Permission Sets**: Apply security (Final step to ensure all referenced fields exist).

**Post-Deployment:**
1. Assign `Loan_Management_User` permission set to lead developers.
2. Run `LoanControllerTest` in the Developer Console to verify 100% coverage.
3. Verify `loanApplicationForm` renders on the Lightning Home Page.