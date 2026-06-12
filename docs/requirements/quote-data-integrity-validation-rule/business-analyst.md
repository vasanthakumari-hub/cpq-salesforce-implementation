# Quote Data Integrity Validation Rule — Business Analyst

### User Stories
As a Sales Manager, I want to ensure that specific quote fields are locked once a quote is approved, so that the pricing integrity remains consistent.

### Acceptance Criteria
- When the 'Approval Status' picklist is set to 'Approved', the 'Discount %', 'Payment Terms', and 'Net Amount' fields must be read-only for non-admin users.
- An error message should appear if a user attempts to edit these fields: "Quote details cannot be modified once the status is Approved."

### Business Rules
- Only users with the 'System Administrator' profile or 'CPQ Manager' permission set can bypass this rule.
- Verification must occur before the record is saved.

### Salesforce-specific Considerations
- Standard CPQ field-level security must align with this validation rule.
- Ensure that system-driven updates (e.g., automated tax calculations) do not trigger this validation.

### Dependencies
- CPQ Package (SBQQ__Quote__c object).
- Approval Process for Quotes.

### Risks and Assumptions
- Assumption: The 'Approval Status' field is the reliable source of truth for the quote lifecycle.
- Risk: Too many validation rules on the Quote object may impact performance during high-volume quote generation.