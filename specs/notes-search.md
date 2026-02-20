# Notes & Search Specification

## Background & Objectives
Notes provide long-form text management alongside standard reminders. A key objective for notes is advanced, natural-language search capability.

## Scenarios
### Scenario: Natural Language Search
- **GIVEN** the user is on the Notes tab
- **WHEN** the user types natural language time phrases like "今天", "昨天", "本周", "上个月"
- **THEN** the search engine should parse the semantic meaning of that phrase
- **AND** filter the list of notes to only show those whose creation or update times fall within the parsed date bounds.

## Future Specifications (Proposed)
- Extend parsing to support more complex natural language combinations.
