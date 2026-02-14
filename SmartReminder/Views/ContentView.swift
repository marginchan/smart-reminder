import SwiftUI
import SwiftData

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
        .preferredColorScheme(appTheme.colorScheme)
    }
}

struct CalendarWeekView: View {
    @ObservedObject var store: ReminderStore
    @State private var expandedDates: Set<Date> = []
    @State private var showingMonthCalendar = false
    
    init(store: ReminderStore) {
        self.store = store
        let today = Calendar.current.startOfDay(for: Date())
        self._expandedDates = State(initialValue: [today])
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) {
                        DaySectionView(date: date, store: store, isExpanded: binding(for: date))
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .background(Color.appSystemBackground)
        .navigationTitle("未来7天")
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
    }
    
    private func binding(for date: Date) -> Binding<Bool> {
        let startOfDay = Calendar.current.startOfDay(for: date)
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
}

struct DaySectionView: View {
    let date: Date
    @ObservedObject var store: ReminderStore
    @Binding var isExpanded: Bool
    
    var reminders: [Reminder] {
        store.reminders.filter {
            Calendar.current.isDate($0.dueDate, inSameDayAs: date) && !$0.isCompleted
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: { withAnimation(.spring()) { isExpanded.toggle() } }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatWeekday(date))
                            .font(.headline)
                            .foregroundColor(isToday ? .blue : .primary)
                        Text(formatDate(date))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !reminders.isEmpty {
                        Text("\(reminders.count) 个待办")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    } else {
                        Text("无待办")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .background(Color.appSecondarySystemBackground)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                if reminders.isEmpty {
                    Text("享受美好的一天！")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                        .transition(.opacity)
                } else {
                    VStack(spacing: 12) {
                        ForEach(reminders) { reminder in
                            ReminderRowView(reminder: reminder, store: store)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
            }
        }
    }
    
    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
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
    @State private var isActive = false
    @State private var opacity = 0.5
    @State private var scale = 0.8
    @State private var shimmerPhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            if isActive {
                ContentView()
            } else {
                VStack(spacing: 20) {
                    NiumaLogoView(size: 150)
                        .scaleEffect(scale)
                    
                    VStack(spacing: 8) {
                        // 带光影效果的标题
                        Text("牛马提醒")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .background(
                                GeometryReader { geometry in
                                    // 光影层
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: .clear, location: 0),
                                            .init(color: .white.opacity(0.7), location: 0.5),
                                            .init(color: .clear, location: 1)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(width: geometry.size.width * 0.3)
                                    .offset(x: -geometry.size.width * 0.3 + CGFloat(shimmerPhase) * geometry.size.width * 1.6)
                                    .mask(
                                        Text("牛马提醒")
                                            .font(.system(size: 40, weight: .bold, design: .rounded))
                                    )
                                }
                            )
                        
                        Text("打工人自己的第二大脑")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .tracking(4)
                    }
                }
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.opacity = 1.0
                        self.scale = 1.0
                    }
                    
                    // 光影从左到右动画
                    withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                        shimmerPhase = 1.0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { self.isActive = true }
                    }
                }
            }
        }
    }
}



struct SettingsView: View {
    @ObservedObject var store: ReminderStore
    @AppStorage("showCompleted") private var showCompleted = true
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @AppStorage("remindersEnabled") private var remindersEnabled = true
    @AppStorage("remindersPausedUntil") private var remindersPausedUntil: Double = 0
    
    var isPaused: Bool {
        !remindersEnabled && Date().timeIntervalSince1970 < remindersPausedUntil
    }
    
    var body: some View {
        Form {
            Section(header: Text("提醒设置")) {
                Toggle(remindersEnabled ? "提醒已开启" : "提醒已暂停", isOn: $remindersEnabled)
                    .tint(.green)
                    .onChange(of: remindersEnabled) { newValue in
                        if !newValue {
                            remindersPausedUntil = Date().addingTimeInterval(7 * 24 * 3600).timeIntervalSince1970
                        } else {
                            remindersPausedUntil = 0
                        }
                    }
                
                if remindersEnabled {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("开启中")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "clock.badge.exclamationmark")
                                .foregroundColor(.secondary)
                            Text("已暂停至 \(formattedPausedTime)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
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
            
            Section(header: Text("显示选项")) {
                Toggle("显示已完成提醒", isOn: $showCompleted)
                    .onChange(of: showCompleted) {
                        store.showCompleted = showCompleted
                    }
                
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
            }
        }
        .navigationTitle("设置")
        .onAppear { store.showCompleted = showCompleted }
    }
    
    private var formattedPausedTime: String {
        let date = Date(timeIntervalSince1970: remindersPausedUntil)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func pauseButton(label: String, hours: Int) -> some View {
        Button(action: {
            #if canImport(UIKit)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            #endif
            withAnimation {
                remindersPausedUntil = Date().addingTimeInterval(Double(hours) * 3600).timeIntervalSince1970
            }
        }) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.appTertiarySystemFill)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CalendarMonthView: View {
    @ObservedObject var store: ReminderStore
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedMonth = Date()
    @State private var selectedDayReminders: [Reminder] = []
    @State private var selectedDate: Date? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                TabView(selection: $selectedMonth) {
                    ForEach(-12...12, id: \.self) { monthOffset in
                        if let monthDate = Calendar.current.date(byAdding: .month, value: monthOffset, to: Date()) {
                            MonthGridView(date: monthDate, store: store, selectedDate: selectedDate) { day in
                                selectDay(day)
                            }
                            .tag(monthDate)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 350)
                
                Divider()
                
                ScrollView {
                    VStack(spacing: 12) {
                        if let date = selectedDate {
                            HStack {
                                Text(formatDetailDate(date))
                                    .font(.headline)
                                Spacer()
                                if selectedDayReminders.isEmpty {
                                    Text("无提醒").font(.subheadline).foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top)
                            
                            ForEach(selectedDayReminders) { reminder in
                                ReminderRowView(reminder: reminder, store: store)
                                    .padding(.horizontal)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
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
                }
            }
        .background(Color.appSystemBackground)

            .navigationTitle(formatMonthYear(selectedMonth))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
    
    private func selectDay(_ date: Date) {
        withAnimation {
            selectedDate = date
            selectedDayReminders = store.reminders.filter { Calendar.current.isDate($0.dueDate, inSameDayAs: date) }
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
        
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<startOffset, id: \.self) { _ in
                Text("").frame(height: 45)
            }
            
            ForEach(days, id: \.self) { day in
                let isSelected = selectedDate != nil && Calendar.current.isDate(day, inSameDayAs: selectedDate!)
                DayCell(date: day, store: store, isSelected: isSelected)
                    .onTapGesture { onSelect(day) }
            }
        }
        .padding(.horizontal)
    }
    
    private func getStartOffset(for date: Date) -> Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let weekday = calendar.component(.weekday, from: startOfMonth)
        return (weekday + 5) % 7
    }
}

struct DayCell: View {
    let date: Date
    @ObservedObject var store: ReminderStore
    let isSelected: Bool
    
    var remindersCount: Int {
        store.reminders.filter { Calendar.current.isDate($0.dueDate, inSameDayAs: date) && !$0.isCompleted }.count
    }
    
    var isToday: Bool { Calendar.current.isDateInToday(date) }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.body)
                .fontWeight(isToday || isSelected ? .bold : .regular)
                .foregroundColor(isToday ? .white : (isSelected ? .blue : .primary))
                .frame(width: 35, height: 35)
                .background(isToday ? Color.blue : (isSelected ? Color.blue.opacity(0.15) : Color.clear))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                )
            
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
        .frame(height: 50)
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



