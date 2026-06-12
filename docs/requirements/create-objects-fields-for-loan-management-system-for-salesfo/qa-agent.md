# create  objects, fields for loan management system for salesforce org. — QA Agent

To ensure a high-quality "Loan Management System" implementation within your CPQ project, we must validate the core data model: **Loan Application** and **Loan Payment**.

### 1. Test Scenarios Table

| Test Case ID | Description | Steps | Expected Result | Type |
| :--- | :--- | :--- | :--- | :--- |
| TC_01 | Positive: Loan Creation | Create a Loan__c record with valid Amount, Term, and Interest Rate. | Record saved; Calculated Total Payable is correct. | Unit |
| TC_02 | Negative: Validation Rule | Attempt to save a Loan with a negative Amount. | System prevents save with custom validation error. | Boundary |
| TC_03 | Bulk: High Volume Processing | Insert 200 Loan records in a single DML operation. | All records processed without Governor Limit issues. | Bulk |
| TC_04 | Security: Field Level Access | Access Loan records with a Restricted User profile. | User cannot view 'Internal Credit Score' field. | Security |
| TC_05 | Integration: Payment Update | Create a Payment record linked to a Loan. | Loan 'Remaining Balance' field updates automatically via Trigger/Flow. | Integration |

---

### 2. Apex Test Data Factory
This utility class ensures consistent data generation across all test suites.

**File Path:** `force-app/main/default/classes/TestDataFactory.cls`
```apex
@isTest
public class TestDataFactory {
    public static List<Loan__c> createLoans(Integer count, Decimal amount) {
        List<Loan__c> loans = new List<Loan__c>();
        for(Integer i=0; i<count; i++) {
            loans.add(new Loan__c(
                Loan_Amount__c = amount,
                Term_Months__c = 12,
                Interest_Rate__c = 5.0,
                Status__c = 'Draft'
            ));
        }
        return loans;
    }

    public static List<Loan_Payment__c> createPayments(Id loanId, Integer count, Decimal amount) {
        List<Loan_Payment__c> payments = new List<Loan_Payment__c>();
        for(Integer i=0; i<count; i++) {
            payments.add(new Loan_Payment__c(
                Loan__c = loanId,
                Payment_Amount__c = amount,
                Payment_Date__c = System.today()
            ));
        }
        return payments;
    }
}
```

**File Path:** `force-app/main/default/classes/TestDataFactory.cls-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>58.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

---

### 3. Apex Test Class (Logic & Bulk Testing)
This class tests the automation logic associated with the Loan objects.

**File Path:** `force-app/main/default/classes/LoanManagementTest.cls`
```apex
@isTest
private class LoanManagementTest {
    
    @testSetup
    static void setup() {
        // Create initial test data wrapper if needed
    }

    @isTest
    static void testLoanTotalCalculationPositive() {
        // Test Logic: Verify calculated fields on Loan creation
        Test.startTest();
        List<Loan__c> loans = TestDataFactory.createLoans(1, 10000);
        insert loans;
        Test.stopTest();

        Loan__c result = [SELECT Id, Total_Payable__c FROM Loan__c WHERE Id = :loans[0].Id];
        System.assertNotEquals(null, result.Total_Payable__c, 'Total Payable should be calculated.');
        System.assertEquals(10500, result.Total_Payable__c, 'Total Payable logic mismatch (Principal + 5% Interest).');
    }

    @isTest
    static void testLoanNegativeAmount() {
        // Test Logic: Validation Rule Check
        Loan__c badLoan = new Loan__c(Loan_Amount__c = -100, Term_Months__c = 12);
        
        Test.startTest();
        try {
            insert badLoan;
            System.assert(false, 'Exception should have been thrown due to validation rule');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Amount cannot be negative'), 'Wrong error message: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testBulkLoanInsertion() {
        // Test Logic: 200+ Records
        List<Loan__c> bulkLoans = TestDataFactory.createLoans(201, 5000);
        
        Test.startTest();
        insert bulkLoans;
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Loan__c];
        System.assertEquals(201, count, 'Bulk insertion failed to process all records.');
    }
}
```

**File Path:** `force-app/main/default/classes/LoanManagementTest.cls-meta.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>58.0</apiVersion>
    <status>Active</status>
</ApexClass>
```

---

### 4. Security & Profile Validation Test
Ensures that the CPQ Loan data is secure across different personas.

**File Path:** `force-app/main/default/classes/LoanSecurityTest.cls`
```apex
@isTest
private class LoanSecurityTest {
    
    @isTest
    static void testLoanAccessForStandardUser() {
        // Create a standard user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User standardUser = new User(Alias = 'stuser', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='loan_test_user@test.com');

        System.runAs(standardUser) {
            // Test Field Level Security
            Boolean isAccessible = Schema.sObjectType.Loan__c.fields.Internal_Credit_Score__c.isAccessible();
            System.assertEquals(false, isAccessible, 'Standard user should not have access to Internal Credit Score');
            
            // Test Record Creation
            try {
                Loan__c l = new Loan__c(Loan_Amount__c = 500);
                insert l;
            } catch (DmlException e) {
                System.assert(e.getMessage().contains('INSUFFICIENT_ACCESS'), 'User should be restricted');
            }
        }
    }
}
```

---

### 5. Jest Test for Loan Calculator LWC
Validates the UI component used for loan estimations.

**File Path:** `force-app/main/default/lwc/loanCalculator/__tests__/loanCalculator.test.js`
```javascript
import { createElement } from 'lwc';
import LoanCalculator from 'c/loanCalculator';

describe('c-loan-calculator', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders and calculates loan preview on input change', () => {
        const element = createElement('c-loan-calculator', {
            is: LoanCalculator
        });
        document.body.appendChild(element);

        // Find input elements
        const amountInput = element.shadowRoot.querySelector('lightning-input[data-id="amount"]');
        amountInput.value = 10000;
        amountInput.dispatchEvent(new CustomEvent('change'));

        const termInput = element.shadowRoot.querySelector('lightning-input[data-id="term"]');
        termInput.value = 12;
        termInput.dispatchEvent(new CustomEvent('change'));

        // Trigger calculation
        const btn = element.shadowRoot.querySelector('lightning-button');
        btn.click();

        return Promise.resolve().then(() => {
            const resultDisplay = element.shadowRoot.querySelector('.result');
            expect(resultDisplay.textContent).toBe('Monthly Payment: $833.33');
        });
    });
});
```

### 6. Summary of Validation Steps
1. **DML Verification**: Ensure Triggers/Flows handle `after insert` and `after update`.
2. **Formula Integrity**: Verify `Remaining_Balance__c` formula (Loan Amount - Total Payments).
3. **Sharing**: Ensure `Loan__c` is set to **Private** OWD and shared via **Loan Officer** criteria-based sharing rules.