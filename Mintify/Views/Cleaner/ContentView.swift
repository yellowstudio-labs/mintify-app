import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: CleanerState
    @EnvironmentObject var permissionManager: PermissionManager
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var showConfirmClean = false
    @State private var cleanResult: (success: Int, failed: Int)?
    @State private var isCleaning = false
    @State private var showPermissionAlert = false
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Always visible)
                headerView
                
                Divider()
                    .background(AppTheme.cardBorder)
                
                // Main Content
                if !appState.isScanning && appState.categories.isEmpty {
                    // Dashboard (Initial State)
                    ScrollView {
                        VStack(spacing: 24) {
                            SystemStatusHero(onScan: { startScanWithPermissionCheck() })
                            CategoryGrid()
                        }
                        .padding(24)
                    }
                } else {
                    // Results & Scanning State (Progressive List)
                    VStack(spacing: 0) {
                        // List of categories (found + placeholders)
                        categoryListView
                        
                        Divider().background(AppTheme.cardBorder)
                        footerView
                    }
                }
            }
            
            // Cleaning/Deleting progress overlay
            if isCleaning || appState.isDeleting {
                LoadingOverlay(message: isCleaning ? "Cleaning..." : "Deleting...")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Clean \(appState.formattedSelectedSize)?", isPresented: $showConfirmClean) {
            Button("Cancel", role: .cancel) { }
            Button("Clean", role: .destructive) {
                performClean()
            }
        } message: {
            Text("This will permanently delete the selected cached files. This action cannot be undone.")
        }
        .alert("Folder Access Required", isPresented: $showPermissionAlert) {
            Button("Grant Access") {
                permissionManager.requestHomeAccess { _ in }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Mintify needs access to your Home folder to scan for files. Would you like to grant access now?")
        }
    }
    
    // MARK: - Permission Check
    private func startScanWithPermissionCheck() {
        if !permissionManager.hasHomeAccess {
            permissionManager.requestHomeAccess { success in
                if success {
                    appState.startScan()
                }
            }
        } else {
            appState.startScan()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 16) {
            Image(systemName: "sparkles")
                .foregroundStyle(AppTheme.mintifyGradient)
                .font(.title2)
            
            Text("Storage Cleaner")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            if appState.isScanning {
                // Simplified Header Status
                HStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(AppTheme.cleanCyan)
                    
                    Text("Scanning...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Button(action: { appState.stopScan() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(AppTheme.overlayMedium)
                )
            } else if !appState.categories.isEmpty {
                // Only show Scan button after first scan has results
                HStack(spacing: 12) {
                    if let lastScan = appState.lastScanTime {
                        Text("Last scan: \(lastScan, formatter: relativeDateFormatter)")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    // Scan/Rescan Button
                    Button(action: { startScanWithPermissionCheck() }) {
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
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // ... (CategoryList) ...

    
    // Helper for date formatting
    private var relativeDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }
    
    // MARK: - Category List (Results)
    
    private var categoryListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Existing content
                ForEach($appState.categories) { $category in
                    CategoryCardView(category: $category, onDelete: { path in
                        appState.removeItemFromList(path: path)
                    })
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                // Skeletons for remaining items
                if appState.isScanning {
                    // Show a fixed number or calculated number of skeletons
                    ForEach(0..<max(1, appState.remainingCategoriesToScan), id: \.self) { index in
                        SkeletonCategoryCard()
                            .transition(.opacity)
                    }
                }
            }
            .padding(20)
            .animation(.default, value: appState.categories.count)
        }
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            if appState.isScanning {
                // Scanning Path Status (Bottom Bar)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Scanning Directory:")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                    Text(appState.currentScanningCategory)
                        .font(.caption)
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
            } else {
                Button(action: { appState.toggleSelectAll() }) {
                    HStack(spacing: 6) {
                        Image(systemName: appState.allSelected ? "checkmark.square.fill" : "square")
                            .foregroundColor(appState.allSelected ? AppTheme.cleanCyan : AppTheme.textSecondary)
                        Text("Select All")
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .disabled(appState.categories.isEmpty)
                
                Spacer()
                
                // Info
                VStack(alignment: .trailing, spacing: 2) {
                    Text(appState.formattedSelectedSize)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.cleanCyan)
                    Text("Selected for cleanup")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.trailing, 16)
                
                // Clean Button
                Button(action: { showConfirmClean = true }) {
                    HStack(spacing: 8) {
                        if isCleaning {
                            ProgressView().controlSize(.small).tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text("Clean Now")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                appState.totalSelectedSize > 0 && !isCleaning
                                ? AppTheme.cleanPink
                                : Color.gray.opacity(0.3)
                            )
                    )
                    .shadow(color: appState.totalSelectedSize > 0 ? AppTheme.cleanPink.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(appState.totalSelectedSize == 0 || isCleaning)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(AppTheme.cardBackground)
    }
    
    private func performClean() {
        isCleaning = true
        cleanResult = nil
        appState.performClean { success, failed in
            cleanResult = (success, failed)
            isCleaning = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                cleanResult = nil
            }
        }
    }
}

// MARK: - Skeleton Category Card

struct SkeletonCategoryCard: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Placeholder
            Circle()
                .fill(AppTheme.overlayMedium)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 8) {
                // Title Placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.overlayMedium)
                    .frame(width: 120, height: 16)
                
                // Subtitle Placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.overlayLight)
                    .frame(width: 180, height: 12)
            }
            
            Spacer()
            
            // Toggle Placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(AppTheme.overlayMedium)
                .frame(width: 40, height: 20)
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
        .overlay(
            GeometryReader { geo in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, AppTheme.overlayLight, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: isAnimating ? geo.size.width : -geo.size.width * 0.5)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Dashboard Components

struct SystemStatusHero: View {
    @ObservedObject var themeManager = ThemeManager.shared
    let onScan: () -> Void
    @State private var diskUsage: Double = 0.0 // 0.0 to 1.0
    @State private var freeSpace: String = "-- GB"
    @State private var totalSpace: String = "-- GB"
    
    var body: some View {
        ViewThatFits {
            // Wide Layout
            HStack(spacing: 32) {
                chartView
                vDivider
                infoView
                Spacer()
                actionButton
            }
            
            // Narrow Layout
            VStack(spacing: 24) {
                chartView
                infoView
                actionButton
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
        )
        .onAppear {
            updateDiskSpace()
        }
    }
    
    private var vDivider: some View {
        Rectangle()
            .fill(AppTheme.cardBorder)
            .frame(width: 1, height: 100)
    }
    
    private var chartView: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.overlayMedium, lineWidth: 12)
                .frame(width: 140, height: 140)
            
            Circle()
                .trim(from: 0, to: diskUsage)
                .stroke(
                    AppTheme.mintifyGradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
                .shadow(color: AppTheme.cleanCyan.opacity(0.3), radius: 8)
            
            VStack(spacing: 2) {
                Text("\(Int(diskUsage * 100))%")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Text("Used")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
    
    private var infoView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Macintosh HD")
                    .font(.title2.bold())
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Your system is ready for a cleanup.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            HStack(spacing: 24) {
                StatusMetric(label: "Free", value: freeSpace, color: AppTheme.cleanCyan)
                StatusMetric(label: "Total", value: totalSpace, color: AppTheme.textSecondary)
            }
        }
    }
    
    private var actionButton: some View {
        Button(action: onScan) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                Text("Scan Now")
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(AppTheme.textPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(AppTheme.cleanCyan.opacity(0.8))
            )
            .shadow(color: AppTheme.cleanCyan.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private func updateDiskSpace() {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory())
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
            if let capacity = values.volumeTotalCapacity, let available = values.volumeAvailableCapacity {
                let used = Int64(capacity - available)
                self.diskUsage = Double(used) / Double(capacity)
                self.totalSpace = ByteCountFormatter.string(fromByteCount: Int64(capacity), countStyle: .file)
                self.freeSpace = ByteCountFormatter.string(fromByteCount: Int64(available), countStyle: .file)
            }
        } catch {
            print("Error retrieving disk usage: \(error)")
        }
    }
}

struct StatusMetric: View {
    @ObservedObject var themeManager = ThemeManager.shared
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary.opacity(0.7))
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
    }
}

struct CategoryGrid: View {
    @ObservedObject var themeManager = ThemeManager.shared
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Areas to Clean")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.leading, 4)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(CleanCategory.allCases, id: \.self) { category in
                    DashboardCard(
                        icon: category.icon,
                        title: category.rawValue,
                        subtitle: category.description,
                        color: colorFor(category)
                    )
                }
            }
        }
    }
    
    private func colorFor(_ category: CleanCategory) -> Color {
        switch category {
        case .userCaches: return AppTheme.cleanCyan
        case .browserCaches: return Color(hex: "9D4EDD") // Brighter Purple
        case .logs: return Color(hex: "FF9F1C")          // Orange
        case .xcode: return Color(hex: "4CC9F0")         // Cyan/Light Blue
        case .developerTools: return .green              // Green
        case .trash: return AppTheme.cleanPink           // Red/Pink
        }
    }
}

struct DashboardCard: View {
    @ObservedObject var themeManager = ThemeManager.shared
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 85)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                )
        )
    }
}

