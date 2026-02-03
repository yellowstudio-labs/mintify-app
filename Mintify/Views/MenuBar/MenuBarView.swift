import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: CleanerState
    @EnvironmentObject var permissionManager: PermissionManager
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var memoryStats: SystemStatsHelper.MemoryStats?
    @State private var cpuStats: SystemStatsHelper.CPUStats?
    @State private var storageStats: SystemStatsHelper.StorageStats?
    @State private var macInfo: SystemStatsHelper.MacInfo?
    
    // Detailed Stats State
    @State private var selectedDetail: DetailType = .none
    @State private var detailedMemory: SystemStatsHelper.DetailedMemoryStats?
    @State private var detailedProcesses: [SystemStatsHelper.AppProcess] = []
    @State private var trashSize: Int64 = 0
    
    private let statsHelper = SystemStatsHelper.shared
    private let refreshTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            MenuBarHeaderView()
            
            MenuBarDashboardView(
                storageStats: storageStats,
                memoryStats: memoryStats,
                cpuStats: cpuStats,
                selectedDetail: $selectedDetail,
                onRefresh: refreshDetailedStats
            )
            
            Divider()
                .opacity(0.1)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            centralContent
            
            Divider()
                .padding(.horizontal, 16)
                .opacity(0.3)
            
            MenuBarFooterView(lastScanTime: appState.lastScanTime)
        }
        .background(AppTheme.mainBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
        .frame(width: 320, height: selectedDetail != .none ? 600 : nil)
        .fixedSize(horizontal: false, vertical: selectedDetail == .none)
        .transaction { transaction in
            transaction.animation = nil
        }
        .onChange(of: selectedDetail) { _ in
            // Directly reposition window to anchor at top
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                AppDelegate.shared?.repositionOverlayWindowToTop()
            }
        }
        .onAppear {
            refreshStats()
        }
        .onReceive(refreshTimer) { _ in
            refreshStats()
        }
    }
    
    private func refreshStats() {
        DispatchQueue.global(qos: .userInitiated).async {
            let memory = statsHelper.getMemoryStats()
            let cpu = statsHelper.getCPUStats()
            let storage = statsHelper.getStorageStats()
            let macInfo = statsHelper.getMacInfo()
            
            DispatchQueue.main.async {
                memoryStats = memory
                cpuStats = cpu
                storageStats = storage
                self.macInfo = macInfo
                
                // If detail is open, refresh it too
                if selectedDetail != .none {
                    refreshDetailedStats()
                }
            }
        }
    }
    
    private func refreshDetailedStats() {
        guard selectedDetail != .none else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if selectedDetail == .memory {
                let detailed = statsHelper.getDetailedMemoryStats()
                let processes = statsHelper.getTopProcesses(by: .memory)
                DispatchQueue.main.async {
                    self.detailedMemory = detailed
                    self.detailedProcesses = processes
                }
            } else if selectedDetail == .cpu {
                let processes = statsHelper.getTopProcesses(by: .cpu)
                DispatchQueue.main.async {
                    self.detailedProcesses = processes
                }
            } else if selectedDetail == .storage {
                let trash = statsHelper.getTrashSize()
                DispatchQueue.main.async {
                    self.trashSize = trash
                }
            }
        }
    }
    @ViewBuilder
    private var centralContent: some View {
        Group {
            if selectedDetail != .none {
                detailView
                    .transition(.opacity)
            } else {
                MenuBarDefaultContentView(
                    appState: appState,
                    memoryStats: memoryStats,
                    storageStats: storageStats,
                    macInfo: macInfo
                )
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var detailView: some View {
        DetailStatsView(
            type: selectedDetail,
            memoryStats: memoryStats,
            cpuStats: cpuStats,
            storageStats: storageStats,
            detailedMemory: detailedMemory,
            topProcesses: detailedProcesses,
            trashSize: trashSize,
            onEmptyTrash: {
                statsHelper.emptyTrash()
                refreshDetailedStats()
            },
            onOpenLargeFiles: {
                AppDelegate.shared?.showMainWindow()
            },
            onBack: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedDetail = .none
                }
            }
        )
    }
}

