/**
 * 社区热点话题组件
 * 展示社区高频标签，点击跳转到相关内容
 */
import SwiftUI

struct TrendingTopicsView: View {
    let topics: [String]
    let onTopicTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                
                Text("社区热点")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(uiColor: ColorPalette.textPrimary))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // 话题标签横向滚动
            if topics.isEmpty {
                Text("暂无热点话题")
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: ColorPalette.textTertiary))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(topics, id: \.self) { topic in
                            TopicTag(
                                topic: topic,
                                action: { onTopicTap(topic) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 12)
        .background(Color(uiColor: ColorPalette.bgSecondary))
        .cornerRadius(12)
    }
}

/// 话题标签
struct TopicTag: View {
    let topic: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }) {
            Text("#\(topic)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(uiColor: ColorPalette.brandPrimary))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(uiColor: ColorPalette.brandLight))
                .cornerRadius(16)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    VStack(spacing: 16) {
        // 有数据状态
        TrendingTopicsView(
            topics: ["大盘", "茅台", "新能源", "芯片概念", "价值投资", "今日复盘"],
            onTopicTap: { topic in print("点击话题: \(topic)") }
        )
        .padding()
        
        // 空状态
        TrendingTopicsView(
            topics: [],
            onTopicTap: { _ in }
        )
        .padding()
    }
    .background(Color(uiColor: ColorPalette.bgPrimary))
}
