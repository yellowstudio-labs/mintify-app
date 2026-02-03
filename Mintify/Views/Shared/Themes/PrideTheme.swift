import SwiftUI

/// Pride Theme - Rainbow Gradient
struct PrideTheme: AppThemeProtocol {
    // MARK: - Backgrounds
    var mainBackground: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "1A1A2E"), Color(hex: "16213E")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Text Colors
    var textPrimary: Color { .white }
    var textSecondary: Color { .white.opacity(0.8) }
    
    // MARK: - Card Styles
    var cardBackground: Color { .white.opacity(0.1) }
    var cardBorder: Color { .white.opacity(0.25) }
    
    // MARK: - Overlay Colors
    var overlayLight: Color { .white.opacity(0.05) }
    var overlayMedium: Color { .white.opacity(0.1) }
    var overlayHeavy: Color { .white.opacity(0.2) }
    
    // MARK: - Sidebar Background
    var sidebarBackground: Color { .black.opacity(0.15) }
    
    // MARK: - Accent Colors
    var cleanPink: Color { Color(hex: "FF69B4") } // Hot Pink
    var cleanCyan: Color { Color(hex: "00D4FF") } // Bright Cyan
    
    // MARK: - Feature Gradients
    var storageGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "004DFF"), Color(hex: "008026")], // Blue to Green
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var memoryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FF69B4"), Color(hex: "750787")], // Pink to Purple
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var cpuGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FF8C00"), Color(hex: "FFED00")], // Orange to Yellow
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var mintifyGradient: LinearGradient {
        // Full Rainbow: Red → Orange → Yellow → Green → Blue → Purple
        LinearGradient(
            colors: [
                Color(hex: "E40303"), // Red
                Color(hex: "FF8C00"), // Orange
                Color(hex: "FFED00"), // Yellow
                Color(hex: "008026"), // Green
                Color(hex: "004DFF"), // Blue
                Color(hex: "750787")  // Purple
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var primaryActionGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "E40303"), Color(hex: "FF8C00"), Color(hex: "FFED00")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
