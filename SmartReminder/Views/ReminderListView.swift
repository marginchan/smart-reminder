//
//  ReminderListView.swift
//  SmartReminder
//

import SwiftUI

struct ReminderListView: View {
    @ObservedObject var store: ReminderStore
    @State private var showingAddReminder = false
    @State private var showingCategoryManagement = false
    @State private var reminderToDelete: Reminder? = nil
    @State private var showingDeleteAlert = false
    @State private var showScrollToTop = false
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            List {
            if store.overdueReminders.isEmpty && store.filteredReminders.isEmpty {
                Section {
                    emptyStateView
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .id("top")
                        .onAppear { withAnimation { showScrollToTop = false } }
                        .onDisappear { withAnimation { showScrollToTop = true } }
                }
            } else {
                // 今日已逾期
                if !store.overdueReminders.isEmpty {
                    Section(header: Text("已逾期 (\(store.overdueReminders.count))").foregroundColor(.red)) {
                        ForEach(store.overdueReminders, id: \.id) { reminder in
                            overdueRow(reminder)
                        }
                    }
                }
                
                // 提醒列表（未来 1 年内）
                if !store.filteredReminders.isEmpty {
                    Section(header: Text("提醒列表 (\(store.filteredReminders.count))").foregroundColor(.primary)) {
                        ForEach(store.filteredReminders, id: \.id) { reminder in
                            filteredRow(reminder)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .listSectionSpacing(0)
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
        .confirmationDialog(
            "确定要删除「\(reminderToDelete?.title ?? "")」吗？此操作无法撤销。",
            isPresented: $showingDeleteAlert,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                if let reminder = reminderToDelete {
                    withAnimation(.easeOut(duration: 0.3)) {
                        store.deleteReminder(reminder)
                    }
                }
                reminderToDelete = nil
            }
            Button("取消", role: .cancel) {
                reminderToDelete = nil
            }
        }
        .navigationTitle("提醒")
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
    
    // MARK: - Components
    @ViewBuilder
    private func overdueRow(_ reminder: Reminder) -> some View {
        let isFirst = reminder.id == store.overdueReminders.first?.id
        ReminderRowView(reminder: reminder, store: store)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .id(isFirst ? "top" : reminder.id.uuidString)
            .onAppear { if isFirst { withAnimation { showScrollToTop = false } } }
            .onDisappear { if isFirst { withAnimation { showScrollToTop = true } } }
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

    @ViewBuilder
    private func filteredRow(_ reminder: Reminder) -> some View {
        let isFirst = store.overdueReminders.isEmpty && reminder.id == store.filteredReminders.first?.id
        ReminderRowView(reminder: reminder, store: store)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .id(isFirst ? "top" : reminder.id.uuidString)
            .onAppear { if isFirst { withAnimation { showScrollToTop = false } } }
            .onDisappear { if isFirst { withAnimation { showScrollToTop = true } } }
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


    

    

    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 20)
            
            // 3D Garfield Animation
            GarfieldAnimationView()
                .frame(height: 200)
            
            VStack(spacing: 8) {
                Text("太棒了！所有任务都搞定了")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("享受你的摸鱼时间吧 ☕️")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button(action: { showingAddReminder = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("添加新任务")
                }
                .fontWeight(.medium)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(20)
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        ReminderListView(store: ReminderStore())
    }
}

struct GarfieldAnimationView: View {
    @State private var isBlinking = false
    @State private var isFloating = false
    @State private var tailWag = false
    
    // Fixed coordinate space dimensions
    // All Path coordinates are relative to center (cx, cy)
    private let canvasWidth: CGFloat = 220
    private let canvasHeight: CGFloat = 200
    private var cx: CGFloat { canvasWidth / 2 }
    private var cy: CGFloat { canvasHeight / 2 }
    
    var body: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(Color.black.opacity(0.2))
                .frame(width: 120, height: 20)
                .offset(y: 110)
                .scaleEffect(isFloating ? 0.9 : 1.1)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isFloating)
            
            // Garfield Body Group - use a fixed frame so all Path children share the same coordinate space
            ZStack {
                // Tail
                Path { path in
                    path.move(to: CGPoint(x: cx + 60, y: cy + 30))
                    path.addCurve(
                        to: CGPoint(x: cx + 100, y: cy - 30),
                        control1: CGPoint(x: cx + 110, y: cy + 30),
                        control2: CGPoint(x: cx + 120, y: cy - 10)
                    )
                }
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: canvasWidth, height: canvasHeight)
                .rotationEffect(.degrees(tailWag ? 10 : -10), anchor: UnitPoint(x: (cx + 60) / canvasWidth, y: (cy + 30) / canvasHeight))
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: tailWag)
                
                // Body/Face Main Shape (Rounded Rect for 3D look)
                RoundedRectangle(cornerRadius: 45)
                    .fill(
                        LinearGradient(gradient: Gradient(colors: [Color(red: 1.0, green: 0.7, blue: 0.2), Color(red: 1.0, green: 0.5, blue: 0.0)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 140, height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 45)
                            .stroke(Color(red: 0.8, green: 0.4, blue: 0.0), lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 5, y: 5) // 3D Shadow
                
                // Ears
                Group {
                    // Left Ear
                    Path { path in
                        path.move(to: CGPoint(x: cx - 50, y: cy - 50))
                        path.addLine(to: CGPoint(x: cx - 20, y: cy - 50))
                        path.addQuadCurve(to: CGPoint(x: cx - 50, y: cy - 80), control: CGPoint(x: cx - 30, y: cy - 70))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 1.0, green: 0.6, blue: 0.1))
                    .overlay(
                        Path { path in
                            path.move(to: CGPoint(x: cx - 50, y: cy - 50))
                            path.addLine(to: CGPoint(x: cx - 20, y: cy - 50))
                            path.addQuadCurve(to: CGPoint(x: cx - 50, y: cy - 80), control: CGPoint(x: cx - 30, y: cy - 70))
                            path.closeSubpath()
                        }.stroke(Color(red: 0.8, green: 0.4, blue: 0.0), lineWidth: 2)
                    )
                    .frame(width: canvasWidth, height: canvasHeight)
                    
                    // Right Ear
                    Path { path in
                        path.move(to: CGPoint(x: cx + 50, y: cy - 50))
                        path.addLine(to: CGPoint(x: cx + 20, y: cy - 50))
                        path.addQuadCurve(to: CGPoint(x: cx + 50, y: cy - 80), control: CGPoint(x: cx + 30, y: cy - 70))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 1.0, green: 0.6, blue: 0.1))
                    .overlay(
                        Path { path in
                            path.move(to: CGPoint(x: cx + 50, y: cy - 50))
                            path.addLine(to: CGPoint(x: cx + 20, y: cy - 50))
                            path.addQuadCurve(to: CGPoint(x: cx + 50, y: cy - 80), control: CGPoint(x: cx + 30, y: cy - 70))
                            path.closeSubpath()
                        }.stroke(Color(red: 0.8, green: 0.4, blue: 0.0), lineWidth: 2)
                    )
                    .frame(width: canvasWidth, height: canvasHeight)
                }
                
                // Stripes (Simplified)
                VStack(spacing: 8) {
                    ForEach(0..<3) { _ in
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 20, height: 4)
                    }
                }
                .offset(y: -45)
                
                // Eyes Background (White)
                HStack(spacing: 2) {
                    Ellipse()
                        .fill(Color.white)
                        .frame(width: 35, height: 45)
                        .overlay(Ellipse().stroke(Color.black, lineWidth: 1))
                    Ellipse()
                        .fill(Color.white)
                        .frame(width: 35, height: 45)
                        .overlay(Ellipse().stroke(Color.black, lineWidth: 1))
                }
                .offset(y: -10)
                
                // Eyelids (Blinking Animation)
                HStack(spacing: 2) {
                    ZStack {
                        Ellipse() // Mask for eyelid
                            .fill(Color.clear)
                            .frame(width: 35, height: 45)
                            .clipShape(Rectangle().offset(y: isBlinking ? 0 : -45))
                        
                        Rectangle() // Eyelid color
                            .fill(Color(red: 1.0, green: 0.65, blue: 0.1))
                            .frame(width: 35, height: 45)
                            .offset(y: isBlinking ? 0 : -45)
                            .mask(Ellipse().frame(width: 35, height: 45))
                    }
                    
                    ZStack {
                        Ellipse() // Mask for eyelid
                            .fill(Color.clear)
                            .frame(width: 35, height: 45)
                            .clipShape(Rectangle().offset(y: isBlinking ? 0 : -45))
                        
                        Rectangle() // Eyelid color
                            .fill(Color(red: 1.0, green: 0.65, blue: 0.1))
                            .frame(width: 35, height: 45)
                            .offset(y: isBlinking ? 0 : -45)
                            .mask(Ellipse().frame(width: 35, height: 45))
                    }
                }
                .offset(y: -10)
                
                // Pupils
                HStack(spacing: 18) {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 8, height: 8)
                }
                .offset(y: -5)
                
                // Nose
                Ellipse()
                    .fill(Color.pink)
                    .frame(width: 15, height: 10)
                    .offset(y: 15)
                
                // Muzzle/Mouth Area
                HStack(spacing: 0) {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.85, blue: 0.5)) // Light yellow/beige
                        .frame(width: 35, height: 30)
                    Circle()
                        .fill(Color(red: 1.0, green: 0.85, blue: 0.5))
                        .frame(width: 35, height: 30)
                }
                .offset(y: 25)
                .zIndex(-1) // Behind nose
                
                // Whiskers
                Group {
                    // Left
                    Path { path in
                        path.move(to: CGPoint(x: cx - 30, y: cy + 25))
                        path.addLine(to: CGPoint(x: cx - 70, y: cy + 20))
                    }.stroke(Color.black, lineWidth: 1)
                    .frame(width: canvasWidth, height: canvasHeight)
                    
                    Path { path in
                        path.move(to: CGPoint(x: cx - 30, y: cy + 30))
                        path.addLine(to: CGPoint(x: cx - 70, y: cy + 30))
                    }.stroke(Color.black, lineWidth: 1)
                    .frame(width: canvasWidth, height: canvasHeight)
                    
                    Path { path in
                        path.move(to: CGPoint(x: cx - 30, y: cy + 35))
                        path.addLine(to: CGPoint(x: cx - 70, y: cy + 40))
                    }.stroke(Color.black, lineWidth: 1)
                    .frame(width: canvasWidth, height: canvasHeight)
                    
                    // Right
                    Path { path in
                        path.move(to: CGPoint(x: cx + 30, y: cy + 25))
                        path.addLine(to: CGPoint(x: cx + 70, y: cy + 20))
                    }.stroke(Color.black, lineWidth: 1)
                    .frame(width: canvasWidth, height: canvasHeight)
                    
                    Path { path in
                        path.move(to: CGPoint(x: cx + 30, y: cy + 30))
                        path.addLine(to: CGPoint(x: cx + 70, y: cy + 30))
                    }.stroke(Color.black, lineWidth: 1)
                    .frame(width: canvasWidth, height: canvasHeight)
                    
                    Path { path in
                        path.move(to: CGPoint(x: cx + 30, y: cy + 35))
                        path.addLine(to: CGPoint(x: cx + 70, y: cy + 40))
                    }.stroke(Color.black, lineWidth: 1)
                    .frame(width: canvasWidth, height: canvasHeight)
                }
            }
            .frame(width: canvasWidth, height: canvasHeight)
            .offset(y: isFloating ? -10 : 10)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isFloating)
        }
        .onAppear {
            isFloating = true
            tailWag = true
            startBlinking()
        }
    }
    
    func startBlinking() {
        // Random blinking
        let randomInterval = Double.random(in: 2...5)
        DispatchQueue.main.asyncAfter(deadline: .now() + randomInterval) {
            withAnimation(.easeOut(duration: 0.15)) {
                isBlinking = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeIn(duration: 0.15)) {
                    isBlinking = false
                }
                startBlinking() // Schedule next blink
            }
        }
    }
}
