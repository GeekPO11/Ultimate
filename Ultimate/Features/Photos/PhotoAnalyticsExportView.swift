import SwiftUI
import SwiftData
import UIKit
import Charts
import _Concurrency

/// View for exporting and sharing photo analytics data
struct PhotoAnalyticsExportView: View {
    let analytics: PhotoProgressAnalytics
    let challenge: Challenge?
    let frequencyData: [PhotoFrequencyData]
    let consistencyScore: Double
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExportFormat: ExportFormat = .pdf
    @State private var includePhotos = true
    @State private var includeCharts = true
    @State private var includeInsights = true
    @State private var isExporting = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    
    enum ExportFormat: String, CaseIterable, Identifiable {
        case pdf = "PDF Report"
        case images = "Image Collection"
        case json = "Data Export"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .images: return "photo.stack"
            case .json: return "doc.text"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.l) {
                        // Export format selection
                        formatSelectionCard
                        
                        // Export options
                        exportOptionsCard
                        
                        // Preview section
                        previewCard
                        
                        // Export button
                        exportButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Export Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let fileURL = exportedFileURL {
                    ShareSheet(activityItems: [fileURL])
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var formatSelectionCard: some View {
        CTCard(style: .glass) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text("Export Format")
                    .font(DesignSystem.Typography.headline)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(ExportFormat.allCases) { format in
                        Button {
                            selectedExportFormat = format
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: format.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedExportFormat == format ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.secondaryText)
                                
                                Text(format.rawValue)
                                    .font(DesignSystem.Typography.caption1)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(selectedExportFormat == format ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.primaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(selectedExportFormat == format ? DesignSystem.Colors.primaryAction.opacity(0.15) : Color.clear)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedExportFormat == format ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.dividers, lineWidth: selectedExportFormat == format ? 2 : 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
    }
    
    private var exportOptionsCard: some View {
        CTCard(style: .glass) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text("Export Options")
                    .font(DesignSystem.Typography.headline)
                
                VStack(spacing: DesignSystem.Spacing.s) {
                    ExportOptionRow(
                        title: "Include Photos",
                        description: "Add progress photos to the export",
                        isEnabled: $includePhotos,
                        icon: "photo"
                    )
                    
                    ExportOptionRow(
                        title: "Include Charts",
                        description: "Add analytics charts and graphs",
                        isEnabled: $includeCharts,
                        icon: "chart.bar"
                    )
                    
                    ExportOptionRow(
                        title: "Include Insights",
                        description: "Add AI-generated insights and recommendations",
                        isEnabled: $includeInsights,
                        icon: "lightbulb"
                    )
                }
            }
            .padding()
        }
    }
    
    private var previewCard: some View {
        CTCard(style: .glass) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text("Export Preview")
                    .font(DesignSystem.Typography.headline)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("File Type")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text(selectedExportFormat.rawValue)
                            .font(DesignSystem.Typography.body)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Estimated Size")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text(estimatedFileSize)
                            .font(DesignSystem.Typography.body)
                            .fontWeight(.medium)
                    }
                }
                
                Divider()
                
                Text("This export will include:")
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    if includePhotos {
                        PreviewItem(icon: "photo", text: "Progress photos comparison")
                    }
                    if includeCharts {
                        PreviewItem(icon: "chart.bar", text: "Analytics charts and statistics")
                    }
                    if includeInsights {
                        PreviewItem(icon: "lightbulb", text: "Progress insights and recommendations")
                    }
                    
                    PreviewItem(icon: "info.circle", text: "Challenge summary and metadata")
                }
            }
            .padding()
        }
    }
    
    private var exportButton: some View {
        Button {
            _Concurrency.Task {
                await performExport()
            }
        } label: {
            HStack {
                if isExporting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
                
                Text(isExporting ? "Exporting..." : "Export & Share")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(DesignSystem.Colors.primaryAction)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isExporting)
    }
    
    // MARK: - Helper Views
    
    struct ExportOptionRow: View {
        let title: String
        let description: String
        @Binding var isEnabled: Bool
        let icon: String
        
        var body: some View {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(DesignSystem.Colors.primaryAction)
                    .font(.system(size: 16))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                    
                    Text(description)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                Toggle("", isOn: $isEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primaryAction))
            }
            .padding(.vertical, 4)
        }
    }
    
    struct PreviewItem: View {
        let icon: String
        let text: String
        
        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(DesignSystem.Colors.primaryAction)
                    .font(.system(size: 14))
                    .frame(width: 16)
                
                Text(text)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var estimatedFileSize: String {
        var baseSize: Double = 0.5 // Base metadata size in MB
        
        if includePhotos {
            baseSize += 2.0 // Estimate 2MB per photo comparison
        }
        if includeCharts {
            baseSize += 0.5 // Chart images
        }
        if includeInsights {
            baseSize += 0.1 // Text content
        }
        
        switch selectedExportFormat {
        case .pdf:
            baseSize *= 1.2 // PDF overhead
        case .images:
            baseSize *= 0.8 // Compressed images
        case .json:
            baseSize *= 0.1 // Text is much smaller
        }
        
        if baseSize < 1.0 {
            return String(format: "%.1f KB", baseSize * 1024)
        } else {
            return String(format: "%.1f MB", baseSize)
        }
    }
    
    // MARK: - Export Logic
    
    private func performExport() async {
        isExporting = true
        
        do {
            let exportManager = AnalyticsExportManager()
            
            let exportData = AnalyticsExportData(
                analytics: analytics,
                challenge: challenge,
                frequencyData: frequencyData,
                consistencyScore: consistencyScore,
                includePhotos: includePhotos,
                includeCharts: includeCharts,
                includeInsights: includeInsights
            )
            
            let fileURL = try await exportManager.exportAnalytics(
                data: exportData,
                format: selectedExportFormat
            )
            
            await MainActor.run {
                exportedFileURL = fileURL
                showingShareSheet = true
                isExporting = false
            }
            
        } catch {
            Logger.error("Export failed: \(error.localizedDescription)", category: .photos)
            
            await MainActor.run {
                isExporting = false
                // Show error alert here
            }
        }
    }
}

