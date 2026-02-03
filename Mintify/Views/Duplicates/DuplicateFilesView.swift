import SwiftUI

/// View for finding and managing duplicate files
struct DuplicateFilesView: View {
    @EnvironmentObject var state: DuplicateFinderState
    @EnvironmentObject var permissionManager: PermissionManager
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var showConfirmDelete = false
    @State private var isRequestingPermission = false
    @State private var isDeleting = false
    @State private var deleteProgress: (current: Int, total: Int) = (0, 0)
    
    // MARK: - Computed Properties
    
    private var filteredGroups: [DuplicateGroup] {
        var groups = state.duplicateGroups
        
        // Apply category filter
        if state.selectedCategory != .all {
            groups = groups.filter { $0.category == state.selectedCategory }
        }
        
        // Apply sorting
        switch state.sortOption {
        case .sizeDesc:
            return groups.sorted { $0.duplicateSize > $1.duplicateSize }
        case .sizeAsc:
            return groups.sorted { $0.duplicateSize < $1.duplicateSize }
        case .countDesc:
            return groups.sorted { $0.fileCount > $1.fileCount }
        case .countAsc:
            return groups.sorted { $0.fileCount < $1.fileCount }
        case .name:
            return groups.sorted { ($0.files.first?.name ?? "") < ($1.files.first?.name ?? "") }
        }
    }
    
    private var totalDuplicateSize: Int64 {
        state.duplicateGroups.reduce(0) { $0 + $1.duplicateSize }
    }
    
    private var selectedSize: Int64 {
        state.duplicateGroups.reduce(0) { $0 + $1.selectedSize }
    }
    
    private var selectedCount: Int {
        state.duplicateGroups.reduce(0) { $0 + $1.selectedCount }
    }
    
