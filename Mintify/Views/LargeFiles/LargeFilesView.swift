import SwiftUI

enum SizeUnit: String, CaseIterable {
    case mb = "MB"
    case gb = "GB"
}

struct LargeFilesView: View {
    @EnvironmentObject var appState: CleanerState
    @EnvironmentObject var state: LargeFilesState
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var showConfirmDelete = false
    @State private var isDeleting = false
    @State private var deleteProgress: (current: Int, total: Int) = (0, 0)
    
    // Computed properties wrapping state for convenience
    private var files: [LargeFile] { state.files }
    private var selectedPaths: Set<String> { state.selectedPaths }
    
    private var formattedMinSize: String {
        formatSize(effectiveMinSize)
    }
    
    private var effectiveMinSize: Int64 {
        let value = Int64(state.sizeInputText) ?? 100
        return state.sizeUnit == .gb ? value * 1024 * 1024 * 1024 : value * 1024 * 1024
    }
    
    var filteredFiles: [LargeFile] {
        var result = state.files
        
        // Filter by category (using path-based detection for Downloads/Desktop)
        if state.selectedCategory != .all {
            result = result.filter { FileTypeCategory.category(forPath: $0.path, fileExtension: $0.fileType) == state.selectedCategory }
        }
        
        // Sort
        switch state.sortOption {
        case .sizeDesc:
            result.sort { $0.size > $1.size }
        case .sizeAsc:
            result.sort { $0.size < $1.size }
        case .dateDesc:
            result.sort { $0.modifiedDate > $1.modifiedDate }
        case .dateAsc:
            result.sort { $0.modifiedDate < $1.modifiedDate }
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        
        return result
    }
    
    var selectedFiles: [LargeFile] {
        state.files.filter { state.selectedPaths.contains($0.path) }
    }
    
    var selectedSize: Int64 {
        selectedFiles.reduce(0) { $0 + $1.size }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with filters
            headerView
            
            Divider()
                .background(AppTheme.cardBorder)
            
            // Content
            HStack(spacing: 0) {
                // Filter sidebar
                filterSidebar
                
                Divider()
                    .background(AppTheme.cardBorder)
                
                // File list area
                VStack(spacing: 0) {
                    if state.isScanning {
                        scanningView
                    } else if state.files.isEmpty {
                        emptyStateView
                    } else {
                        fileListView
                    }
                }
            }
            
            Divider()
                .background(AppTheme.cardBorder)
            
            // Footer
            footerView
        }
        .alert("Move to Trash?", isPresented: $showConfirmDelete) {
            Button("Cancel", role: .cancel) { }
            Button("Move to Trash", role: .destructive) {
                deleteSelectedFiles()
            }
        } message: {
            Text("Are you sure you want to move \(selectedFiles.count) files (\(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file))) to Trash?")
        }
        // Delete progress overlay
        .overlay {
            if isDeleting {
                DeleteProgressOverlay(
                    message: "Moving to Trash...",
                    current: deleteProgress.current,
                    total: deleteProgress.total
                )
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 16) {
            Image(systemName: "doc.badge.clock")
                .foregroundStyle(AppTheme.cleanCyan)
                .font(.title2)
            
            // Title
            Text("Large Files")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            // Sort dropdown
            Menu {
                ForEach(FileSortOption.allCases) { option in
                    Button(action: { state.sortOption = option }) {
                        HStack {
                            Text(option.rawValue)
                            if state.sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Sort:")
                        .foregroundColor(AppTheme.textSecondary)
                    Text(state.sortOption.rawValue)
                        .foregroundColor(AppTheme.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .font(.system(size: 12))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.overlayMedium)
                )
            }
            .buttonStyle(.plain)
            
            // File count
            Text("\(filteredFiles.count) files")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary)
            
            // Scan button
            Button(action: startScan) {
                HStack(spacing: 6) {
                    Image(systemName: state.isScanning ? "stop.fill" : "arrow.clockwise")
                    Text(state.isScanning ? "Scanning..." : "Scan")
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
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
    
    // MARK: - Filter Sidebar
    
    private var filterSidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Size Filter with Input
            VStack(alignment: .leading, spacing: 10) {
                Text("Minimum Size")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .textCase(.uppercase)
                
                // Size input with unit toggle
                HStack(spacing: 6) {
                    // Number input
                    TextField("100", text: $state.sizeInputText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.overlayMedium)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.mint.opacity(0.3), lineWidth: 1)
                        )
                    
                    // Unit toggle (MB/GB)
                    HStack(spacing: 0) {
                        ForEach(SizeUnit.allCases, id: \.self) { unit in
                            Button(action: { state.sizeUnit = unit }) {
                                Text(unit.rawValue)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(state.sizeUnit == unit ? .white : AppTheme.textSecondary)
                                    .frame(width: 32, height: 30)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(state.sizeUnit == unit ? Color.mint : Color.clear)
                                    )
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppTheme.overlayMedium)
                    )
                }
                
                // Quick presets - 2 rows
                VStack(spacing: 4) {
                    HStack(spacing: 3) {
                        SmallPresetButton(label: "100 MB", value: "100", unit: .mb, currentValue: state.sizeInputText, currentUnit: state.sizeUnit) {
                            state.sizeInputText = "100"; state.sizeUnit = .mb
                        }
                        SmallPresetButton(label: "250 MB", value: "250", unit: .mb, currentValue: state.sizeInputText, currentUnit: state.sizeUnit) {
                            state.sizeInputText = "250"; state.sizeUnit = .mb
                        }
                        SmallPresetButton(label: "500 MB", value: "500", unit: .mb, currentValue: state.sizeInputText, currentUnit: state.sizeUnit) {
                            state.sizeInputText = "500"; state.sizeUnit = .mb
                        }
                    }
                    HStack(spacing: 3) {
                        SmallPresetButton(label: "1 GB", value: "1", unit: .gb, currentValue: state.sizeInputText, currentUnit: state.sizeUnit) {
                            state.sizeInputText = "1"; state.sizeUnit = .gb
                        }
                        SmallPresetButton(label: "2 GB", value: "2", unit: .gb, currentValue: state.sizeInputText, currentUnit: state.sizeUnit) {
                            state.sizeInputText = "2"; state.sizeUnit = .gb
                        }
                        SmallPresetButton(label: "5 GB", value: "5", unit: .gb, currentValue: state.sizeInputText, currentUnit: state.sizeUnit) {
                            state.sizeInputText = "5"; state.sizeUnit = .gb
                        }
                    }
                }
                
                // Scan button
                Button(action: startScan) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Scan Files")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.mint.opacity(0.8))
                    )
                }
                .buttonStyle(.plain)
            }
            
            Divider()
                .background(AppTheme.overlayMedium)
            
            // Category Filter
            VStack(alignment: .leading, spacing: 8) {
                Text("File Type")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .textCase(.uppercase)
                
                ForEach(FileTypeCategory.allCases) { category in
                    Button(action: {
                        state.selectedCategory = category
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.system(size: 11))
                                .frame(width: 16)
                            Text(category.rawValue)
                                .font(.system(size: 12))
                            Spacer()
                            
                            // Count badge - use path-based detection
                            let count = state.files.filter { 
                                category == .all || FileTypeCategory.category(forPath: $0.path, fileExtension: $0.fileType) == category 
                            }.count
                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                        .foregroundColor(state.selectedCategory == category ? .mint : AppTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .frame(width: 190)
        .background(AppTheme.sidebarBackground)
    }
    
    // MARK: - File List
    
    private var fileListView: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(filteredFiles) { file in
                    LargeFileRow(
                        file: file,
                        isSelected: state.selectedPaths.contains(file.path),
                        onToggle: { toggleSelection(file.path) },
                        onReveal: { state.scanner.revealInFinder(file) },
                        onOpen: { state.scanner.openFile(file) }
                    )
                }
            }
            .padding(12)
        }
    }
    
    private func toggleSelection(_ path: String) {
        if state.selectedPaths.contains(path) {
            state.selectedPaths.remove(path)
        } else {
            state.selectedPaths.insert(path)
        }
    }
    
    // MARK: - Scanning View
    
    private var scanningView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(.mint)
            
            Text("Scanning for large files...")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            Text(state.scanProgress)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
            
            // Stop button
            Button(action: stopScan) {
                HStack(spacing: 6) {
                    Image(systemName: "stop.fill")
                    Text("Stop Scan")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.red.opacity(0.7))
                )
            }
            .buttonStyle(.plain)
            .contentShape(Capsule())
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.clock")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.textSecondary)
            
            Text("No large files found")
                .font(.headline)
                .foregroundColor(AppTheme.textSecondary)
            
            Text("Files larger than \(formattedMinSize) will appear here")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
            
            Button(action: startScan) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Scan Now")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.mint.opacity(0.8))
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            // Select all toggle
            Button(action: toggleSelectAll) {
                HStack(spacing: 6) {
                    Image(systemName: state.selectedPaths.count == state.files.count && !state.files.isEmpty ? "checkmark.square.fill" : "square")
                        .foregroundColor(.mint)
                    Text("Select All")
                        .foregroundColor(AppTheme.textSecondary)
                }
                .font(.system(size: 12))
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(state.files.isEmpty)
            
            Spacer()
            
            // Selected info
            if !selectedFiles.isEmpty {
                Text("\(selectedFiles.count) selected")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                
                Text("•")
                    .foregroundColor(AppTheme.textSecondary)
                
                Text(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.mint)
            }
            
            // Delete button
            Button(action: { showConfirmDelete = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash.fill")
                    Text("Move to Trash")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(selectedFiles.isEmpty ? AppTheme.overlayMedium : Color.red.opacity(0.8))
                )
            }
            .buttonStyle(.plain)
            .disabled(selectedFiles.isEmpty || isDeleting)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // MARK: - Actions
    
    private func startScan() {
        state.isScanning = true
        state.shouldStopScan = false
        state.files = []
        state.selectedPaths = []
        
        // Capture value to avoid threading issues
        let minSize = effectiveMinSize
        
        DispatchQueue.global(qos: .userInitiated).async { [weak state] in
            guard let state = state else { return }
            let result = state.scanner.scanForLargeFiles(minSize: minSize) { folder in
                DispatchQueue.main.async {
                    state.scanProgress = "Scanning \(folder)..."
                }
            }
            
            DispatchQueue.main.async {
                if !state.shouldStopScan {
                    state.files = result
                }
                state.isScanning = false
                state.scanProgress = ""
            }
        }
    }
    
    private func stopScan() {
        state.shouldStopScan = true
        state.isScanning = false
        state.scanProgress = ""
    }
    
    private func toggleSelectAll() {
        if state.selectedPaths.count == state.files.count {
            state.selectedPaths.removeAll()
        } else {
            state.selectedPaths = Set(state.files.map { $0.path })
        }
    }
    
    private func deleteSelectedFiles() {
        let toDelete = selectedFiles
        guard !toDelete.isEmpty else { return }
        
        isDeleting = true
        deleteProgress = (0, toDelete.count)
        
        DispatchQueue.global(qos: .userInitiated).async {
            var successCount = 0
            var failedCount = 0
            
            for (index, file) in toDelete.enumerated() {
                do {
                    try FileManager.default.trashItem(at: file.url, resultingItemURL: nil)
                    successCount += 1
                } catch {
                    print("[LargeFilesView] Failed to trash: \(file.path) - \(error)")
                    failedCount += 1
                }
                
                // Update progress on main thread
                DispatchQueue.main.async {
                    self.deleteProgress.current = index + 1
                }
            }
            
            DispatchQueue.main.async {
                // Remove deleted files from list
                let deletedPaths = Set(toDelete.map { $0.path })
                self.state.files.removeAll { deletedPaths.contains($0.path) }
                self.state.selectedPaths.subtract(deletedPaths)
                
                self.isDeleting = false
                print("[LargeFilesView] Deleted \(successCount) files, \(failedCount) failed")
            }
        }
    }
    
    private func formatSize(_ bytes: Int64) -> String {
        // Use simple formatting to show exact MB/GB values
        let value = Int64(state.sizeInputText) ?? 100
        if state.sizeUnit == .gb {
            return "\(value) GB"
        } else {
            return "\(value) MB"
        }
    }
}


// MARK: - Large File Row

struct LargeFileRow: View {
    let file: LargeFile
    let isSelected: Bool
    let onToggle: () -> Void
    let onReveal: () -> Void
    let onOpen: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18))
                .foregroundColor(isSelected ? .mint : AppTheme.textSecondary)
            
