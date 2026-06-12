@isTest
public class TestDataFactory {
    public static List<Loan_Application__c> createLoans(Integer count, Decimal amount) {
        List<Loan_Application__c> loans = new List<Loan_Application__c>();
        for(Integer i=0; i<count; i++) {
            loans.add(new Loan_Application__c(
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
