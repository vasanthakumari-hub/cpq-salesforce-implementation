# Quote-to-Opportunity Stage Automation Flow — Business Analyst

### User Stories
As a CPQ Administrator, I want to automatically update the related Opportunity stage to 'Closed Won' when a primary quote is marked as 'Accepted', so that manual data entry is reduced.

### Acceptance Criteria
- Flow triggers when SBQQ__Quote__c.SBQQ__Status__c is changed to 'Accepted'.
- Flow must verify 'SBQQ__Primary__c' is TRUE.
- Flow updates the parent Opportunity.StageName to 'Closed Won'.

### Business Rules
- Only primary quotes can trigger the Opportunity stage update.
- If the Opportunity already has a status of 'Closed Lost', the flow should not overwrite the stage.

### Salesforce-specific Considerations
- Use 'Fast Field Updates' (Before-save) logic where possible, but use 'Actions and Related Records' (After-save) for cross-object updates to Opportunity.
- Ensure recursion control is in place to prevent multiple Opportunity triggers.

### Dependencies
- Salesforce CPQ Package.
- Opportunity Object Stage picklist values.

### Risks and Assumptions
- Assumption: Closing a quote always implies winning the opportunity.
- Risk: Potential conflict with existing Opportunity triggers or Workflows.