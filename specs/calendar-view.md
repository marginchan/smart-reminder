# Calendar & Lunar View Specification

## Background & Objectives
The calendar view provides a holistic visualization of reminders spread out across the month, and implements Chinese Lunar dates and festivals for localization.

## Scenarios
### Scenario: Opening the Calendar
- **GIVEN** the user taps the month calendar icon
- **WHEN** the calendar sheet appears
- **THEN** today's date should be selected by default.
- **AND** the user can page through a total range of -12 months to +12 months relative to the initial open date.

### Scenario: Day Cell Display
- **GIVEN** the calendar month grid is rendered
- **THEN** each day cell must display its corresponding Lunar info (e.g., "初一").
- **AND** if a festival falls on that date, it should override the regular lunar date with the festival name, using a distinctive visual style (e.g., red background).

### Scenario: Selected Date Details
- **GIVEN** the user taps on a specific date cell
- **THEN** the area below the calendar should immediately update to list all reminders scheduled for that specific date.
