import SwiftUI

/// App Delegate for window management and menu bar functionality
class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    var appState = CleanerState()
    var duplicateState = DuplicateFinderState()
    var largeFilesState = LargeFilesState()
    var diskSpaceState = DiskSpaceState()
    var appUninstallerState = AppUninstallerState()
    private var mainWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?
    private var welcomeWindow: NSWindow?
    
    // Menu Bar Items
    private var statusItem: NSStatusItem?
    var overlayWindow: NSWindow? // Exposed for MenuBarView resizing
    private var eventMonitor: Any?
    private var overlayWindowTopY: CGFloat = 0 // Track top position to anchor
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        // Start as accessory (menu bar only, no dock icon)
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        
        // Show welcome screen on first launch, or open menu bar on subsequent launches
        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showWelcomeWindow()
            }
        } else {
            // On subsequent launches, open menu bar popup
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.toggleWindow(nil)
            }
        }
    }
    
    func setupMenuBar() {
        // Create Status Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Mintify")
            button.action = #selector(toggleWindow(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    private func createOverlayWindow() {
        // Create window with no border/title bar
        let window = CustomOverlayWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 400),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Critical: Set background to clear
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false // We handle shadow in the view itself for "floating card" effect
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Setup Content View
        let rootView = MenuBarView()
            .environmentObject(appState)
            .environmentObject(duplicateState)
            .environmentObject(largeFilesState)
            .environmentObject(diskSpaceState)
            .environmentObject(appUninstallerState)
            .environmentObject(PermissionManager.shared)
        
        let hostingController = NSHostingController(rootView: rootView)
        // Ensure hosting view layer is transparent
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 320, height: 400)
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        
        window.contentViewController = hostingController
        
        self.overlayWindow = window
    }
    
    @objc func toggleWindow(_ sender: AnyObject?) {
        if overlayWindow == nil {
            createOverlayWindow()
        }
        
        guard let window = overlayWindow, let button = statusItem?.button else { return }
        
        if window.isVisible {
            closeWindow()
        } else {
            showWindow(window, relativeTo: button)
        }
    }
    
    private func showWindow(_ window: NSWindow, relativeTo button: NSStatusBarButton) {
        // Update content if needed (SwiftUI handles state changes automatically via Observables)
        // Force layout pass to ensure size is correct before positioning
        window.contentViewController?.view.layoutSubtreeIfNeeded()
        
        // Calculate Position
        if let buttonWindow = button.window {
            let buttonRect = buttonWindow.convertToScreen(button.frame)
            let windowSize = window.frame.size
            
            // SIMPLIFIED VERTICAL LAYOUT POSITIONING:
            // Center the window (fixed 320px width) under the button.
            let buttonCenterX = buttonRect.midX
            let x = buttonCenterX - (windowSize.width / 2)
            
            // Position below button - store the TOP edge position
            let topY = buttonRect.minY - 4 // small padding from menu bar
            overlayWindowTopY = topY
            let y = topY - windowSize.height
            
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        // Observe frame changes to anchor at top
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(overlayWindowDidResize(_:)),
            name: NSWindow.didResizeNotification,
            object: window
        )
        
        // Show Window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Start monitoring for outside clicks
        startEventMonitor()
    }
    
    @objc private func overlayWindowDidResize(_ notification: Notification) {
        repositionOverlayWindowToTop()
    }
    
    func repositionOverlayWindowToTop() {
        guard let window = overlayWindow else { return }
        
        // Force layout to get correct size
        window.contentViewController?.view.layoutSubtreeIfNeeded()
        
        // Keep the window anchored at the top (expand downward)
        let currentFrame = window.frame
        let newY = overlayWindowTopY - currentFrame.height
        
        if abs(currentFrame.origin.y - newY) > 1 {
            // Set frame atomically to avoid jitter
            let newFrame = NSRect(x: currentFrame.origin.x, y: newY, width: currentFrame.width, height: currentFrame.height)
            window.setFrame(newFrame, display: true, animate: false)
        }
    }
    
    private func closeWindow() {
        // Remove frame change observer
        if let window = overlayWindow {
            NotificationCenter.default.removeObserver(self, name: NSWindow.didResizeNotification, object: window)
        }
        overlayWindow?.orderOut(nil)
        stopEventMonitor()
    }
    
    private func startEventMonitor() {
        // Monitor global and local events to detect clicks outside
        // We capture left and right mouse clicks.
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            // If explicit click outside, close.
            self?.closeWindow()
        }
    }
    
    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    func showMainWindow() {
        // Close menu bar overlay first
        closeWindow()
        
        // Show dock icon when main window is open
        NSApp.setActivationPolicy(.regular)
        
        if let window = mainWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let contentView = MainContentView()
            .environmentObject(appState)
            .environmentObject(duplicateState)
            .environmentObject(largeFilesState)
            .environmentObject(diskSpaceState)
            .environmentObject(appUninstallerState)
            .environmentObject(PermissionManager.shared)
        
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Mintify"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView] as NSWindow.StyleMask
        window.setContentSize(NSSize(width: 960, height: 680))
        window.minSize = NSSize(width: 800, height: 600)
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        // Set window background color
        window.backgroundColor = NSColor(red: 26/255, green: 26/255, blue: 46/255, alpha: 1)
        
        // Set delegate to track window close
        window.delegate = self
        
        // Keep reference
        self.mainWindow = window
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func showSettingsWindow() {
        // Close menu bar overlay first
        closeWindow()
        
        // Show dock icon
        NSApp.setActivationPolicy(.regular)
        
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView()
            .environmentObject(appState)
            .environmentObject(PermissionManager.shared)
        
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.styleMask = [.titled, .closable, .fullSizeContentView] as NSWindow.StyleMask
        window.setContentSize(NSSize(width: 620, height: 560))
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = NSColor(red: 26/255, green: 26/255, blue: 46/255, alpha: 1)
        
        // Set delegate to track window close
        window.delegate = self
        
        self.settingsWindow = window
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func showWelcomeWindow() {
        // Show dock icon
        NSApp.setActivationPolicy(.regular)
        
        if let window = welcomeWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create @State binding for isPresented using a wrapper class
        let welcomeState = WelcomeWindowState()
        
        let welcomeView = WelcomeViewWrapper(state: welcomeState)
            .environmentObject(PermissionManager.shared)
        
        let hostingController = NSHostingController(rootView: welcomeView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Welcome"
        window.styleMask = [.titled, .closable, .fullSizeContentView] as NSWindow.StyleMask
        window.setContentSize(NSSize(width: 520, height: 600))
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = NSColor(red: 26/255, green: 26/255, blue: 46/255, alpha: 1)
        
        window.delegate = self
        welcomeState.window = window
        
        self.welcomeWindow = window
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func showAboutWindow() {
        // Close menu bar overlay first
        closeWindow()
        
        // Show dock icon
        NSApp.setActivationPolicy(.regular)
        
        if let window = aboutWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let aboutView = AboutView()
        
        let hostingController = NSHostingController(rootView: aboutView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "About Mintify"
        window.styleMask = [.titled, .closable, .fullSizeContentView] as NSWindow.StyleMask
        window.setContentSize(NSSize(width: 340, height: 480))
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = NSColor(red: 26/255, green: 26/255, blue: 46/255, alpha: 1)
        
        // Set delegate to track window close
        window.delegate = self
        
        self.aboutWindow = window
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// Hide main window and dock icon, returning to menu bar-only mode
    func hideMainWindowAndDockIcon() {
        // Check if any main windows are still visible
        let hasVisibleMainWindow = (mainWindow?.isVisible ?? false) || (settingsWindow?.isVisible ?? false) || (aboutWindow?.isVisible ?? false)
        
        if !hasVisibleMainWindow {
            // No main windows visible, hide dock icon
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

// MARK: - NSWindowDelegate
extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        // If main window, settings window, or about window is closing, check if we should hide dock icon
        if window === mainWindow || window === settingsWindow || window === aboutWindow {
            // Delay slightly to allow window to fully close
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.hideMainWindowAndDockIcon()
            }
        }
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        
        // If main window, settings window, or about window gains focus, close the menu bar overlay
        if window === mainWindow || window === settingsWindow || window === aboutWindow {
            closeWindow()
        }
    }
}
