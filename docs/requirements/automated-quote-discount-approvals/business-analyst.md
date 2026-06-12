# Automated Quote Discount Approvals — Business Analyst

### User Story
As a Sales Manager, I want to require an automated approval process for any quote where the average discount exceeds 15% or the total value is over $50k, so that we maintain profit margins.

### Acceptance Criteria
- Trigger approval when `SBQQ__AverageDiscount__c` > 15%.
- Trigger approval when `SBQQ__NetAmount__c` > $50,000.
- Approvers must receive an email notification and a Salesforce Bell notification.
- Quote status must change to 'Approved' only after all steps are completed.

### Business Rules
- Only the 'Primary' quote can be submitted for approval.
- Sales Reps cannot edit the quote once it is in 'Pending' status (Locking).

### Salesforce Considerations
- Use Advanced Approvals (if licensed) or standard Approval Processes.
- Consider using 'Smart Approvals' to avoid re-approving unchanged steps.

### Dependencies
- CPQ Quote object and fields must be finalized.
- User Hierarchy/Approver Matrix must be defined in Salesforce.

### Risks and Assumptions
- Assumption: The business uses a standard hierarchical approval path.