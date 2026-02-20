import SwiftUI
import SwiftData
import UserNotifications

#if canImport(UIKit)
import UIKit
#endif

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "跟随系统"
    case light = "浅色模式"
    case dark = "深色模式"
    
    var id: String { self.rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) private var modelContext
    @StateObject private var store = ReminderStore()
    @State private var showingAddReminder = false
    @State private var selectedTab = 0
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ReminderListView(store: store)
            }
            .tabItem {
                Label("提醒", systemImage: "bell.fill")
            }
            .tag(0)
            
            NavigationStack {
                CalendarWeekView(store: store)
            }
            .tabItem {
                Label("日历", systemImage: "calendar")
            }
            .tag(1)
            
            NavigationStack {
                NotesView(store: store)
            }
            .tabItem {
                Label("便签", systemImage: "note.text")
            }
            .tag(2)
            
            NavigationStack {
                SettingsView(store: store)
            }
            .tabItem {
                Label("设置", systemImage: "gear")
            }
            .tag(3)
        }
        .onAppear {
            store.setupModelContext(modelContext)
        }
        .onChange(of: scenePhase) { oldValue, newValue in
            if newValue == .active {
                // 延迟刷新，避免阻塞 UI
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    store.refreshForTab(selectedTab)
                }
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // 先完成切换动画，再局部刷新目标页面数据
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                store.refreshForTab(newValue)
            }
        }
        .preferredColorScheme(appTheme.colorScheme)
    }
}

struct CalendarWeekView: View {
    @ObservedObject var store: ReminderStore
    @State private var expandedDates: Set<Date> = []
    @State private var showingMonthCalendar = false
    @State private var showingAddReminder = false
    @State private var selectedDateForAdd: Date? = nil
    @State private var visibleDates: [Date] = []
    @State private var isLoadingMore = false
    @State private var hasMoreDays = true
    @State private var showScrollToTop = false
    
    private let calendar = Calendar.current
    private let topAnchorID = "calendarTopAnchor"
    private let prefetchThreshold = 5  // 距离底部还有 5 个时开始预加载
    
    init(store: ReminderStore) {
        self.store = store
        let today = Calendar.current.startOfDay(for: Date())
        self._expandedDates = State(initialValue: [])
        self._visibleDates = State(initialValue: CalendarWeekView.makeDates(from: today, days: 30))
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Color.clear
                    .frame(height: 1)
                    .id(topAnchorID)
                
                LazyVStack(spacing: 20) {
                    ForEach(Array(visibleDates.enumerated()), id: \.element) { index, date in
                        DaySectionView(
                            date: date,
                            store: store,
                            isExpanded: binding(for: date),
                            showingAddReminder: $showingAddReminder,
                            selectedDateForAdd: $selectedDateForAdd
                        )
                        .onAppear {
                            // 提前预加载：距离底部还有 prefetchThreshold 个时触发
                            if index >= visibleDates.count - prefetchThreshold {
                                loadMoreDays()
                            }
                            // 第一个日期回到可视区域时隐藏按钮
                            if index == 0 {
                                withAnimation { showScrollToTop = false }
                            }
                        }
                        .onDisappear {
                            // 第一个日期离开可视区域时显示按钮
                            if index == 0 {
                                withAnimation { showScrollToTop = true }
                            }
                        }
                    }
                    
                    // 底部加载指示器
                    if hasMoreDays {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(.secondary)
                            Text("加载更多...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .onAppear { loadMoreDays() }
                    }
                }
                .padding()
                .padding(.bottom, 80)
            }
            .background(Color.appSystemBackground)
            .overlay(alignment: .bottomTrailing) {
                if showScrollToTop {
                    Button {
                        withAnimation {
                            proxy.scrollTo(topAnchorID, anchor: .top)
                        }
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("日历")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingMonthCalendar = true }) {
                    Image(systemName: "calendar")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showingMonthCalendar) {
            CalendarMonthView(store: store)
        }
        .sheet(isPresented: $showingAddReminder) {
            AddReminderView(store: store, isPresented: $showingAddReminder, initialDate: selectedDateForAdd)
        }
    }
    
    private func binding(for date: Date) -> Binding<Bool> {
        let startOfDay = calendar.startOfDay(for: date)
        return Binding(
            get: { expandedDates.contains(startOfDay) },
            set: { isExpanded in
                if isExpanded {
                    expandedDates.insert(startOfDay)
                } else {
                    expandedDates.remove(startOfDay)
                }
            }
        )
    }
    
    private static func makeDates(from start: Date, days: Int) -> [Date] {
        guard days > 0 else { return [] }
        let calendar = Calendar.current
        return (0..<days).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
    
    private func loadMoreDays() {
        guard !isLoadingMore, hasMoreDays else { return }
        guard let lastDate = visibleDates.last else { return }
        let maxDate = calendar.date(byAdding: .year, value: 1, to: calendar.startOfDay(for: Date())) ?? lastDate
        let nextDate = calendar.date(byAdding: .day, value: 1, to: lastDate) ?? lastDate
        guard nextDate <= maxDate else {
            hasMoreDays = false
            return
        }
        
        isLoadingMore = true
        let remainingDays = calendar.dateComponents([.day], from: nextDate, to: maxDate).day ?? 0
        let batch = min(30, remainingDays + 1)
        let more = CalendarWeekView.makeDates(from: nextDate, days: batch)
        
        // 微延迟让 UI 有喘息空间
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            visibleDates.append(contentsOf: more)
            isLoadingMore = false
            if batch >= remainingDays + 1 {
                hasMoreDays = false
            }
        }
    }
}

struct DaySectionView: View {
    let date: Date
    @ObservedObject var store: ReminderStore
    @Binding var isExpanded: Bool
    @Binding var showingAddReminder: Bool
    @Binding var selectedDateForAdd: Date?
    
