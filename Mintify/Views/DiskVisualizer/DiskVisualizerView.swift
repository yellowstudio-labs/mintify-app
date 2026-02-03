import SwiftUI

/// View for Disk Space Visualizer feature
struct DiskVisualizerView: View {
    @EnvironmentObject var state: DiskSpaceState
    @ObservedObject var themeManager = ThemeManager.shared
    
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
                if !state.hasScanned && !state.isScanning {
                    // Init State - Request Permission
                    initStateView
                } else {
                    // Results
                    ScrollView {
                        VStack(spacing: 20) {
                            // Storage Overview
                            storageOverviewSection
                            
                            // Breadcrumb Navigation
                            if !state.currentPath.isEmpty && !state.isScanning {
                                breadcrumbNav
                            }
                            
                            // Disk Items Bar Chart (only show after scan completes)
                            if !state.isScanning {
                                diskItemsSection
                            }
                        }
                        .padding(24)
                    }
                }
            }
            
            // Inline loading indicator at bottom
            if state.isScanning {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        ProgressView()
                            .controlSize(.small)
                        Text(state.scanStatus)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(AppTheme.cardBackground)
                            .shadow(color: .black.opacity(0.2), radius: 8)
                    )
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            state.loadStorageOverview()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Image(systemName: "chart.pie")
                .foregroundStyle(AppTheme.storageGradient)
                .font(.title2)
            
            Text("Disk Space")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            if state.hasScanned {
                // Refresh Button (consistent with other views)
                Button(action: {
                    state.currentPath = []
                    startScan()
                }) {
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
                    .fill(AppTheme.storageGradient.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.storageGradient)
            }
            
            // Title and Description
            VStack(spacing: 12) {
                Text("Analyze Your Disk")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Scan your disk to see what's taking up space.\nIncludes system, user data, and applications.")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Storage Overview (always accessible)
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("Total")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                    Text(ByteCountFormatter.string(fromByteCount: state.storageOverview.total, countStyle: .file))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 4) {
                    Text("Used")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                    Text(ByteCountFormatter.string(fromByteCount: state.storageOverview.used, countStyle: .file))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.cleanCyan)
                }
                
                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("Free")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                    Text(ByteCountFormatter.string(fromByteCount: state.storageOverview.free, countStyle: .file))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cardBackground)
            )
            
            // Scan Button (consistent style with other views)
            Button(action: {
                requestPermissionAndScan()
            }) {
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
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Storage Overview Section
    
    private var storageOverviewSection: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "internaldrive.fill")
                    .foregroundStyle(AppTheme.storageGradient)
                    .font(.system(size: 16))
                
                Text("Macintosh HD")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Text(ByteCountFormatter.string(fromByteCount: state.storageOverview.total, countStyle: .file))
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            // Storage Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.storageGradient)
                        .frame(width: max(8, geo.size.width * usedPercentage))
                        .shadow(color: AppTheme.cleanCyan.opacity(0.3), radius: 4)
                }
            }
            .frame(height: 12)
            
            // Usage Labels
            HStack {
                LabelWithDot(text: "Used", value: ByteCountFormatter.string(fromByteCount: state.storageOverview.used, countStyle: .file), color: AppTheme.cleanCyan)
                
                Spacer()
                
                LabelWithDot(text: "Free", value: ByteCountFormatter.string(fromByteCount: state.storageOverview.free, countStyle: .file), color: .green)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
        )
    }
    
    private var usedPercentage: CGFloat {
        guard state.storageOverview.total > 0 else { return 0 }
        return CGFloat(state.storageOverview.used) / CGFloat(state.storageOverview.total)
    }
    
    // MARK: - Breadcrumb Navigation
    
    private var breadcrumbNav: some View {
        HStack(spacing: 8) {
            // Home button
            Button(action: {
                state.currentPath = []
                startScan()
            }) {
                Image(systemName: "house.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.cleanCyan)
            }
            .buttonStyle(.plain)
            
            ForEach(Array(state.currentPath.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Button(action: {
                        // Navigate to this level
                        state.currentPath = Array(state.currentPath.prefix(through: index))
                        drillDown(into: item)
                    }) {
                        Text(item.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(index == state.currentPath.count - 1 ? AppTheme.textPrimary : AppTheme.cleanCyan)
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    // MARK: - Disk Items Section
    
    private var diskItemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(state.currentPath.isEmpty ? "Space Usage by Folder" : state.currentPath.last?.name ?? "")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
            if state.diskItems.isEmpty && !state.isScanning {
                emptyState
            } else {
                VStack(spacing: 2) {
                    ForEach(state.diskItems.prefix(15)) { item in
                        DiskItemRow(item: item, maxSize: state.diskItems.first?.size ?? 1)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if item.isDirectory {
                                    state.currentPath.append(item)
                                    drillDown(into: item)
                                } else {
                                    // Open in Finder
                                    NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
                                }
                            }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.cardBackground)
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
        )
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.textSecondary)
            
            Text("No items to display")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
            
            Text("Some folders may require permission to access")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Helper Functions
    
    private func requestPermissionAndScan() {
        // Store reference to the main window BEFORE showing panel
        let mainWindow = NSApp.keyWindow ?? NSApp.windows.first(where: { $0.isVisible && $0.canBecomeKey })
        
        // Activate app first to prevent window from hiding
        NSApp.activate(ignoringOtherApps: true)
        
        // Use NSOpenPanel to request folder access
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select your Home folder to grant Mintify access for disk analysis"
        panel.prompt = "Grant Access"
        
        // Try to start at home directory
        if let homeURL = URL(string: "file://\(state.scanner.getHomeDirectoryPath())") {
            panel.directoryURL = homeURL
        }
        
        // Use beginSheetModal if we have a window, otherwise use begin
        if let window = mainWindow {
            panel.beginSheetModal(for: window) { response in
                // Start scan regardless (we'll show what we can access)
                self.startScan()
            }
        } else {
            panel.begin { response in
                // Re-activate app after panel closes to restore window focus
                DispatchQueue.main.async {
                    NSApp.activate(ignoringOtherApps: true)
                    
                    // Bring main window back to front
                    if let window = mainWindow {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                
                // Start scan regardless (we'll show what we can access)
                self.startScan()
            }
        }
    }
    
    private func startScan() {
        guard !state.isScanning else { return }
        
        state.isScanning = true
        state.diskItems = []
        state.hasScanned = true
        
        Task {
            let items = await state.scanner.scanHomeDirectory { status in
                Task { @MainActor in
                    state.scanStatus = status
                }
            }
            
            await MainActor.run {
                state.diskItems = items
                state.isScanning = false
            }
        }
    }
    
    private func drillDown(into item: DiskItem) {
        guard item.isDirectory else { return }
        
        state.isScanning = true
        state.diskItems = []
        
        Task {
            let items = await state.scanner.scanDirectory(at: item.url) { status in
                Task { @MainActor in
                    state.scanStatus = status
                }
            }
            
            await MainActor.run {
                state.diskItems = items
                state.isScanning = false
            }
        }
    }
}

// MARK: - Subviews

struct DiskItemRow: View {
    let item: DiskItem
    let maxSize: Int64
    
    private var barPercentage: CGFloat {
        guard maxSize > 0 else { return 0 }
        return CGFloat(item.size) / CGFloat(maxSize)
    }
    
    private var itemColor: Color {
        DiskItemCategory.from(path: item.path).color
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                .font(.system(size: 16))
                .foregroundColor(itemColor)
                .frame(width: 24)
            
            // Name and Size
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                
                // Size Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(itemColor)
                            .frame(width: max(4, geo.size.width * barPercentage))
                    }
                }
                .frame(height: 4)
            }
            
            Spacer()
            
            // Size and Percentage
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.formattedSize)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                
                if item.percentage > 0 {
                    Text(String(format: "%.1f%%", item.percentage))
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            // Chevron for directories
            if item.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

struct LabelWithDot: View {
    let text: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary)
            
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}

#Preview {
    DiskVisualizerView()
        .environmentObject(DiskSpaceState())
        .frame(width: 700, height: 600)
}
