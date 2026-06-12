/**
 * @description Selector class for querying Loan Application records
 * @author Salesforce Developer Agent
 */
public with sharing class LoanSelector {
    
    public static List<Loan_Application__c> getLoanApplicationsById(Set<Id> loanIds) {
        return [
            SELECT Id, Name, Loan_Amount__c, Status__c, CreatedDate
            FROM Loan_Application__c
            WHERE Id IN :loanIds
            WITH SECURITY_ENFORCED
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Loan_Application__c> getRecentLoans() {
        return [
            SELECT Id, Name, Loan_Amount__c, Status__c 
            FROM Loan_Application__c 
            ORDER BY CreatedDate DESC 
            LIMIT 10
        ];
    }
}