// MARK: - Subviews

struct MenuBarHeaderView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.mintifyGradient)
                
                Text("Mintify")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            
            Spacer()
            
            Button(action: { AppDelegate.shared?.showSettingsWindow() }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(6)
                    .background(AppTheme.cardBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
    }
}

struct MenuBarDashboardView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    let storageStats: SystemStatsHelper.StorageStats?
    let memoryStats: SystemStatsHelper.MemoryStats?
    let cpuStats: SystemStatsHelper.CPUStats?
    @Binding var selectedDetail: DetailType
    var onRefresh: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            dashboardItem(
                type: .storage,
                value: Double(storageStats?.usedPercentage ?? 0),
                title: "Storage",
                subtitle: (storageStats?.formattedFree ?? "—") + " Free",
                icon: "internaldrive.fill",
                gradient: AppTheme.storageGradient,
                shadowColor: AppTheme.cleanCyan
            )
            
            dashboardItem(
                type: .memory,
                value: Double(memoryStats?.usedPercentage ?? 0),
                title: "Memory",
                subtitle: memoryStats?.formattedUsed ?? "—",
                icon: "memorychip.fill",
                gradient: AppTheme.memoryGradient,
                shadowColor: AppTheme.cleanPink
            )
            
            dashboardItem(
                type: .cpu,
                value: Double(cpuStats?.usagePercentage ?? 0),
                title: "CPU",
                subtitle: cpuStats != nil ? "\(Int(cpuStats!.usagePercentage))% • \(cpuStats!.thermalStateString)" : "—",
                icon: "cpu.fill",
                gradient: AppTheme.cpuGradient,
                shadowColor: Color(hex: "FF9F1C")
            )
        }
        .padding(.horizontal, 12)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }
    
    @ViewBuilder
    private func dashboardItem(
        type: DetailType,
        value: Double,
        title: String,
        subtitle: String,
        icon: String,
        gradient: LinearGradient,
        shadowColor: Color
    ) -> some View {
        DashboardItemView(
            type: type,
            value: value,
            title: title,
            subtitle: subtitle,
            icon: icon,
            gradient: gradient,
            shadowColor: shadowColor,
            selectedDetail: $selectedDetail,
            onRefresh: onRefresh
        )
    }
}

// Separate view to handle hover state
struct DashboardItemView: View {
    let type: DetailType
    let value: Double
    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    let shadowColor: Color
    @Binding var selectedDetail: DetailType
    var onRefresh: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        CircularProgressView(
            value: value,
            total: 100,
            title: title,
            subtitle: subtitle,
            icon: icon,
            gradient: gradient,
            shadowColor: shadowColor,
            isHovered: isHovered,
            isActive: selectedDetail == type
        )
        .frame(width: 80, height: 120) // Fixed size to prevent jitter when hover/active changes
        .opacity(selectedDetail != .none && selectedDetail != type ? 0.5 : 1.0)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
            DispatchQueue.main.async {
                if hovering {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDetail = selectedDetail == type ? .none : type
            }
            onRefresh()
        }
    }
}

