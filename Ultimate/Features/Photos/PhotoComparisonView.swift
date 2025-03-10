import SwiftUI
import SwiftData

/// View for comparing progress photos
struct PhotoComparisonView: View {
    // MARK: - Properties
    
    var selectedChallenge: Challenge?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var photos: [ProgressPhoto]
    
    @State private var selectedAngle: PhotoAngle = .front
    @State private var comparisonMode: ComparisonMode = .sideBySide
    @State private var earlierDate: Date?
    @State private var laterDate: Date?
    @State private var sliderPosition: Double = 0.5
    
    // Service for managing photos
    private let photoService = ProgressPhotoService()
    
    // MARK: - Comparison Mode
    
    enum ComparisonMode: String, CaseIterable, Identifiable {
        case sideBySide = "Side by Side"
        case slider = "Slider"
        
        var id: Self { self }
        
        var icon: String {
            switch self {
            case .sideBySide: return "rectangle.split.2x1"
            case .slider: return "slider.horizontal.below.rectangle"
            }
        }
    }
    
    // MARK: - Initialization
    
    init(selectedChallenge: Challenge? = nil) {
        self.selectedChallenge = selectedChallenge
        
        var descriptor = FetchDescriptor<ProgressPhoto>()
        if let challengeId = selectedChallenge?.id {
            descriptor.predicate = #Predicate<ProgressPhoto> { photo in
                photo.challenge?.id == challengeId
            }
        }
        descriptor.sortBy = [SortDescriptor(\.date, order: .forward)]
        
        _photos = Query(descriptor)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium animated background
                PremiumBackground()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Angle selector
                        CTCard(style: .glass) {
                            angleSelector
                        }
                        
                        // Date selectors
                        CTCard(style: .glass) {
                            dateSelectors
                        }
                        
                        // Comparison mode selector
                        CTCard(style: .glass) {
                            comparisonModeSelector
                        }
                        
