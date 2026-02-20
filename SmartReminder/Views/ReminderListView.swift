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
            
            // Interactive Dumpling Cat Game
            DumplingCatView()
                .frame(height: 300)
            
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

struct DumplingCatView: View {
    @State private var scale: CGFloat = 1.0
    @State private var squash: CGFloat = 1.0
    @State private var eyesOffset: CGSize = .zero
    @State private var isBlinking = false
    @State private var isSurprised = false
    @State private var showHeart = false
    
    @State private var foodOffset: CGSize = .zero
    @State private var fishOpacity: Double = 1.0
    
    @State private var yarnOffset: CGSize = .zero
    @State private var yarnRotation: Double = 0
    
    let impactMed = UIImpactFeedbackGenerator(style: .medium)
    let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    
    let catBody = Color(red: 0.95, green: 0.85, blue: 0.75)
    let catMarkings = Color(red: 0.85, green: 0.65, blue: 0.45)
    
    var body: some View {
        VStack(spacing: 30) {
            // Cat Area
            ZStack {
                // Shadow
                Ellipse()
                    .fill(Color.black.opacity(0.1))
                    .frame(width: 120, height: 20)
                    .offset(y: 80)
                    .scaleEffect(squash)
                
                // Tail
                Capsule()
                    .fill(catMarkings)
                    .frame(width: 20, height: 60)
                    .offset(x: 60, y: 50)
                    .rotationEffect(.degrees(45))
                
                // Body
                Circle()
                    .fill(catBody)
                    .frame(width: 160, height: 160)
                    .scaleEffect(x: squash, y: 1/squash)
                    .scaleEffect(scale)
                    .onTapGesture { pokeCat() }
                    .gesture(
                        DragGesture(minimumDistance: 5)
                            .onChanged { _ in petCat() }
                            .onEnded { _ in stopPetting() }
                    )
                
                // Ears
                HStack(spacing: 60) {
                    Capsule()
                        .fill(catMarkings)
                        .frame(width: 30, height: 40)
                        .rotationEffect(.degrees(-30))
                    Capsule()
                        .fill(catMarkings)
                        .frame(width: 30, height: 40)
                        .rotationEffect(.degrees(30))
                }
                .offset(y: -70)
                .scaleEffect(scale)
                .scaleEffect(x: squash, y: 1/squash)
                
                // Face
                VStack(spacing: 8) {
                    // Eyes
                    HStack(spacing: 40) {
                        if isSurprised {
                            Circle().fill(Color.black).frame(width: 16, height: 16)
                            Circle().fill(Color.black).frame(width: 16, height: 16)
                        } else {
                            ZStack {
                                Circle().fill(Color.white).frame(width: 24, height: 24)
                                Circle().fill(Color.black).frame(width: 12, height: 12)
                                    .scaleEffect(y: isBlinking ? 0.1 : 1)
                                    .offset(eyesOffset)
                            }
                            ZStack {
                                Circle().fill(Color.white).frame(width: 24, height: 24)
                                Circle().fill(Color.black).frame(width: 12, height: 12)
                                    .scaleEffect(y: isBlinking ? 0.1 : 1)
                                    .offset(eyesOffset)
                            }
                        }
                    }
                    
                    // Nose and Mouth
                    VStack(spacing: 2) {
                        Ellipse().fill(Color.pink).frame(width: 8, height: 5)
                        Text(isSurprised ? "O" : "w")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black.opacity(0.6))
                    }
                }
                .offset(y: -10)
                .scaleEffect(scale)
                .scaleEffect(x: squash, y: 1/squash)
                
                if isSurprised {
                    Text("!")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.red)
                        .offset(x: 70, y: -70)
                }
                
                if showHeart {
                    Text("💖")
                        .font(.system(size: 30))
                        .offset(y: -90)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .zIndex(1)
            
            // Props Area panel
            HStack(spacing: 50) {
                Text("🐟")
                    .font(.system(size: 45))
                    .opacity(fishOpacity)
                    .offset(foodOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { v in
                                foodOffset = v.translation
                                updateEyes(target: v.translation)
                            }
                            .onEnded { v in
                                checkFoodDrop(location: v.translation)
                            }
                    )
                
                Text("🧶")
                    .font(.system(size: 45))
                    .offset(yarnOffset)
                    .rotationEffect(.degrees(yarnRotation))
                    .gesture(
                        DragGesture()
                            .onChanged { v in
                                yarnOffset = v.translation
                                yarnRotation = Double(v.translation.width)
                                updateEyes(target: v.translation)
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                    yarnOffset = .zero
                                    yarnRotation = 0
                                    eyesOffset = .zero
                                }
                            }
                    )
            }
            .zIndex(2)
        }
        .onAppear {
            startBlinking()
        }
    }
    
    // Logic Methods
    private func updateEyes(target: CGSize) {
        let dx = target.width
        let dy = target.height - 100 // props are generally dragged up towards face
        let distance = sqrt(dx*dx + dy*dy)
        let maxOffset: CGFloat = 5.0
        
        if distance > 0 {
            let ratio = min(maxOffset, distance / 15) / distance
            eyesOffset = CGSize(width: dx * ratio, height: dy * ratio)
        }
    }
    
    private func checkFoodDrop(location: CGSize) {
        if location.height < -60 && abs(location.width) < 60 {
            // Eat
            withAnimation(.easeIn(duration: 0.2)) {
                fishOpacity = 0
                foodOffset = CGSize(width: location.width, height: location.height - 20)
            }
            impactMed.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                scale = min(scale * 1.05, 1.3)
                squash = 1.1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring()) {
                    squash = 1.0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                foodOffset = .zero
                withAnimation(.easeIn) {
                    fishOpacity = 1.0
                }
                eyesOffset = .zero
            }
        } else {
            withAnimation(.spring()) {
                foodOffset = .zero
                eyesOffset = .zero
            }
        }
    }
    
    private func pokeCat() {
        impactHeavy.impactOccurred()
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            isSurprised = true
            squash = 0.85
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring()) {
                isSurprised = false
                squash = 1.0
            }
        }
    }
    
    private func petCat() {
        if Int.random(in: 0...5) == 0 {
            impactMed.impactOccurred()
            withAnimation {
                showHeart = true
            }
        }
    }
    
    private func stopPetting() {
        withAnimation {
            showHeart = false
        }
    }
    
    private func startBlinking() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 2...4), repeats: true) { timer in
            if !isSurprised {
                withAnimation(.linear(duration: 0.1)) {
                    isBlinking = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.linear(duration: 0.1)) {
                        isBlinking = false
                    }
                }
            }
            timer.fireDate = Date().addingTimeInterval(Double.random(in: 2...4))
        }
    }
}
