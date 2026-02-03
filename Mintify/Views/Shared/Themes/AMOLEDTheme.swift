import SwiftUI

/// AMOLED Theme - Pure Black
struct AMOLEDTheme: AppThemeProtocol {
    // MARK: - Backgrounds
    var mainBackground: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "000000"), Color(hex: "0A0A0A")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Text Colors
    var textPrimary: Color { .white }
    var textSecondary: Color { Color(hex: "ABABAB") }
    
    // MARK: - Card Styles
    var cardBackground: Color { Color(hex: "1A1A1A") }
    var cardBorder: Color { Color(hex: "2A2A2A") }
    
    // MARK: - Overlay Colors
    var overlayLight: Color { .white.opacity(0.05) }
    var overlayMedium: Color { .white.opacity(0.1) }
    var overlayHeavy: Color { .white.opacity(0.15) }
    
    // MARK: - Sidebar Background
    var sidebarBackground: Color { Color.black.opacity(0.3) }
    
    // MARK: - Accent Colors
    var cleanPink: Color { Color(hex: "FF4081") }
    var cleanCyan: Color { Color(hex: "00E5FF") }
    
    // MARK: - Feature Gradients
    var storageGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "00E5FF"), Color(hex: "00B8D4")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var memoryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FF4081"), Color(hex: "F50057")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var cpuGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FFD740"), Color(hex: "FFC400")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var mintifyGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FF4081"), Color(hex: "7C4DFF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var primaryActionGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FF4081"), Color(hex: "E040FB")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
