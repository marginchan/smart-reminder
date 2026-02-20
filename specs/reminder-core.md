# Core Reminder Logic Specification

## Background & Objectives
Reminders are the core functionality of the SmartReminder application. This module handles how reminders are created, displayed, and filtered on the main homepage.

## Scenarios
### Scenario: Homepage Display
- **GIVEN** a user opens the app
- **THEN** the homepage should display reminders from the current time up to a maximum of 1 year into the future.
- **AND** the list must support infinite scrolling.

### Scenario: Overdue Reminders
- **GIVEN** a reminder's due date is today but the time has passed
- **AND** the reminder is not completed
- **WHEN** the user views the homepage
- **THEN** the reminder must appear in a distinct distinct "今日已逾期" (Overdue Today) section.

### Scenario: Empty States
- **GIVEN** there are no overdue reminders and no future reminders
- **WHEN** the user views the homepage
- **THEN** a unified empty state prompt should be displayed.

## Definitions
- **今日已逾期**: A reminder where `dueDate < Date.now()` AND `Calendar.isDateInToday(dueDate) == true` AND `isCompleted == false`.
- **未来 1 年提醒**: A reminder where `dueDate >= Date.now()` AND `dueDate <= Date.now() + 1 year`.