    @State private var reminderToDelete: Reminder?
    @State private var showingDeleteAlert = false
    
    var reminders: [Reminder] {
        store.remindersForDate(date)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: { withAnimation(.spring()) { isExpanded.toggle() } }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatWeekday(date))
                            .font(.headline)
                            .foregroundColor(isToday ? .blue : .primary)
                        HStack(spacing: 6) {
                            Text(formatDate(date))
                                .font(.callout)
                                .foregroundColor(.secondary)
                            if let festival = lunarInfo.festival {
                                Text(festival)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Color.red.opacity(0.9))
                                    .clipShape(Capsule())
                            } else {
                                Text(lunarInfo.lunarText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if !reminders.isEmpty {
                        Text("\(reminders.count) 个提醒")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    } else {
                        Text("无提醒")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.appSecondarySystemBackground)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                HStack {
                    Spacer()
                    Button(action: {
                        selectedDateForAdd = date
                        showingAddReminder = true
                    }) {
                        Label("添加提醒", systemImage: "plus")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 4)
                
                if reminders.isEmpty {
                    Text("享受美好的一天！")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                        .transition(.opacity)
                } else {
                    List {
                        ForEach(reminders) { reminder in
                            ReminderRowView(reminder: reminder, store: store)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button { reminderToDelete = reminder; showingDeleteAlert = true } label: {
                                        Label("删除", systemImage: "trash")
                                    }.tint(.red)
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button { withAnimation(.easeOut(duration: 0.3)) { store.toggleComplete(reminder) } } label: {
                                        Label("完成", systemImage: "checkmark")
                                    }.tint(.green)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollDisabled(true)
                    .frame(height: CGFloat(reminders.count) * 84)
                }
            }
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            if let reminder = reminderToDelete, reminder.repeatFrequency != .never {
                Button("仅删除本次", role: .destructive) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        store.deleteReminder(reminder, deleteFuture: false)
                    }
                    reminderToDelete = nil
                }
                Button("删除整个系列", role: .destructive) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        store.deleteReminder(reminder, deleteFuture: true)
                    }
                    reminderToDelete = nil
                }
                Button("取消", role: .cancel) { reminderToDelete = nil }
            } else {
                Button("取消", role: .cancel) { reminderToDelete = nil }
                Button("删除", role: .destructive) {
                    if let reminder = reminderToDelete {
                        withAnimation(.easeOut(duration: 0.3)) {
                            store.deleteReminder(reminder)
                        }
                    }
                    reminderToDelete = nil
                }
            }
        } message: {
            if let reminder = reminderToDelete, reminder.repeatFrequency != .never {
                Text("这是一个重复提醒。「仅删除本次」将保留其他日期的提醒，而「删除整个系列」将永久删除所有相关提醒。")
            } else {
                Text("确定要删除「\(reminderToDelete?.title ?? "")」吗？此操作无法撤销。")
            }
        }
    }
    
    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    
    private var lunarInfo: LunarFestivalInfo {
        LunarFestivalService.shared.info(for: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
    
    private func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE"
        if isToday { return "今天" }
        return formatter.string(from: date)
    }
}