// MARK: - Export Manager

class AnalyticsExportManager {
    func exportAnalytics(data: AnalyticsExportData, format: PhotoAnalyticsExportView.ExportFormat) async throws -> URL {
        switch format {
        case .pdf:
            return try await exportToPDF(data: data)
        case .images:
            return try await exportToImages(data: data)
        case .json:
            return try await exportToJSON(data: data)
        }
    }
    
    private func exportToPDF(data: AnalyticsExportData) async throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "ProgressAnalytics_\(Date().timeIntervalSince1970).pdf"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        // Create PDF content
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        
        let pdfData = pdfRenderer.pdfData { context in
            context.beginPage()
            
            // Add title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.label
            ]
            
            let title = "Progress Analytics Report"
            title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
            
            // Define info attributes for reuse
            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ]
            
            // Add challenge info
            if let challenge = data.challenge {
                let challengeInfo = "Challenge: \(challenge.name)\nDuration: \(challenge.durationInDays) days\nStatus: \(challenge.status.rawValue)"
                
                challengeInfo.draw(at: CGPoint(x: 50, y: 100), withAttributes: infoAttributes)
            }
            
            // Add consistency score
            let consistencyText = "Consistency Score: \(Int(data.consistencyScore * 100))%"
            let consistencyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.systemBlue
            ]
            
            consistencyText.draw(at: CGPoint(x: 50, y: 200), withAttributes: consistencyAttributes)
            
            // Add photos if included
            if data.includePhotos {
                // Draw comparison images
                let firstImage = data.analytics.firstImage
                let secondImage = data.analytics.secondImage
                
                firstImage.draw(in: CGRect(x: 50, y: 300, width: 150, height: 200))
                secondImage.draw(in: CGRect(x: 250, y: 300, width: 150, height: 200))
                
                let beforeLabel = "Before"
                let afterLabel = "After"
                
                beforeLabel.draw(at: CGPoint(x: 50, y: 520), withAttributes: infoAttributes)
                afterLabel.draw(at: CGPoint(x: 250, y: 520), withAttributes: infoAttributes)
            }
        }
        
        try pdfData.write(to: fileURL)
        return fileURL
    }
    
    private func exportToImages(data: AnalyticsExportData) async throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderName = "ProgressImages_\(Date().timeIntervalSince1970)"
        let folderURL = documentsPath.appendingPathComponent(folderName)
        
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        
        if data.includePhotos {
            // Save comparison images
            if let firstImageData = data.analytics.firstImage.pngData() {
                let firstImageURL = folderURL.appendingPathComponent("before.png")
                try firstImageData.write(to: firstImageURL)
            }
            
            if let secondImageData = data.analytics.secondImage.pngData() {
                let secondImageURL = folderURL.appendingPathComponent("after.png")
                try secondImageData.write(to: secondImageURL)
            }
        }
        
        // Create a zip file of the folder
        let zipURL = documentsPath.appendingPathComponent("\(folderName).zip")
        try await createZipFile(from: folderURL, to: zipURL)
        
        return zipURL
    }
    
    private func exportToJSON(data: AnalyticsExportData) async throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "ProgressAnalytics_\(Date().timeIntervalSince1970).json"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        let exportDict: [String: Any] = [
            "challenge": [
                "name": data.challenge?.name ?? "Unknown",
                "duration": data.challenge?.durationInDays ?? 0,
                "status": data.challenge?.status.rawValue ?? "unknown"
            ],
            "analytics": [
                "timeSpan": data.analytics.daysBetween,
                "consistencyScore": data.consistencyScore,
                "firstPhotoDate": data.analytics.firstPhoto.date.timeIntervalSince1970,
                "secondPhotoDate": data.analytics.secondPhoto.date.timeIntervalSince1970
            ],
            "frequencyData": data.frequencyData.map { freq in
                [
                    "date": freq.date.timeIntervalSince1970,
                    "photoCount": freq.photoCount
                ]
            },
            "exportDate": Date().timeIntervalSince1970,
            "version": "2.0.0"
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted)
        try jsonData.write(to: fileURL)
        
        return fileURL
    }
    
    private func createZipFile(from folderURL: URL, to zipURL: URL) async throws {
        // Simplified zip creation - in a real app, you might use a proper zip library
        // For now, just return the folder URL
        try FileManager.default.moveItem(at: folderURL, to: zipURL)
    }
}

// MARK: - Data Models

struct AnalyticsExportData {
    let analytics: PhotoProgressAnalytics
    let challenge: Challenge?
    let frequencyData: [PhotoFrequencyData]
    let consistencyScore: Double
    let includePhotos: Bool
    let includeCharts: Bool
    let includeInsights: Bool
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    let sampleAnalytics = PhotoProgressAnalytics(
        firstPhoto: ProgressPhoto(challenge: nil, date: Date(), angle: .front, fileURL: URL(fileURLWithPath: ""), isBlurred: false),
        secondPhoto: ProgressPhoto(challenge: nil, date: Date(), angle: .front, fileURL: URL(fileURLWithPath: ""), isBlurred: false),
        firstImage: UIImage(),
        secondImage: UIImage(),
        daysBetween: 30
    )
    
    PhotoAnalyticsExportView(
        analytics: sampleAnalytics,
        challenge: nil,
        frequencyData: [],
        consistencyScore: 0.85
    )
} 