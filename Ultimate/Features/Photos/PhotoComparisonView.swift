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
    @State private var beforeDate: Date?
    @State private var afterDate: Date?
    @State private var sliderPosition: Double = 0.5
    @State private var overlayOpacity: Double = 0.5
    
    @State private var fetchedPhotos: [ProgressPhoto] = []
    
    private let photoService = ProgressPhotoService()
    
    // MARK: - Comparison Mode
    
    enum ComparisonMode: String, CaseIterable, Identifiable {
        case sideBySide = "Side by Side"
        case slider = "Slider"
        case overlay = "Overlay"
        
        var id: Self { self }
        
        var icon: String {
            switch self {
            case .sideBySide: return "rectangle.split.2x1"
            case .slider: return "slider.horizontal.below.rectangle"
            case .overlay: return "square.2.layers.3d"
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
            ScrollView {
                VStack(spacing: 16) {
                    angleSelector
                    
                    dateSelectors
                    
                    comparisonModeSelector
                    
                    if let beforeDate = beforeDate, let afterDate = afterDate,
                       let beforePhoto = getPhoto(for: beforeDate, angle: selectedAngle),
                       let afterPhoto = getPhoto(for: afterDate, angle: selectedAngle),
                       let beforeImage = UIImage(contentsOfFile: beforePhoto.fileURL.path()),
                       let afterImage = UIImage(contentsOfFile: afterPhoto.fileURL.path()) {
                        
                        switch comparisonMode {
                        case .sideBySide:
                            sideBySideView(beforeImage: beforeImage, afterImage: afterImage)
                        case .slider:
                            sliderView(beforeImage: beforeImage, afterImage: afterImage)
                        case .overlay:
                            overlayView(beforeImage: beforeImage, afterImage: afterImage)
                        }
                    } else {
                        placeholderView
                    }
                }
                .padding()
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
                if beforeDate == nil || afterDate == nil {
                    let availableDates = getAvailableDates(for: selectedAngle)
                    if availableDates.count >= 2 {
                        afterDate = availableDates[0]
                        beforeDate = availableDates[1]
                    } else if availableDates.count == 1 {
                        afterDate = availableDates[0]
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    /// Angle selector view
    private var angleSelector: some View {
        HStack {
            Text("Angle:")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Picker("Angle", selection: $selectedAngle) {
                ForEach(PhotoAngle.allCases, id: \.self) { angle in
                    Label(angle.description, systemImage: angle.icon)
                        .tag(angle)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedAngle) {
                // Reset dates when angle changes
                let availableDates = getAvailableDates(for: selectedAngle)
                if availableDates.count >= 2 {
                    afterDate = availableDates[0]
                    beforeDate = availableDates[1]
                } else if availableDates.count == 1 {
                    afterDate = availableDates[0]
                    beforeDate = nil
                } else {
                    afterDate = nil
                    beforeDate = nil
                }
            }
        }
    }
    
    /// Date selectors
    private var dateSelectors: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Before:")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Menu {
                    ForEach(getAvailableDates(for: selectedAngle), id: \.self) { date in
                        Button(formatDate(date)) {
                            beforeDate = date
                        }
                    }
                } label: {
                    Text(beforeDate != nil ? formatDate(beforeDate!) : "Select date")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(beforeDate != nil ? DesignSystem.Colors.primaryText : DesignSystem.Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(8)
                }
            }
            
            VStack(alignment: .leading) {
                Text("After:")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Menu {
                    ForEach(getAvailableDates(for: selectedAngle), id: \.self) { date in
                        Button(formatDate(date)) {
                            afterDate = date
                        }
                    }
                } label: {
                    Text(afterDate != nil ? formatDate(afterDate!) : "Select date")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(afterDate != nil ? DesignSystem.Colors.primaryText : DesignSystem.Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    /// Comparison mode selector
    private var comparisonModeSelector: some View {
        VStack(alignment: .leading) {
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
            Text("Select two dates with photos to compare")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(12)
    }
    
    /// Side by side view
    private func sideBySideView(beforeImage: UIImage, afterImage: UIImage) -> some View {
        HStack(spacing: 4) {
            VStack {
                Text("Before")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Image(uiImage: beforeImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
            }
            
            VStack {
                Text("After")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Image(uiImage: afterImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
            }
        }
        .frame(maxHeight: 400)
    }
    
    /// Slider view
    private func sliderView(beforeImage: UIImage, afterImage: UIImage) -> some View {
        VStack {
            ZStack(alignment: .leading) {
                Image(uiImage: beforeImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
                
                Image(uiImage: afterImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
                    .mask(
                        GeometryReader { geo in
                            Rectangle()
                                .frame(width: geo.size.width * sliderPosition)
                        }
                    )
                
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 2)
                        .position(x: geo.size.width * sliderPosition, y: geo.size.height / 2)
                }
            }
            .frame(maxHeight: 350)
            
            Slider(value: $sliderPosition)
                .padding(.horizontal)
                .padding(.top, 8)
            
            HStack {
                Text("Before")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Spacer()
                
                Text("After")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .padding(.horizontal)
        }
    }
    
    /// Overlay view
    private func overlayView(beforeImage: UIImage, afterImage: UIImage) -> some View {
        VStack {
            ZStack {
                Image(uiImage: beforeImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
                
                Image(uiImage: afterImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
                    .opacity(overlayOpacity)
            }
            .frame(maxHeight: 350)
            
            Slider(value: $overlayOpacity)
                .padding(.horizontal)
                .padding(.top, 8)
            
            HStack {
                Text("Before")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Spacer()
                
                Text("After")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get available dates for the selected angle
    private func getAvailableDates(for angle: PhotoAngle) -> [Date] {
        let dates = photos
            .filter { $0.angle == angle }
            .map { $0.date }
            .sorted(by: >)
        
        return Array(Set(dates.map { Calendar.current.startOfDay(for: $0) })).sorted(by: >)
    }
    
    /// Get photo for the selected date and angle
    private func getPhoto(for date: Date?, angle: PhotoAngle) -> ProgressPhoto? {
        guard let date = date else { return nil }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return photos.first { photo in
            photo.angle == angle &&
            photo.date >= startOfDay &&
            photo.date < endOfDay
        }
    }
    
    /// Format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func loadPhotos() {
        var descriptor = FetchDescriptor<ProgressPhoto>()
        
        if let challengeId = selectedChallenge?.id {
            descriptor.predicate = #Predicate<ProgressPhoto> { photo in
                photo.challenge?.id == challengeId
            }
            descriptor.sortBy = [SortDescriptor(\.date, order: .forward)]
        }
        
        do {
            fetchedPhotos = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching photos: \(error)")
        }
    }
    
    private func getPhoto(for date: Date) -> ProgressPhoto? {
        return fetchedPhotos.first { photo in
            Calendar.current.isDate(photo.date, inSameDayAs: date)
        }
    }
}

// MARK: - Preview

#Preview {
    PhotoComparisonView()
        .modelContainer(for: [User.self, Challenge.self, Task.self, DailyTask.self, ProgressPhoto.self], inMemory: true)
} 
