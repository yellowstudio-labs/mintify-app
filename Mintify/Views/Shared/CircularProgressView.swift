import SwiftUI

struct CircularProgressView: View {
    let value: Double
    let total: Double
    let title: String
    let subtitle: String?
    let icon: String
    let gradient: LinearGradient
    let shadowColor: Color
    var size: CGFloat = 70
    var lineWidth: CGFloat = 6
    var isHovered: Bool = false
    var isActive: Bool = false
    
    // Compute actual size based on hover/active state (no scaleEffect)
    private var scaleFactor: CGFloat {
        if isActive {
            return 1.1
        } else if isHovered {
            return 1.0
        } else {
            return 0.9
        }
    }
    
    private var actualSize: CGFloat {
        return size * scaleFactor
    }
    
    private var actualLineWidth: CGFloat {
        return lineWidth * scaleFactor
    }
    
    // Fixed font sizes - don't scale too much to prevent text overflow
    private var actualTitleFontSize: CGFloat {
        return 12 // Fixed size
    }
    
    private var actualSubtitleFontSize: CGFloat {
        return 10 // Fixed size
    }
    
    private var actualTopPadding: CGFloat {
        return 4
    }
    
    var percentage: Double {
        return min(max(value / total, 0), 1)
    }
    
    var displayValue: String {
        return "\(Int(percentage * 100))%"
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background Circle
                Circle()
                    .stroke(AppTheme.overlayMedium, lineWidth: actualLineWidth)
                
                // Progress Circle
                Circle()
                    .trim(from: 0.0, to: CGFloat(percentage))
                    .stroke(
                        gradient,
                        style: StrokeStyle(lineWidth: actualLineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: shadowColor.opacity(isActive ? 0.6 : 0.4), radius: isActive ? 6 : 4, x: 0, y: 0)
                
                // Center Content
                VStack(spacing: 0) {
                    Image(systemName: icon)
                        .font(.system(size: actualSize * 0.22, weight: .semibold))
                        .foregroundStyle(gradient)
                        .padding(.bottom, 2)
                    
                    Text(displayValue)
                        .font(.system(size: actualSize * 0.22, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .opacity(isActive ? 0.9 : 1.0)
            }
            .frame(width: actualSize, height: actualSize)
            .background(
                Circle()
                    .fill(AppTheme.cardBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(-actualLineWidth/2)
            )
            
            Text(title)
                .font(.system(size: actualTitleFontSize, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.top, actualTopPadding)
            
            if let sub = subtitle {
                Text(sub)
                    .font(.system(size: actualSubtitleFontSize, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        // Single smooth spring animation for all size changes
        .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0), value: scaleFactor)
    }
}
