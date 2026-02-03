import SwiftUI

/// Main content view with tab navigation
struct MainContentView: View {
    @EnvironmentObject var appState: CleanerState
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.mainBackground
                .ignoresSafeArea()
            
            HStack(spacing: 0) {
                // Sidebar navigation
                sidebarView
                
                Divider()
                    .background(AppTheme.cardBorder)
                
                // Content based on selected tab
                Group {
                    switch appState.selectedTab {
                    case .cleaner:
                        ContentView()
                    case .largeFiles:
                        LargeFilesView()
                    case .duplicates:
                        DuplicateFilesView()
                    case .memory:
                        MemoryOptimizerView()
                    case .diskSpace:
                        DiskVisualizerView()
                    case .uninstaller:
                        AppUninstallerView()
                    case .settings:
                        // Settings now opens in separate window, fallback to cleaner
                        ContentView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private var sidebarView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 28) // Reduced from 42 to align with standard title bar
            
            // Logo header - centered
            VStack(spacing: 8) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 48, height: 48)
                
                Text("Mintify")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.bottom, 24)
            
            // Main tab buttons (excluding Settings)
            VStack(spacing: 4) {
                ForEach(MainTab.allCases.filter { $0 != .settings }, id: \.self) { tab in
                    SidebarTabButton(
                        tab: tab,
                        isSelected: appState.selectedTab == tab,
                        action: { appState.selectedTab = tab }
                    )
                }
            }
            
            Spacer()
            
            // Settings and About buttons at bottom
            HStack(spacing: 8) {
                // Settings button
                Button(action: { AppDelegate.shared?.showSettingsWindow() }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.cardBackground)
                        )
                }
                .buttonStyle(.plain)
                .help("Settings")
                
                // About button
                Button(action: { AppDelegate.shared?.showAboutWindow() }) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.cardBackground)
                        )
                }
                .buttonStyle(.plain)
                .help("About Mintify")
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
        .frame(width: 180)
        .background(AppTheme.sidebarBackground)
    }
}

struct SidebarTabButton: View {
    let tab: MainTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: 15))
                    .frame(width: 20)
                
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: .medium))
                
                Spacer()
            }
            .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? AppTheme.cardBackground : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
    }
}

#Preview {
    MainContentView()
        .environmentObject(CleanerState())
        .environmentObject(DuplicateFinderState())
}
