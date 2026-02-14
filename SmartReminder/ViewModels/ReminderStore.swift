//
//  ReminderStore.swift
//  SmartReminder
//

import Foundation
import SwiftData
import Combine
import NaturalLanguage

@MainActor
class ReminderStore: ObservableObject {
    @Published var reminders: [Reminder] = []
    @Published var categories: [ReminderCategory] = []
    @Published var notes: [Note] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: ReminderCategory?
    @Published var selectedPriority: Priority?
    @Published var showCompleted: Bool = true
    @Published var noteSearchText: String = ""
    
    private var modelContext: ModelContext?
    private var notificationManager = NotificationManager()
    
    func setupModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchReminders()
        fetchCategories()
        fetchNotes()
        initializeDefaultCategories()
        seedDefaultData()
        seedDefaultNotes()
    }
    
    // MARK: - Fetch
    
    func fetchReminders() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Reminder>()
        reminders = (try? context.fetch(descriptor)) ?? []
    }
    
    func fetchCategories() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<ReminderCategory>()
        categories = (try? context.fetch(descriptor)) ?? []
    }
    
    func fetchNotes() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Note>()
        let fetchedNotes = (try? context.fetch(descriptor)) ?? []
        // Sort in memory: pinned first, then by updatedAt descending
        notes = fetchedNotes.sorted {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned && !$1.isPinned
            }
            return $0.updatedAt > $1.updatedAt
        }
    }
    
    // MARK: - CRUD
    
    func addReminder(_ reminder: Reminder) {
        guard let context = modelContext else { return }
        context.insert(reminder)
        save()
        fetchReminders()
        scheduleNotification(for: reminder)
    }
    
    func updateReminder(_ reminder: Reminder) {
        save()
        fetchReminders()
        scheduleNotification(for: reminder)
    }
    
    func deleteReminder(_ reminder: Reminder) {
        guard let context = modelContext else { return }
        cancelNotification(for: reminder)
        context.delete(reminder)
        save()
        fetchReminders()
    }
    
    func toggleComplete(_ reminder: Reminder) {
        reminder.isCompleted.toggle()
        save()
        fetchReminders()
        
        if reminder.isCompleted {
            cancelNotification(for: reminder)
        } else {
            scheduleNotification(for: reminder)
        }
    }
    
    // MARK: - Category
    
    func addCategory(_ category: ReminderCategory) {
        guard let context = modelContext else { return }
        context.insert(category)
        save()
        fetchCategories()
    }
    
    func deleteCategory(_ category: ReminderCategory) {
        guard let context = modelContext else { return }
        context.delete(category)
        save()
        fetchCategories()
    }
    
    func updateCategory(_ category: ReminderCategory) {
        save()
        fetchCategories()
    }
    
    private func initializeDefaultCategories() {
        if categories.isEmpty {
            for category in ReminderCategory.defaultCategories {
                addCategory(category)
            }
        }
    }
    
    private func seedDefaultData() {
        // 如果没有提醒，则填充默认优质数据
        if reminders.isEmpty {
            // 确保分类已加载
            if categories.isEmpty {
                initializeDefaultCategories()
            }
            
            let today = Date()
            let calendar = Calendar.current
            
            // 获取分类引用
            let work = categories.first { $0.name == "工作" }
            let personal = categories.first { $0.name == "个人" }
            let health = categories.first { $0.name == "健康" }
            let shopping = categories.first { $0.name == "购物" }
            let study = categories.first { $0.name == "学习" }
            
            // 辅助函数：生成相对时间
            func date(offsetDays: Int, hour: Int, minute: Int) -> Date {
                let targetDay = calendar.date(byAdding: .day, value: offsetDays, to: today)!
                return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: targetDay)!
            }
            
            let samples = [
                // 🔴 逾期任务
                Reminder(
                    title: "📧 回复 HR 邮件",
                    notes: "确认入职体检时间",
                    dueDate: date(offsetDays: -1, hour: 10, minute: 30),
                    priority: .high,
                    category: work
                ),
                
                // 🟢 今天任务
                Reminder(
                    title: "👋 欢迎使用 牛马提醒",
                    notes: "← 左滑推迟任务 | 右滑完成任务 →",
                    dueDate: date(offsetDays: 0, hour: 9, minute: 0),
                    priority: .high,
                    category: personal
                ),
                Reminder(
                    title: "💊 服用维生素 & 喝水",
                    notes: "保持身体健康",
                    dueDate: date(offsetDays: 0, hour: 13, minute: 0),
                    priority: .medium,
                    category: health,
                    repeatFrequency: .daily
                ),
                Reminder(
                    title: "🛒 超市采购",
                    notes: "清单：\n- 牛奶 🥛\n- 全麦面包 🍞\n- 鸡蛋 🥚\n- 苹果 🍎",
                    dueDate: date(offsetDays: 0, hour: 18, minute: 30),
                    priority: .medium,
                    category: shopping
                ),
                
                // 🔵 明天任务
                Reminder(
                    title: "📅 团队周会",
                    notes: "带上电脑，准备好 PPT 演示",
                    dueDate: date(offsetDays: 1, hour: 10, minute: 0),
                    priority: .high,
                    category: work,
                    repeatFrequency: .weekly
                ),
                Reminder(
                    title: "📖 阅读时间",
                    notes: "《乔布斯传》第 5 章",
                    dueDate: date(offsetDays: 1, hour: 21, minute: 0),
                    priority: .low,
                    category: study
                ),
                
                // 🟣 后天及未来
                Reminder(
                    title: "🏃 去健身房",
                    notes: "有氧运动 30 分钟 + 力量训练",
                    dueDate: date(offsetDays: 2, hour: 19, minute: 0),
                    priority: .medium,
                    category: health
                ),
                Reminder(
                    title: "🎁 给妈妈买生日礼物",
                    notes: "考虑买丝巾或者护肤品",
                    dueDate: date(offsetDays: 3, hour: 12, minute: 0),
                    priority: .high,
                    category: personal
                ),
                Reminder(
                    title: "✈️ 预订机票",
                    notes: "五一假期出游，提前订票便宜",
                    dueDate: date(offsetDays: 5, hour: 20, minute: 0),
                    priority: .medium,
                    category: personal
                )
            ]
            
            for reminder in samples {
                modelContext?.insert(reminder)
            }
            
            do {
                try modelContext?.save()
                // 重新获取以更新视图
                fetchReminders()
                print("✅ 优质 Mock 数据填充完成")
            } catch {
                print("❌ 数据填充失败: \(error)")
            }
        }
    }
    
    // MARK: - Notification
    
    private func scheduleNotification(for reminder: Reminder) {
        guard !reminder.isCompleted && reminder.dueDate > Date() else { return }
        notificationManager.scheduleNotification(for: reminder)
    }
    
    private func cancelNotification(for reminder: Reminder) {
        if let identifier = reminder.notificationIdentifier {
            notificationManager.cancelNotification(identifier: identifier)
        }
    }
    
    // MARK: - Save
    
    private func save() {
        guard let context = modelContext else { return }
        do {
            try context.save()
        } catch {
            print("保存失败: \(error)")
        }
    }
    
    // MARK: - Filtered Reminders
    
    var filteredReminders: [Reminder] {
        var result = reminders
        
        // 搜索过滤
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 分类过滤
        if let category = selectedCategory {
            result = result.filter { $0.category?.id == category.id }
        }
        
        // 优先级过滤
        if let priority = selectedPriority {
            result = result.filter { $0.priority == priority }
        }
        
        // 完成状态过滤
        if !showCompleted {
            result = result.filter { !$0.isCompleted }
        }
        
        return result
    }
    
    var todayReminders: [Reminder] {
        let calendar = Calendar.current
        return reminders.filter {
            calendar.isDate($0.dueDate, inSameDayAs: Date()) && !$0.isCompleted
        }
    }
    
    var upcomingReminders: [Reminder] {
        return reminders.filter { $0.dueDate > Date() && !$0.isCompleted }
    }
    
    var completedReminders: [Reminder] {
        return reminders.filter { $0.isCompleted }
    }
    
    var overdueReminders: [Reminder] {
        return reminders.filter { $0.dueDate < Date() && !$0.isCompleted }
    }
    
    // MARK: - Natural Language Processing
    
    struct ParsedReminder {
        var title: String
        var dueDate: Date?
        var priority: Priority = .medium
        var repeatFrequency: RepeatFrequency = .never
    }
    
    func parseNaturalLanguage(_ text: String) -> ParsedReminder {
        var parsedTitle = text
        var parsedDate: Date? = nil
        var parsedPriority: Priority = .medium
        var parsedRepeat: RepeatFrequency = .never
        
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
            let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
            
            if let firstMatch = matches.first, let date = firstMatch.date {
                parsedDate = date
            }
        } catch {
            print("NSDataDetector error: \(error)")
        }
        
        // Simple keyword matching for priority
        if text.contains("重要") || text.contains("紧急") || text.contains("立刻") || text.contains("马上") {
            parsedPriority = .high
        } else if text.contains("有空") || text.contains("顺便") {
            parsedPriority = .low
        }
        
        // Simple keyword matching for repeat frequency
        if text.contains("每天") {
            parsedRepeat = .daily
        } else if text.contains("每周") {
            parsedRepeat = .weekly
        } else if text.contains("每月") {
            parsedRepeat = .monthly
        } else if text.contains("每年") {
            parsedRepeat = .yearly
        }
        
        return ParsedReminder(
            title: parsedTitle,
            dueDate: parsedDate,
            priority: parsedPriority,
            repeatFrequency: parsedRepeat
        )
    }
    
    // MARK: - Notes CRUD
    
    func addNote(_ note: Note) {
        guard let context = modelContext else { return }
        context.insert(note)
        save()
        fetchNotes()
    }
    
    func updateNote(_ note: Note) {
        note.updatedAt = Date()
        save()
        fetchNotes()
    }
    
    func deleteNote(_ note: Note) {
        guard let context = modelContext else { return }
        context.delete(note)
        save()
        fetchNotes()
    }
    
    func togglePinNote(_ note: Note) {
        note.isPinned.toggle()
        note.updatedAt = Date()
        save()
        fetchNotes()
    }
    
    // MARK: - Filtered Notes
    
    var filteredNotes: [Note] {
        if noteSearchText.isEmpty {
            return notes
        }
        return notes.filter {
            $0.title.localizedCaseInsensitiveContains(noteSearchText) ||
            $0.content.localizedCaseInsensitiveContains(noteSearchText)
        }
    }
    
    // MARK: - Seed Default Notes
    
    private func seedDefaultNotes() {
        guard notes.isEmpty else { return }
        
        let defaultNotes = [
            Note(title: "💡 欢迎使用便签", content: "在这里记录你的灵感、待办事项或任何想法。便签支持多种颜色，可以置顶重要的便签。", color: "#FFD60A", isPinned: true),
            Note(title: "📝 使用技巧", content: "• 点击右下角 + 号添加新便签\n• 长按便签可以编辑或删除\n• 点击置顶图标可以将便签置顶\n• 使用搜索功能快速查找便签", color: "#4ECDC4"),
            Note(title: "🎯 本周目标", content: "完成 App 功能开发\n优化用户界面\n测试所有功能", color: "#FF6B6B")
        ]
        
        for note in defaultNotes {
            modelContext?.insert(note)
        }
        
        do {
            try modelContext?.save()
            fetchNotes()
            print("✅ 默认便签数据填充完成")
        } catch {
            print("❌ 便签数据填充失败: \(error)")
        }
    }
}
