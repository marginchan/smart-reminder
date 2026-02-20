# Category Management Specification

## Background & Objectives
Categories help organize reminders. There is a requirement for a base "Default" category that provides a safety net for all reminders to ensure they are always categorized.

## Scenarios
### Scenario: Deleting the Default Category
- **GIVEN** the user navigates to the category management screen
- **WHEN** the user attempts to delete the category named "默认" (Default)
- **THEN** the deletion must be intercepted and prevented
- **AND** a Toast notification should appear saying "默认分类不可删除".

### Scenario: Creating a New Reminder
- **GIVEN** the user opens the "Add Reminder" sheet
- **WHEN** the user has not explicitly chosen a category
- **THEN** the "默认" (Default) category should be automatically and securely selected by default.
