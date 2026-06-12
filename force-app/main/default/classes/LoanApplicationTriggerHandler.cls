public with sharing class LoanApplicationTriggerHandler {
    public static void handleBeforeInsert(List<Loan_Application__c> newList) {
        LoanService.validateLoansBeforeApproval(newList);
    }
}
