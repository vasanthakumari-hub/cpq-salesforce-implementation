/**
 * @description Service class handling business logic for Loan Management
 * @author Salesforce Developer Agent
 */
public with sharing class LoanService {
    
    /**
     * @description Calculates potential interest or validations before approval
     */
    public static void validateLoansBeforeApproval(List<Loan_Application__c> loans) {
        for(Loan_Application__c loan : loans) {
            if(loan.Loan_Amount__c <= 0) {
                loan.addError('Loan Amount must be greater than zero.');
            }
        }
    }

    @AuraEnabled
    public static String createLoanApplication(Decimal amount, String status) {
        try {
            Loan_Application__c newLoan = new Loan_Application__c(
                Loan_Amount__c = amount,
                Status__c = status
            );
            insert newLoan;
            return newLoan.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating loan: ' + e.getMessage());
        }
    }
}
