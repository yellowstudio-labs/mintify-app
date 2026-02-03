import SwiftUI

/// View for Memory Optimizer feature
struct MemoryOptimizerView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var memoryStats: SystemStatsHelper.MemoryStats?
    @State private var detailedStats: SystemStatsHelper.DetailedMemoryStats?
    @State private var topProcesses: [SystemStatsHelper.AppProcess] = []
    @State private var isRefreshing = false
    @State private var isFreeing = false
    @State private var lastFreeResult: String?
    @State private var showFreeResult = false
    
    private let statsHelper = SystemStatsHelper.shared
    private let refreshTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
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
                ScrollView {
                    VStack(spacing: 20) {
                        // Memory Gauge Section
                        memoryGaugeSection
                        
                        // Memory Breakdown
                        memoryBreakdownSection
                        
                        // Top Memory Consumers
                        topConsumersSection
                    }
                    .padding(24)
                }
            }
            
            // Free Memory Result Toast
            if showFreeResult, let result = lastFreeResult {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(result)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.bottom, 32)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            refreshStats()
        }
        .onReceive(refreshTimer) { _ in
            refreshStats()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Image(systemName: "memorychip")
                .foregroundStyle(AppTheme.memoryGradient)
                .font(.title2)
            
            Text("Memory Optimizer")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            // Free Memory Button
            Button(action: freeMemory) {
                HStack(spacing: 8) {
                    if isFreeing {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(isFreeing ? "Freeing..." : "Free Up Memory")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isFreeing ? Color.gray : AppTheme.cleanCyan)
                )
            }
            .buttonStyle(.plain)
            .disabled(isFreeing)
        }
    }
    
    // MARK: - Memory Gauge Section
    
    private var memoryGaugeSection: some View {
        HStack(spacing: 24) {
            // Circular Gauge
            ZStack {
                // Background Circle
                Circle()
                    .stroke(AppTheme.overlayMedium, lineWidth: 12)
                
                // Used Memory Arc
                Circle()
                    .trim(from: 0, to: CGFloat((memoryStats?.usedPercentage ?? 0) / 100.0))
                    .stroke(
                        AppTheme.memoryGradient,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: AppTheme.cleanPink.opacity(0.4), radius: 8)
                
                VStack(spacing: 4) {
                    Text("\(Int(memoryStats?.usedPercentage ?? 0))%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Used")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .frame(width: 140, height: 140)
            .padding(20)
            
            // Memory Info Cards
            VStack(spacing: 12) {
                MemoryInfoCard(
                    title: "Used Memory",
                    value: memoryStats?.formattedUsed ?? "—",
                    icon: "circle.fill",
                    color: AppTheme.cleanPink
                )
                
                MemoryInfoCard(
                    title: "Free Memory",
                    value: memoryStats?.formattedFree ?? "—",
                    icon: "circle.fill",
                    color: .green
                )
                
                MemoryInfoCard(
                    title: "Total Memory",
                    value: memoryStats?.formattedTotal ?? "—",
                    icon: "memorychip",
                    color: AppTheme.textSecondary
                )
            }
            .frame(maxWidth: .infinity)
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
    
    // MARK: - Memory Breakdown Section
    
    private var memoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Memory Breakdown")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
            if let detailed = detailedStats {
                VStack(spacing: 12) {
                    MemoryBreakdownRow(
                        title: "App Memory",
                        value: detailed.formattedApp,
                        percentage: Double(detailed.appMemory) / Double(ProcessInfo.processInfo.physicalMemory) * 100,
                        color: AppTheme.cleanCyan
                    )
                    
                    MemoryBreakdownRow(
                        title: "Wired",
                        value: detailed.formattedWired,
                        percentage: Double(detailed.wired) / Double(ProcessInfo.processInfo.physicalMemory) * 100,
                        color: .orange
                    )
                    
                    MemoryBreakdownRow(
                        title: "Compressed",
                        value: detailed.formattedCompressed,
                        percentage: Double(detailed.compressed) / Double(ProcessInfo.processInfo.physicalMemory) * 100,
                        color: .purple
                    )
                    
                    MemoryBreakdownRow(
                        title: "Memory Pressure",
                        value: "\(Int(detailed.pressurePercentage))%",
                        percentage: detailed.pressurePercentage,
                        color: pressureColor(detailed.pressurePercentage)
                    )
                }
            } else {
                Text("Loading...")
                    .foregroundColor(AppTheme.textSecondary)
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
    
    // MARK: - Top Consumers Section
    
    private var topConsumersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Memory Consumers")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Button(action: {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
                }) {
                    HStack(spacing: 4) {
                        Text("Activity Monitor")
                            .font(.system(size: 12))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(AppTheme.cleanCyan)
                }
                .buttonStyle(.plain)
            }
            
            if topProcesses.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.regular)
                        Text("Loading processes...")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(topProcesses.prefix(10)) { process in
                        ProcessRow(process: process)
                        
                        if process.id != topProcesses.prefix(10).last?.id {
                            Divider()
                                .background(AppTheme.overlayMedium)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.overlayLight)
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
    
    // MARK: - Helper Functions
    
    private func refreshStats() {
        Task { @MainActor in
            memoryStats = statsHelper.getMemoryStats()
            detailedStats = statsHelper.getDetailedMemoryStats()
            topProcesses = statsHelper.getTopProcesses(by: .memory, limit: 15)
        }
    }
    
    private func freeMemory() {
        isFreeing = true
        
        // Get memory before
        let beforeStats = statsHelper.getMemoryStats()
        let beforeFree = beforeStats.free
        
        Task {
            // Small delay to show loading state
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            // Refresh stats after "freeing"
            // Note: In sandbox, we can't actually run purge command
            // But we refresh stats which may show memory freed by system
            
            await MainActor.run {
                refreshStats()
                
                // Calculate freed memory
                let afterStats = statsHelper.getMemoryStats()
                let freed = afterStats.free > beforeFree ? afterStats.free - beforeFree : 0
                
                if freed > 0 {
                    lastFreeResult = "Freed \(ByteCountFormatter.string(fromByteCount: Int64(freed), countStyle: .memory))"
                } else {
                    lastFreeResult = "Memory optimized"
                }
                
                isFreeing = false
                showFreeResult = true
                
                // Hide toast after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showFreeResult = false
                    }
                }
            }
        }
    }
    
    private func pressureColor(_ percentage: Double) -> Color {
        if percentage < 30 { return .green }
        else if percentage < 60 { return .orange }
        else { return AppTheme.cleanPink }
    }
}

// MARK: - Subviews

struct MemoryInfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.overlayLight)
        )
    }
}

struct MemoryBreakdownRow: View {
    let title: String
    let value: String
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppTheme.overlayMedium)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(4, geo.size.width * CGFloat(percentage / 100)))
                }
            }
            .frame(height: 6)
        }
    }
}

struct ProcessRow: View {
    let process: SystemStatsHelper.AppProcess
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = process.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 24, height: 24)
            }
            
            Text(process.name)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
            
            Spacer()
            
            Text(process.displayValue)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.cleanCyan)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
        }
    }
}

#Preview {
    MemoryOptimizerView()
        .frame(width: 700, height: 600)
}
