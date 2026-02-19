//
//  ReminderStore.swift
//  SmartReminder
//

import Foundation
import SwiftData
import Combine
import NaturalLanguage

#if canImport(UIKit)
import UIKit
#endif

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
    
    var modelContext: ModelContext?
    private let notificationManager = NotificationManager.shared
    
    // 标记是否已初始化示例数据
    private let hasInitializedSampleDataKey = "hasInitializedSampleData"
    private var hasInitializedSampleData: Bool {
        get { UserDefaults.standard.bool(forKey: hasInitializedSampleDataKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasInitializedSampleDataKey) }
    }
    
    func setupModelContext(_ context: ModelContext) {
        self.modelContext = context
        refresh()
        initializeDefaultCategories()
        
        // 仅在首次安装时初始化示例数据
        if !hasInitializedSampleData {
            seedDefaultData()
            seedDefaultNotes()
            hasInitializedSampleData = true
        }
    }
    
    // MARK: - Fetch
    
    func refresh() {
        fetchReminders()
        fetchCategories()
        fetchNotes()
    }
    
    /// 按目标 Tab 局部刷新，避免不必要的数据更新
    func refreshForTab(_ tab: Int) {
        switch tab {
        case 0: // 提醒
            fetchReminders()
            fetchCategories()
        case 1: // 日历
            fetchReminders()
        case 2: // 便签
            fetchNotes()
        default: // 设置等
            break
        }
    }
    
    func fetchReminders() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Reminder>()
        reminders = (try? context.fetch(descriptor)) ?? []
    }
    
    func fetchCategories() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<ReminderCategory>()
        let fetched = (try? context.fetch(descriptor)) ?? []
        categories = fetched.sorted { c1, c2 in
            if c1.name == "默认" { return true }
            if c2.name == "默认" { return false }
            return c1.createdAt < c2.createdAt
        }
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
        cancelNotification(for: reminder)
        scheduleNotification(for: reminder)
    }
    
    func deleteReminder(_ reminder: Reminder) {
        guard let context = modelContext else { return }
        cancelNotification(for: reminder)
        context.delete(reminder)
        save()
        fetchReminders()
        notificationManager.clearBadge()
    }
    
    func toggleComplete(_ reminder: Reminder) {
        reminder.isCompleted.toggle()
        save()
        fetchReminders()
        
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(reminder.isCompleted ? .success : .warning)
        #endif
        
        if reminder.isCompleted {
            cancelNotification(for: reminder)
            notificationManager.clearBadge()
            notificationManager.clearDeliveredNotifications()
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
        for category in ReminderCategory.defaultCategories {
            if !categories.contains(where: { $0.name == category.name }) {
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
    
    /// 重新调度所有未完成且未过期提醒的通知（暂停恢复时使用）
    func rescheduleAllNotifications() {
        let now = Date()
        for reminder in reminders where !reminder.isCompleted && reminder.dueDate > now {
            notificationManager.scheduleNotification(for: reminder)
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
        
        // 完成状态过滤 - 首页不显示已完成的提醒
        result = result.filter { !$0.isCompleted }
        
        // 仅展示当前时间之后、未来 1 年内的提醒（首页提醒列表）
        // 当天已逾期的提醒由 overdueReminders 单独展示，这里不重复
        let now = Date()
        let oneYearLater = Calendar.current.date(byAdding: .year, value: 1, to: now) ?? now
        result = result.filter { $0.dueDate >= now && $0.dueDate <= oneYearLater }
        
        // 按时间排序：未完成的在前，最近的时间排在最上面
        result.sort { r1, r2 in
            if r1.isCompleted != r2.isCompleted {
                return !r1.isCompleted
            }
            return r1.dueDate < r2.dueDate
        }
        
        return result
    }
    
    var todayReminders: [Reminder] {
        let calendar = Calendar.current
        var result = reminders.filter { reminder in
            calendar.isDate(reminder.dueDate, inSameDayAs: Date()) && !reminder.isCompleted
        }
        result.sort { r1, r2 in
            if r1.isCompleted != r2.isCompleted {
                return !r1.isCompleted
            }
            return r1.dueDate < r2.dueDate
        }
        return result
    }
    
    var upcomingReminders: [Reminder] {
        return reminders.filter { $0.dueDate > Date() && !$0.isCompleted }
    }
    
    var completedReminders: [Reminder] {
        return reminders.filter { $0.isCompleted }
    }
    
    var overdueReminders: [Reminder] {
        let now = Date()
        let startOfToday = Calendar.current.startOfDay(for: now)
        // 仅展示当天逾期的未完成提醒
        return reminders.filter {
            $0.dueDate < now && $0.dueDate >= startOfToday && !$0.isCompleted
        }.sorted { $0.dueDate < $1.dueDate }
    }
    
    // MARK: - Recurring Reminder Expansion
    
    /// 为重复提醒生成未来 1 年内的所有虚拟日期
    private func generateOccurrenceDates(for reminder: Reminder) -> [Date] {
        guard reminder.repeatFrequency != .never,
              let component = reminder.repeatFrequency.calendarComponent else {
            return []
        }
        
        let calendar = Calendar.current
        let now = Date()
        let maxDate: Date
        
        switch reminder.repeatFrequency {
        case .yearly:
            maxDate = calendar.date(byAdding: .year, value: 3, to: now) ?? now
        default:
            maxDate = calendar.date(byAdding: .year, value: 1, to: now) ?? now
        }
        
        var dates: [Date] = []
        var occurrence = reminder.dueDate
        var count = 1
        
        while count <= 500 { // 安全上限
            guard let next = calendar.date(byAdding: component, value: count, to: reminder.dueDate) else { break }
            if next > maxDate { break }
            if next > now || calendar.isDate(next, inSameDayAs: now) {
                dates.append(next)
            }
            count += 1
        }
        
        return dates
    }
    
    /// 返回某天所有提醒（含重复提醒的虚拟实例）
    func remindersForDate(_ date: Date) -> [Reminder] {
        let calendar = Calendar.current
        
        // 1. 原始提醒：dueDate 就在这一天的
        var result = reminders.filter {
            calendar.isDate($0.dueDate, inSameDayAs: date) && !$0.isCompleted
        }
        
        // 2. 重复提醒的虚拟实例
        let recurringReminders = reminders.filter {
            $0.repeatFrequency != .never && !$0.isCompleted
        }
        
        for reminder in recurringReminders {
            // 原始日期已经在上面处理了，跳过
            if calendar.isDate(reminder.dueDate, inSameDayAs: date) { continue }
            
            // 检查该日期是否是这个重复提醒的某个实例
            if isOccurrenceDate(date, for: reminder) {
                result.append(reminder)
            }
        }
        
        return result.sorted { $0.dueDate < $1.dueDate }
    }
    
    /// 快速判断某天是否是某个重复提醒的实例日期（不生成所有日期）
    private func isOccurrenceDate(_ date: Date, for reminder: Reminder) -> Bool {
        guard reminder.repeatFrequency != .never,
              let component = reminder.repeatFrequency.calendarComponent else {
            return false
        }
        
        let calendar = Calendar.current
        let reminderDate = calendar.startOfDay(for: reminder.dueDate)
        let targetDate = calendar.startOfDay(for: date)
        
        // 目标日期必须在原始日期之后
        guard targetDate > reminderDate else { return false }
        
        switch reminder.repeatFrequency {
        case .daily:
            return true // 每天都是
        case .weekly:
            return calendar.component(.weekday, from: reminderDate) == calendar.component(.weekday, from: targetDate)
        case .monthly:
            return calendar.component(.day, from: reminderDate) == calendar.component(.day, from: targetDate)
        case .yearly:
            let rComps = calendar.dateComponents([.month, .day], from: reminderDate)
            let tComps = calendar.dateComponents([.month, .day], from: targetDate)
            return rComps.month == tComps.month && rComps.day == tComps.day
        case .never:
            return false
        }
    }
    
    /// filteredReminders 的增强版，包含重复提醒的未来实例
    var expandedFilteredReminders: [Reminder] {
        var result = filteredReminders
        
        // 获取所有未完成的重复提醒
        let recurringReminders = reminders.filter {
            $0.repeatFrequency != .never && !$0.isCompleted
        }
        
        let calendar = Calendar.current
        
        for reminder in recurringReminders {
            let futureDates = generateOccurrenceDates(for: reminder)
            for date in futureDates {
                // 避免与已有的 filteredReminders 重复（原始 dueDate）
                if !result.contains(where: { $0.id == reminder.id && calendar.isDate($0.dueDate, inSameDayAs: date) }) {
                    // 使用确定性 UUID：基于原始 ID + 日期，确保 SwiftUI 列表稳定
                    let dateString = "\(calendar.component(.year, from: date))-\(calendar.component(.month, from: date))-\(calendar.component(.day, from: date))"
                    let stableID = UUID(uuidString: stableUUIDString(from: reminder.id.uuidString + dateString))
                        ?? UUID()
                    
                    let virtualReminder = Reminder(
                        id: stableID,
                        title: reminder.title,
                        notes: reminder.notes,
                        dueDate: date,
                        priority: reminder.priority,
                        category: reminder.category,
                        repeatFrequency: reminder.repeatFrequency
                    )
                    result.append(virtualReminder)
                }
            }
        }
        
        // 重新排序
        result.sort { $0.dueDate < $1.dueDate }
        
        return result
    }
    
    /// 基于输入字符串生成确定性 UUID 字符串
    private func stableUUIDString(from input: String) -> String {
        var hash = [UInt8](repeating: 0, count: 16)
        let data = Array(input.utf8)
        for (i, byte) in data.enumerated() {
            hash[i % 16] ^= byte
            hash[i % 16] = hash[i % 16] &+ byte
        }
        // 格式化为 UUID 字符串
        let hex = hash.map { String(format: "%02x", $0) }.joined()
        let uuid = "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(4))-\(hex.dropFirst(12).prefix(4))-\(hex.dropFirst(16).prefix(4))-\(hex.dropFirst(20).prefix(12))"
        return uuid
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
        let text = noteSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            return notes
        }
        let dateRange = noteSearchDateRange(from: text)
        return notes.filter { note in
            let matchesText = note.title.localizedCaseInsensitiveContains(text) ||
                note.content.localizedCaseInsensitiveContains(text)
            let matchesDate = dateRange.map { range in
                range.contains(note.updatedAt) || range.contains(note.createdAt)
            } ?? false
            return matchesText || matchesDate
        }
    }
    
    private func noteSearchDateRange(from text: String) -> ClosedRange<Date>? {
        let calendar = Calendar.current
        let now = Date()
        
        if let dayRange = recentDaysRange(from: text, now: now) {
            return dayRange
        }
        if text.contains("今天") {
            return dayRange(for: now)
        }
        if text.contains("明天") {
            guard let date = calendar.date(byAdding: .day, value: 1, to: now) else { return nil }
            return dayRange(for: date)
        }
        if text.contains("后天") {
            guard let date = calendar.date(byAdding: .day, value: 2, to: now) else { return nil }
            return dayRange(for: date)
        }
        if text.contains("大后天") {
            guard let date = calendar.date(byAdding: .day, value: 3, to: now) else { return nil }
            return dayRange(for: date)
        }
        if text.contains("昨天") {
            guard let date = calendar.date(byAdding: .day, value: -1, to: now) else { return nil }
            return dayRange(for: date)
        }
        if text.contains("前天") {
            guard let date = calendar.date(byAdding: .day, value: -2, to: now) else { return nil }
            return dayRange(for: date)
        }
        if text.contains("本周") {
            return calendar.dateInterval(of: .weekOfYear, for: now).map { closedRange(from: $0) }
        }
        if text.contains("上周") {
            guard let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now) else { return nil }
            return calendar.dateInterval(of: .weekOfYear, for: lastWeek).map { closedRange(from: $0) }
        }
        if text.contains("下周") {
            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: now) else { return nil }
            return calendar.dateInterval(of: .weekOfYear, for: nextWeek).map { closedRange(from: $0) }
        }
        if text.contains("本月") {
            return calendar.dateInterval(of: .month, for: now).map { closedRange(from: $0) }
        }
        if text.contains("上个月") || text.contains("上月") {
            guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else { return nil }
            return calendar.dateInterval(of: .month, for: lastMonth).map { closedRange(from: $0) }
        }
        if text.contains("下个月") || text.contains("下月") {
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) else { return nil }
            return calendar.dateInterval(of: .month, for: nextMonth).map { closedRange(from: $0) }
        }
        if text.contains("本年") || text.contains("今年") {
            return calendar.dateInterval(of: .year, for: now).map { closedRange(from: $0) }
        }
        if text.contains("去年") {
            guard let lastYear = calendar.date(byAdding: .year, value: -1, to: now) else { return nil }
            return calendar.dateInterval(of: .year, for: lastYear).map { closedRange(from: $0) }
        }
        if text.contains("上半年") {
            return halfYearRange(for: now, isFirstHalf: true)
        }
        if text.contains("下半年") {
            return halfYearRange(for: now, isFirstHalf: false)
        }
        
        let parsed = parseNaturalLanguage(text)
        if let date = parsed.dueDate {
            return dayRange(for: date)
        }
        return nil
    }
    
    private func recentDaysRange(from text: String, now: Date) -> ClosedRange<Date>? {
        let patterns = ["近(\\d+)天", "最近(\\d+)天"]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: text.utf16.count)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text),
               let days = Int(text[range]) {
                let safeDays = max(1, min(days, 365))
                let calendar = Calendar.current
                let start = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -(safeDays - 1), to: now) ?? now)
                let end = endOfDay(for: now)
                return start...end
            }
        }
        if text.contains("近一周") || text.contains("最近一周") {
            return recentDaysRange(from: "近7天", now: now)
        }
        if text.contains("近一月") || text.contains("最近一月") {
            return recentDaysRange(from: "近30天", now: now)
        }
        if text.contains("最近三天") {
            return recentDaysRange(from: "近3天", now: now)
        }
        return nil
    }
    
    private func halfYearRange(for now: Date, isFirstHalf: Bool) -> ClosedRange<Date>? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let startMonth = isFirstHalf ? 1 : 7
        let endMonth = isFirstHalf ? 6 : 12
        guard let startDate = calendar.date(from: DateComponents(year: year, month: startMonth, day: 1)),
              let endDate = calendar.date(from: DateComponents(year: year, month: endMonth, day: 1)),
              let endInterval = calendar.dateInterval(of: .month, for: endDate) else { return nil }
        let end = endOfDay(for: endInterval.end.addingTimeInterval(-1))
        return calendar.startOfDay(for: startDate)...end
    }
    
    private func dayRange(for date: Date) -> ClosedRange<Date> {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = endOfDay(for: date)
        return start...end
    }
    
    private func closedRange(from interval: DateInterval) -> ClosedRange<Date> {
        interval.start...endOfDay(for: interval.end.addingTimeInterval(-1))
    }
    
    private func endOfDay(for date: Date) -> Date {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: start)?.addingTimeInterval(-1) ?? date
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

