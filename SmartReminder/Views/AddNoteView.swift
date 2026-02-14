//
//  AddNoteView.swift
//  SmartReminder
//

import SwiftUI

struct AddNoteView: View {
    @ObservedObject var store: ReminderStore
    @Environment(\.dismiss) var dismiss
    var note: Note?
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedColor: String = "#FFD60A"
    @State private var isPinned: Bool = false
    
    @State private var activeFullscreenField: EditorField?
    
    enum EditorField: Identifiable {
        case title
        case content
        
        var id: Self { self }
    }
    
    private var isEditing: Bool { note != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("标题") {
                    ZStack(alignment: .bottomTrailing) {
                        TextField("输入便签标题", text: $title)
                            .padding(.trailing, 30)
                        
                        Button {
                            activeFullscreenField = .title
                        } label: {
                            Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Section("内容") {
                    ZStack(alignment: .bottomTrailing) {
                        TextEditor(text: $content)
                            .frame(minHeight: 150)
                        
                        Button {
                            activeFullscreenField = .content
                        } label: {
                            Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                                .foregroundColor(.blue)
                                .font(.caption)
                                .padding(8)
                                .background(Color.appSystemBackgroundPlain.opacity(0.8))
                                .clipShape(Circle())
                        }
                        .padding(4)
                        .buttonStyle(.plain)
                    }
                }
                
                Section("颜色") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(Note.defaultColors, id: \.self) { color in
                            colorButton(color: color)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Toggle("置顶", isOn: $isPinned)
                }
            }
            .navigationTitle(isEditing ? "编辑便签" : "新便签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveNote()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let note = note {
                    title = note.title
                    content = note.content
                    selectedColor = note.color
                    isPinned = note.isPinned
                }
            }
            .fullScreenCover(item: $activeFullscreenField) { field in
                FullscreenNoteEditor(
                    text: field == .title ? $title : $content,
                    field: field
                )
            }
        }
    }
    
    private func colorButton(color: String) -> some View {
        Button {
            selectedColor = color
        } label: {
            Circle()
                .fill(Color.fromHex( color))
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                )
        }
        .buttonStyle(.plain) // 确保点击区域正确
    }
    
    private func saveNote() {
        if let note = note {
            note.title = title
            note.content = content
            note.color = selectedColor
            note.isPinned = isPinned
            store.updateNote(note)
        } else {
            let newNote = Note(
                title: title,
                content: content,
                color: selectedColor,
                isPinned: isPinned
            )
            store.addNote(newNote)
        }
        dismiss()
    }
}

struct FullscreenNoteEditor: View {
    @Binding var text: String
    let field: AddNoteView.EditorField
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                if field == .title {
                    TextField("输入标题", text: $text, axis: .vertical)
                        .font(.title)
                        .padding()
                } else {
                    TextEditor(text: $text)
                        .padding()
                        .font(.body)
                }
                Spacer()
                
                if field == .content {
                    markdownToolbar
                }
            }
            .navigationTitle(field == .title ? "编辑标题" : "编辑内容")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var markdownToolbar: some View {
        HStack(spacing: 20) {
            Button {
                appendMarkdown("**", suffix: "**")
            } label: {
                Image(systemName: "bold")
            }
            
            Button {
                appendMarkdown("*", suffix: "*")
            } label: {
                Image(systemName: "italic")
            }
            
            Button {
                appendMarkdown("- ")
            } label: {
                Image(systemName: "list.bullet")
            }
            
            Spacer()
        }
        .padding()
        .background(Color.appSecondarySystemBackground)
    }
    
    private func appendMarkdown(_ prefix: String, suffix: String = "") {
        // Simple append for now as TextEditor doesn't support easy cursor insertion in SwiftUI
        if text.isEmpty || text.hasSuffix("\n") {
            text += prefix + suffix
        } else {
            text += "\n" + prefix + suffix
        }
    }
}
