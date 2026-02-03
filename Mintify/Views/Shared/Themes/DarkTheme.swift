import SwiftUI

/// Dark Theme - Mystic Purple (Original)
struct DarkTheme: AppThemeProtocol {
    // MARK: - Backgrounds
    var mainBackground: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "2A1B3D"), Color(hex: "44318D")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Text Colors
    var textPrimary: Color { .white }
    var textSecondary: Color { .white.opacity(0.7) }
    
    // MARK: - Card Styles
    var cardBackground: Color { .white.opacity(0.1) }
    var cardBorder: Color { .white.opacity(0.2) }
    
    // MARK: - Overlay Colors
    var overlayLight: Color { .white.opacity(0.05) }
    var overlayMedium: Color { .white.opacity(0.1) }
    var overlayHeavy: Color { .white.opacity(0.2) }
    
    // MARK: - Sidebar Background
    var sidebarBackground: Color { .black.opacity(0.15) }
    
    // MARK: - Accent Colors
    var cleanPink: Color { Color(hex: "EB6CA4") }
    var cleanCyan: Color { Color(hex: "4CC9F0") }
    
    // MARK: - Feature Gradients
    var storageGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "4CC9F0"), Color(hex: "4361EE")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var memoryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "F72585"), Color(hex: "7209B7")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var cpuGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "F7D754"), Color(hex: "FF9F1C")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var mintifyGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "EB6CA4"), Color(hex: "7209B7")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var primaryActionGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "EB6CA4"), Color(hex: "C5DAF7")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
