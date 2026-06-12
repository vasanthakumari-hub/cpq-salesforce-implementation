# Quote Lifecycle Visual Progress LWC — Business Analyst

### User Stories
As a Sales Representative, I want a visual progress bar on the Quote record, so that I can easily see which stage of the sales/approval lifecycle the quote is currently in.

### Acceptance Criteria
- The LWC must display stages: Draft, In Review, Approved, Presented, Denied.
- The component must be reactive to changes in the 'Status' field without requiring a page refresh.
- Color coding: Green for completed, Blue for current, Red for denied.

### Business Rules
- The component should only be visible on the 'Approved' or 'Draft' record types.
- The stage 'Approved' should only be highlighted when the 'SBQQ__Quote__c.SBQQ__Status__c' is equal to 'Approved'.

### Salesforce-specific Considerations
- Use Lightning Data Service (LDS) for wire service to ensure low latency and cache management.
- Component must be mobile-responsive for Salesforce Mobile App.

### Dependencies
- Lightning App Builder (for page placement).
- CPQ Quote Status picklist values.

### Risks and Assumptions
- Assumption: The business will not change picklist values frequently.
- Risk: If custom statuses are added later, the LWC CSS/Logic will require manual updates.