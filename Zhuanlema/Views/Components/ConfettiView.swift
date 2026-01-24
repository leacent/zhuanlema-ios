/**
 * 撒花/粒子动效组件
 * 用于打卡成功后的视觉反馈
 */
import SwiftUI

/// 粒子类型
enum ConfettiType {
    case gold    // 金币粒子（赚了）
    case gray    // 灰色粒子（亏了）
}

/// 单个粒子
struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var rotation: Double
    var velocityX: CGFloat
    var velocityY: CGFloat
    var rotationSpeed: Double
    let symbol: String
    let color: Color
}

/// 撒花动效视图
struct ConfettiView: View {
    let type: ConfettiType
    let isActive: Bool
    let onComplete: (() -> Void)?
    
    @State private var particles: [Particle] = []
    @State private var timer: Timer?
    
    private let particleCount = 40
    
    init(type: ConfettiType, isActive: Bool, onComplete: (() -> Void)? = nil) {
        self.type = type
        self.isActive = isActive
        self.onComplete = onComplete
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Text(particle.symbol)
                        .font(.system(size: 24))
                        .foregroundColor(particle.color)
                        .scaleEffect(particle.scale)
                        .opacity(particle.opacity)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onChange(of: isActive) { oldValue, newValue in
                if newValue {
                    startAnimation(in: geometry.size)
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    /// 开始动画
    private func startAnimation(in size: CGSize) {
        // 清除旧粒子
        particles.removeAll()
        timer?.invalidate()
        
        // 生成新粒子
        let centerX = size.width / 2
        let centerY = size.height / 2 - 50 // 从按钮位置稍上方开始
        
        for _ in 0..<particleCount {
            let particle = createParticle(at: CGPoint(x: centerX, y: centerY))
            particles.append(particle)
        }
        
        // 动画更新
        var frameCount = 0
        let maxFrames = 90 // 约1.5秒 @ 60fps
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { t in
            frameCount += 1
            
            if frameCount >= maxFrames {
                t.invalidate()
                timer = nil
                
                withAnimation(.easeOut(duration: 0.3)) {
                    for i in particles.indices {
                        particles[i].opacity = 0
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    particles.removeAll()
                    onComplete?()
                }
                return
            }
            
            // 更新每个粒子的位置
            for i in particles.indices {
                particles[i].x += particles[i].velocityX
                particles[i].y += particles[i].velocityY
                particles[i].rotation += particles[i].rotationSpeed
                
                // 根据类型应用不同的物理效果
                switch type {
                case .gold:
                    // 金币向上喷射，然后下落
                    particles[i].velocityY += 0.3 // 重力
                    particles[i].velocityX *= 0.98 // 空气阻力
                case .gray:
                    // 灰色粒子缓慢下落
                    particles[i].velocityY += 0.15
                    particles[i].velocityX *= 0.95
                }
                
                // 逐渐淡出
                if frameCount > maxFrames / 2 {
                    particles[i].opacity -= 0.02
                    particles[i].opacity = max(0, particles[i].opacity)
                }
            }
        }
    }
    
    /// 创建单个粒子
    private func createParticle(at center: CGPoint) -> Particle {
        let angle = Double.random(in: 0..<360) * .pi / 180
        let speed: CGFloat
        let symbol: String
        let color: Color
        
        switch type {
        case .gold:
            speed = CGFloat.random(in: 8...15)
            symbol = ["💰", "🪙", "✨", "⭐️", "🌟"].randomElement()!
            color = Color(uiColor: ColorPalette.brandAccent)
        case .gray:
            speed = CGFloat.random(in: 4...8)
            symbol = ["💨", "🌫️", "☁️", "·", "•"].randomElement()!
            color = Color(uiColor: ColorPalette.textTertiary)
        }
        
        // 初始速度方向（主要向上）
        let velocityX = cos(angle) * speed * CGFloat.random(in: 0.5...1.5)
        let velocityY: CGFloat
        
        switch type {
        case .gold:
            velocityY = -abs(sin(angle) * speed) - CGFloat.random(in: 5...10) // 向上
        case .gray:
            velocityY = CGFloat.random(in: -2...2) // 水平散开
        }
        
        return Particle(
            x: center.x + CGFloat.random(in: -20...20),
            y: center.y + CGFloat.random(in: -20...20),
            scale: CGFloat.random(in: 0.6...1.2),
            opacity: 1.0,
            rotation: Double.random(in: 0...360),
            velocityX: velocityX,
            velocityY: velocityY,
            rotationSpeed: Double.random(in: -10...10),
            symbol: symbol,
            color: color
        )
    }
}

/// 撒花动效修饰器
struct ConfettiModifier: ViewModifier {
    let type: ConfettiType
    @Binding var isActive: Bool
    let onComplete: (() -> Void)?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            ConfettiView(type: type, isActive: isActive, onComplete: {
                isActive = false
                onComplete?()
            })
        }
    }
}

extension View {
    /// 添加撒花动效
    func confetti(type: ConfettiType, isActive: Binding<Bool>, onComplete: (() -> Void)? = nil) -> some View {
        modifier(ConfettiModifier(type: type, isActive: isActive, onComplete: onComplete))
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var showGold = false
        @State private var showGray = false
        
        var body: some View {
            ZStack {
                Color.black.opacity(0.1).ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Button("金币撒花") {
                        showGold = true
                    }
                    .padding()
                    .background(Color.yellow)
                    .cornerRadius(8)
                    
                    Button("灰色粒子") {
                        showGray = true
                    }
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .confetti(type: .gold, isActive: $showGold)
            .confetti(type: .gray, isActive: $showGray)
        }
    }
    
    return PreviewWrapper()
}
