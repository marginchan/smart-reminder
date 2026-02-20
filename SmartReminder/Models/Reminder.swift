//
//  Reminder.swift
//  SmartReminder
//

import Foundation
import SwiftData

@Model
class Reminder {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var dueDate: Date = Date()
    var isCompleted: Bool = false
    var priority: Priority = Priority.medium
    var category: ReminderCategory?
    var repeatFrequency: RepeatFrequency = RepeatFrequency.never
    var createdAt: Date = Date()
    var notificationIdentifier: String?
    
    var excludedDates: [Date]?
    @Transient var originalReminderId: UUID?
    var groupId: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        dueDate: Date,
        isCompleted: Bool = false,
        priority: Priority = .medium,
        category: ReminderCategory? = nil,
        repeatFrequency: RepeatFrequency = .never,
        excludedDates: [Date]? = nil,
        originalReminderId: UUID? = nil,
        groupId: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.priority = priority
        self.category = category
        self.repeatFrequency = repeatFrequency
        self.createdAt = createdAt
        self.notificationIdentifier = id.uuidString
        self.excludedDates = excludedDates
        self.originalReminderId = originalReminderId
        self.groupId = groupId
    }
}

enum Priority: Int, Codable, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
    
    var title: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "#8E8E93"      // 灰色
        case .medium: return "#007AFF"   // 蓝色
        case .high: return "#FF3B30"     // 红色
        }
    }
}

enum RepeatFrequency: String, Codable, CaseIterable {
    case never = "永不"
    case daily = "每天"
    case weekly = "每周"
    case monthly = "每月"
    case yearly = "每年"
    
    var calendarComponent: Calendar.Component? {
        switch self {
        case .never: return nil
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .monthly: return .month
        case .yearly: return .year
        }
    }
}
