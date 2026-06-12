# CPQ Product Compatibility Rules — Business Analyst

### User Stories
As a Product Manager, I want to prevent sales reps from adding 'Product B' if 'Product A' is not already in the quote, so that technical compatibility is maintained.

### Acceptance Criteria
- Error message displays: "Product B cannot be added without Product A."
- Product B is automatically removed or blocked from selection if Product A is absent from the Quote Line Editor.

### Business Rules
- Rule applies to all Commercial and Enterprise price books.
- Validation must run in the Quote Line Editor (Real-time).

### Salesforce-specific Considerations
- Use Product Action and Configuration Rule objects within CPQ.
- Ensure the 'Evaluation Event' is set to 'Always' to provide immediate feedback to the rep.

### Dependencies
- CPQ Quote Line Editor.
- Product Records (Product A and Product B).

### Risks and Assumptions
- Assumption: These product dependencies are global and do not vary by region.
- Risk: High number of Product Rules can lead to slow performance in the Quote Line Editor.