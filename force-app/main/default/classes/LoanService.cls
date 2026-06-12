public with sharing class LoanService {
    @AuraEnabled
    public static List<Loan_Payment__c> getPaymentsByLoanId(Id loanId) {
        try {
            return [SELECT Id, Amount__c, Payment_Date__c 
                    FROM Loan_Payment__c 
                    WHERE Loan_Application__c = :loanId 
                    ORDER BY Payment_Date__c DESC];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void createPayment(Id loanId, Decimal amount) {
        try {
            Loan_Payment__c payment = new Loan_Payment__c(
                Loan_Application__c = loanId,
                Amount__c = amount,
                Payment_Date__c = Date.today()
            );
            insert payment;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}