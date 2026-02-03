import SwiftUI

/// A reusable overlay component showing delete progress
struct DeleteProgressOverlay: View {
    let message: String
    let current: Int
    let total: Int
    var onCancel: (() -> Void)?
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            // Content card
            VStack(spacing: 20) {
                // Spinner
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                
                // Message
                Text(message)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                // Progress info
                if total > 0 {
                    VStack(spacing: 8) {
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 6)
                                
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.red.opacity(0.8), Color.orange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(0, geometry.size.width * progress), height: 6)
                            }
                        }
                        .frame(height: 6)
                        
                        // Count
                        Text("\(current) / \(total)")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(width: 200)
                }
                
                // Cancel button (optional)
                if let onCancel = onCancel {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            )
        }
    }
}

/// Simple loading overlay without progress
struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
            )
        }
    }
}

#Preview {
    ZStack {
        Color.gray
        DeleteProgressOverlay(
            message: "Deleting files...",
            current: 3,
            total: 10,
            onCancel: {}
        )
    }
}
