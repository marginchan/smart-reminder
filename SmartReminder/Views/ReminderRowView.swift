import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct ReminderRowView: View {
    var reminder: Reminder
    var store: ReminderStore
    
    @State private var showingEditSheet = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(priorityColor)
                .frame(width: 4)
                .padding(.vertical, 12)
                .padding(.leading, 12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(reminder.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .strikethrough(reminder.isCompleted)
                    .foregroundColor(reminder.isCompleted ? .secondary : .primary)
                    .lineLimit(2)
                
                if !reminder.notes.isEmpty {
                    Text(reminder.notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text(formattedDate(reminder.dueDate))
                    }
                    .font(.caption)
                    .foregroundColor(isOverdue ? .red : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isOverdue ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    if let category = reminder.category {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                            Text(category.name)
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.fromHex( category.color).opacity(0.1))
                        .foregroundColor(Color.fromHex( category.color))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.trailing, 16)
        }
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
        case .low: return .green
        case .medium: return .blue
        case .high: return .red
        }
    }
    
    private var isOverdue: Bool {
        reminder.dueDate < Date() && !reminder.isCompleted
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return "今天 " + formatter.string(from: date)
        } else {
            formatter.dateFormat = "MM-dd HH:mm"
            return formatter.string(from: date)
        }
    }
}

