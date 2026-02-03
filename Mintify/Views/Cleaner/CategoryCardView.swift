import SwiftUI

private let actionButtonWidth: CGFloat = 28
private let sizeColumnWidth: CGFloat = 70

struct CategoryCardView: View {
    @Binding var category: CleanableCategory
    @ObservedObject var themeManager = ThemeManager.shared
    var onDelete: (String) -> Void
    @State private var isExpanded = false
    @State private var isHovered = false
    
    private var categoryColor: Color {
        switch category.category.color {
        case "blue": return AppTheme.cleanCyan
        case "purple": return Color(hex: "9D4EDD") // Brighter Purple (was 7209B7)
        case "orange": return Color(hex: "FF9F1C")
        case "cyan": return AppTheme.cleanCyan
        case "green": return .green // Keep green for distinction or add to theme
        case "red": return AppTheme.cleanPink
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category header
            HStack(spacing: 12) {
                // Checkbox
                Toggle(isOn: $category.isSelected) {
                    EmptyView()
                }
                .toggleStyle(.checkbox)
                .onChange(of: category.isSelected) { newValue in
                    for i in category.items.indices {
                        category.items[i].isSelected = newValue
                    }
                }
                
                // Icon with colored background
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(categoryColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: category.category.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(categoryColor)
                }
                
                // Category info
                VStack(alignment: .leading, spacing: 3) {
                    Text(category.category.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    HStack(spacing: 8) {
                        // Item count badge
                        Text("\(category.items.count) items")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(categoryColor.opacity(0.2))
                            )
                        
                        Text(category.category.description)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Size
                Text(category.formattedSize)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(width: sizeColumnWidth, alignment: .trailing)
                
                // Action buttons
                HStack(spacing: 6) {
                    Button(action: { openInFinder(category.items.first?.path) }) {
                        Image(systemName: "folder")
                            .font(.system(size: 12))
                            .foregroundColor(categoryColor)
                            .frame(width: actionButtonWidth, height: actionButtonWidth)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(categoryColor.opacity(0.15))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Open in Finder")
                    
                    Button(action: { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() } }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(width: actionButtonWidth, height: actionButtonWidth)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
            }
            
            // Expanded items
            if isExpanded {
                Divider()
                    .background(AppTheme.cardBorder)
                    .padding(.horizontal, 16)
                
                VStack(spacing: 0) {
                    ForEach(category.items.indices, id: \.self) { index in
                        ItemRowView(item: $category.items[index], onDelete: onDelete, accentColor: categoryColor)
                        
                        if index < category.items.count - 1 {
                            Divider()
                                .background(AppTheme.overlayMedium.opacity(0.5))
                                .padding(.leading, 52)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isHovered ? AppTheme.cardBackground.opacity(0.2) : AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    private func openInFinder(_ path: String?) {
        guard let path = path else { return }
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
    }
}

struct ItemRowView: View {
    @EnvironmentObject var appState: CleanerState
    @ObservedObject var themeManager = ThemeManager.shared
    @Binding var item: CleanableItem
    var onDelete: (String) -> Void
    var accentColor: Color
    
    @State private var isExpanded = false
    @State private var subItems: [(name: String, size: Int64, path: String)] = []
    @State private var isLoadingSubItems = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Toggle(isOn: $item.isSelected) {
                    EmptyView()
                }
                .toggleStyle(.checkbox)
                
                Text(item.name)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                Text(item.formattedSize)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: sizeColumnWidth, alignment: .trailing)
                
                // Action buttons
                HStack(spacing: 6) {
                    if appState.isDeleting {
                        ProgressView()
                            .controlSize(.mini)
                            .frame(width: actionButtonWidth, height: actionButtonWidth)
                    } else {
                        Button(action: { confirmDelete() }) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundColor(.red)
                                .frame(width: actionButtonWidth, height: actionButtonWidth)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.red.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                        .help("Delete")
                    }
                    
                    Button(action: { openInFinder(item.path) }) {
                        Image(systemName: "folder")
                            .font(.system(size: 11))
                            .foregroundColor(accentColor)
                            .frame(width: actionButtonWidth, height: actionButtonWidth)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(accentColor.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Open in Finder")
                    
                    Button(action: { 
                        withAnimation(.spring(response: 0.3)) { 
                            isExpanded.toggle()
                            if isExpanded && subItems.isEmpty && !isLoadingSubItems {
                                loadSubItemsAsync()
                            }
                        } 
                    }) {
                        Group {
                            if isLoadingSubItems {
                                ProgressView()
                                    .controlSize(.mini)
                                    .tint(AppTheme.textSecondary)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            }
                        }
                        .frame(width: actionButtonWidth, height: actionButtonWidth)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            // Sub-items
            if isExpanded && !subItems.isEmpty {
                VStack(spacing: 0) {
                    ForEach(subItems.prefix(15), id: \.path) { subItem in
                        SubItemRowView(
                            name: subItem.name,
                            size: subItem.size,
                            path: subItem.path,
                            accentColor: accentColor,
                            onDelete: { path in
                                confirmDeleteSubItem(name: subItem.name, path: path)
                            }
                        )
                    }
                    
                    if subItems.count > 15 {
                        Text("... and \(subItems.count - 15) more")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.leading, 52)
                            .padding(.vertical, 6)
                    }
                }
            }
        }
    }
    
    private func openInFinder(_ path: String) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
    }
    
    private func confirmDelete() {
        NSApp.activate(ignoringOtherApps: true)
        
        // Calculate size in background to avoid blocking UI
        let itemPath = item.path
        let itemName = item.name
        
        DispatchQueue.global(qos: .userInitiated).async {
            let size = StorageScanner().calculateSize(at: URL(fileURLWithPath: itemPath)) ?? 0
            let formattedSize = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Delete \"\(itemName)\"?"
                alert.informativeText = "Path: \(itemPath)\nSize: \(formattedSize)\n\nThis action cannot be undone."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Delete")
                alert.addButton(withTitle: "Cancel")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    self.deleteItemInBackground(at: itemPath)
                }
            }
        }
    }
    
    private func confirmDeleteSubItem(name: String, path: String) {
        NSApp.activate(ignoringOtherApps: true)
        
        // Calculate size in background to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            let size = StorageScanner().calculateSize(at: URL(fileURLWithPath: path)) ?? 0
            let formattedSize = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Delete \"\(name)\"?"
                alert.informativeText = "Path: \(path)\nSize: \(formattedSize)\n\nThis action cannot be undone."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Delete")
                alert.addButton(withTitle: "Cancel")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    self.deleteSubItemInBackground(path: path)
                }
            }
        }
    }
    
    private func deleteSubItemInBackground(path: String) {
        appState.isDeleting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            var deleteError: Error? = nil
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                deleteError = error
            }
            
            DispatchQueue.main.async {
                self.appState.isDeleting = false
                if let error = deleteError {
                    self.showError(error)
                } else {
                    self.subItems.removeAll { $0.path == path }
                }
            }
        }
    }
    
    private func deleteItemInBackground(at path: String) {
        appState.isDeleting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            var deleteError: Error? = nil
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                deleteError = error
            }
            
            DispatchQueue.main.async {
                self.appState.isDeleting = false
                if let error = deleteError {
                    self.showError(error)
                } else {
                    self.onDelete(path)
                    self.subItems.removeAll { $0.path == path }
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Failed to delete"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func loadSubItemsAsync() {
        isLoadingSubItems = true
        let path = item.path
        
        DispatchQueue.global(qos: .userInitiated).async {
            let url = URL(fileURLWithPath: path)
            let fm = FileManager.default
            
            var items: [(name: String, size: Int64, path: String)] = []
            
            if let contents = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) {
                for content in contents {
                    let name = content.lastPathComponent
                    if name.hasPrefix(".") { continue }
                    
                    var isDir: ObjCBool = false
                    fm.fileExists(atPath: content.path, isDirectory: &isDir)
                    
                    if isDir.boolValue {
                        if let size = StorageScanner().calculateSize(at: content), size > 100_000 {
                            items.append((name: name, size: size, path: content.path))
                        }
                    } else {
                        if let attrs = try? fm.attributesOfItem(atPath: content.path),
                           let size = attrs[.size] as? Int64, size > 100_000 {
                            items.append((name: name, size: size, path: content.path))
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                subItems = items.sorted { $0.size > $1.size }
                isLoadingSubItems = false
            }
        }
    }
}

struct SubItemRowView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    let name: String
    let size: Int64
    let path: String
    let accentColor: Color
    let onDelete: (String) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.fill")
                .font(.system(size: 10))
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 16)
            
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
            
            Spacer()
            
            Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: sizeColumnWidth, alignment: .trailing)
            
            HStack(spacing: 6) {
                Button(action: { onDelete(path) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                
                Button(action: { openInFinder(path) }) {
                    Image(systemName: "folder")
                        .font(.system(size: 10))
                        .foregroundColor(accentColor.opacity(0.8))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                
                // Placeholder for alignment
                Color.clear.frame(width: actionButtonWidth, height: actionButtonWidth)
            }
        }
        .padding(.horizontal, 16)
        .padding(.leading, 36)
        .padding(.vertical, 6)
    }
    
    private func openInFinder(_ path: String) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
    }
}