            // File icon
            Image(nsImage: file.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
            
            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                
                Text(file.url.deletingLastPathComponent().path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~"))
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Modified date
            if !isHovered {
                Text(file.formattedDate)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            // Size badge
            Text(file.formattedSize)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.mint.opacity(0.3))
                )
            
            // Actions (show on hover)
            if isHovered {
                HStack(spacing: 6) {
                    Button(action: onReveal) {
                        Image(systemName: "folder")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(AppTheme.textSecondary)
                    
                    Button(action: onOpen) {
                        Image(systemName: "arrow.up.forward.square")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.mint.opacity(0.1) : (isHovered ? AppTheme.overlayLight : Color.clear))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Preset Button

struct PresetButton: View {
    let text: String
    let unit: SizeUnit
    let currentValue: String
    let currentUnit: SizeUnit
    let action: () -> Void
    
    private var isSelected: Bool {
        currentValue == text && currentUnit == unit
    }
    
    var body: some View {
        Button(action: action) {
            Text("\(text)\(unit.rawValue)")
                .font(.system(size: 10))
                .foregroundColor(isSelected ? .mint : AppTheme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.mint.opacity(0.2) : AppTheme.overlayLight)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Small Preset Button (fixed width)

struct SmallPresetButton: View {
    let label: String
    let value: String
    let unit: SizeUnit
    let currentValue: String
    let currentUnit: SizeUnit
    let action: () -> Void
    
    private var isSelected: Bool {
        currentValue == value && currentUnit == unit
    }
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isSelected ? .mint : AppTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.mint.opacity(0.2) : AppTheme.overlayLight)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

#Preview {
    LargeFilesView()
        .environmentObject(CleanerState())
        .frame(width: 600, height: 500)
        .background(Color(red: 0.05, green: 0.05, blue: 0.1))
}
