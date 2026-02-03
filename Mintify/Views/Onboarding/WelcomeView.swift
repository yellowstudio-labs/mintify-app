import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var permissionManager: PermissionManager
    @Binding var isPresented: Bool
    @State private var currentStep = 0
    @State private var isRequestingAccess = false
    
    private let features = [
        WelcomeFeature(
            icon: "sparkles",
            title: "Storage Cleaner",
            description: "Scan and remove junk files, caches, and temporary data to free up disk space."
        ),
        WelcomeFeature(
            icon: "doc.on.doc",
            title: "Duplicate Finder",
            description: "Find and remove duplicate files taking up valuable storage."
        ),
        WelcomeFeature(
            icon: "memorychip",
            title: "System Monitor",
            description: "Monitor CPU, memory, and disk usage in real-time from the menu bar."
        )
    ]
    
    var body: some View {
        ZStack {
            AppTheme.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Content
                if currentStep == 0 {
                    featuresSection
                } else {
                    permissionSection
                }
                
                Spacer()
                
                // Footer buttons
                footerSection
            }
            .padding(32)
        }
        .frame(width: 520, height: 600)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon
            ZStack {
                Circle()
                    .fill(AppTheme.mintifyGradient)
                    .frame(width: 72, height: 72)
                    .shadow(color: AppTheme.cleanPink.opacity(0.4), radius: 16, x: 0, y: 6)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            VStack(spacing: 6) {
                Text("Welcome to Mintify")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(currentStep == 0 ? "Keep your Mac clean and fast" : "One more step to get started")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: 16) {
            ForEach(features) { feature in
                featureRow(feature)
            }
        }
    }
    
    private func featureRow(_ feature: WelcomeFeature) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.cleanCyan.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.mintifyGradient)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(feature.description)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppTheme.cardBackground)
        )
    }
    
    // MARK: - Permission Section
    private var permissionSection: some View {
        VStack(spacing: 24) {
            // Permission card
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(permissionManager.hasHomeAccess ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: permissionManager.hasHomeAccess ? "checkmark.shield.fill" : "folder.badge.plus")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(permissionManager.hasHomeAccess ? .green : .orange)
                }
                
                VStack(spacing: 8) {
                    Text(permissionManager.hasHomeAccess ? "Access Granted!" : "Folder Access Required")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text(permissionManager.hasHomeAccess
                         ? "You're all set! Mintify can now scan your files."
                         : "Mintify needs access to your Home folder to scan for junk files, duplicates, and more.")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if !permissionManager.hasHomeAccess {
                    Button(action: requestAccess) {
                        HStack(spacing: 8) {
                            if isRequestingAccess {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            } else {
                                Image(systemName: "folder.badge.plus")
                            }
                            Text("Grant Access")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [.orange, .orange.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isRequestingAccess)
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.cardBorder, lineWidth: 1)
                    )
            )
            
            // Info note
            if !permissionManager.hasHomeAccess {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(AppTheme.cleanCyan)
                        .font(.system(size: 14))
                    
                    Text("A file picker will open. Select your Home folder and click Grant Access.")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.horizontal, 8)
            }
        }
    }
    
    // MARK: - Footer
    private var footerSection: some View {
        HStack {
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<2) { index in
                    Circle()
                        .fill(currentStep == index ? AppTheme.cleanCyan : AppTheme.cardBorder)
                        .frame(width: 8, height: 8)
                }
            }
            
            Spacer()
            
            if currentStep == 0 {
                Button(action: { withAnimation { currentStep = 1 } }) {
                    HStack(spacing: 6) {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(AppTheme.cleanCyan))
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 12) {
                    if !permissionManager.hasHomeAccess {
                        Button(action: skipAndClose) {
                            Text("Skip for Now")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button(action: completeOnboarding) {
                        Text(permissionManager.hasHomeAccess ? "Get Started" : "Done")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(AppTheme.cleanCyan))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 24)
    }
    
    // MARK: - Actions
    private func requestAccess() {
        isRequestingAccess = true
        permissionManager.requestHomeAccess { _ in
            isRequestingAccess = false
        }
    }
    
    private func skipAndClose() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        isPresented = false
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        isPresented = false
        // Open main Mintify window
        AppDelegate.shared?.showMainWindow()
    }
}

// MARK: - Feature Model
struct WelcomeFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - Window State for closing
class WelcomeWindowState: ObservableObject {
    @Published var isPresented = true
    weak var window: NSWindow?
    
    func close() {
        isPresented = false
        window?.close()
    }
}

// MARK: - Wrapper View
struct WelcomeViewWrapper: View {
    @ObservedObject var state: WelcomeWindowState
    @EnvironmentObject var permissionManager: PermissionManager
    
    var body: some View {
        WelcomeView(isPresented: Binding(
            get: { state.isPresented },
            set: { newValue in
                if !newValue {
                    state.close()
                }
            }
        ))
        .environmentObject(permissionManager)
    }
}

#Preview {
    WelcomeView(isPresented: .constant(true))
        .environmentObject(PermissionManager.shared)
}