// MARK: - Mock Data Generation

#if targetEnvironment(simulator)
extension ReminderStore {
    func generateMockData() {
        guard let context = modelContext else { return }
        
        print("🤖 Generating Mock Data...")
        
        // 1. Ensure Categories exist
        let categoryNames = ["工作", "个人", "购物", "学习"]
        var categoryMap: [String: ReminderCategory] = [:]
        
        // Check existing categories
        for category in categories {
            categoryMap[category.name] = category
        }
        
        for name in categoryNames {
            if categoryMap[name] == nil {
                let color = ["#FF3B30", "#007AFF", "#34C759", "#FF9500"].randomElement() ?? "#007AFF"
                let icon = ["briefcase.fill", "person.fill", "cart.fill", "book.fill"].randomElement() ?? "list.bullet"
                let newCategory = ReminderCategory(name: name, color: color, icon: icon)
                context.insert(newCategory)
                categoryMap[name] = newCategory
            }
        }
        
        // 2. Generate Random Reminders
        let titles = ["提交周报", "买牛奶", "预约牙医", "学习 SwiftData", "健身", "给妈妈打电话", "整理桌面", "阅读一本书", "Code Review", "写文档"]
        let priorities: [Priority] = [.low, .medium, .high]
        
        let now = Date()
        let calendar = Calendar.current
        
        for _ in 0..<10 {
            let title = titles.randomElement()!
            let category = categoryMap.values.randomElement()
            let priority = priorities.randomElement()!
            
            // Random date: mostly around now
            let dayOffset = Int.random(in: -5...10)
            let hourOffset = Int.random(in: 0...23)
            let date = calendar.date(byAdding: .day, value: dayOffset, to: now)!
            let dueDate = calendar.date(byAdding: .hour, value: hourOffset, to: date)!
            
            let reminder = Reminder(
                title: title,
                notes: "这是自动生成的测试数据\nID: \(UUID().uuidString.prefix(8))",
                dueDate: dueDate,
                priority: priority,
                category: category
            )
            
            // Randomly complete some past reminders
            if dayOffset < 0 && Bool.random() {
                reminder.isCompleted = true

            }
            
            context.insert(reminder)
        }
        
        // 3. Generate Random Notes
        let noteTitles = ["会议记录", "购物清单", "灵感闪现", "待办事项"]
        for _ in 0..<3 {
            let title = noteTitles.randomElement()!
            let note = Note(
                title: title,
                content: "这是自动生成的测试便签内容。\nMock Data \nTime: \(Date())",
                color: ["#FFD60A", "#4ECDC4", "#FF6B6B"].randomElement() ?? "#FFD60A",
                isPinned: Bool.random()
            )
            context.insert(note)
        }
        
        do {
            try context.save()
            // Refresh UI
            fetchReminders()
            fetchCategories()
            fetchNotes()
            print("✅ Mock Data Generated Successfully")
        } catch {
            print("❌ Failed to save mock data: \(error)")
        }
    }
}
#endif
