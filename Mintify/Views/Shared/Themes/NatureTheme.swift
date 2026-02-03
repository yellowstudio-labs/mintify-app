import SwiftUI

/// Nature Theme - Forest Green
struct NatureTheme: AppThemeProtocol {
    // MARK: - Backgrounds
    var mainBackground: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "0D1F22"), Color(hex: "1A3C34")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Text Colors
    var textPrimary: Color { Color(hex: "E8F5E9") } // Mint White
    var textSecondary: Color { Color(hex: "A5D6A7") } // Light Green
    
    // MARK: - Card Styles
    var cardBackground: Color { Color(hex: "2E7D32").opacity(0.15) }
    var cardBorder: Color { Color(hex: "4CAF50").opacity(0.3) }
    
    // MARK: - Overlay Colors
    var overlayLight: Color { .white.opacity(0.05) }
    var overlayMedium: Color { .white.opacity(0.1) }
    var overlayHeavy: Color { .white.opacity(0.2) }
    
    // MARK: - Sidebar Background
    var sidebarBackground: Color { .black.opacity(0.15) }
    
    // MARK: - Accent Colors
    var cleanPink: Color { Color(hex: "FF7043") } // Coral for warnings/delete
    var cleanCyan: Color { Color(hex: "26A69A") } // Teal
    
    // MARK: - Feature Gradients
    var storageGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "66BB6A"), Color(hex: "43A047")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var memoryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "26C6DA"), Color(hex: "00ACC1")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var cpuGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FFCA28"), Color(hex: "FFB300")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var mintifyGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "26A69A"), Color(hex: "00897B")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var primaryActionGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "66BB6A"), Color(hex: "26A69A")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
