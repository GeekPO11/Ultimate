import SwiftUI
import PhotosUI

/// Photo picker for selecting photos from the photo library
struct PhotoPicker: View {
    let selectedChallenge: Challenge?
    @Binding var selectedAngle: PhotoAngle
    let onPhotoSelected: (UIImage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.l) {
                // Header
                Text("Select a Photo")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // Angle selector
                VStack(spacing: DesignSystem.Spacing.s) {
                    Text("Photo Angle")
                        .font(DesignSystem.Typography.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: DesignSystem.Spacing.m) {
                        ForEach(PhotoAngle.allCases, id: \.self) { angle in
                            Button(action: {
                                selectedAngle = angle
                            }) {
                                VStack(spacing: DesignSystem.Spacing.xxs) {
                                    Image(systemName: angle.icon)
                                        .font(.system(size: 24))
                                        .foregroundColor(selectedAngle == angle ? DesignSystem.Colors.neonBlue : DesignSystem.Colors.secondaryText)
                                    
                                    Text(angle.rawValue)
                                        .font(DesignSystem.Typography.caption1)
                                        .foregroundColor(selectedAngle == angle ? DesignSystem.Colors.neonBlue : DesignSystem.Colors.secondaryText)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignSystem.Spacing.s)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.small)
                                        .fill(Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.small)
                                        .strokeBorder(selectedAngle == angle ? DesignSystem.Colors.neonBlue : DesignSystem.Colors.dividers, lineWidth: selectedAngle == angle ? 1.5 : 1)
                                        .shadow(color: selectedAngle == angle ? DesignSystem.Colors.neonBlue.opacity(0.6) : Color.clear, radius: 3, x: 0, y: 0)
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Selected image preview
                if let selectedImage = selectedImage {
                    VStack(spacing: DesignSystem.Spacing.s) {
                        Text("Preview")
                            .font(DesignSystem.Typography.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 300)
                            .cornerRadius(DesignSystem.BorderRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                                    .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                } else {
                    // Photo picker
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        VStack(spacing: DesignSystem.Spacing.m) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 60))
                                .foregroundColor(DesignSystem.Colors.primaryAction)
                            
                            Text("Tap to Select a Photo")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.BorderRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                                .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: DesignSystem.Spacing.m) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(DesignSystem.Typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.neonPink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.m)
                            .background(Color.clear)
                            .cornerRadius(DesignSystem.BorderRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                                    .strokeBorder(DesignSystem.Colors.neonPink, lineWidth: 1.5)
                                    .shadow(color: DesignSystem.Colors.neonPink, radius: 4, x: 0, y: 0)
                            )
                    }
                    
                    Button(action: {
                        if let selectedImage = selectedImage {
                            onPhotoSelected(selectedImage)
                            dismiss()
                        }
                    }) {
                        Text("Use Photo")
                            .font(DesignSystem.Typography.body)
                            .fontWeight(.medium)
                            .foregroundColor(selectedImage != nil ? DesignSystem.Colors.neonCyan : DesignSystem.Colors.neonCyan.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.m)
                            .background(Color.clear)
                            .cornerRadius(DesignSystem.BorderRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                                    .strokeBorder(selectedImage != nil ? DesignSystem.Colors.neonCyan : DesignSystem.Colors.neonCyan.opacity(0.5), lineWidth: 1.5)
                                    .shadow(color: selectedImage != nil ? DesignSystem.Colors.neonCyan : Color.clear, radius: 4, x: 0, y: 0)
                            )
                    }
                    .disabled(selectedImage == nil)
                }
                .padding(.horizontal)
                .padding(.bottom, DesignSystem.Spacing.l)
            }
            .navigationTitle("Choose Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .onChange(of: selectedItem) { _, newValue in
                loadTransferable(from: newValue)
            }
        }
    }
    
    /// Loads the selected image
    private func loadTransferable(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        self.selectedImage = image
                    }
                case .failure(let error):
                    print("Error loading image: \(error)")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PhotoPicker(
        selectedChallenge: nil,
        selectedAngle: .constant(.front),
        onPhotoSelected: { _ in }
    )
} 