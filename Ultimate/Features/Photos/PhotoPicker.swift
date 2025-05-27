import SwiftUI
import PhotosUI

/// Enhanced photo picker for selecting images from the photo library
struct PhotoPicker: View {
    var selectedChallenge: Challenge?
    var selectedAngle: Binding<PhotoAngle>
    var onPhotoSelected: (UIImage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.l) {
                // Header
                VStack(spacing: DesignSystem.Spacing.m) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 48))
                        .foregroundColor(DesignSystem.Colors.primaryAction)
                    
                    VStack(spacing: DesignSystem.Spacing.s) {
                        Text("Select Photo from Library")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("Choose a \(selectedAngle.wrappedValue.description.lowercased()) photo from your library")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                
                Spacer()
                
                // Photo picker
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    VStack(spacing: DesignSystem.Spacing.m) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                        
                        Text("Browse Library")
                            .font(DesignSystem.Typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(DesignSystem.Colors.primaryAction)
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                }
                .disabled(isLoading)
                .opacity(isLoading ? 0.6 : 1.0)
                .padding(.horizontal)
                
                if isLoading {
                    HStack(spacing: DesignSystem.Spacing.s) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                        
                        Text("Loading photo...")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .background(PremiumBackground())
            .navigationTitle("Photo Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primaryAction)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                if let newItem = newItem {
                    loadPhoto(from: newItem)
                }
            }
        }
    }
    
    private func loadPhoto(from item: PhotosPickerItem) {
        isLoading = true
        
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        onPhotoSelected(image)
                        dismiss()
                    }
                case .failure(let error):
                    print("Failed to load photo: \(error)")
                }
            }
        }
    }
}

#Preview {
    PhotoPicker(
        selectedChallenge: nil,
        selectedAngle: .constant(.front),
        onPhotoSelected: { _ in }
    )
} 