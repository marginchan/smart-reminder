//
//  ReminderListView.swift
//  SmartReminder
//

import SwiftUI
import UIKit

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
            if store.overdueReminders.isEmpty && store.expandedFilteredReminders.isEmpty {
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
                if !store.expandedFilteredReminders.isEmpty {
                    Section(header: Text("提醒列表 (\(store.expandedFilteredReminders.count))").foregroundColor(.primary)) {
                        ForEach(store.expandedFilteredReminders, id: \.id) { reminder in
                            filteredRow(reminder)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
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
        .navigationTitle("提醒")
        .overlay(alignment: .bottomTrailing) {
            if showScrollToTop {
                Button {
                    withAnimation {
                        if store.overdueReminders.isEmpty && store.expandedFilteredReminders.isEmpty {
                            scrollProxy.scrollTo("top", anchor: .top)
                        } else if let firstId = store.overdueReminders.first?.id ?? store.expandedFilteredReminders.first?.id {
                            scrollProxy.scrollTo(firstId, anchor: .top)
                        }
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
        if reminder.isDeleted || reminder.modelContext == nil {
            EmptyView()
        } else {
            let isFirst = reminder.id == store.overdueReminders.first?.id
            ReminderRowView(reminder: reminder, store: store)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .id(reminder.id)
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
    }

    @ViewBuilder
    private func filteredRow(_ reminder: Reminder) -> some View {
        if reminder.isDeleted || reminder.modelContext == nil {
            EmptyView()
        } else {
            let isFirst = store.overdueReminders.isEmpty && reminder.id == store.expandedFilteredReminders.first?.id
            ReminderRowView(reminder: reminder, store: store)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .id(reminder.id)
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
    }


    

    

    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 20)
            
            // 2D Interactive Cat Petting Animation
            InteractiveCatView()
                .frame(height: 250)
            
            VStack(spacing: 8) {
                Text("太棒了！所有任务都搞定了")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("享受你的撸猫时间吧 ☕️")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
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

enum CatState {
    case sleeping
    case awake
    case happy
}

struct HeartParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
}

struct InteractiveCatView: View {
    @State private var catState: CatState = .sleeping
    @State private var happiness: Double = 0.0
    
    // Animation states
    @State private var isBlinking = false
    @State private var isBreathing = false
    @State private var tailAngle: Double = 0
    @State private var hearts: [HeartParticle] = []
    
    @State private var sleepTimer: Timer?
    @State private var purrTimer: Timer?
    
    // Impact feedback
    let impactMed = UIImpactFeedbackGenerator(style: .medium)
    let impactLight = UIImpactFeedbackGenerator(style: .light)
    
    private let catColor = Color(red: 0.95, green: 0.65, blue: 0.25)
    private let catDarkColor = Color(red: 0.85, green: 0.45, blue: 0.15)
    private let catBellyColor = Color(red: 0.98, green: 0.85, blue: 0.65)
    
    var body: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(Color.black.opacity(0.15))
                .frame(width: 140, height: 25)
                .offset(y: 85)
                .scaleEffect(isBreathing ? 1.05 : 0.95)
            
            // Cat Body
            ZStack {
                // Tail
                Capsule()
                    .fill(catDarkColor)
                    .frame(width: 16, height: 80)
                    .offset(x: 60, y: 10)
                    .rotationEffect(.degrees(tailAngle + 45), anchor: .bottom)
                
                // Main Body
                RoundedRectangle(cornerRadius: 50)
                    .fill(catColor)
                    .frame(width: 140, height: 110)
                    .offset(y: 30)
                    .scaleEffect(y: isBreathing ? 1.02 : 0.98, anchor: .bottom)
                
                // Belly
                Ellipse()
                    .fill(catBellyColor)
                    .frame(width: 90, height: 60)
                    .offset(y: 45)
                    .scaleEffect(y: isBreathing ? 1.03 : 0.97, anchor: .center)
                
                // Head
                ZStack {
                    // Ears
                    RoundedRectangle(cornerRadius: 6)
                        .fill(catDarkColor)
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-15))
                        .offset(x: -35, y: -45)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(catDarkColor)
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(15))
                        .offset(x: 35, y: -45)
                    
                    // Face Base
                    Ellipse()
                        .fill(catColor)
                        .frame(width: 120, height: 95)
                        .offset(y: -20)
                    
                    // Cheeks / lower face
                    Ellipse()
                        .fill(catBellyColor)
                        .frame(width: 100, height: 50)
                        .offset(y: -5)
                    
                    // Eyes
                    switch catState {
                    case .sleeping:
                        // Sleeping (straight line)
                        Capsule()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 16, height: 3)
                            .offset(x: -20, y: -20)
                        Capsule()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 16, height: 3)
                            .offset(x: 20, y: -20)
                    case .awake:
                        // Awake eyes (round, blinking)
                        Circle()
                            .fill(Color.black.opacity(0.8))
                            .frame(width: 12, height: 12)
                            .offset(x: -20, y: -20)
                            .scaleEffect(y: isBlinking ? 0.1 : 1)
                        
                        Circle()
                            .fill(Color.black.opacity(0.8))
                            .frame(width: 12, height: 12)
                            .offset(x: 20, y: -20)
                            .scaleEffect(y: isBlinking ? 0.1 : 1)
                            
                    case .happy:
                        // Happy eyes (^ ^)
                        Circle()
                            .trim(from: 0.5, to: 1.0)
                            .stroke(Color.black.opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 16, height: 16)
                            .offset(x: -20, y: -15)
                        
                        Circle()
                            .trim(from: 0.5, to: 1.0)
                            .stroke(Color.black.opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 16, height: 16)
                            .offset(x: 20, y: -15)
                    }
                    
                    // Nose
                    Ellipse()
                        .fill(Color.pink)
                        .frame(width: 10, height: 6)
                        .offset(y: -5)
                    
                    // Mouth
                    HStack(spacing: 0) {
                        Circle()
                            .trim(from: 0.0, to: 0.5)
                            .stroke(Color.black.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 10, height: 10)
                        Circle()
                            .trim(from: 0.0, to: 0.5)
                            .stroke(Color.black.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 10, height: 10)
                    }
                    .offset(y: 2)
                }
                .rotationEffect(.degrees(catState == .sleeping ? 5 : 0))
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        handlePetting()
                    }
            )
            
            // Floating Hearts
            ForEach(hearts) { heart in
                Image(systemName: "heart.fill")
                    .foregroundColor(Color.pink)
                    .font(.system(size: 24))
                    .scaleEffect(heart.scale)
                    .opacity(heart.opacity)
                    .position(x: heart.x, y: heart.y)
            }
        }
        .frame(width: 250, height: 250)
        .onAppear {
            startBreathing()
            startBlinking()
            startTailWag()
        }
        .onDisappear {
            sleepTimer?.invalidate()
            purrTimer?.invalidate()
        }
    }
    
    // MARK: - Interactions
    
    private func handlePetting() {
        resetSleepTimer()
        
        // Slightly wake up if sleeping
        if catState == .sleeping {
            withAnimation(.spring()) {
                catState = .awake
            }
        }
        
        // Increase happiness
        happiness += 0.05
        
        if happiness > 1.0 {
            if catState != .happy {
                impactMed.impactOccurred()
                withAnimation(.spring()) {
                    catState = .happy
                }
                startPurring()
            } else {
                // Already happy, small purr vibrations
                if Int.random(in: 0...5) == 0 {
                    impactLight.impactOccurred()
                    spawnHeart()
                }
            }
        }
    }
    
    private func spawnHeart() {
        let newHeart = HeartParticle(
            x: 125 + CGFloat.random(in: -40...40),
            y: 80,
            scale: 0.1,
            opacity: 1.0
        )
        
        hearts.append(newHeart)
        let index = hearts.count - 1
        
        withAnimation(.easeOut(duration: 1.5)) {
            hearts[index].y -= 60 + CGFloat.random(in: 0...40)
            hearts[index].scale = 1.0
            hearts[index].opacity = 0.0
        }
        
        // Remove after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if !hearts.isEmpty {
                hearts.removeFirst()
            }
        }
    }
    
    // MARK: - Automation Timers
    
    private func resetSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            happiness = 0
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                catState = .sleeping
            }
            purrTimer?.invalidate()
        }
    }
    
    private func startPurring() {
        purrTimer?.invalidate()
        purrTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            if catState == .happy {
                spawnHeart()
            } else {
                purrTimer?.invalidate()
            }
        }
    }
    
    private func startBreathing() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            isBreathing = true
        }
    }
    
    private func startBlinking() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 2...5), repeats: true) { timer in
            if catState == .awake {
                withAnimation(.linear(duration: 0.1)) {
                    isBlinking = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.linear(duration: 0.1)) {
                        isBlinking = false
                    }
                }
            }
            timer.fireDate = Date().addingTimeInterval(Double.random(in: 2...5))
        }
    }
    
    private func startTailWag() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            let speed = catState == .happy ? 0.3 : 1.5
            let angle = catState == .happy ? 20.0 : 10.0
            
            withAnimation(.easeInOut(duration: speed)) {
                tailAngle = angle
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + speed) {
                withAnimation(.easeInOut(duration: speed)) {
                    tailAngle = -angle / 2
                }
            }
        }
    }
}
