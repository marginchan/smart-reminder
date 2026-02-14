//
//  NotesView.swift
//  SmartReminder
//

import SwiftUI

struct NotesView: View {
    @ObservedObject var store: ReminderStore
    @State private var showingAddNote = false
    @State private var selectedNote: Note?
    @State private var noteToEdit: Note?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // 搜索栏
                searchBar
                
                // 便签列表
                if store.filteredNotes.isEmpty {
                    emptyStateView
                } else {
                    notesGrid
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .background(Color.appSystemBackground)
        .navigationTitle("便签")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddNote = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingAddNote) {
            AddNoteView(store: store, note: nil)
        }
        .sheet(item: $noteToEdit) { note in
            AddNoteView(store: store, note: note)
        }
    }
    
    // MARK: - Components
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("搜索便签", text: $store.noteSearchText)
        }
        .padding(10)
        .background(Color.appSecondarySystemBackground)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var notesGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        
        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(store.filteredNotes, id: \.id) { note in
                NoteCardView(note: note, store: store, onEdit: {
                    noteToEdit = note
                })
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 60)
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("没有便签")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("点击右上角按钮添加新便签")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
    }
}

// MARK: - Note Card View

struct NoteCardView: View {
    let note: Note
    @ObservedObject var store: ReminderStore
    let onEdit: () -> Void
    @State private var showingDeleteAlert = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                Spacer()
                Text(formattedDate(note.updatedAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(note.title)
                .font(.headline)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
            }
            
            Spacer()
        }
        .padding()
        .frame(height: 160)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                // 背景色适配：浅色模式下更清淡，深色模式下更通透
                Color.fromHex( note.color)
                    .opacity(colorScheme == .dark ? 0.2 : 0.15)
            }
        )
        .cornerRadius(12)
        // 添加边框以增强卡片感（可选）
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.fromHex( note.color).opacity(0.3), lineWidth: 1)
        )
        .contentShape(Rectangle()) // 确保点击区域覆盖整个卡片
        .onTapGesture {
            onEdit()
        }
        .contextMenu {
            Button {
                store.togglePinNote(note)
            } label: {
                Label(note.isPinned ? "取消置顶" : "置顶", systemImage: note.isPinned ? "pin.slash" : "pin")
            }
            
            Button {
                onEdit()
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                store.deleteNote(note)
            }
        } message: {
            Text("确定要删除这条便签吗？")
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}
