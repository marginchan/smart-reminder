//
//  AddReminderView.swift
//  SmartReminder
//

import SwiftUI

struct AddReminderView: View {
    @ObservedObject var store: ReminderStore
    @Binding var isPresented: Bool
    var initialDate: Date? = nil
    
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate: Date
    @State private var priority: Priority = .medium
    @State private var selectedCategory: ReminderCategory?
    @State private var repeatFrequency: RepeatFrequency = .never
    @State private var showingAddCategory = false
    @State private var showingDatePicker = false
    
    init(store: ReminderStore, isPresented: Binding<Bool>, initialDate: Date? = nil) {
        self.store = store
        self._isPresented = isPresented
        self.initialDate = initialDate
        self._dueDate = State(initialValue: initialDate ?? Date())
    }
    
    private var isValid: Bool {
        !title.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("标题", text: $title)
                    
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("备注（可选）")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                    }
                }
                
                Section(header: Text("时间")) {
                    Button {
                        showingDatePicker = true
                    } label: {
                        HStack {
                            Text("提醒时间")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(formatDate(dueDate))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Picker("重复", selection: $repeatFrequency) {
                        ForEach(RepeatFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                }
                
                Section(header: Text("优先级")) {
                    HStack(spacing: 12) {
                        ForEach(Priority.allCases, id: \.self) { p in
                            Button(action: { priority = p }) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.fromHex(p.color))
                                        .frame(width: 10, height: 10)
                                    Text(p.title)
                                        .font(.subheadline)
                                        .fontWeight(priority == p ? .semibold : .regular)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(priority == p ? Color.fromHex(p.color).opacity(0.15) : Color.gray.opacity(0.1))
                                .foregroundColor(priority == p ? Color.fromHex(p.color) : .secondary)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(priority == p ? Color.fromHex(p.color) : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Section(header: Text("分类")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {

                            // 分类列表
                            ForEach(store.categories, id: \.id) { category in
                                CategoryChip(
                                    name: category.name,
                                    color: category.color,
                                    icon: category.icon,
                                    isSelected: selectedCategory?.id == category.id
                                ) {
                                    selectedCategory = category
                                }
                            }
                            
                            // 添加分类按钮
                            Button(action: { showingAddCategory = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("新建提醒")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddCategory) {
                AddCategorySheet(store: store, selectedCategory: $selectedCategory)
            }
            .sheet(isPresented: $showingDatePicker) {
                CustomDatePickerSheet(date: $dueDate)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveReminder()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .onAppear {
            if let initialDate = initialDate {
                dueDate = initialDate
            }
            applyDefaultCategory()
        }
        .onChange(of: store.categories) { oldValue, newValue in
            applyDefaultCategory()
        }
    }
    
    private func saveReminder() {
        let reminder = Reminder(
            title: title,
            notes: notes,
            dueDate: dueDate,
            priority: priority,
            category: selectedCategory,
            repeatFrequency: repeatFrequency
        )
        store.addReminder(reminder)
        isPresented = false
    }
    
    private func applyDefaultCategory() {
        if selectedCategory == nil {
            selectedCategory = store.categories.first { $0.name == "默认" }
        }
    }
    
    private func parseTitle() {
        let parsed = store.parseNaturalLanguage(title)
        
        if let date = parsed.dueDate {
            withAnimation {
                dueDate = date
            }
        }
        
        withAnimation {
            priority = parsed.priority
            repeatFrequency = parsed.repeatFrequency
        }
    }
}

struct EditReminderView: View {
    var reminder: Reminder
    @ObservedObject var store: ReminderStore
    @Binding var isPresented: Bool
    
    @State private var title: String
    @State private var notes: String
    @State private var dueDate: Date
    @State private var priority: Priority
    @State private var selectedCategory: ReminderCategory?
    @State private var repeatFrequency: RepeatFrequency
    @State private var showingAddCategory = false
    @State private var showingDatePicker = false
    
    init(reminder: Reminder, store: ReminderStore, isPresented: Binding<Bool>) {
        self.reminder = reminder
        self.store = store
        self._isPresented = isPresented
        self._title = State(initialValue: reminder.title)
        self._notes = State(initialValue: reminder.notes)
        self._dueDate = State(initialValue: reminder.dueDate)
        self._priority = State(initialValue: reminder.priority)
        self._selectedCategory = State(initialValue: reminder.category)
        self._repeatFrequency = State(initialValue: reminder.repeatFrequency)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("标题", text: $title)
                    
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("备注（可选）")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                    }
                }
                
                Section(header: Text("时间")) {
                    Button {
                        showingDatePicker = true
                    } label: {
                        HStack {
                            Text("提醒时间")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(formatDate(dueDate))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Picker("重复", selection: $repeatFrequency) {
                        ForEach(RepeatFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                }
                
                Section(header: Text("优先级")) {
                    HStack(spacing: 12) {
                        ForEach(Priority.allCases, id: \.self) { p in
                            Button(action: { priority = p }) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.fromHex(p.color))
                                        .frame(width: 10, height: 10)
                                    Text(p.title)
                                        .font(.subheadline)
                                        .fontWeight(priority == p ? .semibold : .regular)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(priority == p ? Color.fromHex(p.color).opacity(0.15) : Color.gray.opacity(0.1))
                                .foregroundColor(priority == p ? Color.fromHex(p.color) : .secondary)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(priority == p ? Color.fromHex(p.color) : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Section(header: Text("分类")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // 分类列表
                            ForEach(store.categories, id: \.id) { category in
                                CategoryChip(
                                    name: category.name,
                                    color: category.color,
                                    icon: category.icon,
                                    isSelected: selectedCategory?.id == category.id
                                ) {
                                    selectedCategory = category
                                }
                            }
                            
                            // 添加分类按钮
                            Button(action: { showingAddCategory = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        store.deleteReminder(reminder)
                        isPresented = false
                    } label: {
                        HStack {
                            Spacer()
                            Text("删除提醒")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("编辑提醒")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddCategory) {
                AddCategorySheet(store: store, selectedCategory: $selectedCategory)
            }
            .sheet(isPresented: $showingDatePicker) {
                CustomDatePickerSheet(date: $dueDate)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        updateReminder()
                    }
                }
            }
        }
    }
    
    private func updateReminder() {
        reminder.title = title
        reminder.notes = notes
        reminder.dueDate = dueDate
        reminder.priority = priority
        reminder.category = selectedCategory
        reminder.repeatFrequency = repeatFrequency
        store.updateReminder(reminder)
        isPresented = false
    }
}

struct CategoryChip: View {
    let name: String
    let color: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.fromHex(color) : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 新建分类弹窗
struct AddCategorySheet: View {
    @ObservedObject var store: ReminderStore
    @Binding var selectedCategory: ReminderCategory?
    @Environment(\.dismiss) var dismiss
    
    @State private var newCategoryName = ""
    @State private var selectedColor = "#007AFF"
    @State private var selectedIcon = "folder.fill"
    
    let availableColors = [
        "#007AFF", "#34C759", "#FF9500", "#FF3B30",
        "#5856D6", "#AF52DE", "#FF2D55", "#5AC8FA",
        "#FFCC00", "#8E8E93"
    ]
    
    let availableIcons = [
        "folder.fill", "briefcase.fill", "person.fill", "cart.fill",
        "heart.fill", "book.fill", "star.fill", "flag.fill",
        "tag.fill", "bell.fill", "calendar", "house.fill",
        "car.fill", "airplane", "gift.fill", "creditcard.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("名称")) {
                    TextField("分类名称", text: $newCategoryName)
                }
                
                Section(header: Text("颜色")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Circle()
                                .fill(Color.fromHex(color))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("图标")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .foregroundColor(selectedIcon == icon ? .blue : .primary)
                                .cornerRadius(8)
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("新建分类")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium, .large])
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        addCategory()
                    }
                    .disabled(newCategoryName.isEmpty)
                }
            }
        }
    }
    
    private func addCategory() {
        let category = ReminderCategory(
            name: newCategoryName,
            color: selectedColor,
            icon: selectedIcon
        )
        store.addCategory(category)
        selectedCategory = category
        dismiss()
    }
}

fileprivate func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy年M月d日 HH:mm"
    return formatter.string(from: date)
}

#if canImport(UIKit)
import UIKit
#endif

struct CustomDatePickerSheet: View {
    @Binding var date: Date
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var selectedDay: Int
    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    
    private let calendar = Calendar.current
    private let years = Array(2024...2035)
    private let months = Array(1...12)
    private let hours = Array(0...23)
    private let minutes = Array(0...59)
    
    init(date: Binding<Date>) {
        self._date = date
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date.wrappedValue)
        
        self._selectedYear = State(initialValue: components.year ?? 2024)
        self._selectedMonth = State(initialValue: components.month ?? 1)
        self._selectedDay = State(initialValue: components.day ?? 1)
        self._selectedHour = State(initialValue: components.hour ?? 12)
        self._selectedMinute = State(initialValue: components.minute ?? 0)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("取消") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text("选择时间")
                    .font(.headline)
                
                Spacer()
                
                Button("确定") {
                    saveDate()
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundColor(.blue)
            }
            .padding()
            #if canImport(UIKit)
            .background(Color(UIColor.secondarySystemBackground))
            #else
            .background(Color.gray.opacity(0.1))
            #endif
            
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Picker("Year", selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text("\(String(format: "%02d", year % 100))年").tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: geometry.size.width * 0.19)
                    .clipped()
                    
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(months, id: \.self) { month in
                            Text("\(month)月").tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: geometry.size.width * 0.19)
                    .clipped()
                    
                    Picker("Day", selection: $selectedDay) {
                        ForEach(daysInMonth, id: \.self) { day in
                            Text("\(day)日").tag(day)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: geometry.size.width * 0.19)
                    .clipped()
                    
                    Picker("Hour", selection: $selectedHour) {
                        ForEach(hours, id: \.self) { hour in
                            Text("\(hour)时").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: geometry.size.width * 0.19)
                    .clipped()
                    
                    Picker("Minute", selection: $selectedMinute) {
                        ForEach(minutes, id: \.self) { minute in
                            Text("\(String(format: "%02d", minute))分").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: geometry.size.width * 0.19)
                    .clipped()
                }
            }
            .frame(height: 200)
            .padding(.vertical)
        }
        #if canImport(UIKit)
        .background(Color(UIColor.systemBackground))
        #else
        .background(Color.white)
        #endif
        .presentationDetents([.height(300)])
        .onChange(of: selectedMonth) { oldValue, newValue in adjustDaySelection() }
        .onChange(of: selectedYear) { oldValue, newValue in adjustDaySelection() }
    }
    
    private var daysInMonth: [Int] {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = 1
        
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return Array(1...30)
        }
        return Array(range)
    }
    
    private func adjustDaySelection() {
        let count = daysInMonth.count
        if selectedDay > count {
            selectedDay = count
        }
    }
    
    private func saveDate() {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = selectedDay
        components.hour = selectedHour
        components.minute = selectedMinute
        
        if let newDate = calendar.date(from: components) {
            date = newDate
        }
    }
}
