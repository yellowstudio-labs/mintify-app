import Foundation
import AppKit
import SwiftUI

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var hasHomeAccess: Bool = false
    @Published var hasTrashAccess: Bool = false
    @Published var homeURL: URL?
    @Published var trashURL: URL?
    
    private let bookmarkKey = "security_scoped_bookmarks"
    
    init() {
        restoreBookmarks()
        checkPermissions()
    }
    
    func checkPermissions() {
        checkHomeAccess()
        checkTrashAccess()
    }
    
    private func checkHomeAccess() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let desktop = home.appendingPathComponent("Desktop")
        let documents = home.appendingPathComponent("Documents")
        
        let fileManager = FileManager.default
        
        let canReadDesktop = fileManager.isReadableFile(atPath: desktop.path)
        let canReadDocuments = fileManager.isReadableFile(atPath: documents.path)
        
        DispatchQueue.main.async {
            self.hasHomeAccess = canReadDesktop && canReadDocuments
        }
    }
    
    private func checkTrashAccess() {
        // Use macOS official API to access Trash
        if let trashURL = FileManager.default.urls(for: .trashDirectory, in: .userDomainMask).first {
            if let _ = try? FileManager.default.contentsOfDirectory(atPath: trashURL.path) {
                DispatchQueue.main.async {
                    self.hasTrashAccess = true
                    self.trashURL = trashURL
                }
                return
            }
        }
        
        // Fallback: Check the traditional path
        let trashPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
        if let _ = try? FileManager.default.contentsOfDirectory(atPath: trashPath.path) {
            DispatchQueue.main.async {
                self.hasTrashAccess = true
                self.trashURL = trashPath
            }
            return
        }
        
        DispatchQueue.main.async {
            self.hasTrashAccess = false
        }
    }
    
    // MARK: - Home Access Request
    
    func requestHomeAccess(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            // Store reference to the main window BEFORE showing panel
            let mainWindow = NSApp.keyWindow ?? NSApp.windows.first(where: { $0.isVisible && $0.canBecomeKey })
            
            NSApp.activate(ignoringOtherApps: true)
            
            let openPanel = NSOpenPanel()
            openPanel.message = "Mintify needs access to your Home folder to scan for duplicates and clean files."
            openPanel.prompt = "Grant Access"
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
            openPanel.treatsFilePackagesAsDirectories = false
            openPanel.allowsMultipleSelection = false
            openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
            
            let handleResponse: (NSApplication.ModalResponse) -> Void = { response in
                if response == .OK, let url = openPanel.url {
                    self.saveBookmark(for: url)
                    self.checkPermissions()
                    completion(true)
                } else {
                    completion(false)
                }
            }
            
            // Use beginSheetModal if we have a window, otherwise use begin
            if let window = mainWindow {
                openPanel.beginSheetModal(for: window, completionHandler: handleResponse)
            } else {
                openPanel.begin { response in
                    DispatchQueue.main.async {
                        NSApp.activate(ignoringOtherApps: true)
                        if let window = mainWindow {
                            window.makeKeyAndOrderFront(nil)
                        }
                    }
                    handleResponse(response)
                }
            }
        }
    }
    
    // MARK: - Trash Access Request
    
    func requestTrashAccess(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            // First, try automatic access via macOS API
            if let trashURL = FileManager.default.urls(for: .trashDirectory, in: .userDomainMask).first {
                if let _ = try? FileManager.default.contentsOfDirectory(atPath: trashURL.path) {
                    self.trashURL = trashURL
                    self.hasTrashAccess = true
                    completion(true)
                    return
                }
            }
            
            // Fallback: Check traditional path
            let trashPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
            if let _ = try? FileManager.default.contentsOfDirectory(atPath: trashPath.path) {
                self.trashURL = trashPath
                self.hasTrashAccess = true
                completion(true)
                return
            }
            
            // If automatic access fails, show alert guiding to Full Disk Access
            let alert = NSAlert()
            alert.messageText = "Trash Access Required"
            alert.informativeText = """
            Mintify needs Full Disk Access to scan your Trash folder.
            
            How to grant access:
            1. Click "Open Settings" below
            2. Click the + button at the bottom of the list
            3. Find and select Mintify.app
            4. Click Open, then enable the toggle
            5. Restart Mintify
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Cancel")
            
            NSApp.activate(ignoringOtherApps: true)
            
            if alert.runModal() == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            completion(false)
        }
    }
    
    // MARK: - Bookmark Management
    
    private func saveBookmark(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            var bookmarks = UserDefaults.standard.dictionary(forKey: bookmarkKey) ?? [:]
            bookmarks[url.path] = bookmarkData
            UserDefaults.standard.set(bookmarks, forKey: bookmarkKey)
            
            if url.startAccessingSecurityScopedResource() {
                DispatchQueue.main.async {
                    self.homeURL = url
                }
            }
        } catch {
            print("[PermissionManager] Failed to save bookmark: \(error)")
        }
    }
    
    private func restoreBookmarks() {
        guard let bookmarks = UserDefaults.standard.dictionary(forKey: bookmarkKey) as? [String: Data] else { return }
        
        for (path, bookmarkData) in bookmarks {
            do {
                var isStale = false
                let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                if url.startAccessingSecurityScopedResource() {
                    // Only restore home URL bookmark (trash doesn't use bookmarks)
                    if url.path.hasSuffix(NSUserName()) {
                        DispatchQueue.main.async {
                            self.homeURL = url
                        }
                    }
                }
            } catch {
                print("[PermissionManager] Failed to restore bookmark for \(path): \(error)")
            }
        }
    }
}
