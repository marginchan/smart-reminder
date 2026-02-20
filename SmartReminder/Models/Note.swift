//
//  Note.swift
//  SmartReminder
//

import Foundation
import SwiftData

@Model
class Note {
    var id: UUID = UUID()
    var title: String = ""
    var content: String = ""
    var color: String = ""
    var isPinned: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String = "",
        color: String = "#FFD60A",
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.color = color
        self.isPinned = isPinned
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    static let defaultColors: [String] = [
        "#FFD60A", // 黄色
        "#FF6B6B", // 红色
        "#4ECDC4", // 青色
        "#95E1D3", // 薄荷绿
        "#F38181", // 粉红
        "#AA96DA", // 紫色
        "#FCBAD3", // 浅粉
        "#FFFFD2"  // 浅黄
    ]
}
