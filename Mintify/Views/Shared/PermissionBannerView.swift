import SwiftUI

struct PermissionBannerView: View {
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 18))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Full Disk Access Required")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Click + to add Mintify, then enable it to scan Trash")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Button(action: onOpenSettings) {
                Text("Open Settings")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.8))
                    )
            }
            .buttonStyle(.plain)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// Helper to check and open Full Disk Access
struct PermissionHelper {
    
    /// Check if app has Full Disk Access by trying to list .Trash contents
    /// Note: isReadableFile() is unreliable in Sandbox, use contentsOfDirectory instead
    static func hasFullDiskAccess() -> Bool {
        let fileManager = FileManager.default
        
        // Test 1: .Trash
        let trashPath = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
        if let _ = try? fileManager.contentsOfDirectory(atPath: trashPath.path) {
            return true
        }
        
        // Test 2: Library/Safari (FDA protected)
        let safariPath = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Safari")
        if let _ = try? fileManager.contentsOfDirectory(atPath: safariPath.path) {
            return true
        }
        
        return false
    }
    
    /// Open System Settings to Full Disk Access pane
    static func openFullDiskAccessSettings() {
        // Try macOS 13+ URL first
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        } else if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Show an alert prompting user to grant Full Disk Access
    static func showPermissionAlert() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            
            let alert = NSAlert()
            alert.messageText = "Full Disk Access Required"
            alert.informativeText = """
            Mintify needs Full Disk Access to scan your Trash folder.
            
            How to grant access:
            1. Click "Open Settings" below
            2. Click the + button at the bottom of the list
            3. Navigate to Applications and find Mintify.app
               (or press Cmd+Shift+G and paste the app path)
            4. Select Mintify.app and click Open
            5. Enable the toggle next to Mintify
            6. Restart Mintify for changes to take effect
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Later")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                openFullDiskAccessSettings()
            }
        }
    }
}

#Preview {
    PermissionBannerView(
        onOpenSettings: {},
        onDismiss: {}
    )
    .padding()
    .background(Color.black)
}
