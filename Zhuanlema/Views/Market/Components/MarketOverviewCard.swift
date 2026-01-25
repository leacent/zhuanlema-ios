/**
 * 市场总览卡片
 * 展示今日赚钱比例和涨跌分布
 * 中国红渐变背景，突出打卡特色
 */
import SwiftUI

struct MarketOverviewCard: View {
    let stats: MarketStats?
    
    var body: some View {
        VStack(spacing: 0) {
            if let stats = stats {
                // 赚钱比例大号显示
                VStack(spacing: 8) {
                    Text("今日")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.0f%%", stats.winRate * 100))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("的人赚了")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                // 涨跌分布图
                VStack(spacing: 12) {
                    // 柱状图
                    HStack(alignment: .bottom, spacing: 0) {
                        // 上涨柱
                        Rectangle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: stats.upRatio > 0 ? nil : 0)
                            .frame(height: 8)
                        
                        // 下跌柱
                        Rectangle()
                            .fill(Color(uiColor: ColorPalette.tradingDown))
                            .frame(height: 8)
                    }
                    .frame(height: 8)
                    .cornerRadius(4)
                    
                    // 数据标签
                    HStack {
                        // 上涨
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.white)
                                .frame(width: 8, height: 8)
                            
                            Text("上涨 \(stats.upCount)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        // 下跌
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(uiColor: ColorPalette.tradingDown))
                                .frame(width: 8, height: 8)
                            
                            Text("下跌 \(stats.downCount)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        // 成交额
                        Text("成交 \(stats.totalVolume)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            } else {
                // 加载状态
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("加载市场数据...")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(height: 180)
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(uiColor: ColorPalette.brandPrimary),
                    Color(uiColor: ColorPalette.brandSecondary)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(
            color: Color(uiColor: ColorPalette.brandPrimary).opacity(0.3),
            radius: 10,
            x: 0,
            y: 5
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        // 有数据状态
        MarketOverviewCard(
            stats: MarketStats(
                upCount: 2733,
                downCount: 1336,
                flatCount: 135,
                totalVolume: "31,184亿",
                winRate: 0.62
            )
        )
        .padding()
        
        // 加载状态
        MarketOverviewCard(stats: nil)
            .padding()
    }
    .background(Color(uiColor: ColorPalette.bgPrimary))
}