struct LaunchScreenView: View {
    var body: some View {
        ContentView()
    }
}

// 后续会使用请不要删除
/*
struct LaunchScreenView_Legacy: View {
    @State private var isActive = false
    @State private var opacity = 0.5
    @State private var scale = 0.8
    @State private var shimmerPosition: CGFloat = -0.5
    
    var body: some View {
        ZStack {
            if isActive {
                ContentView()
            } else {
                VStack(spacing: 24) {
                    NiumaLogoView(size: 150)
                        .scaleEffect(scale)
                    
                    VStack(spacing: 12) {
                        // 带光影效果的标题
                        ZStack {
                            // 底层文字
                            Text("牛马提醒")
                                .font(.system(size: 42, weight: .heavy, design: .rounded))
                                .foregroundColor(.primary)
                            
                            // 光影层 - 更明显的效果
                            Text("牛马提醒")
                                .font(.system(size: 42, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .mask(
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                stops: [
                                                    .init(color: .clear, location: 0),
                                                    .init(color: .clear, location: 0.3),
                                                    .init(color: .white, location: 0.5),
                                                    .init(color: .clear, location: 0.7),
                                                    .init(color: .clear, location: 1)
                                                ],
                                                startPoint: UnitPoint(x: 0, y: 0.5),
                                                endPoint: UnitPoint(x: 1, y: 0.5)
                                            )
                                        )
                                        .rotationEffect(.degrees(20))
                                        .frame(width: 150, height: 80)
                                        .offset(x: shimmerPosition * 200, y: 0)
                                )
                                .blendMode(.hardLight)
                        }
                        
                        ZStack {
                            Text("打工人的智能助手")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .tracking(3)
                            
                            Text("打工人的智能助手")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .tracking(3)
                                .mask(
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                stops: [
                                                    .init(color: .clear, location: 0),
                                                    .init(color: .clear, location: 0.3),
                                                    .init(color: .white, location: 0.5),
                                                    .init(color: .clear, location: 0.7),
                                                    .init(color: .clear, location: 1)
                                                ],
                                                startPoint: UnitPoint(x: 0, y: 0.5),
                                                endPoint: UnitPoint(x: 1, y: 0.5)
                                            )
                                        )
                                        .rotationEffect(.degrees(20))
                                        .frame(width: 140, height: 40)
                                        .offset(x: shimmerPosition * 160, y: 0)
                                )
                                .blendMode(.hardLight)
                        }
                    }
                }
                .opacity(opacity)
                .onAppear {
                    // 图标缩放动画
                    withAnimation(.easeIn(duration: 1.0)) {
                        self.opacity = 1.0
                        self.scale = 1.0
                    }
                    
                    // 光影从左到右扫过
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            shimmerPosition = 2.0
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation { self.isActive = true }
                    }
                }
            }
        }
    }
}
*/



struct SettingsView: View {
    @ObservedObject var store: ReminderStore

    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @AppStorage("remindersEnabled") private var remindersEnabled = true
    @AppStorage("remindersPausedUntil") private var remindersPausedUntil: Double = 0
    @State private var notificationStatus: String = "检查中..."
    
    var isPaused: Bool {
        !remindersEnabled && Date().timeIntervalSince1970 < remindersPausedUntil
    }
    
