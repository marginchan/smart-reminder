//
//  ReminderListView.swift
//  SmartReminder
//

import SwiftUI

struct ReminderListView: View {
    @ObservedObject var store: ReminderStore
    @State private var showingAddReminder = false
    @State private var showingCategoryManagement = false
    
    var body: some View {
        List {
            // 品牌 Logo Section
            Section {
                // 品牌 Logo
                HStack(spacing: 12) {
                    NiumaLogoView(size: 50)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("牛马提醒")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text("打工人的智能助手")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .bottom)
                .padding(.bottom, 8)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            
            // 逾期任务
            if !store.overdueReminders.isEmpty {
                Section(header: Text("已逾期").foregroundColor(.red)) {
                    ForEach(store.overdueReminders, id: \.id) { reminder in
                        ReminderRowView(reminder: reminder, store: store)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        store.deleteReminder(reminder)
                                    }
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    withAnimation {
                                        store.toggleComplete(reminder)
                                    }
                                } label: {
                                    Label("完成", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                    }
                }
            }
            
            // 提醒列表
            if store.filteredReminders.isEmpty {
                Section {
                    emptyStateView
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            } else {
                Section(header: Text("提醒列表 (\(store.filteredReminders.count))").foregroundColor(.primary)) {
                    ForEach(store.filteredReminders, id: \.id) { reminder in
                        ReminderRowView(reminder: reminder, store: store)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        store.deleteReminder(reminder)
                                    }
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    withAnimation {
                                        store.toggleComplete(reminder)
                                    }
                                } label: {
                                    Label("完成", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(Color.appSystemBackground)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { showingCategoryManagement = true }) {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.title2)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddReminder = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingAddReminder) {
            AddReminderView(store: store, isPresented: $showingAddReminder)
        }
        .sheet(isPresented: $showingCategoryManagement) {
            NavigationStack {
                CategoryManagementView(store: store)
            }
        }
    }
    
    // MARK: - Components
    

    

    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 40)
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("没有提醒")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("点击右上角按钮添加新提醒")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
}

#Preview {
    NavigationStack {
        ReminderListView(store: ReminderStore())
    }
}
