# CPQ Advanced Discounting Permission Set — Business Analyst

### User Stories
As a Sales Operations Specialist, I want to restrict who can apply discounts above 20% to just the Sales Leadership team, so that margin targets are protected.

### Acceptance Criteria
- Create a 'CPQ Advanced Discounting' Permission Set.
- Assign users who are allowed to apply discretionary discounts above a certain threshold.
- Revoke 'Transfer Leads' or other unrelated permissions to keep the set focused on CPQ.

### Business Rules
- Standard Sales Reps can only discount up to 10%.
- Discounts 11-20% require Director approval (handled via Flow/Approval process).
- Discounts >20% require this specific Permission Set and VP approval.

### Salesforce-specific Considerations
- Use Custom Permissions within the Permission Set to gate specific LWC components or Flow logic.
- Ensure Permission Set is compatible with CPQ License types.

### Dependencies
- Salesforce CPQ License.
- User Role Hierarchy.

### Risks and Assumptions
- Assumption: Management will provide a list of users for initial assignment.
- Risk: Manual assignment of permission sets can be forgotten during onboarding (consider using Permission Set Groups).