struct MenuBarDefaultContentView: View {
    @ObservedObject var appState: CleanerState
    @ObservedObject var themeManager = ThemeManager.shared
    @EnvironmentObject var permissionManager: PermissionManager
    let memoryStats: SystemStatsHelper.MemoryStats?
    let storageStats: SystemStatsHelper.StorageStats?
    let macInfo: SystemStatsHelper.MacInfo?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            macInfoCard
            junkStatusCard
        }
        .padding(.horizontal, 16)
        .transition(.opacity)
    }

    private var junkStatusCard: some View {
        VStack(spacing: 12) {
            // Header with Stop button when scanning
            HStack {
                Text("System Junk")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                // Stop button when scanning
                if appState.isScanning {
                    Button(action: {
                        appState.stopScan()
                    }) {
                        Text("Stop")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Info Row similar to Mac Info
            HStack {
                if appState.isScanning {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.cleanCyan)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Scanning • \(Int(appState.scanProgress * 100))%")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppTheme.textPrimary)
                            Text(appState.currentScanningCategory)
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.textSecondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                } else if appState.hasScanned && appState.totalCleanableSize > 0 {
                    infoItem(icon: "trash", title: "Cleanable", value: appState.formattedTotalSize)
                } else if !permissionManager.hasHomeAccess {
                    infoItem(icon: "lock.fill", title: "Permission", value: "Access Required")
                } else {
                    infoItem(icon: "checkmark.circle", title: "Status", value: "Ready to Scan")
                }
                
                Spacer()
            }
            
            // Scan Button Row / Progress
            if appState.isScanning {
                ProgressView(value: appState.scanProgress)
                    .progressViewStyle(.linear)
                    .tint(AppTheme.cleanCyan)
                    .frame(height: 4)
            } else {
                // Two buttons: Scan Now + Open Menu
                HStack(spacing: 8) {
                    // Scan Now button
                    Button(action: {
                        if !permissionManager.hasHomeAccess {
                            permissionManager.requestHomeAccess { success in
                                if success {
                                    appState.startScan()
                                }
                            }
                        } else if !appState.isScanning {
                            appState.startScan()
                        }
                    }) {
                        HStack {
                            Image(systemName: permissionManager.hasHomeAccess ? "arrow.triangle.2.circlepath" : "lock.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text(permissionManager.hasHomeAccess ? "Scan Now" : "Grant Access")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: permissionManager.hasHomeAccess ? [AppTheme.cleanCyan, AppTheme.cleanCyan.opacity(0.8)] : [.orange, .orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    // Open Menu button
                    Button(action: { AppDelegate.shared?.showMainWindow() }) {
                        HStack {
                            Image(systemName: "macwindow")
                                .font(.system(size: 11, weight: .medium))
                            Text("Mintify App")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(AppTheme.cardBackground.opacity(0.8))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(AppTheme.cardBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }

    private var macInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mac Info")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
            if let info = macInfo {
                VStack(spacing: 8) {
                    // Line 1: Model
                    infoItem(icon: "laptopcomputer", title: "Model", value: info.modelName)
                    
                    Divider().opacity(0.1)

                    // Line 2: Chip + Disk
                    HStack {
                         infoItem(icon: "memorychip", title: "Chip", value: info.processorName)
                         Spacer()
                         infoItem(icon: "internaldrive", title: "Macintosh HD", value: info.volumeTotalSize)
                    }
                    
                    Divider().opacity(0.1)
                    
                    // Line 3: macOS + Memory
                    HStack {
                        infoItem(icon: "menucard", title: "macOS", value: info.osVersion)
                        Spacer()
                        infoItem(icon: "memorychip.fill", title: "Memory", value: info.memorySize)
                    }
                }
            } else {
                ProgressView()
                    .scaleEffect(0.5)
            }
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }
    
    private func infoItem(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 14)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary)
                Text(value)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8) // Allow scaling down to 80%
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }
}

struct MenuBarFooterView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    let lastScanTime: Date?
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if let lastScan = lastScanTime {
                Label {
                    Text("\(lastScan, style: .time)")
                } icon: {
                    Image(systemName: "clock")
                }
                .font(.system(size: 10))
                .foregroundColor(AppTheme.textSecondary)
            } else {
                 Text("Ready")
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: { AppDelegate.shared?.showMainWindow() }) {
                    Text("Open Menu")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundColor(AppTheme.textPrimary)
                .onHover { isHovered in
                    if isHovered { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
                
                Text("•")
                    .foregroundColor(AppTheme.textSecondary.opacity(0.5))
                
                Button(action: { AppDelegate.shared?.showAboutWindow() }) {
                    Text("About")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundColor(AppTheme.textSecondary)
                .onHover { isHovered in
                    if isHovered { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
                
                Text("•")
                    .foregroundColor(AppTheme.textSecondary.opacity(0.5))
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .onHover { isHovered in
                    if isHovered { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
            }
        }
        .padding(16)
    }
}

#Preview {
    MenuBarView()
        .environmentObject(CleanerState())
        .frame(height: 600)
}
