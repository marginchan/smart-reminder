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
            
            // Interactive Garfield Game
            GarfieldGameView()
                .frame(height: 380) // Increased height to prevent overlap
                
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


import SwiftUI
import UIKit

enum GarfieldState {
    case sleeping
    case awake
    case happy
    case eating
    case annoyed
}

struct LasagnaParticle: Identifiable {
    let id = UUID()
    var offset: CGSize
    var opacity: Double
}

struct HeartParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
}

struct GarfieldGameView: View {
    @State private var state: GarfieldState = .awake
    @State private var hunger: Double = 0.5 // 0 to 1
    @State private var happiness: Double = 0.5 // 0 to 1
    
    // Animations
    @State private var isBreathing = false
    @State private var eyesOffset: CGSize = .zero
    @State private var tailAngle: Double = 0
    
    // Interactions
    @State private var foodOffset: CGSize = .zero
    @State private var isDraggingFood = false
    @State private var hearts: [HeartParticle] = []
    
    @State private var sleepTimer: Timer?
    @State private var purrTimer: Timer?
    
    let impactMed = UIImpactFeedbackGenerator(style: .medium)
    let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    
    // Colors
    let garfieldOrange = Color(red: 0.98, green: 0.6, blue: 0.15)
    let garfieldDarkOrange = Color(red: 0.85, green: 0.45, blue: 0.05)
    let garfieldYellow = Color(red: 1.0, green: 0.85, blue: 0.4)
    
    var body: some View {
        VStack(spacing: 20) {
            // HUD
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("饱食度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ProgressView(value: hunger)
                        .tint(.orange)
                }
                VStack(alignment: .leading) {
                    Text("心情值")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ProgressView(value: happiness)
                        .tint(.pink)
                }
            }
            .padding(.horizontal, 40)
            
            // Character Area
            ZStack {
                // Shadow
                Ellipse()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 160, height: 30)
                    .offset(y: 110)
                    .scaleEffect(isBreathing ? 1.05 : 0.95)
                
                // Tail
                Capsule()
                    .fill(garfieldDarkOrange)
                    .frame(width: 24, height: 75)
                    .offset(x: 55, y: 35)
                    .rotationEffect(.degrees(tailAngle + 40), anchor: .bottom)
                    // Tail stripes
                    .overlay(
                        VStack(spacing: 8) {
                            ForEach(0..<3) { _ in
                                Capsule()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(width: 24, height: 4)
                            }
                        }
                        .offset(y: -5)
                    )
                
                // Body
                Ellipse()
                    .fill(garfieldOrange)
                    .frame(width: 90, height: 80)
                    .offset(y: 60)
                    .scaleEffect(y: isBreathing ? 1.02 : 0.98, anchor: .bottom)
                    // Small side stripes
                    .overlay(
                        VStack(spacing: 8) {
                            Capsule().fill(Color.black.opacity(0.4)).frame(width: 15, height: 3)
                            Capsule().fill(Color.black.opacity(0.4)).frame(width: 25, height: 3)
                        }
                        .offset(x: -35, y: 25)
                        .rotationEffect(.degrees(-25))
                    )
                    .overlay(
                        VStack(spacing: 8) {
                            Capsule().fill(Color.black.opacity(0.4)).frame(width: 15, height: 3)
                            Capsule().fill(Color.black.opacity(0.4)).frame(width: 25, height: 3)
                        }
                        .offset(x: 35, y: 25)
                        .rotationEffect(.degrees(25))
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in petHead() }
                    )
                    .onTapGesture { pokeBelly() }
                
                // Feet (smaller and closer)
                HStack(spacing: 20) {
                    Capsule().fill(garfieldOrange).frame(width: 24, height: 16).offset(y: 100)
                    Capsule().fill(garfieldOrange).frame(width: 24, height: 16).offset(y: 100)
                }
                
