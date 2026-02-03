import SwiftUI

/// App-wide state management for Storage Cleaner feature
class CleanerState: ObservableObject {
    @Published var categories: [CleanableCategory] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var currentScanningCategory: String = ""
    @Published var lastScanTime: Date?
    @Published var cleanErrors: [String] = []
    @Published var remainingCategoriesToScan: Int = 0
    @Published var hasScanned = false
    @Published var isDeleting = false  // For individual item deletion loading overlay
    
    // Navigation
    @Published var selectedTab: MainTab = .cleaner
    
    // Enabled categories for scanning (default: all except Trash)
    @Published var enabledCategories: Set<CleanCategory> = Set(CleanCategory.allCases.filter { $0 != .trash })
    
    private let scanner = StorageScanner()
    private var scanGeneration: Int = 0  // Increments on each new scan to cancel old async jobs
    
    @Published var shouldStopScan = false
    
    var totalCleanableSize: Int64 {
        categories.reduce(0) { $0 + $1.totalSize }
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalCleanableSize, countStyle: .file)
    }
    
    var totalSelectedSize: Int64 {
        categories.reduce(0) { total, category in
            total + category.items.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
        }
    }
    
    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSelectedSize, countStyle: .file)
    }
    
    var allSelected: Bool {
        !categories.isEmpty && categories.allSatisfy { cat in
            cat.items.allSatisfy { $0.isSelected }
        }
    }
    
    func toggleSelectAll() {
        let newValue = !allSelected
        for i in categories.indices {
            categories[i].isSelected = newValue
            for j in categories[i].items.indices {
                categories[i].items[j].isSelected = newValue
            }
        }
    }
    
    func startScan() {
        // Increment generation to invalidate any running scans
        scanGeneration += 1
        let currentGeneration = scanGeneration
        
        isScanning = true
        shouldStopScan = false
        scanProgress = 0
        currentScanningCategory = "Initializing..."
        cleanErrors = []
        categories = []
        
        // Only scan enabled categories
        let categoriesToScan = CleanCategory.allCases.filter { enabledCategories.contains($0) }
        remainingCategoriesToScan = categoriesToScan.count
        
        guard !categoriesToScan.isEmpty else {
            isScanning = false
            currentScanningCategory = ""
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            for (index, category) in categoriesToScan.enumerated() {
                // Check if this scan is still valid (not cancelled by a new scan or stop)
                guard self.scanGeneration == currentGeneration && !self.shouldStopScan else {
                    return
                }
                
                let items = self.scanner.scanCategoryWithProgress(category) { folderName in
                    // Only update UI if this scan is still valid
                    guard self.scanGeneration == currentGeneration else { return }
                    DispatchQueue.main.async {
                        self.currentScanningCategory = "\(category.rawValue)/\(folderName)"
                        self.scanProgress = (Double(index) + 0.5) / Double(categoriesToScan.count)
                    }
                }
                
                // Check again before appending
                guard self.scanGeneration == currentGeneration && !self.shouldStopScan else {
                    return
                }
                
                DispatchQueue.main.async {
                    // Final check on main thread
                    guard self.scanGeneration == currentGeneration && !self.shouldStopScan else { return }
                    
                    if !items.isEmpty {
                        self.categories.append(CleanableCategory(category: category, items: items))
                    }
                    self.remainingCategoriesToScan = categoriesToScan.count - index - 1
                    self.scanProgress = Double(index + 1) / Double(categoriesToScan.count)
                }
            }
            
            DispatchQueue.main.async {
                // Only complete if this scan is still valid
                guard self.scanGeneration == currentGeneration && !self.shouldStopScan else { return }
                self.isScanning = false
                self.currentScanningCategory = ""
                self.lastScanTime = Date()
                self.hasScanned = true
            }
        }
    }
    
    func stopScan() {
        shouldStopScan = true
        isScanning = false
        currentScanningCategory = ""
        categories = []
        scanProgress = 0
    }
    
    func removeItemFromList(path: String) {
        for i in categories.indices {
            categories[i].items.removeAll { $0.path == path }
        }
        categories.removeAll { $0.items.isEmpty }
    }
    
    func performClean(completion: @escaping (Int, Int) -> Void) {
        var itemsToClean: [CleanableItem] = []
        for category in categories {
            itemsToClean.append(contentsOf: category.items.filter { $0.isSelected })
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let result = self.scanner.cleanItems(itemsToClean)
            
            DispatchQueue.main.async {
                for item in itemsToClean {
                    self.removeItemFromList(path: item.path)
                }
                self.cleanErrors = result.errors
                completion(result.success, result.failed)
            }
        }
    }
}