                        // Photo comparison view
                        if let earlierDate = earlierDate, let laterDate = laterDate,
                           let earlierPhoto = getPhoto(for: earlierDate, angle: selectedAngle),
                           let laterPhoto = getPhoto(for: laterDate, angle: selectedAngle),
                           let earlierImage = photoService.loadPhoto(from: earlierPhoto.fileURL),
                           let laterImage = photoService.loadPhoto(from: laterPhoto.fileURL) {
                            
                            CTCard(style: .glass) {
                                switch comparisonMode {
                                case .sideBySide:
                                    sideBySideView(earlierImage: earlierImage, laterImage: laterImage)
                                case .slider:
                                    sliderView(earlierImage: earlierImage, laterImage: laterImage)
                                }
                            }
                        } else {
                            CTCard(style: .glass) {
                                placeholderView
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Compare Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Set default dates if not already set
                if earlierDate == nil || laterDate == nil {
                    let availableDates = getAvailableDates(for: selectedAngle)
                    if availableDates.count >= 2 {
                        laterDate = availableDates[0]
                        earlierDate = availableDates[1]
                    } else if availableDates.count == 1 {
                        laterDate = availableDates[0]
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    /// Angle selector view
    private var angleSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Angle:")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            // Grid of angle options
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(PhotoAngle.allCases, id: \.self) { angle in
                    Button {
                        selectedAngle = angle
                    } label: {
                        Text(angle.description)
                            .font(DesignSystem.Typography.body)
                            .fontWeight(selectedAngle == angle ? .semibold : .regular)
                            .foregroundColor(selectedAngle == angle ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedAngle == angle ? DesignSystem.Colors.primaryAction.opacity(0.15) : Color.clear)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedAngle == angle ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.dividers, lineWidth: selectedAngle == angle ? 2 : 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .onChange(of: selectedAngle) {
                // Reset dates when angle changes
                let availableDates = getAvailableDates(for: selectedAngle)
                if availableDates.count >= 2 {
                    laterDate = availableDates[0]
                    earlierDate = availableDates[1]
                } else if availableDates.count == 1 {
                    laterDate = availableDates[0]
                    earlierDate = nil
                } else {
                    laterDate = nil
                    earlierDate = nil
                }
            }
        }
    }
    
    /// Date selectors
    private var dateSelectors: some View {
        VStack(spacing: 12) {
            Text("Select two dates to compare")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Date 1:")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Menu {
                        ForEach(getAvailableDates(for: selectedAngle), id: \.self) { date in
                            Button(formatDate(date)) {
                                earlierDate = date
                            }
                        }
                    } label: {
                        HStack {
                            Text(earlierDate != nil ? formatDate(earlierDate!) : "Select date")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(earlierDate != nil ? DesignSystem.Colors.primaryText : DesignSystem.Colors.secondaryText)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Date 2:")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Menu {
                        ForEach(getAvailableDates(for: selectedAngle), id: \.self) { date in
                            Button(formatDate(date)) {
                                laterDate = date
                            }
                        }
                    } label: {
                        HStack {
                            Text(laterDate != nil ? formatDate(laterDate!) : "Select date")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(laterDate != nil ? DesignSystem.Colors.primaryText : DesignSystem.Colors.secondaryText)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    /// Comparison mode selector
    private var comparisonModeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Comparison Mode:")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Picker("Comparison Mode", selection: $comparisonMode) {
                ForEach(ComparisonMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    /// Placeholder view
    private var placeholderView: some View {
        VStack {
            Spacer()
            
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.primaryAction.opacity(0.7))
                .padding(.bottom, 16)
            
            Text("Select two dates with photos to compare")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
    }
    
    /// Side by side view
    private func sideBySideView(earlierImage: UIImage, laterImage: UIImage) -> some View {
        VStack(spacing: 16) {
            // Display date information
            if let earlierDate = earlierDate, let laterDate = laterDate {
                HStack {
                    Text("Comparing photos from:")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Spacer()
                }
                
                HStack {
                    Text(formatDate(earlierDate))
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("vs")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text(formatDate(laterDate))
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Spacer()
                }
                .padding(.bottom, 8)
            }
            
            HStack(spacing: 12) {
                VStack {
                    Text(earlierDate != nil ? formatDate(earlierDate!) : "Earlier")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(DesignSystem.Colors.primaryAction.opacity(0.2))
                        .cornerRadius(DesignSystem.BorderRadius.small)
                    
                    Image(uiImage: earlierImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(DesignSystem.BorderRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                                .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
                        )
                }
                
                VStack {
                    Text(laterDate != nil ? formatDate(laterDate!) : "Later")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(DesignSystem.Colors.primaryAction.opacity(0.2))
                        .cornerRadius(DesignSystem.BorderRadius.small)
                    
                    Image(uiImage: laterImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(DesignSystem.BorderRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                                .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
                        )
                }
            }
            .frame(maxHeight: 400)
        }
    }
    
    /// Slider view
    private func sliderView(earlierImage: UIImage, laterImage: UIImage) -> some View {
        VStack(spacing: 16) {
            // Display date information
            if let earlierDate = earlierDate, let laterDate = laterDate {
                HStack {
                    Text("Comparing photos from:")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Spacer()
                }
                
                HStack {
                    Text(formatDate(earlierDate))
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("vs")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text(formatDate(laterDate))
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Spacer()
                }
                .padding(.bottom, 8)
            }
            
            // Improved slider view with proper sizing
            GeometryReader { geometry in
                ZStack {
                    // Background image (earlier)
                    Image(uiImage: earlierImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .cornerRadius(DesignSystem.BorderRadius.medium)
                    
                    // Overlay image (later) with mask
                    Image(uiImage: laterImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .cornerRadius(DesignSystem.BorderRadius.medium)
                        .mask(
                            Rectangle()
                                .frame(width: geometry.size.width * sliderPosition)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        )
                    
                    // Divider line
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 3)
                        .frame(height: geometry.size.height)
                        .position(x: geometry.size.width * sliderPosition, y: geometry.size.height / 2)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 0)
                    
                    // Slider handle
                    Circle()
                        .fill(DesignSystem.Colors.primaryAction)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 0)
                        .position(x: geometry.size.width * sliderPosition, y: geometry.size.height / 2)
                    
                    // Full-width drag area for better touch handling
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let newPosition = value.location.x / geometry.size.width
                                    sliderPosition = min(max(newPosition, 0), 1)
                                }
                        )
                    
                    // Labels overlaid on the image
                    VStack {
                        Spacer()
                        HStack {
                            Text(earlierDate != nil ? formatDate(earlierDate!) : "Earlier")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(.white)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(DesignSystem.BorderRadius.small)
                                .padding(8)
                            
                            Spacer()
                            
                            Text(laterDate != nil ? formatDate(laterDate!) : "Later")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(.white)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(DesignSystem.BorderRadius.small)
                                .padding(8)
                        }
                    }
                }
                .frame(height: geometry.size.height)
                .cornerRadius(DesignSystem.BorderRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                        .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
                )
            }
            .frame(height: 400)
            .onAppear {
                // Initialize slider position to 0.5 (middle) when view appears
                sliderPosition = 0.5
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get available dates for the selected angle
    private func getAvailableDates(for angle: PhotoAngle) -> [Date] {
        let filteredPhotos = photos.filter { photo in
            photo.angle == angle && 
            (selectedChallenge == nil || photo.challenge?.id == selectedChallenge?.id)
        }
        
        let dates = filteredPhotos.map { Calendar.current.startOfDay(for: $0.date) }
        return Array(Set(dates)).sorted(by: >)
    }
    
    /// Get photo for the selected date and angle
    private func getPhoto(for date: Date?, angle: PhotoAngle) -> ProgressPhoto? {
        guard let date = date else { return nil }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return photos.first { photo in
            photo.angle == angle &&
            photo.date >= startOfDay &&
            photo.date < endOfDay &&
            (selectedChallenge == nil || photo.challenge?.id == selectedChallenge?.id)
        }
    }
    
    /// Format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    PhotoComparisonView()
        .modelContainer(for: [User.self, Challenge.self, Task.self, DailyTask.self, ProgressPhoto.self], inMemory: true)
} 