    var body: some View {
        Form {
            Section(header: Text("提醒设置")) {
                Toggle(remindersEnabled ? "提醒已开启" : "提醒已暂停", isOn: $remindersEnabled)
                    .tint(.green)
                    .onChange(of: remindersEnabled) { oldValue, newValue in
                        if !newValue {
                            remindersPausedUntil = Date().addingTimeInterval(7 * 24 * 3600).timeIntervalSince1970
                            // 实际取消所有待发送的通知
                            NotificationManager.shared.cancelAllNotifications()
                            NotificationManager.shared.clearBadge()
                        } else {
                            remindersPausedUntil = 0
                            // 重新调度所有未完成提醒的通知
                            store.rescheduleAllNotifications()
                        }
                    }
                
                if remindersEnabled {
                    // 开启状态下不显示额外文字/图标
                } else {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "clock.badge.exclamationmark")
                                .foregroundColor(.secondary)
                            Text("已暂停至 \(formattedPausedTime)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .contentTransition(.numericText())
                                .animation(.default, value: remindersPausedUntil)
                        }
                        
                        HStack(spacing: 12) {
                            pauseButton(label: "1小时", hours: 1)
                            pauseButton(label: "4小时", hours: 4)
                            pauseButton(label: "1天", hours: 24)
                            pauseButton(label: "7天", hours: 168)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section(header: Text("通知状态")) {
                HStack {
                    Image(systemName: notificationStatus == "已授权" ? "bell.badge.fill" : "bell.slash.fill")
                        .foregroundColor(notificationStatus == "已授权" ? .green : .red)
                    Text("通知权限")
                    Spacer()
                    Text(notificationStatus)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("显示选项")) {
                Picker("主题模式", selection: $appTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
            }
            
            Section(header: Text("关于")) {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0").foregroundColor(.secondary)
                }
                
                Link(destination: URL(string: "https://example.com/privacy")!) {
                    HStack {
                        Text("隐私政策")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            #if targetEnvironment(simulator)
            Section(header: Text("开发工具")) {
                Button {
                    store.generateMockData()
                } label: {
                    Label("生成测试数据", systemImage: "hammer.fill")
                        .foregroundColor(.purple)
                }
            }
            #endif
        }
        .navigationTitle("设置")
        .onAppear {
            checkNotificationStatus()
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    notificationStatus = "已授权"
                case .denied:
                    notificationStatus = "已拒绝"
                case .notDetermined:
                    notificationStatus = "未设置"
                case .provisional:
                    notificationStatus = "临时授权"
                @unknown default:
                    notificationStatus = "未知"
                }
            }
        }
    }
    
    private var formattedPausedTime: String {
        let date = Date(timeIntervalSince1970: remindersPausedUntil)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func pauseButton(label: String, hours: Int) -> some View {
        PauseButtonView(label: label) {
            #if canImport(UIKit)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            #endif
            withAnimation {
                remindersPausedUntil = Date().addingTimeInterval(Double(hours) * 3600).timeIntervalSince1970
            }
        }
    }
}

/// 独立按钮视图，使用手势手动追踪按压状态，避免 Form 拦截 ButtonStyle
struct PauseButtonView: View {
    let label: String
    let action: () -> Void
    
    @GestureState private var isPressed = false
    
    var body: some View {
        Text(label)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.primary)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isPressed ? Color.secondary.opacity(0.3) : Color.appTertiarySystemFill)
            .cornerRadius(8)
            .scaleEffect(isPressed ? 0.93 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
                    .onEnded { _ in
                        action()
                    }
            )
    }
}

struct CalendarMonthView: View {
    @ObservedObject var store: ReminderStore
    @Environment(\.dismiss) var dismiss
    
    private let calendar = Calendar.current
    @State private var baseMonth: Date
    @State private var selectedMonth: Date
    @State private var selectedDayReminders: [Reminder] = []
    @State private var selectedDate: Date? = nil
    @State private var showingAddReminder = false
    @State private var showScrollToTop = false
    @State private var reminderToDelete: Reminder?
    @State private var showingDeleteAlert = false
    
    init(store: ReminderStore) {
        self.store = store
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
        _baseMonth = State(initialValue: startOfMonth)
        _selectedMonth = State(initialValue: startOfMonth)
    }
    
    private var minMonth: Date {
        calendar.date(byAdding: .month, value: -12, to: baseMonth) ?? baseMonth
    }
    
    private var maxMonth: Date {
        calendar.date(byAdding: .month, value: 12, to: baseMonth) ?? baseMonth
    }
    
    @ViewBuilder
    private var remindersListView: some View {
                VStack(spacing: 12) {
                            if let date = selectedDate {
                            HStack {
                                Text(formatDetailDate(date))
                                    .font(.headline)
                                Spacer()
                                if selectedDayReminders.isEmpty {
                                    Text("无提醒").font(.subheadline).foregroundColor(.secondary)
                                }
                                // 只有今天或未来日期才显示添加按钮
                                if date >= Calendar.current.startOfDay(for: Date()) {
                                    Button(action: {
                                        showingAddReminder = true
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus.circle.fill")
                                            Text("添加")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top)
                            
                            List {
                                ForEach(selectedDayReminders) { reminder in
                                    ReminderRowView(reminder: reminder, store: store)
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button { reminderToDelete = reminder; showingDeleteAlert = true } label: {
                                                Label("删除", systemImage: "trash")
                                            }.tint(.red)
                                        }
                                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                            Button { withAnimation(.easeOut(duration: 0.3)) { store.toggleComplete(reminder) } } label: {
                                                Label("完成", systemImage: "checkmark")
                                            }.tint(.green)
                                        }
                                }
                            }
                            .listStyle(.plain)
                            .scrollDisabled(true)
                            .frame(height: CGFloat(selectedDayReminders.count) * 84)
                        } else {
                            VStack(spacing: 20) {
                                Spacer().frame(height: 40)
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary.opacity(0.5))
                                Text("选择日期查看详情")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.bottom, 40)
    }

    @ViewBuilder
    private var calendarHeaderAndGrid: some View {
        VStack(spacing: 0) {
                ZStack {
                    Text(formatMonthYear(selectedMonth))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Button {
                            shiftMonth(-1)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 32, height: 32)
                        }
                        
                        Spacer()
                        
                        if selectedMonth != baseMonth {
                            Button {
                                jumpToToday()
                            } label: {
                                Text("回到今天")
                                    .font(.caption2.weight(.medium))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            .padding(.trailing, 4)
                        }
                        
                        Button {
                            shiftMonth(1)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 32, height: 32)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                HStack {
                    ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 6)
                TabView(selection: $selectedMonth) {
                    ForEach(-12...12, id: \.self) { monthOffset in
                        if let monthDate = calendar.date(byAdding: .month, value: monthOffset, to: baseMonth) {
                            let normalized = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) ?? monthDate
                            MonthGridView(date: normalized, store: store, selectedDate: selectedDate) { day in
                                selectDay(day)
                            }
                            .tag(normalized)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: gridHeight(for: selectedMonth))
                .animation(.easeInOut, value: selectedMonth)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 0) {
                calendarHeaderAndGrid

                
                Divider()
                    .padding(.bottom, 8)
                
                remindersListView

                    .id("top")
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("scroll")).minY)
                    })
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    withAnimation {
                        showScrollToTop = value < -50
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if showScrollToTop {
                        Button {
                            withAnimation {
                                scrollProxy.scrollTo("top", anchor: .top)
                            }
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.blue.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            }
        .background(Color.appSystemBackground)

            .navigationTitle("月历")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddReminderView(store: store, isPresented: $showingAddReminder, initialDate: selectedDate)
            }
            .onAppear {
                if selectedDate == nil {
                    selectDay(Date())
                }
            }
            .onChange(of: store.reminders) { oldValue, newValue in
                if let currentSelected = selectedDate {
                    selectedDayReminders = store.remindersForDate(currentSelected)
                }
            }
            .alert("确认删除", isPresented: $showingDeleteAlert) {
                if let reminder = reminderToDelete, reminder.repeatFrequency != .never {
                    Button("仅删除本次", role: .destructive) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            store.deleteReminder(reminder, deleteFuture: false)
                        }
                        reminderToDelete = nil
                    }
                    Button("删除整个系列", role: .destructive) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            store.deleteReminder(reminder, deleteFuture: true)
                        }
                        reminderToDelete = nil
                    }
                    Button("取消", role: .cancel) { reminderToDelete = nil }
                } else {
                    Button("取消", role: .cancel) { reminderToDelete = nil }
                    Button("删除", role: .destructive) {
                        if let reminder = reminderToDelete {
                            withAnimation(.easeOut(duration: 0.3)) {
                                store.deleteReminder(reminder)
                            }
                        }
                        reminderToDelete = nil
                    }
                }
            } message: {
                if let reminder = reminderToDelete, reminder.repeatFrequency != .never {
                    Text("这是一个重复提醒。「仅删除本次」将保留其他日期的提醒，而「删除整个系列」将永久删除所有相关提醒。")
                } else {
                    Text("确定要删除「\(reminderToDelete?.title ?? "")」吗？此操作无法撤销。")
                }
            }
        }
    }
    
