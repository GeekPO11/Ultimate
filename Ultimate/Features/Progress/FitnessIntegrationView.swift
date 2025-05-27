import SwiftUI
import HealthKit

struct FitnessIntegrationView: View {
    @State private var isHealthKitAuthorized = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let healthKitService = HealthKitService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.l) {
                    // Header Section
                    VStack(spacing: DesignSystem.Spacing.m) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(DesignSystem.Colors.primaryAction)
                                .font(.system(size: 18))
                            
                            Text("HealthKit Integration")
                                .font(DesignSystem.Typography.headline)
                                .fontWeight(.bold)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Spacer()
                        }
                        
                        Text("Connect with Apple Health to automatically track your fitness progress and sync data across devices.")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(Material.thin)
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                    
                    // Status Section
                    VStack(spacing: DesignSystem.Spacing.m) {
                        HStack {
                            Text("Status")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: isHealthKitAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isHealthKitAuthorized ? .green : .red)
                                .font(.system(size: 20))
                            
                            Text(isHealthKitAuthorized ? "Connected" : "Not Connected")
                                .font(DesignSystem.Typography.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Material.thin)
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                    
                    // Permissions Section
                    VStack(spacing: DesignSystem.Spacing.m) {
                        HStack {
                            Text("Permissions")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            
                            Spacer()
                        }
                        
                        PermissionRow(
                            title: "Body Weight",
                            description: "Track weight changes",
                            isGranted: isHealthKitAuthorized
                        )
                        
                        PermissionRow(
                            title: "Body Fat Percentage",
                            description: "Monitor body composition",
                            isGranted: isHealthKitAuthorized
                        )
                        
                        PermissionRow(
                            title: "Lean Body Mass",
                            description: "Track muscle mass changes",
                            isGranted: isHealthKitAuthorized
                        )
                        
                        PermissionRow(
                            title: "Height",
                            description: "Reference for BMI calculations",
                            isGranted: isHealthKitAuthorized
                        )
                    }
                    .padding()
                    .background(Material.thin)
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                    
                    // Action Button
                    VStack(spacing: DesignSystem.Spacing.s) {
                        Button(action: toggleHealthKitAuthorization) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: isHealthKitAuthorized ? "arrow.clockwise" : "plus.circle.fill")
                                        .font(.system(size: 16))
                                }
                                
                                Text(isHealthKitAuthorized ? "Refresh Permissions" : "Connect to Health")
                                    .font(DesignSystem.Typography.body)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(DesignSystem.Colors.primaryAction)
                            .cornerRadius(DesignSystem.BorderRadius.medium)
                        }
                        .disabled(isLoading)
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(DesignSystem.Typography.footnote)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Info Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                        Text("About HealthKit Integration")
                            .font(DesignSystem.Typography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("Your health data is securely stored on your device and never shared without your permission. You can revoke access at any time through the Health app settings.")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Material.thin)
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                }
                .padding()
            }
            .navigationTitle("Fitness Integration")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                checkAuthorizationStatus()
            }
        }
    }
    
    private func toggleHealthKitAuthorization() {
        isLoading = true
        errorMessage = nil
        
        if isHealthKitAuthorized {
            // Refresh authorization status
            checkAuthorizationStatus()
        } else {
            // Request authorization
            healthKitService.requestAuthorization { success, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if success {
                        self.isHealthKitAuthorized = true
                    } else {
                        self.errorMessage = error?.localizedDescription ?? "Failed to connect to Health"
                    }
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        isLoading = true
        healthKitService.checkAuthorizationStatus()
        // The status is checked synchronously, so we can read it immediately
        DispatchQueue.main.async {
            self.isHealthKitAuthorized = self.healthKitService.currentAuthorizationStatus == .approved
            self.isLoading = false
        }
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let isGranted: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(description)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: isGranted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isGranted ? .green : DesignSystem.Colors.secondaryText)
                .font(DesignSystem.Typography.caption2)
        }
    }
} 