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
