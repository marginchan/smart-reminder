//
//  Category.swift
//  SmartReminder
//

import Foundation
import SwiftData
import SwiftUI

@Model
class ReminderCategory {
    var id: UUID
    var name: String
    var color: String
    var icon: String
    var createdAt: Date
    
    @Relationship(deleteRule: .nullify, inverse: \Reminder.category)
    var reminders: [Reminder]?
    
    init(
        id: UUID = UUID(),
        name: String,
        color: String = "#007AFF",
        icon: String = "folder.fill"
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.createdAt = Date()
    }
    
    static let defaultCategories: [ReminderCategory] = [
        ReminderCategory(name: "工作", color: "#007AFF", icon: "briefcase.fill"),
        ReminderCategory(name: "个人", color: "#34C759", icon: "person.fill"),
        ReminderCategory(name: "购物", color: "#FF9500", icon: "cart.fill"),
        ReminderCategory(name: "健康", color: "#FF2D55", icon: "heart.fill"),
        ReminderCategory(name: "学习", color: "#5856D6", icon: "book.fill")
    ]
}
extension Color {
    static var appSystemBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color(white: 0.95)
        #endif
    }
    
    static var appSecondarySystemBackground: Color {
        #if canImport(UIKit)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(white: 0.9)
        #endif
    }
    
    static var appTertiarySystemFill: Color {
        #if canImport(UIKit)
        return Color(UIColor.tertiarySystemFill)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
    
    static var appSystemBackgroundPlain: Color {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #else
        return Color.white
        #endif
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    static func fromHex(_ hex: String) -> Color {
        return Color(hex: hex)
    }
}
