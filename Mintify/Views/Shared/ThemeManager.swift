import SwiftUI

/// Manages theme selection and persistence
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppThemeProtocol
    @AppStorage("selectedTheme") private var selectedThemeId: String = ThemeType.dark.rawValue
    
    var currentThemeType: ThemeType {
        ThemeType(rawValue: selectedThemeId) ?? .dark
    }
    
    init() {
        let themeType = ThemeType(rawValue: UserDefaults.standard.string(forKey: "selectedTheme") ?? ThemeType.dark.rawValue) ?? .dark
        currentTheme = themeType.createTheme()
    }
    
    func switchTheme(to themeType: ThemeType) {
        selectedThemeId = themeType.rawValue
        currentTheme = themeType.createTheme()
    }
}

// MARK: - Convenience accessor for backward compatibility
/// Global theme accessor that bridges old static calls to ThemeManager
struct AppTheme {
    private static var manager: ThemeManager { ThemeManager.shared }
    
    // MARK: - Backgrounds
    static var mainBackground: LinearGradient { manager.currentTheme.mainBackground }
    
    // MARK: - Text Colors
    static var textPrimary: Color { manager.currentTheme.textPrimary }
    static var textSecondary: Color { manager.currentTheme.textSecondary }
    
    // MARK: - Card Styles
    static var cardBackground: Color { manager.currentTheme.cardBackground }
    static var cardBorder: Color { manager.currentTheme.cardBorder }
    
    // MARK: - Overlay Colors
    static var overlayLight: Color { manager.currentTheme.overlayLight }
    static var overlayMedium: Color { manager.currentTheme.overlayMedium }
    static var overlayHeavy: Color { manager.currentTheme.overlayHeavy }
    
    // MARK: - Sidebar Background
    static var sidebarBackground: Color { manager.currentTheme.sidebarBackground }
    
    // MARK: - Accent Colors
    static var cleanPink: Color { manager.currentTheme.cleanPink }
    static var cleanCyan: Color { manager.currentTheme.cleanCyan }
    
    // MARK: - Feature Gradients
    static var storageGradient: LinearGradient { manager.currentTheme.storageGradient }
    static var memoryGradient: LinearGradient { manager.currentTheme.memoryGradient }
    static var cpuGradient: LinearGradient { manager.currentTheme.cpuGradient }
    static var mintifyGradient: LinearGradient { manager.currentTheme.mintifyGradient }
    static var primaryActionGradient: LinearGradient { manager.currentTheme.primaryActionGradient }
}
