import SwiftUI

/// View for App Uninstaller feature
struct AppUninstallerView: View {
    @EnvironmentObject var state: AppUninstallerState
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var isRemoving = false
    @State private var showRemoveConfirm = false
    @State private var removeResult: (success: Int, failed: Int, revealed: Bool)?
    @State private var showRemoveResult = false
    @State private var showFinderInstructionSheet = false
    @State private var appPathToReveal: String = ""
    
    var body: some View {
        ZStack {
            AppTheme.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                
                Divider()
                    .background(AppTheme.cardBorder)
                
                // Main Content
                if state.apps.isEmpty {
                    // Init State (shown during scanning too)
                    initStateView
                } else {
                    HStack(spacing: 0) {
                        // App List (Left Panel)
                        appListPanel
                            .frame(width: 320)
                        
                        Divider()
                            .background(AppTheme.cardBorder)
                        
                        // Detail Panel (Right)
                        detailPanel
                    }
                }
            }
            
            // Remove Result Toast (only for non-/Applications apps)
            if showRemoveResult, let result = removeResult, !result.revealed {
                resultToast(result: result)
            }
        }
        .onChange(of: state.searchText) { _, newValue in
            state.filterApps(newValue)
        }
        .alert("Remove Application", isPresented: $showRemoveConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                removeSelectedApp()
            }
        } message: {
            if let app = state.selectedApp {
                if app.path.hasPrefix("/Applications") {
                    Text("Leftover files will be moved to Trash. You will then be guided to manually delete the app from Finder.")
                } else {
                    Text("Are you sure you want to remove \(app.name) and its leftovers? This will move them to Trash.")
                }
            }
        }
        .sheet(isPresented: $showFinderInstructionSheet) {
            finderInstructionSheet
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Image(systemName: "trash.circle")
                .foregroundStyle(AppTheme.cleanPink)
                .font(.title2)
            
            Text("App Uninstaller")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            if !state.apps.isEmpty {
                // Refresh Button (consistent with other views)
                Button(action: loadApps) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Scan")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(AppTheme.cleanCyan.opacity(0.8))
                    )
                }
                .buttonStyle(.plain)
                .disabled(state.isScanning)
            }
        }
    }
    
    // MARK: - Init State View
    
    private var initStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(AppTheme.cleanPink.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.cleanPink)
            }
            
            // Title and Description
            VStack(spacing: 12) {
                Text(state.isScanning ? "Scanning Applications..." : "App Uninstaller")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(state.isScanning ? "Finding installed applications and calculating sizes" : "Completely remove apps and their leftover files.\nFind hidden cache, preferences, and support files.")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            if !state.isScanning {
                // Features
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "app.badge.checkmark", text: "Scan all installed applications")
                    FeatureRow(icon: "magnifyingglass", text: "Find leftover files in Library")
                    FeatureRow(icon: "trash", text: "Move to Trash for safe removal")
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.cardBackground)
                )
                
                // Scan Button (consistent style with other views)
                Button(action: loadApps) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Scan")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(AppTheme.cleanCyan.opacity(0.8))
                    )
                }
                .buttonStyle(.plain)
            } else {
                // Progress Bar during scanning
                VStack(spacing: 16) {
                    // Current app being scanned
                    if !state.currentScanningApp.isEmpty {
                        Text(state.currentScanningApp)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(1)
                    }
                    
                    // Progress bar
                    VStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppTheme.cleanPink)
                                    .frame(width: state.scanTotal > 0 ? geo.size.width * CGFloat(state.scanProgress) / CGFloat(state.scanTotal) : 0)
                                    .animation(.easeInOut(duration: 0.2), value: state.scanProgress)
                            }
                        }
                        .frame(height: 8)
                        .frame(maxWidth: 300)
                        
                        // Progress text
                        if state.scanTotal > 0 {
                            Text("\(state.scanProgress) / \(state.scanTotal) apps")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - App List Panel
    
    private var appListPanel: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.textSecondary)
                
                TextField("Search apps...", text: $state.searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(AppTheme.textPrimary)
                
                if !state.searchText.isEmpty {
                    Button(action: { state.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            
            // App Count and Loading
            HStack {
                Text("\(state.filteredApps.count) apps")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                
                if state.isScanning {
                    ProgressView()
                        .controlSize(.mini)
                        .scaleEffect(0.7)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // App List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(state.filteredApps) { app in
                        AppListRow(app: app, isSelected: state.selectedApp?.id == app.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectApp(app)
                            }
                    }
                }
            }
        }
        .background(Color.white.opacity(0.02))
    }
    
    // MARK: - Detail Panel
    
    private var detailPanel: some View {
        Group {
            if let app = state.selectedApp {
                VStack(spacing: 0) {
                    // App Header
                    appDetailHeader(app: app)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Leftovers List
                    if state.isFindingLeftovers {
                        loadingLeftoversView
                    } else if app.leftovers.isEmpty {
                        emptyLeftoversView
                    } else {
                        leftoversList(for: app)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Action Buttons
                    actionButtonsView(for: app)
                }
            } else {
                emptySelectionView
            }
        }
    }
    
    private func appDetailHeader(app: AppInfo) -> some View {
        HStack(spacing: 16) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 64, height: 64)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(app.bundleIdentifier ?? "No bundle ID")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                
                HStack(spacing: 16) {
                    LabeledSize(label: "App", size: app.formattedBundleSize)
                    if !app.leftovers.isEmpty {
                        LabeledSize(label: "Leftovers", size: app.formattedLeftoversSize)
                    }
                    LabeledSize(label: "Total", size: app.formattedTotalSize, highlight: true)
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            // Reveal in Finder
            Button(action: {
                NSWorkspace.shared.selectFile(app.path, inFileViewerRootedAtPath: "")
            }) {
                Image(systemName: "folder")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .foregroundColor(AppTheme.textSecondary)
        }
        .padding(20)
    }
    
    private var loadingLeftoversView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.regular)
            Text("Finding leftovers...")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyLeftoversView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.green)
            Text("No leftovers found")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
            Text("This app appears to be cleanly installed")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func leftoversList(for app: AppInfo) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                // Group by type
                ForEach(LeftoverType.allCases, id: \.self) { type in
                    let typeLeftovers = app.leftovers.filter { $0.type == type }
                    if !typeLeftovers.isEmpty {
                        LeftoverSection(type: type, leftovers: typeLeftovers)
                    }
                }
            }
            .padding(16)
        }
    }
    
    private func actionButtonsView(for app: AppInfo) -> some View {
        HStack(spacing: 12) {
            // Complete Removal Button
            Button(action: {
                showRemoveConfirm = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                    Text("Move to Trash")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.cleanPink)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }
    
    private var emptySelectionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "app.dashed")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.textSecondary.opacity(0.5))
            
            Text("Select an app")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
            
            Text("Choose an app from the list to view its details and leftovers")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private func resultToast(result: (success: Int, failed: Int, revealed: Bool)) -> some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: result.failed == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(result.failed == 0 ? .green : .orange)
                    
                    Text(result.failed == 0 ? "Moved \(result.success) items to Trash" : "Moved \(result.success) items, \(result.failed) failed")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(result.failed == 0 ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
            )
            .padding(.bottom, 32)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var finderInstructionSheet: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppTheme.cleanCyan.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.green)
            }
            
            // Title
            Text("Leftover Files Removed")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            // Explanation about App Sandbox
            VStack(spacing: 12) {
                Text("One more step to complete")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Mintify runs in macOS App Sandbox for your security and privacy. This means we cannot directly delete apps in /Applications folder without requesting full disk access.")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text("We've cleaned up all leftover files. Please follow the steps below to complete the removal:")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            
            // Instructions
            VStack(alignment: .leading, spacing: 12) {
                InstructionStep(number: 1, text: "Click 'Open in Finder' button below")
                InstructionStep(number: 2, text: "Right-click on the highlighted app")
                InstructionStep(number: 3, text: "Select 'Move to Trash'")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            
            // Buttons
            HStack(spacing: 12) {
                Button(action: {
                    showFinderInstructionSheet = false
                }) {
                    Text("Close")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    NSWorkspace.shared.selectFile(appPathToReveal, inFileViewerRootedAtPath: "")
                    showFinderInstructionSheet = false
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder")
                        Text("Open in Finder")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.cleanCyan)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(32)
        .frame(width: 420)
        .background(AppTheme.mainBackground)
    }
    
    // MARK: - Helper Functions
    
    private func loadApps() {
        // Reset to init view for rescan
        state.apps = []
        state.filteredApps = []
        state.isScanning = true
        state.selectedApp = nil
        state.hasScanned = true
        state.scanProgress = 0
        state.scanTotal = 0
        state.currentScanningApp = ""
        
        Task {
            let scannedApps = await state.scanner.scanInstalledApps { current, total, appName in
                Task { @MainActor in
                    state.scanProgress = current
                    state.scanTotal = total
                    state.currentScanningApp = appName
                }
            }
            
            await MainActor.run {
                state.apps = scannedApps
                state.filteredApps = scannedApps
                state.isScanning = false
            }
        }
    }
    
    private func selectApp(_ app: AppInfo) {
        state.selectedApp = app
        state.isFindingLeftovers = true
        
        Task {
            let leftovers = await state.scanner.findLeftovers(for: app)
            
            await MainActor.run {
                if let index = state.apps.firstIndex(where: { $0.id == app.id }) {
                    state.apps[index].leftovers = leftovers
                    state.selectedApp = state.apps[index]
                }
                state.isFindingLeftovers = false
            }
        }
    }
    
    private func removeSelectedApp() {
        guard let app = state.selectedApp else { return }
        
        isRemoving = true
        
        Task {
            let result = await state.scanner.moveToTrash(app: app, includeLeftovers: true)
            
            await MainActor.run {
                removeResult = result
                isRemoving = false
                
                // Remove from list
                state.apps.removeAll { $0.id == app.id }
                state.filteredApps.removeAll { $0.id == app.id }
                state.selectedApp = nil
                
                // For /Applications apps, show instruction sheet instead of toast
                if result.revealed {
                    appPathToReveal = app.path
                    showFinderInstructionSheet = true
                } else {
                    // Show toast for non-/Applications apps
                    showRemoveResult = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showRemoveResult = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Subviews

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.cleanCyan)
                .font(.system(size: 14))
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.cleanCyan)
                    .frame(width: 24, height: 24)
                
                Text("\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}

struct AppListRow: View {
    let app: AppInfo
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                
                Text(app.formattedBundleSize)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isSelected ? AppTheme.cleanCyan.opacity(0.15) : Color.clear)
        .overlay(
            Rectangle()
                .fill(isSelected ? AppTheme.cleanCyan : Color.clear)
                .frame(width: 3),
            alignment: .leading
        )
    }
}

struct LabeledSize: View {
    let label: String
    let size: String
    var highlight: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppTheme.textSecondary)
            Text(size)
                .font(.system(size: 12, weight: highlight ? .bold : .medium))
                .foregroundColor(highlight ? AppTheme.cleanCyan : AppTheme.textPrimary)
        }
    }
}

struct LeftoverSection: View {
    let type: LeftoverType
    let leftovers: [LeftoverItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                    .foregroundColor(type.color)
                    .font(.system(size: 12))
                
                Text(type.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Text(ByteCountFormatter.string(fromByteCount: leftovers.reduce(0) { $0 + $1.size }, countStyle: .file))
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            // Items
            VStack(spacing: 0) {
                ForEach(leftovers) { leftover in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(type.color)
                            .font(.system(size: 12))
                        
                        Text(leftover.name)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(leftover.formattedSize)
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Button(action: {
                            NSWorkspace.shared.selectFile(leftover.path, inFileViewerRootedAtPath: "")
                        }) {
                            Image(systemName: "folder")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.03))
            )
        }
    }
}

#Preview {
    AppUninstallerView()
        .environmentObject(AppUninstallerState())
        .frame(width: 900, height: 600)
}
