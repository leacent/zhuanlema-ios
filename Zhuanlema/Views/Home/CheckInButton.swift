/**
 * 圆形打卡按钮组件
 * 中国红主题，带弹性动画
 */
import SwiftUI

struct CheckInButton: View {
    let isCheckedIn: Bool
    let action: () -> Void
    
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            // 弹性动画
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 0.9
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
            
            action()
        }) {
            ZStack {
                // 背景圆
                Circle()
                    .fill(isCheckedIn ? Color(uiColor: ColorPalette.textSecondary) : Color(uiColor: ColorPalette.brandPrimary))
                    .frame(width: 150, height: 150)
                    .shadow(color: Color(uiColor: ColorPalette.brandPrimary).opacity(0.3), radius: 20, x: 0, y: 10)
                
                // 文字
                VStack(spacing: 8) {
                    Text(isCheckedIn ? "已打卡" : "赚了吗?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    if !isCheckedIn {
                        Text("点击打卡")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .scaleEffect(scale)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 40) {
        CheckInButton(isCheckedIn: false) {
            print("未打卡 - 点击")
        }
        
        CheckInButton(isCheckedIn: true) {
            print("已打卡 - 点击")
        }
    }
    .padding()
    .background(Color(uiColor: ColorPalette.bgPrimary))
}