                // Head
                ZStack {
                    // Ears (Kitten style, tiny triangles)
                    HStack(spacing: 40) {
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 15))
                            path.addQuadCurve(to: CGPoint(x: 8, y: -15), control: CGPoint(x: -5, y: -5))
                            path.addQuadCurve(to: CGPoint(x: 24, y: 15), control: CGPoint(x: 20, y: -5))
                        }
                        .fill(garfieldOrange)
                        .frame(width: 24, height: 30)
                        
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 15))
                            path.addQuadCurve(to: CGPoint(x: 16, y: -15), control: CGPoint(x: 4, y: -5))
                            path.addQuadCurve(to: CGPoint(x: 24, y: 15), control: CGPoint(x: 29, y: -5))
                        }
                        .fill(garfieldOrange)
                        .frame(width: 24, height: 30)
                    }
                    .offset(y: -55)
                    
                    // Head shape (rounder and larger relative to body)
                    Ellipse()
                        .fill(garfieldOrange)
                        .frame(width: 150, height: 130)
                        .offset(y: -5)
                    
                    // Head Stripes (just two small cute ones on top)
                    VStack(spacing: 6) {
                        Capsule().fill(Color.black.opacity(0.4)).frame(width: 12, height: 3)
                        Capsule().fill(Color.black.opacity(0.4)).frame(width: 20, height: 3)
                    }
                    .offset(y: -55)
                    
                    // Eyes Background (Massive, placed lower down for baby proportions)
                    HStack(spacing: -2) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                            .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                            .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                    }
                    .offset(y: 10)
                    
                    // Pupils (Huge and watery)
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle().fill(Color.white).frame(width: 10, height: 10).offset(x: 5, y: -5)
                            )
                            .offset(eyesOffset)
                        Circle()
                            .fill(Color.black)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle().fill(Color.white).frame(width: 10, height: 10).offset(x: 5, y: -5)
                            )
                            .offset(eyesOffset)
                    }
                    .offset(y: 10)
                    
                    // Eyelids (Lazy/Half-closed)
                    if state == .sleeping {
                        HStack(spacing: -2) {
                            Circle()
                                .fill(garfieldOrange)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    VStack {
                                        Spacer()
                                        Rectangle().fill(Color.black).frame(height: 2)
                                    }
                                )
                            Circle()
                                .fill(garfieldOrange)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    VStack {
                                        Spacer()
                                        Rectangle().fill(Color.black).frame(height: 2)
                                    }
                                )
                        }
                        .offset(y: 10)
                    } else if state != .annoyed && state != .happy {
                        // Wide awake mostly, just a tiny sliver of eyelid for cuteness
                        HStack(spacing: -2) {
                            Rectangle()
                                .fill(garfieldOrange)
                                .frame(width: 60, height: 12)
                                .mask(Circle().frame(width: 60, height: 60).offset(y: -24))
                                .overlay(VStack { Spacer(); Rectangle().fill(Color.black).frame(height: 1) })
                            Rectangle()
                                .fill(garfieldOrange)
                                .frame(width: 60, height: 12)
                                .mask(Circle().frame(width: 60, height: 60).offset(y: -24))
                                .overlay(VStack { Spacer(); Rectangle().fill(Color.black).frame(height: 1) })
                        }
                        .offset(y: -14)
                    } else if state == .happy {
                        // Happy eyes (fully covered with cute ^ shape)
                        HStack(spacing: -2) {
                            Circle().fill(garfieldOrange).frame(width: 60, height: 60)
                                .overlay(
                                    Path { path in
                                        path.move(to: CGPoint(x: 10, y: 30))
                                        path.addQuadCurve(to: CGPoint(x: 50, y: 30), control: CGPoint(x: 30, y: 15))
                                    }.stroke(Color.black, lineWidth: 2.5)
                                )
                            Circle().fill(garfieldOrange).frame(width: 60, height: 60)
                                .overlay(
                                    Path { path in
                                        path.move(to: CGPoint(x: 10, y: 30))
                                        path.addQuadCurve(to: CGPoint(x: 50, y: 30), control: CGPoint(x: 30, y: 15))
                                    }.stroke(Color.black, lineWidth: 2.5)
                                )
                        }
                        .offset(y: 10)
                    }
                    
                    // Muzzle (Yellow area) - tiny for a kitten
                    HStack(spacing: -2) {
                        Ellipse()
                            .fill(garfieldYellow)
                            .frame(width: 25, height: 20)
                        Ellipse()
                            .fill(garfieldYellow)
                            .frame(width: 25, height: 20)
                    }
                    .offset(y: 40)
                    
                    // Nose - tiny and cute pink triangle/circle
                    Circle()
                        .fill(Color.pink)
                        .frame(width: 8, height: 6)
                        .offset(y: 31)
                    
                    // Mouth
                    if state == .eating {
                        Circle()
                            .trim(from: 0.5, to: 1.0)
                            .fill(Color.black.opacity(0.8))
                            .frame(width: 16, height: 16)
                            .rotationEffect(.degrees(180))
                            .offset(y: 42)
                    } else {
                        Path { path in
                            path.move(to: CGPoint(x: -8, y: 44))
                            path.addQuadCurve(to: CGPoint(x: 0, y: 47), control: CGPoint(x: -4, y: 49))
                            path.addQuadCurve(to: CGPoint(x: 8, y: 44), control: CGPoint(x: 4, y: 49))
                        }
                        .stroke(Color.black, lineWidth: 1.5)
                    }
                    
                    // Whiskers (3 on each side)
                    Group {
                        Path { path in path.move(to: CGPoint(x: -22, y: 35)); path.addLine(to: CGPoint(x: -42, y: 31)) }.stroke(Color.black.opacity(0.4), lineWidth: 1.5)
                        Path { path in path.move(to: CGPoint(x: -22, y: 39)); path.addLine(to: CGPoint(x: -45, y: 39)) }.stroke(Color.black.opacity(0.4), lineWidth: 1.5)
                        Path { path in path.move(to: CGPoint(x: -22, y: 43)); path.addLine(to: CGPoint(x: -42, y: 47)) }.stroke(Color.black.opacity(0.4), lineWidth: 1.5)
                        
                        Path { path in path.move(to: CGPoint(x: 22, y: 35)); path.addLine(to: CGPoint(x: 42, y: 31)) }.stroke(Color.black.opacity(0.4), lineWidth: 1.5)
                        Path { path in path.move(to: CGPoint(x: 22, y: 39)); path.addLine(to: CGPoint(x: 45, y: 39)) }.stroke(Color.black.opacity(0.4), lineWidth: 1.5)
                        Path { path in path.move(to: CGPoint(x: 22, y: 43)); path.addLine(to: CGPoint(x: 42, y: 47)) }.stroke(Color.black.opacity(0.4), lineWidth: 1.5)
                    }
                }
                .rotationEffect(.degrees(state == .sleeping ? 5 : 0))
                
                // Emotes
                if state == .sleeping {
                    Text("Zzz")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.gray)
                        .offset(x: 60, y: -70)
                } else if state == .annoyed {
                    Text("💢")
                        .font(.system(size: 32))
                        .offset(x: 50, y: -60)
                }
                
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
            .frame(width: 300, height: 240)
            
            // Interaction Area (Lasagna)
            VStack(spacing: 2) {
                Text("喂千层面")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("🍝")
                    .font(.system(size: 40))
                    .offset(foodOffset)
                    .scaleEffect(isDraggingFood ? 1.2 : 1.0)
                    .gesture(
                        DragGesture()
                            .onChanged { v in
                                isDraggingFood = true
                                foodOffset = v.translation
                                updateEyes(target: v.translation)
                                
                                if state == .sleeping {
                                    state = .awake
                                    resetSleepTimer()
                                }
                            }
                            .onEnded { v in
                                isDraggingFood = false
                                checkFoodDrop(location: v.translation)
                            }
                    )
            }
            .frame(height: 60)
            .zIndex(2) // Above cat
        }
        .onAppear {
            startBreathing()
            startTailWag()
            resetSleepTimer()
            
            // Passive decay
            Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
                hunger = max(0, hunger - 0.05)
                happiness = max(0, happiness - 0.05)
            }
        }
        .onDisappear {
            sleepTimer?.invalidate()
            purrTimer?.invalidate()
        }
    }
    
    // MARK: - Handlers
    
    private func updateEyes(target: CGSize) {
        let dx = target.width
        let dy = target.height - 150 // Lasagna is below the face
        let distance = sqrt(dx*dx + dy*dy)
        let maxOffset: CGFloat = 8.0
        
        if distance > 0 {
            let ratio = min(maxOffset, distance / 15) / distance
            eyesOffset = CGSize(width: dx * ratio, height: dy * ratio)
        }
    }
    
    private func checkFoodDrop(location: CGSize) {
        // If dragged up near the mouth
        if location.height < -120 && abs(location.width) < 80 {
            // Eat
            impactHeavy.impactOccurred()
            withAnimation(.spring()) {
                state = .eating
                hunger = min(1.0, hunger + 0.2)
                happiness = min(1.0, happiness + 0.1)
                foodOffset = CGSize(width: location.width, height: location.height - 20)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut) {
                    foodOffset = .zero
                    eyesOffset = .zero
                    state = .happy
                }
                resetSleepTimer()
            }
        } else {
            // Snap back
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                foodOffset = .zero
                eyesOffset = .zero
            }
        }
    }
    
    private func pokeBelly() {
        resetSleepTimer()
        impactHeavy.impactOccurred()
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            state = .annoyed
            happiness = max(0, happiness - 0.1)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.default) {
                state = .awake
            }
        }
    }
    
    private func petHead() {
        resetSleepTimer()
        state = .happy
        happiness = min(1.0, happiness + 0.05)
        
        if Int.random(in: 0...5) == 0 {
            impactMed.impactOccurred()
            spawnHeart()
        }
    }
    
    private func spawnHeart() {
        let newHeart = HeartParticle(
            x: 150 + CGFloat.random(in: -40...40),
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if !hearts.isEmpty {
                hearts.removeFirst()
            }
        }
    }
    
    private func resetSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 1.0)) {
                state = .sleeping
                eyesOffset = .zero
            }
        }
    }
    
    private func startBreathing() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            isBreathing = true
        }
    }
    
    private func startTailWag() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            let speed = state == .happy ? 0.3 : 1.5
            let angle = state == .happy ? 20.0 : 10.0
            
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
