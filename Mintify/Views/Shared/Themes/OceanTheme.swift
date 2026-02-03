import SwiftUI

/// Ocean Theme - Deep Blue
struct OceanTheme: AppThemeProtocol {
    // MARK: - Backgrounds
    var mainBackground: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "0A1929"), Color(hex: "0D2137")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Text Colors
    var textPrimary: Color { Color(hex: "E3F2FD") } // Ice White
    var textSecondary: Color { Color(hex: "90CAF9") } // Sky Blue
    
    // MARK: - Card Styles
    var cardBackground: Color { Color(hex: "1E88E5").opacity(0.12) }
    var cardBorder: Color { Color(hex: "42A5F5").opacity(0.25) }
    
    // MARK: - Overlay Colors
    var overlayLight: Color { .white.opacity(0.05) }
    var overlayMedium: Color { .white.opacity(0.1) }
    var overlayHeavy: Color { .white.opacity(0.2) }
    
    // MARK: - Sidebar Background
    var sidebarBackground: Color { .black.opacity(0.15) }
    
    // MARK: - Accent Colors
    var cleanPink: Color { Color(hex: "FF7043") } // Coral for contrast
    var cleanCyan: Color { Color(hex: "00E5FF") } // Bright Cyan
    
    // MARK: - Feature Gradients
    var storageGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "4FC3F7"), Color(hex: "0288D1")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var memoryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "26C6DA"), Color(hex: "00838F")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var cpuGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FFAB40"), Color(hex: "FF6D00")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var mintifyGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "00E5FF"), Color(hex: "2979FF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var primaryActionGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "00E5FF"), Color(hex: "4FC3F7")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
