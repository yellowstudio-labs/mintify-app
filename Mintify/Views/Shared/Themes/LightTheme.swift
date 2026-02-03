import SwiftUI

/// Light Theme - Clean White Background
/// A true light theme with white background and dark text for maximum readability
struct LightTheme: AppThemeProtocol {
    // MARK: - Backgrounds
    // Clean white to light grey gradient
    var mainBackground: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FFFFFF"), Color(hex: "F1F5F9")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Text Colors
    // Dark text for proper contrast on white background
    var textPrimary: Color { Color(hex: "1E293B") }    // Slate 800
    var textSecondary: Color { Color(hex: "64748B") }  // Slate 500
    
    // MARK: - Card Styles
    // Clean white cards
    var cardBackground: Color { Color.white }  // Pure white
    var cardBorder: Color { Color(hex: "E2E8F0") }      // Slate 200
    
    // MARK: - Sidebar Background
    var sidebarBackground: Color { Color.white }  // Pure white
    
    // MARK: - Overlay Colors (subtle grey for depth)
    var overlayLight: Color { Color(hex: "94A3B8").opacity(0.08) }   // Grey tint
    var overlayMedium: Color { Color(hex: "94A3B8").opacity(0.15) }
    var overlayHeavy: Color { Color(hex: "94A3B8").opacity(0.25) }
    
    // MARK: - Accent Colors (Vibrant for light bg)
    var cleanPink: Color { Color(hex: "EC4899") }   // Pink 500
    var cleanCyan: Color { Color(hex: "06B6D4") }   // Cyan 500
    
    // MARK: - Feature Gradients
    var storageGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "06B6D4"), Color(hex: "0891B2")],  // Cyan
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var memoryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "A855F7"), Color(hex: "9333EA")],  // Purple
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var cpuGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],  // Amber
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var mintifyGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "EC4899"), Color(hex: "8B5CF6")],  // Pink to Violet
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var primaryActionGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "EC4899"), Color(hex: "F472B6")],  // Pink shades
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
