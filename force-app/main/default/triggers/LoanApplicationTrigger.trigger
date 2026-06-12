trigger LoanApplicationTrigger on Loan_Application__c (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        LoanApplicationTriggerHandler.handleBeforeInsert(Trigger.new);
    }
}
