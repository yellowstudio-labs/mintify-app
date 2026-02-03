import SwiftUI

// MARK: - Detailed Stats Views

enum DetailType {
    case memory
    case cpu
    case storage
    case none
}

struct DetailStatsView: View {
    @EnvironmentObject var appState: CleanerState
    
    let type: DetailType
    let memoryStats: SystemStatsHelper.MemoryStats?
    let cpuStats: SystemStatsHelper.CPUStats?
    let storageStats: SystemStatsHelper.StorageStats?
    let detailedMemory: SystemStatsHelper.DetailedMemoryStats?
    let topProcesses: [SystemStatsHelper.AppProcess]
    let trashSize: Int64
    
    var onEmptyTrash: () -> Void
    var onOpenLargeFiles: () -> Void
    var onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header Title with Back Button
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(8)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Text(titleForType)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            if type == .storage {
                storageBody
            } else {
                // Key Metrics Grid
                metricsGrid
                
                // Top Consumers
                consumersList
            }
        }
        .padding(16)
        // Removed fixed width so it adapts to parent container
    }
    
    private var titleForType: String {
        switch type {
        case .memory: return "Memory Details"
        case .cpu: return "Processor Load"
        case .storage: return "Disk Usage"
        case .none: return ""
        }
    }
            
    // MARK: - Metrics Grid
    
    private var metricsGrid: some View {
        HStack(spacing: 12) {
            if type == .memory {
                // Pressure
                MetricCard(
                    title: "Pressure",
                    value: "\(Int(detailedMemory?.pressurePercentage ?? 0))%",
                    color: detailedMemory?.pressurePercentage ?? 0 > 60 ? AppTheme.cleanPink : .green
                )
                
                // Swap
                MetricCard(
                    title: "Swap Used",
                    value: detailedMemory?.formattedSwap ?? "0 B",
                    color: AppTheme.textSecondary
                )
            } else {
                // CPU Core Count
                MetricCard(
                    title: "Cores",
                    value: "\(cpuStats?.coreCount ?? 0)",
                    color: AppTheme.textPrimary
                )
                
                // Idle
                MetricCard(
                    title: "Idle",
                    value: String(format: "%.0f%%", 100 - (cpuStats?.usagePercentage ?? 0)),
                    color: AppTheme.textSecondary
                )
            }
        }
    }
    
    // MARK: - Storage Body
    
    private var storageBody: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                // Storage Overview Card
                storageOverviewCard
                
                // Quick Stats Grid
                storageQuickStats
                
                // System Junk Card
                storageSystemJunkCard
            }
        }
    }
    
    // MARK: - Storage Overview Card
    
    private var storageOverviewCard: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.storageGradient)
                Text("Macintosh HD")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text(storageStats?.formattedTotal ?? "--")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            // Storage Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.white.opacity(0.08))
                    
                    // Used Space
                    RoundedRectangle(cornerRadius: 5)
                        .fill(AppTheme.storageGradient)
                        .frame(width: max(6, geo.size.width * CGFloat((storageStats?.usedPercentage ?? 0) / 100)))
                        .shadow(color: AppTheme.cleanCyan.opacity(0.3), radius: 2, x: 0, y: 0)
                }
            }
            .frame(height: 10)
            
            // Usage Labels
            HStack(spacing: 12) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(AppTheme.cleanCyan)
                        .frame(width: 6, height: 6)
                    Text("Used")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textSecondary)
                    Text(storageStats?.formattedUsed ?? "--")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                Spacer()
                
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                    Text("Free")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textSecondary)
                    Text(storageStats?.formattedFree ?? "--")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.cardBorder, lineWidth: 1))
    }
    
    // MARK: - Quick Stats Grid
    
    private var storageQuickStats: some View {
        HStack(spacing: 10) {
            // Usage Percentage
            StorageStatCard(
                icon: "chart.pie.fill",
                title: "Usage",
                value: "\(Int(storageStats?.usedPercentage ?? 0))%",
                color: storageHealthColor
            )
            
            // Health Status
            StorageStatCard(
                icon: "heart.fill",
                title: "Health",
                value: storageHealthStatus,
                color: storageHealthColor
            )
        }
    }
    
    private var storageHealthStatus: String {
        let percentage = storageStats?.usedPercentage ?? 0
        if percentage < 50 { return "Excellent" }
        else if percentage < 75 { return "Good" }
        else if percentage < 90 { return "Fair" }
        else { return "Low" }
    }
    
    private var storageHealthColor: Color {
        let percentage = storageStats?.usedPercentage ?? 0
        if percentage < 50 { return .green }
        else if percentage < 75 { return AppTheme.cleanCyan }
        else if percentage < 90 { return .orange }
        else { return AppTheme.cleanPink }
    }
    
    // MARK: - System Junk Card
    
    private var storageSystemJunkCard: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "trash.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.cleanPink)
                Text("System Junk")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                
                if appState.isScanning {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.7)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if appState.isScanning {
                        Text(appState.currentScanningCategory)
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(1)
                    } else if appState.hasScanned {
                        Text(appState.formattedTotalSize)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Cleanable files found")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textSecondary)
                    } else {
                        Text("Not scanned yet")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                if !appState.isScanning {
                    Button(action: {
                        // Always open Cleaner window - let user decide what to clean
                        AppDelegate.shared?.showMainWindow()
                    }) {
                        Text(appState.hasScanned && appState.totalCleanableSize > 0 ? "Clean" : "Scan")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(
                                    appState.hasScanned && appState.totalCleanableSize > 0 
                                        ? AppTheme.cleanPink 
                                        : AppTheme.cleanCyan
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if appState.isScanning {
                ProgressView(value: appState.scanProgress)
                    .progressViewStyle(.linear)
                    .tint(AppTheme.cleanCyan)
                    .frame(height: 3)
            }
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.cardBorder, lineWidth: 1))
    }
    
    // MARK: - Quick Actions
    
    private var storageQuickActions: some View {
        VStack(spacing: 6) {
            Text("Quick Actions")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: onOpenLargeFiles) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.badge.clock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.storageGradient)
                    Text("Find Large Files")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(10)
                .background(AppTheme.cardBackground)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.cardBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Consumers List
    
    private var consumersList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Consumers")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(topProcesses.prefix(20)) { process in
                            HStack {
                                if let icon = process.icon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                } else {
                                    Image(systemName: "app.fill")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                
                                Text(process.name)
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(process.displayValue)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .frame(width: 60, alignment: .trailing)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Open Activity Monitor
                                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
                            }
                            
                            if process.id != topProcesses.prefix(20).last?.id {
                                Divider().opacity(0.2)
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
        }
    }
}

