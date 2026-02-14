//
//  AddReminderView.swift
//  SmartReminder
//

import SwiftUI

struct AddReminderView: View {
    @ObservedObject var store: ReminderStore
    @Binding var isPresented: Bool
    
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date()
    @State private var priority: Priority = .medium
    @State private var selectedCategory: ReminderCategory?
    @State private var repeatFrequency: RepeatFrequency = .never
    
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
                    DatePicker(
                        "提醒时间",
                        selection: $dueDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    
                    Picker("重复", selection: $repeatFrequency) {
                        ForEach(RepeatFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                }
                
                Section(header: Text("优先级")) {
                    Picker("优先级", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(Color.fromHex( priority.color))
                                    .frame(width: 10, height: 10)
                                Text(priority.title)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("分类")) {
                    if store.categories.isEmpty {
                        Text("暂无分类")
                            .foregroundColor(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                CategoryChip(
                                    name: "无",
                                    color: "#8E8E93",
                                    icon: "xmark.circle.fill",
                                    isSelected: selectedCategory == nil
                                ) {
                                    selectedCategory = nil
                                }
                                
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
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationTitle("新建提醒")
            .navigationBarTitleDisplayMode(.inline)
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
                    DatePicker(
                        "提醒时间",
                        selection: $dueDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    
                    Picker("重复", selection: $repeatFrequency) {
                        ForEach(RepeatFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                }
                
                Section(header: Text("优先级")) {
                    Picker("优先级", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(Color.fromHex( priority.color))
                                    .frame(width: 10, height: 10)
                                Text(priority.title)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("分类")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryChip(
                                name: "无",
                                color: "#8E8E93",
                                icon: "xmark.circle.fill",
                                isSelected: selectedCategory == nil
                            ) {
                                selectedCategory = nil
                            }
                            
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
            .background(isSelected ? Color.fromHex( color) : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
