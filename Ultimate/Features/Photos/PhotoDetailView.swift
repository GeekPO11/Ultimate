import SwiftUI

/// View for displaying and managing a single photo
struct PhotoDetailView: View {
    let photo: ProgressPhoto
    let photoService: ProgressPhotoService
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var image: UIImage?
    @State private var isBlurred: Bool
    @State private var notes: String
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var showingSaveToLibraryConfirmation = false
    @State private var saveToLibrarySuccess = false
    @State private var saveToLibraryError: Error?
    @State private var showingSaveConfirmation = false
    
    init(photo: ProgressPhoto, photoService: ProgressPhotoService) {
        self.photo = photo
        self.photoService = photoService
        self._isBlurred = State(initialValue: photo.isBlurred)
        self._notes = State(initialValue: photo.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.l) {
                    // Photo
                    if let image = image {
                        ZStack {
                            Image(uiImage: isBlurred ? photoService.blurPhoto(image: image) ?? image : image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(DesignSystem.BorderRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                                        .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
                                )
                            
                            // Privacy indicator
                            if isBlurred {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        
                                        Image(systemName: "eye.slash.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(DesignSystem.Colors.primaryAction)
                                            .clipShape(Circle())
                                            .padding(DesignSystem.Spacing.s)
                                    }
                                }
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(DesignSystem.Colors.cardBackground)
                            .aspectRatio(3/4, contentMode: .fit)
                            .cornerRadius(DesignSystem.BorderRadius.medium)
                            .overlay(
                                ProgressView()
                            )
                    }
                    
                    // Metadata
                    VStack(spacing: DesignSystem.Spacing.m) {
                        // Date and angle
                        HStack {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                                Text("Date")
                                    .font(DesignSystem.Typography.caption1)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                
                                Text(photo.date, style: .date)
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxs) {
                                Text("Angle")
                                    .font(DesignSystem.Typography.caption1)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                
                                HStack(spacing: DesignSystem.Spacing.xxs) {
                                    Image(systemName: photo.angle.icon)
                                        .font(.system(size: 14))
                                    
                                    Text(photo.angle.rawValue)
                                        .font(DesignSystem.Typography.body)
                                }
                                .foregroundColor(DesignSystem.Colors.primaryText)
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Challenge
                        if let challenge = photo.challenge {
                            HStack {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                                    Text("Challenge")
                                        .font(DesignSystem.Typography.caption1)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                    
                                    Text(challenge.name)
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(DesignSystem.Colors.primaryText)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            Divider()
                                .padding(.horizontal)
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Notes")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            TextEditor(text: $notes)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                .frame(minHeight: 100)
                                .padding(DesignSystem.Spacing.xs)
                                .background(DesignSystem.Colors.cardBackground)
                                .cornerRadius(DesignSystem.BorderRadius.small)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.small)
                                        .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
                                )
                                .submitLabel(.done)
                                .onSubmit {
                                    saveChanges()
                                }
                        }
                        .padding(.horizontal)
                        
                        // Privacy toggle
                        Toggle(isOn: $isBlurred) {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: isBlurred ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(isBlurred ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.secondaryText)
                                
                                Text("Privacy Mode")
                                    .font(DesignSystem.Typography.body)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primaryAction))
                        .padding(.horizontal)
                        
                        // Action buttons
                        HStack(spacing: DesignSystem.Spacing.m) {
                            // Share button
                            Button(action: {
                                showingShareSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
                                }
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.neonBlue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignSystem.Spacing.s)
                                .background(Color.clear)
                                .cornerRadius(DesignSystem.BorderRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                                        .strokeBorder(DesignSystem.Colors.neonBlue, lineWidth: 1.5)
                                        .shadow(color: DesignSystem.Colors.neonBlue, radius: 4, x: 0, y: 0)
                                )
                            }
                            
                            // Delete button
                            Button(action: {
                                showingDeleteAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete")
                                }
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.neonPink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignSystem.Spacing.s)
                                .background(Color.clear)
                                .cornerRadius(DesignSystem.BorderRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                                        .strokeBorder(DesignSystem.Colors.neonPink, lineWidth: 1.5)
                                        .shadow(color: DesignSystem.Colors.neonPink, radius: 4, x: 0, y: 0)
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, DesignSystem.Spacing.s)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Photo Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        saveChanges()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.neonPink)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        saveChanges()
                    }) {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.neonGreen)
                    }
                }
            }
            .onAppear {
                loadImage()
            }
            .alert("Delete Photo", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deletePhoto()
                }
            } message: {
                Text("Are you sure you want to delete this photo? This action cannot be undone.")
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = image {
                    ShareSheet(activityItems: [image])
                }
            }
            .overlay(
                // Save confirmation toast
                ZStack {
                    if showingSaveConfirmation {
                        VStack {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Notes saved")
                                    .font(DesignSystem.Typography.subheadline)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        .padding(.top, 60)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                }
                .animation(.easeInOut, value: showingSaveConfirmation)
            )
            .alert("Save to Photo Library", isPresented: $showingSaveToLibraryConfirmation) {
                // ... existing code ...
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Loads the photo image
    private func loadImage() {
        DispatchQueue.global().async {
            let loadedImage = self.photoService.loadPhoto(from: self.photo.fileURL)
            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }
    }
    
    /// Saves changes to the photo
    private func saveChanges() {
        photo.notes = notes.isEmpty ? nil : notes
        photo.isBlurred = isBlurred
        photo.updatedAt = Date()
        
        try? modelContext.save()
        
        // Show save confirmation
        withAnimation {
            showingSaveConfirmation = true
        }
        
        // Hide confirmation after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingSaveConfirmation = false
            }
        }
    }
    
    /// Deletes the photo
    private func deletePhoto() {
        // Delete the file
        _ = photoService.deletePhoto(at: photo.fileURL)
        
        // Delete from database
        modelContext.delete(photo)
        try? modelContext.save()
        
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    PhotoDetailView(
        photo: ProgressPhoto(
            id: UUID(),
            date: Date(),
            angle: .front,
            fileURL: URL(string: "file:///tmp/photo.jpg")!,
            notes: "Sample notes for this photo",
            isBlurred: false
        ),
        photoService: ProgressPhotoService()
    )
    .modelContainer(for: [User.self, Challenge.self, Task.self, DailyTask.self, ProgressPhoto.self], inMemory: true)
} 