// MARK: - Subviews

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.cardBackground)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.cardBorder, lineWidth: 1))
    }
}

struct StorageStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.cardBackground)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.cardBorder, lineWidth: 1))
    }
}

struct LabelValue: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
            Text(value)
                .font(.caption.bold())
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}

struct DetailedMemoryGraph: View {
    let stats: SystemStatsHelper.MemoryStats?
    let detailed: SystemStatsHelper.DetailedMemoryStats?
    
    var body: some View {
        ZStack {
            // Placeholder graph for now - could be double ring
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 16)
                .padding(20)
            
            if let stats = stats {
                Circle()
                    .trim(from: 0, to: Double(stats.usedPercentage) / 100.0)
                    .stroke(
                        AppTheme.memoryGradient,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .padding(20)
                    .shadow(color: AppTheme.cleanPink.opacity(0.5), radius: 10)
            }
            
            VStack(spacing: 2) {
                Text(stats?.formattedUsed ?? "--")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text("of \(stats?.formattedTotal ?? "--")")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}

struct DetailedCPUGraph: View {
    let stats: SystemStatsHelper.CPUStats?
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 16)
                .padding(20)
            
            if let stats = stats {
                Circle()
                    .trim(from: 0, to: Double(stats.usagePercentage) / 100.0)
                    .stroke(
                        AppTheme.cpuGradient,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .padding(20)
                    .shadow(color: Color.orange.opacity(0.5), radius: 10)
            }
            
            VStack(spacing: 2) {
                Text(stats?.formattedUsage ?? "--")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text("Load")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}