    private func selectDay(_ date: Date) {
        withAnimation {
            selectedDate = date
            selectedDayReminders = store.remindersForDate(date)
        }
    }
    
    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: date)
    }
    
    private func formatDetailDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func shiftMonth(_ offset: Int) {
        guard let nextMonth = calendar.date(byAdding: .month, value: offset, to: selectedMonth) else { return }
        let normalized = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth)) ?? nextMonth
        let target: Date
        if isBeforeMin(normalized) {
            target = maxMonth
        } else if isAfterMax(normalized) {
            target = minMonth
        } else {
            target = normalized
        }
        withAnimation {
            selectedMonth = target
        }
    }
    
    private func jumpToToday() {
        let today = Date()
        let normalized = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
        withAnimation {
            selectedMonth = normalized
        }
        selectDay(today)
    }
    
    private func isBeforeMin(_ date: Date) -> Bool {
        calendar.compare(date, to: minMonth, toGranularity: .month) == .orderedAscending
    }
    
    private func isAfterMax(_ date: Date) -> Bool {
        calendar.compare(date, to: maxMonth, toGranularity: .month) == .orderedDescending
    }
    
    private func gridHeight(for date: Date) -> CGFloat {
        let daysCount = date.getAllDaysInMonth().count
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let weekday = calendar.component(.weekday, from: startOfMonth)
        let startOffset = (weekday - 1) % 7
        let rows = Int(ceil(Double(daysCount + startOffset) / 7.0))
        return CGFloat(rows * 65 + max(rows - 1, 0) * 10) + 20
    }
}

