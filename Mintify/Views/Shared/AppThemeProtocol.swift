import SwiftUI

/// Protocol defining all theme properties
protocol AppThemeProtocol {
    // MARK: - Backgrounds
    var mainBackground: LinearGradient { get }
    
    // MARK: - Text Colors
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    
    // MARK: - Card Styles
    var cardBackground: Color { get }
    var cardBorder: Color { get }
    
    // MARK: - Overlay Colors (for semi-transparent backgrounds)
    var overlayLight: Color { get }   // Lightest overlay (0.05-0.1)
    var overlayMedium: Color { get }  // Medium overlay (0.1-0.2)
    var overlayHeavy: Color { get }   // Heavy overlay (0.2-0.3)
    
    // MARK: - Sidebar Background
    var sidebarBackground: Color { get }
    
    // MARK: - Accent Colors
    var cleanPink: Color { get }
    var cleanCyan: Color { get }
    
    // MARK: - Feature Gradients
    var storageGradient: LinearGradient { get }
    var memoryGradient: LinearGradient { get }
    var cpuGradient: LinearGradient { get }
    var mintifyGradient: LinearGradient { get }
    var primaryActionGradient: LinearGradient { get }
}

/// Available theme types
enum ThemeType: String, CaseIterable, Identifiable {
    case dark = "Dark"
    case light = "Light"
    case pride = "Pride"
    case nature = "Nature"
    case sunset = "Sunset"
    case ocean = "Ocean"
    case amoled = "AMOLED"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .pride: return "flag.fill"
        case .nature: return "leaf.fill"
        case .sunset: return "sunset.fill"
        case .ocean: return "water.waves"
        case .amoled: return "circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .dark: return "Mystic Purple"
        case .light: return "Clean White"
        case .pride: return "Rainbow Gradient"
        case .nature: return "Forest Green"
        case .sunset: return "Golden Hour"
        case .ocean: return "Deep Blue"
        case .amoled: return "Pure Black"
        }
    }
    
    func createTheme() -> AppThemeProtocol {
        switch self {
        case .dark: return DarkTheme()
        case .light: return LightTheme()
        case .pride: return PrideTheme()
        case .nature: return NatureTheme()
        case .sunset: return SunsetTheme()
        case .ocean: return OceanTheme()
        case .amoled: return AMOLEDTheme()
        }
    }
}
