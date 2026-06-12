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