struct MonthGridView: View {
    let date: Date
    @ObservedObject var store: ReminderStore
    let selectedDate: Date?
    let onSelect: (Date) -> Void
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        let days = date.getAllDaysInMonth()
        let startOffset = getStartOffset(for: date)
        
        VStack(spacing: 0) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<startOffset, id: \.self) { _ in
                    Color.clear.frame(height: 65)
                }
                
                ForEach(days, id: \.self) { day in
                    let isSelected = selectedDate != nil && Calendar.current.isDate(day, inSameDayAs: selectedDate!)
                    DayCell(date: day, store: store, isSelected: isSelected)
                        .onTapGesture { onSelect(day) }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            Spacer(minLength: 0)
        }
    }
    
    private func getStartOffset(for date: Date) -> Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let weekday = calendar.component(.weekday, from: startOfMonth)
        return (weekday - 1) % 7
    }
}

struct DayCell: View {
    let date: Date
    @ObservedObject var store: ReminderStore
    let isSelected: Bool
    
    var remindersCount: Int {
        store.remindersForDate(date).count
    }
    
    var isToday: Bool { Calendar.current.isDateInToday(date) }
    
    private var lunarInfo: LunarFestivalInfo {
        LunarFestivalService.shared.info(for: date)
    }
    
    private var lunarTextColor: Color {
        lunarInfo.festival == nil ? .secondary : .red
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.body)
                .fontWeight(isToday || isSelected ? .bold : .regular)
                .foregroundColor(isToday ? .white : (isSelected ? .blue : .primary))
                .frame(width: 32, height: 32)
                .background(isToday ? Color.blue : (isSelected ? Color.blue.opacity(0.15) : Color.clear))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                )
            
            if let festival = lunarInfo.festival {
                Text(festival)
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(.red)
                    .lineLimit(1)
            } else {
                Text(lunarInfo.lunarText)
                    .font(.system(size: 9))
                    .foregroundColor(lunarTextColor)
                    .lineLimit(1)
            }
            
            HStack(spacing: 3) {
                if remindersCount > 0 {
                    Text("\(remindersCount)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 12, height: 12)
                        .background(Color.orange)
                        .clipShape(Circle())
                }
            }
            .frame(height: 12)
        }
        .frame(height: 65)
        .contentShape(Rectangle())
    }
}

extension Date {
    func getAllDaysInMonth() -> [Date] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        let startOfMonth = calendar.date(from: components)!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        return range.compactMap { day -> Date? in
            return calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }
}


struct NiumaLogoView: View {
    @Environment(\.colorScheme) var colorScheme
    var size: CGFloat = 200
    
    var body: some View {
        Image("NiumaLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Helper Extensions

// Color extensions are now in Extensions/Color+Hex.swift

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}



