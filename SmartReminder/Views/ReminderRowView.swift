import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct ReminderRowView: View {
    var reminder: Reminder
    var store: ReminderStore
    
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(priorityColor)
                .frame(width: 4)
                .padding(.vertical, 12)
                .padding(.leading, 12)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(reminder.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .strikethrough(reminder.isCompleted)
                    .foregroundColor(reminder.isCompleted ? .secondary : .primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let category = reminder.category {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                            Text(category.name)
                        }
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .foregroundColor(.secondary)
                        .cornerRadius(6)
                    }
                    
                    if !reminder.notes.isEmpty {
                        Text(reminder.notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 8)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedTime(reminder.dueDate))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isOverdue ? .red : .primary)
                let isToday = Calendar.current.isDateInToday(reminder.dueDate)
                Text(formattedDateShort(reminder.dueDate))
                    .font(.caption)
                    .fontWeight(isToday ? .semibold : .regular)
                    .foregroundColor(isOverdue ? .red : (isToday ? .accentColor : .secondary))
            }
            .padding(.trailing, 16)
        }
        .frame(height: 72)
        .background(Color.appSecondarySystemBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditSheet = true
        }
        .sheet(isPresented: $showingEditSheet) {
            EditReminderView(reminder: reminder, store: store, isPresented: $showingEditSheet)
        }
    }
    
    private var priorityColor: Color {
        switch reminder.priority {
        case .low: return Color.secondary.opacity(0.3)
        case .medium: return Color.fromHex("#007AFF").opacity(0.4)
        case .high: return Color.fromHex("#FF3B30").opacity(0.5)
        }
    }
    
    private var isOverdue: Bool {
        reminder.dueDate < Date() && !reminder.isCompleted
    }
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }()
    
    private func formattedTime(_ date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }
    
    private func formattedDateShort(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInTomorrow(date) {
            return "明天"
        } else {
            return Self.shortDateFormatter.string(from: date)
        }
    }
}

