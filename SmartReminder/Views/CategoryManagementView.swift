import SwiftUI

struct CategoryManagementView: View {
    @ObservedObject var store: ReminderStore
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var selectedColor = "#007AFF"
    @State private var selectedIcon = "folder.fill"
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var categoryToDelete: ReminderCategory? = nil
    @State private var showingDeleteAlert = false
    
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
    
    private func remindersCount(for category: ReminderCategory) -> Int {
        store.reminders.filter { $0.category?.id == category.id }.count
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            List {
                Section(header: Text("我的分类")) {
                    if store.categories.isEmpty {
                        ContentUnavailableView {
                            Label("暂无分类", systemImage: "folder.badge.questionmark")
                        } description: {
                            Text("点击右上角添加新分类")
                        }
                    } else {
                        ForEach(store.categories, id: \.id) { category in
                            NavigationLink {
                                CategoryDetailView(category: category, store: store)
                            } label: {
                                CategoryRowView(category: category, store: store)
                            }
                        }
                        .onDelete(perform: deleteCategories)
                    }
                }
            }
            
            if showToast {
                ToastView(message: toastMessage, isShowing: $showToast)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle("分类管理")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddCategory = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showingAddCategory, onDismiss: { resetForm() }) {
            NavigationStack {
                Form {
                    Section(header: Text("名称")) {
                        TextField("分类名称", text: $newCategoryName)
                    }
                    
                    Section(header: Text("颜色")) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(availableColors, id: \.self) { color in
                                Circle()
                                    .fill(Color.fromHex( color))
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
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            showingAddCategory = false
                        }
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
        .alert("确认删除分类", isPresented: $showingDeleteAlert, presenting: categoryToDelete) { category in
            Button("取消", role: .cancel) { categoryToDelete = nil }
            Button("删除", role: .destructive) {
                store.deleteCategory(category)
                categoryToDelete = nil
            }
        } message: { category in
            let count = remindersCount(for: category)
            if count > 0 {
                Text("分类「\(category.name)」下有 \(count) 个提醒，删除后这些提醒将变为未分类。")
            } else {
                Text("确定要删除分类「\(category.name)」吗？")
            }
        }
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            guard index < store.categories.count else { continue }
            let category = store.categories[index]
            if category.name == "默认" {
                showToast(message: "默认分类不可删除")
                continue
            }
            categoryToDelete = category
            showingDeleteAlert = true
        }
    }
    
    private func addCategory() {
        let category = ReminderCategory(
            name: newCategoryName,
            color: selectedColor,
            icon: selectedIcon
        )
        store.addCategory(category)
        showingAddCategory = false
    }
    
    private func showToast(message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
    }
    
    private func resetForm() {
        newCategoryName = ""
        selectedColor = "#007AFF"
        selectedIcon = "folder.fill"
    }
}

struct CategoryRowView: View {
    var category: ReminderCategory
    @ObservedObject var store: ReminderStore
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundColor(Color.fromHex( category.color))
                .frame(width: 36, height: 36)
                .background(Color.fromHex( category.color).opacity(0.15))
                .cornerRadius(8)
            
            Text(category.name)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            let count = store.reminders.filter { $0.category?.id == category.id }.count
            if count > 0 {
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(minWidth: 22, minHeight: 22)
                    .background(Color.blue)
                    .cornerRadius(11)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CategoryDetailView: View {
    var category: ReminderCategory
    @ObservedObject var store: ReminderStore
    @State private var showingEditSheet = false
    
    /// 仅显示未完成 & 未过期的提醒
    var activeReminders: [Reminder] {
        let now = Date()
        return store.reminders
            .filter { $0.category?.id == category.id && !$0.isCompleted && $0.dueDate >= now }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if activeReminders.isEmpty {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 50)
                        Image(systemName: category.icon)
                            .font(.system(size: 60))
                            .foregroundColor(Color.fromHex(category.color))
                            .opacity(0.3)
                        Text("该分类下暂无待办提醒")
                            .foregroundColor(.secondary)
                    }
                } else {
                    ForEach(activeReminders) { reminder in
                        ReminderRowView(reminder: reminder, store: store)
                    }
                }
            }
            .padding()
        }
        .background(Color.appSystemBackground)
        .navigationTitle(category.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditCategoryView(category: category, store: store)
        }
    }
}

struct EditCategoryView: View {
    var category: ReminderCategory
    @ObservedObject var store: ReminderStore
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var selectedColor: String
    @State private var selectedIcon: String
    
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
    
    init(category: ReminderCategory, store: ReminderStore) {
        self.category = category
        self.store = store
        _name = State(initialValue: category.name)
        _selectedColor = State(initialValue: category.color)
        _selectedIcon = State(initialValue: category.icon)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("名称")) {
                    TextField("分类名称", text: $name)
                }
                
                Section(header: Text("颜色")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Circle()
                                .fill(Color.fromHex( color))
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
            .navigationTitle("编辑分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        category.name = name
                        category.color = selectedColor
                        category.icon = selectedIcon
                        store.updateCategory(category)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}