    private var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalDuplicateSize, countStyle: .file)
    }
    
    private var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Progress bar when scanning
                if state.isScanning {
                    scanningProgressView
                }
                
                Divider()
                    .background(AppTheme.overlayMedium)
                
                // Main content
                HStack(spacing: 0) {
                    if !state.duplicateGroups.isEmpty {
                        // Filter sidebar
                        filterSidebar
                        
                        Divider()
                            .background(AppTheme.overlayMedium)
                    }
                    
                    // Content area
                    if state.duplicateGroups.isEmpty && !state.isScanning {
                        emptyStateView
                    } else {
                        duplicateListView
                    }
                }
                
                Divider()
                    .background(AppTheme.overlayMedium)
                
                // Footer
                footerView
            }
        }
        // Delete progress overlay
        .overlay {
            if isDeleting {
                DeleteProgressOverlay(
                    message: "Deleting files...",
                    current: deleteProgress.current,
                    total: deleteProgress.total
                )
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(spacing: 16) {
            Image(systemName: "doc.on.doc")
                .foregroundStyle(AppTheme.cleanCyan)
                .font(.title2)
            
            Text("Duplicate Finder")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            // Sort dropdown
            Menu {
                ForEach(DuplicateSortOption.allCases) { option in
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
            
            // Group count
            Text("\(filteredGroups.count) groups")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary)
            
            // Scan button
            if !state.isScanning {
                Button(action: startScan) {
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
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
    
    // MARK: - Scanning Progress
    
    private var scanningProgressView: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.overlayMedium)
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.teal, Color.mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geometry.size.width * state.scanProgress), height: 6)
                        .shadow(color: .mint.opacity(0.5), radius: 4, x: 0, y: 0)
                }
            }
            .frame(height: 6)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.mint)
                    .font(.caption)
                
                Text(state.scanStatus)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(Int(state.scanProgress * 100))%")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.mint)
                
                // Stop button
                Button(action: stopScan) {
                    HStack(spacing: 4) {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.7))
                    )
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
    
    // MARK: - Filter Sidebar
    
    private var filterSidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("File Type")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .textCase(.uppercase)
                .padding(.top, 16)
            
            ForEach(DuplicateCategory.allCases, id: \.self) { category in
                FilterButton(
                    category: category,
                    count: countForCategory(category),
                    isSelected: state.selectedCategory == category,
                    action: { state.selectedCategory = category }
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(width: 200)
        .background(AppTheme.sidebarBackground)
    }
    
    private func countForCategory(_ category: DuplicateCategory) -> Int {
        if category == .all {
            return state.duplicateGroups.count
        }
        return state.duplicateGroups.filter { $0.category == category }.count
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.textSecondary)
            
            Text("Find Duplicate Files")
                .font(.headline)
                .foregroundColor(AppTheme.textSecondary)
            
            Text("Click Scan to search for duplicate files")
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
            .contentShape(Capsule())
            .padding(.top, 8)
            
            VStack(spacing: 8) {
                if !permissionManager.hasHomeAccess {
                    Text("Mintify needs access to your Home folder to find duplicates.")
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        isRequestingPermission = true
                        permissionManager.requestHomeAccess { success in
                            isRequestingPermission = false
                            if success {
                                // optional: auto start scan?
                            }
                        }
                    }) {
                        HStack {
                            if isRequestingPermission {
                                ProgressView()
                                    .controlSize(.small)
                                    .scaleEffect(0.7)
                            }
                            Text("Grant Access")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.8))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                } else {
                     Text("Access to Home folder granted")
                        .font(.caption2)
                        .foregroundColor(.green.opacity(0.7))
                        
                     HStack(spacing: 16) {
                        Label("Desktop", systemImage: "desktopcomputer")
                        Label("Downloads", systemImage: "arrow.down.circle")
                        Label("Documents", systemImage: "doc.text")
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Duplicate List
    
    private var duplicateListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredGroups) { group in
                    DuplicateGroupCard(
                        group: binding(for: group),
                        isExpanded: state.expandedGroups.contains(group.id),
                        onToggleExpand: { toggleExpand(group.id) },
                        onReveal: { file in state.scanner.revealInFinder(file) },
                        onOpen: { file in state.scanner.openFile(file) }
                    )
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func binding(for group: DuplicateGroup) -> Binding<DuplicateGroup> {
        guard let index = state.duplicateGroups.firstIndex(where: { $0.id == group.id }) else {
            return .constant(group)
        }
        return $state.duplicateGroups[index]
    }
    
    private func toggleExpand(_ id: UUID) {
        if state.expandedGroups.contains(id) {
            state.expandedGroups.remove(id)
        } else {
            state.expandedGroups.insert(id)
        }
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            // Auto-select button
            Button(action: autoSelectDuplicates) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.mint)
                    Text("Auto-select Duplicates")
                        .foregroundColor(AppTheme.textSecondary)
                }
                .font(.system(size: 12))
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(state.duplicateGroups.isEmpty)
            
            Spacer()
            
            // Stats
            if !state.duplicateGroups.isEmpty {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(state.duplicateGroups.count) groups • \(formattedTotalSize) recoverable")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    if selectedCount > 0 {
                        Text("\(selectedCount) selected • \(formattedSelectedSize)")
                            .font(.caption)
                            .foregroundColor(.mint)
                    }
                }
            }
            
            // Delete button
            Button(action: { showConfirmDelete = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Remove Selected")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(selectedCount > 0 ? Color.red.opacity(0.8) : Color.gray.opacity(0.3))
                )
            }
            .buttonStyle(.plain)
            .disabled(selectedCount == 0 || isDeleting)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .alert("Remove \(selectedCount) duplicates?", isPresented: $showConfirmDelete) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                deleteSelected()
            }
        } message: {
            Text("This will move \(formattedSelectedSize) of duplicate files to Trash. Original files will be kept.")
        }
    }
    
    // MARK: - Actions
    
    private func startScan() {
        state.isScanning = true
        state.scanProgress = 0
        state.scanStatus = "Initializing..."
        state.duplicateGroups = []
        state.expandedGroups = []
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = state.scanner.scanForDuplicates { status, progress in
                DispatchQueue.main.async {
                    state.scanStatus = status
                    state.scanProgress = progress
                }
            }
            
            DispatchQueue.main.async {
                if !state.scanner.shouldStopScan {
                    state.duplicateGroups = result
                    // Auto-expand first few groups
                    for group in result.prefix(3) {
                        state.expandedGroups.insert(group.id)
                    }
                }
                state.isScanning = false
                state.scanStatus = ""
            }
        }
    }
    
    private func stopScan() {
        state.scanner.shouldStopScan = true
        state.isScanning = false
        state.scanStatus = ""
        state.duplicateGroups = []
    }
    
    private func autoSelectDuplicates() {
        for i in state.duplicateGroups.indices {
            for j in state.duplicateGroups[i].files.indices {
                // Select all files except the original
                state.duplicateGroups[i].files[j].isSelected = !state.duplicateGroups[i].files[j].isOriginal
            }
        }
    }
    
    private func deleteSelected() {
        let filesToDelete = state.duplicateGroups.flatMap { $0.files.filter { $0.isSelected } }
        guard !filesToDelete.isEmpty else { return }
        
        isDeleting = true
        deleteProgress = (0, filesToDelete.count)
        
        DispatchQueue.global(qos: .userInitiated).async {
            var successCount = 0
            var failedCount = 0
            
            for (index, file) in filesToDelete.enumerated() {
                do {
                    try FileManager.default.trashItem(at: file.url, resultingItemURL: nil)
                    successCount += 1
                } catch {
                    print("[DuplicateFilesView] Failed to trash: \(file.path) - \(error)")
                    failedCount += 1
                }
                
                // Update progress on main thread
                DispatchQueue.main.async {
                    self.deleteProgress.current = index + 1
                }
            }
            
            DispatchQueue.main.async {
                // Remove deleted files from groups
                for i in self.state.duplicateGroups.indices {
                    self.state.duplicateGroups[i].files.removeAll { file in
                        filesToDelete.contains { $0.path == file.path }
                    }
                }
                
                // Remove empty groups or groups with only 1 file
                self.state.duplicateGroups.removeAll { $0.files.count < 2 }
                
                self.isDeleting = false
                print("[DuplicateFilesView] Deleted \(successCount) files, \(failedCount) failed")
            }
        }
    }
}

