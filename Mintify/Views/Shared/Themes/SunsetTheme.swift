import SwiftUI

/// Sunset Theme - Golden Hour
struct SunsetTheme: AppThemeProtocol {
    // MARK: - Backgrounds
    var mainBackground: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "1A0A2E"), Color(hex: "2D1B4E")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Text Colors
    var textPrimary: Color { Color(hex: "FFF8E1") } // Warm White
    var textSecondary: Color { Color(hex: "FFCC80") } // Peach
    
    // MARK: - Card Styles
    var cardBackground: Color { Color(hex: "FF6B35").opacity(0.1) }
    var cardBorder: Color { Color(hex: "FF9800").opacity(0.25) }
    
    // MARK: - Overlay Colors
    var overlayLight: Color { .white.opacity(0.05) }
    var overlayMedium: Color { .white.opacity(0.1) }
    var overlayHeavy: Color { .white.opacity(0.2) }
    
    // MARK: - Sidebar Background
    var sidebarBackground: Color { .black.opacity(0.15) }
    
    // MARK: - Accent Colors
    var cleanPink: Color { Color(hex: "FF6B6B") } // Coral Red
    var cleanCyan: Color { Color(hex: "FFD93D") } // Golden Yellow
    
    // MARK: - Feature Gradients
    var storageGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FFD93D"), Color(hex: "FF6B35")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var memoryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FF6B6B"), Color(hex: "C44569")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var cpuGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FFA726"), Color(hex: "FF7043")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var mintifyGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FF6B35"), Color(hex: "F7931E")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var primaryActionGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FF6B35"), Color(hex: "FFD93D")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
