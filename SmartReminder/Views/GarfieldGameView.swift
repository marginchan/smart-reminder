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
    @State private var state: GarfieldState = .sleeping
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
        VStack(spacing: 40) {
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
                    .frame(width: 20, height: 100)
                    .offset(x: 80, y: 30)
                    .rotationEffect(.degrees(tailAngle + 45), anchor: .bottom)
                    // Tail stripes
                    .overlay(
                        VStack(spacing: 10) {
                            ForEach(0..<4) { _ in
                                Capsule()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 20, height: 5)
                            }
                        }
                        .offset(y: -10)
                    )
                
                // Body
                Circle()
                    .fill(garfieldOrange)
                    .frame(width: 170, height: 160)
                    .offset(y: 35)
                    .scaleEffect(y: isBreathing ? 1.02 : 0.98, anchor: .bottom)
                    // Body Stripes (Back)
                    .overlay(
                        VStack(spacing: 12) {
                            Capsule().fill(Color.black.opacity(0.6)).frame(width: 40, height: 6)
                            Capsule().fill(Color.black.opacity(0.6)).frame(width: 50, height: 6)
                            Capsule().fill(Color.black.opacity(0.6)).frame(width: 40, height: 6)
                        }
                        .offset(x: -60, y: 20)
                        .rotationEffect(.degrees(-15))
                    )
                    .overlay(
                        VStack(spacing: 12) {
                            Capsule().fill(Color.black.opacity(0.6)).frame(width: 40, height: 6)
                            Capsule().fill(Color.black.opacity(0.6)).frame(width: 50, height: 6)
                            Capsule().fill(Color.black.opacity(0.6)).frame(width: 40, height: 6)
                        }
                        .offset(x: 60, y: 20)
                        .rotationEffect(.degrees(15))
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in petHead() }
                    )
                    .onTapGesture { pokeBelly() }
                
                // Feet
                HStack(spacing: 50) {
                    Capsule().fill(garfieldOrange).frame(width: 40, height: 25).offset(y: 105)
                    Capsule().fill(garfieldOrange).frame(width: 40, height: 25).offset(y: 105)
                }
                
                // Head
                ZStack {
                    // Ears
                    Path { path in
                        path.move(to: CGPoint(x: -30, y: -45))
                        path.addLine(to: CGPoint(x: -55, y: -80))
                        path.addLine(to: CGPoint(x: -10, y: -65))
                        
                        path.move(to: CGPoint(x: 30, y: -45))
                        path.addLine(to: CGPoint(x: 55, y: -80))
                        path.addLine(to: CGPoint(x: 10, y: -65))
                    }
                    .fill(garfieldOrange)
                    
                    // Head shape
                    Ellipse()
                        .fill(garfieldOrange)
                        .frame(width: 140, height: 110)
                        .offset(y: -20)
                    
                    // Head Stripes
                    VStack(spacing: 6) {
                        Capsule().fill(Color.black.opacity(0.6)).frame(width: 15, height: 4)
                        Capsule().fill(Color.black.opacity(0.6)).frame(width: 25, height: 4)
                        Capsule().fill(Color.black.opacity(0.6)).frame(width: 15, height: 4)
                    }
                    .offset(y: -55)
                    
                    // Eyes Background (White overlapping)
                    HStack(spacing: -5) {
                        Ellipse()
                            .fill(Color.white)
                            .frame(width: 45, height: 55)
                            .overlay(Ellipse().stroke(Color.black, lineWidth: 1))
                        Ellipse()
                            .fill(Color.white)
                            .frame(width: 45, height: 55)
                            .overlay(Ellipse().stroke(Color.black, lineWidth: 1))
                    }
                    .offset(y: -25)
                    
                    // Pupils
                    HStack(spacing: 15) {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 8, height: 8)
                            .offset(eyesOffset)
                        Circle()
                            .fill(Color.black)
                            .frame(width: 8, height: 8)
                            .offset(eyesOffset)
                    }
                    .offset(y: -20)
                    
                    // Eyelids (Lazy/Half-closed)
                    if state == .sleeping {
                        HStack(spacing: -5) {
                            Rectangle()
                                .fill(garfieldOrange)
                                .frame(width: 45, height: 55)
                                .mask(Ellipse().frame(width: 45, height: 55))
                                .overlay(
                                    VStack {
                                        Spacer()
                                        Rectangle().fill(Color.black).frame(height: 2)
                                    }
                                )
                            Rectangle()
                                .fill(garfieldOrange)
                                .frame(width: 45, height: 55)
                                .mask(Ellipse().frame(width: 45, height: 55))
                                .overlay(
                                    VStack {
                                        Spacer()
                                        Rectangle().fill(Color.black).frame(height: 2)
                                    }
                                )
                        }
                        .offset(y: -25)
                    } else if state != .annoyed && state != .happy {
                        // Half closed
                        HStack(spacing: -5) {
                            Rectangle()
                                .fill(garfieldOrange)
                                .frame(width: 45, height: 25) // Covers top half
                                .mask(Ellipse().frame(width: 45, height: 55).offset(y: -15))
                                .overlay(VStack { Spacer(); Rectangle().fill(Color.black).frame(height: 1) })
                            Rectangle()
                                .fill(garfieldOrange)
                                .frame(width: 45, height: 25)
                                .mask(Ellipse().frame(width: 45, height: 55).offset(y: -15))
                                .overlay(VStack { Spacer(); Rectangle().fill(Color.black).frame(height: 1) })
                        }
                        .offset(y: -40)
                    } else if state == .happy {
                        // Happy eyes (completely covered with ^ shape)
                        HStack(spacing: -5) {
                            Ellipse().fill(garfieldOrange).frame(width: 45, height: 55)
                                .overlay(
                                    Path { path in
                                        path.move(to: CGPoint(x: 10, y: 30))
                                        path.addQuadCurve(to: CGPoint(x: 35, y: 30), control: CGPoint(x: 22.5, y: 15))
                                    }.stroke(Color.black, lineWidth: 3)
                                )
                            Ellipse().fill(garfieldOrange).frame(width: 45, height: 55)
                                .overlay(
                                    Path { path in
                                        path.move(to: CGPoint(x: 10, y: 30))
                                        path.addQuadCurve(to: CGPoint(x: 35, y: 30), control: CGPoint(x: 22.5, y: 15))
                                    }.stroke(Color.black, lineWidth: 3)
                                )
                        }
                        .offset(y: -25)
                    }
                    
                    // Muzzle (Yellow area)
                    HStack(spacing: -10) {
                        Ellipse()
                            .fill(garfieldYellow)
                            .frame(width: 55, height: 45)
                        Ellipse()
                            .fill(garfieldYellow)
                            .frame(width: 55, height: 45)
                    }
                    .offset(y: 15)
                    
                    // Nose
                    Ellipse()
                        .fill(Color.pink)
                        .frame(width: 16, height: 12)
                        .offset(y: 0)
                    
                    // Mouth
                    if state == .eating {
                        Circle()
                            .trim(from: 0.5, to: 1.0)
                            .fill(Color.black.opacity(0.8))
                            .frame(width: 30, height: 30)
                            .rotationEffect(.degrees(180))
                            .offset(y: 20)
                    } else {
                        Path { path in
                            path.move(to: CGPoint(x: -15, y: 25))
                            path.addQuadCurve(to: CGPoint(x: 0, y: 30), control: CGPoint(x: -10, y: 32))
                            path.addQuadCurve(to: CGPoint(x: 15, y: 25), control: CGPoint(x: 10, y: 32))
                        }
                        .stroke(Color.black, lineWidth: 2)
                    }
                    
                    // Whiskers
                    Group {
                        Path { path in path.move(to: CGPoint(x: -35, y: 15)); path.addLine(to: CGPoint(x: -70, y: 10)) }.stroke(Color.black, lineWidth: 1)
                        Path { path in path.move(to: CGPoint(x: -35, y: 20)); path.addLine(to: CGPoint(x: -70, y: 20)) }.stroke(Color.black, lineWidth: 1)
                        Path { path in path.move(to: CGPoint(x: -35, y: 25)); path.addLine(to: CGPoint(x: -70, y: 30)) }.stroke(Color.black, lineWidth: 1)
                        
                        Path { path in path.move(to: CGPoint(x: 35, y: 15)); path.addLine(to: CGPoint(x: 70, y: 10)) }.stroke(Color.black, lineWidth: 1)
                        Path { path in path.move(to: CGPoint(x: 35, y: 20)); path.addLine(to: CGPoint(x: 70, y: 20)) }.stroke(Color.black, lineWidth: 1)
                        Path { path in path.move(to: CGPoint(x: 35, y: 25)); path.addLine(to: CGPoint(x: 70, y: 30)) }.stroke(Color.black, lineWidth: 1)
                    }
                }
                .rotationEffect(.degrees(state == .sleeping ? 5 : 0))
                
                // Emotes
                if state == .sleeping {
                    Text("Zzz")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.gray)
                        .offset(x: 80, y: -80)
                } else if state == .annoyed {
                    Text("💢")
                        .font(.system(size: 32))
                        .offset(x: 70, y: -70)
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
            .frame(width: 300, height: 260)
            
            // Interaction Area (Lasagna)
            VStack {
                Text("喂千层面")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("🍝")
                    .font(.system(size: 50))
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
