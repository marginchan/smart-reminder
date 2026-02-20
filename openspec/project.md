# SmartReminder Project OpenSpec
# https://github.com/open-specs/openspec

## Project Overview
SmartReminder is a modern iOS reminder and task management application explicitly targeted for the Apple ecosystem.

## Technology Stack
- **Language**: Swift 5.10+
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Architecture**: MVVM (Model-View-ViewModel)
- **Local Notifications**: UserNotifications (UNUserNotificationCenter)

## Directory Structure
- `Models/`: Contains all SwiftData `@Model` classes (Reminder, Note, Category).
- `ViewModels/`: Contains `ReminderStore.swift` which handles all data mutation, querying, and business logic.
- `Views/`: SwiftUI View components. Modularized into smaller reusable components.
- `Services/`: Isolated system services like push notifications and date/lunar logic.

## Architecture Guidelines
### 1. Model Layer (SwiftData)
- Always use standard `@Model` macros for persistent classes.
- Handle relationships cleanly. Avoid heavy computed properties iterating through massive arrays on the main thread.

### 2. View Layer (SwiftUI)
- Views must NEVER mutate the `ModelContext` directly. All mutating operations MUST be routed through the `ReminderStore` ViewModel.
- Prevent SwiftData Deletion Crashes: ALWAYS wrap the `body` of a View representing a singular SwiftData model (e.g., `ReminderRowView`, `NoteCardView`) with an existence check:
  ```swift
  if model.isDeleted || model.modelContext == nil {
      EmptyView()
  } else {
      // Normal View Content
  }
  ```
- Modularize large views into subviews. Avoid `ContentView` growing out of control.

### 3. Service & ViewModel Layer
- The ViewModel (`ReminderStore`) acts as the single source of truth for the interaction between Views, SwiftData, and the `NotificationManager`.
- Keep notifications perfectly synchronized with physical data deletions by cancelling notifications *before* SwiftData deletion.

## Coding Standards
- **Naming**: Use camelCase for instances/functions, PascalCase for Structs/Classes.
- **Access Control**: Use `private` for state variables inside Views unless they need to be injected via parameters.
- **Localization**: Keep user-facing strings ready for potential future localization, though current targets are explicitly Chinese (`zh-Hans`).
- **Safety**: Prefer `if let` and `guard let` over force unwrap `!`. Never force unwrap properties fetched from SwiftData.