// MARK: - Filter Button

struct FilterButton: View {
    let category: DuplicateCategory
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))
                    .frame(width: 16)
                
                Text(category.rawValue)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                
                Spacer(minLength: 4)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.mint.opacity(0.5) : AppTheme.overlayMedium)
                        )
                }
            }
            .foregroundColor(isSelected ? .mint : AppTheme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.mint.opacity(0.15) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Duplicate Group Card

struct DuplicateGroupCard: View {
    @Binding var group: DuplicateGroup
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onReveal: (DuplicateFile) -> Void
    let onOpen: (DuplicateFile) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggleExpand) {
                HStack(spacing: 12) {
                    // File icon
                    if let firstFile = group.files.first {
                        Image(nsImage: firstFile.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.files.first?.name ?? "Unknown")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            Text("\(group.fileCount) copies")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Text("•")
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Text(ByteCountFormatter.string(fromByteCount: group.duplicateSize, countStyle: .file) + " recoverable")
                                .font(.caption)
                                .foregroundColor(.mint)
                        }
                    }
                    
                    Spacer()
                    
                    // Category badge
                    Text(group.category.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppTheme.overlayMedium)
                        )
                    
                    // Expand chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Expanded file list
            if isExpanded {
                Divider()
                    .background(AppTheme.overlayMedium)
                
                VStack(spacing: 0) {
                    ForEach(group.files.indices, id: \.self) { index in
                        DuplicateFileRow(
                            file: $group.files[index],
                            onReveal: { onReveal(group.files[index]) },
                            onOpen: { onOpen(group.files[index]) }
                        )
                        
                        if index < group.files.count - 1 {
                            Divider()
                                .background(AppTheme.overlayLight)
                                .padding(.leading, 48)
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.overlayLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppTheme.overlayMedium, lineWidth: 1)
        )
    }
}

// MARK: - Duplicate File Row

struct DuplicateFileRow: View {
    @Binding var file: DuplicateFile
    let onReveal: () -> Void
    let onOpen: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Selection checkbox (not for original)
            if file.isOriginal {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                    .frame(width: 20, height: 20)
                    .padding(.top, 2)
            } else {
                Button(action: { file.isSelected.toggle() }) {
                    Image(systemName: file.isSelected ? "checkmark.square.fill" : "square")
                        .font(.system(size: 14))
                        .foregroundColor(file.isSelected ? .mint : AppTheme.textSecondary)
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            
            // File info container
            VStack(alignment: .leading, spacing: 4) {
                // Top row: Name, Metadata, Actions
                HStack(spacing: 8) {
                    // Name and Badge
                    HStack(spacing: 6) {
                        Text(file.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        if file.isOriginal {
                            Text("ORIGINAL")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.green.opacity(0.2))
                                )
                        }
                    }
                    
                    Spacer()
                    
                    // Size and Date
                    HStack(spacing: 12) {
                        Text(file.formattedSize)
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                        
                        Text(file.formattedCreatedDate)
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    // Actions
                    HStack(spacing: 4) {
                        Button(action: onReveal) {
                            Image(systemName: "folder")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(width: 24, height: 24)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("Reveal in Finder")
                        
                        Button(action: onOpen) {
                            Image(systemName: "eye")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(width: 24, height: 24)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("Open file")
                    }
                }
                
                // Bottom row: Path (full width)
                Text(file.path)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        // Background for the whole row (selection highlight)
        .background(file.isSelected ? Color.mint.opacity(0.1) : Color.clear)
    }
}

#Preview {
    DuplicateFilesView()
}
