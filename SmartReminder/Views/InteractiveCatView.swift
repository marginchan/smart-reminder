import SwiftUI
import UIKit

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
                Path { path in
                    path.move(to: CGPoint(x: 60, y: 70))
                    path.addQuadCurve(to: CGPoint(x: 120, y: 20), control: CGPoint(x: 100, y: 70))
                }
                .stroke(catDarkColor, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(tailAngle), anchor: .init(x: 0.25, y: 0.8))
                
                // Main Body
                RoundedRectangle(cornerRadius: 60)
                    .fill(catColor)
                    .frame(width: 150, height: 110)
                    .offset(y: 30)
                    .scaleEffect(y: isBreathing ? 1.02 : 0.98, anchor: .bottom)
                
                // Belly
                Ellipse()
                    .fill(catBellyColor)
                    .frame(width: 100, height: 70)
                    .offset(y: 45)
                    .scaleEffect(y: isBreathing ? 1.03 : 0.97, anchor: .center)
                
                // Head
                ZStack {
                    // Ears
                    Path { path in
                        // Left ear
                        path.move(to: CGPoint(x: -35, y: -20))
                        path.addLine(to: CGPoint(x: -50, y: -60))
                        path.addLine(to: CGPoint(x: -15, y: -45))
                        
                        // Right ear
                        path.move(to: CGPoint(x: 35, y: -20))
                        path.addLine(to: CGPoint(x: 50, y: -60))
                        path.addLine(to: CGPoint(x: 15, y: -45))
                    }
                    .fill(catDarkColor)
                    
                    // Face
                    Ellipse()
                        .fill(catColor)
                        .frame(width: 120, height: 95)
                        .offset(y: -20)
                    
                    // Cheeks
                    Ellipse()
                        .fill(catBellyColor)
                        .frame(width: 100, height: 50)
                        .offset(y: 0)
                    
                    // Eyes
                    switch catState {
                    case .sleeping:
                        // Sleeping eyes (closed curves)
                        Path { path in
                            path.move(to: CGPoint(x: -30, y: -20))
                            path.addQuadCurve(to: CGPoint(x: -10, y: -20), control: CGPoint(x: -20, y: -15))
                            
                            path.move(to: CGPoint(x: 10, y: -20))
                            path.addQuadCurve(to: CGPoint(x: 30, y: -20), control: CGPoint(x: 20, y: -15))
                        }
                        .stroke(Color.black.opacity(0.7), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        
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
                        Path { path in
                            path.move(to: CGPoint(x: -30, y: -15))
                            path.addQuadCurve(to: CGPoint(x: -10, y: -15), control: CGPoint(x: -20, y: -25))
                            
                            path.move(to: CGPoint(x: 10, y: -15))
                            path.addQuadCurve(to: CGPoint(x: 30, y: -15), control: CGPoint(x: 20, y: -25))
                        }
                        .stroke(Color.black.opacity(0.8), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    }
                    
                    // Nose
                    Ellipse()
                        .fill(Color.pink)
                        .frame(width: 12, height: 8)
                        .offset(y: -5)
                    
                    // Mouth
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: -1))
                        path.addLine(to: CGPoint(x: 0, y: 5))
                        path.addQuadCurve(to: CGPoint(x: -12, y: 10), control: CGPoint(x: -5, y: 12))
                        path.move(to: CGPoint(x: 0, y: 5))
                        path.addQuadCurve(to: CGPoint(x: 12, y: 10), control: CGPoint(x: 5, y: 12))
                    }
                    .stroke(Color.black.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round))
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
