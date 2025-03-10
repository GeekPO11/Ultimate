import SwiftUI
import Charts

/// A component for visualizing challenge progress with various chart types
struct CTProgressChart: View {
    // MARK: - Properties
    let data: [ProgressDataPoint]
    let chartType: ChartType
    let title: String
    let subtitle: String?
    let showLegend: Bool
    
    // Additional properties for enhanced visuals
    private let glassEffect = true
    private let animationDuration: Double = 0.8
    private let gradientColors: [Color] = [
        DesignSystem.Colors.primaryAction,
        DesignSystem.Colors.secondaryAction
    ]
    
    // Custom colors for pie chart
    private let pieChartColors: [Color] = [
        DesignSystem.Colors.primaryAction,
        DesignSystem.Colors.neonBlue,
        DesignSystem.Colors.neonGreen,
        DesignSystem.Colors.neonOrange,
        DesignSystem.Colors.neonPurple,
        DesignSystem.Colors.accent,
        Color(hex: "00C7BE"), // Teal
        Color(hex: "8A2BE2"), // BlueViolet
        Color(hex: "FF6347"), // Tomato
        Color(hex: "20B2AA")  // LightSeaGreen
    ]
    
    // MARK: - Initialization
    init(
        data: [ProgressDataPoint],
        chartType: ChartType = .bar,
        title: String,
        subtitle: String? = nil,
        showLegend: Bool = true
    ) {
        self.data = data
        self.chartType = chartType
        self.title = title
        self.subtitle = subtitle
        self.showLegend = showLegend
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title section
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .padding(.horizontal, 16)
            
            // Chart content
            chartContent
                .frame(height: 220)
                .padding(.horizontal, 8)
            
            // Legend
            if showLegend {
                legendView
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 16)
        .background {
            if glassEffect {
                RoundedRectangle(cornerRadius: 16)
                    .fill(DesignSystem.Colors.cardBackground.opacity(0.7))
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Material.ultraThinMaterial)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(LinearGradient(
                                colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(DesignSystem.Colors.cardBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Chart Content
    @ViewBuilder
    private var chartContent: some View {
        switch chartType {
        case .bar:
            enhancedBarChart
        case .line:
            enhancedLineChart
        case .area:
            enhancedAreaChart
        case .pie:
            enhancedPieChart
        case .progress:
            enhancedProgressChart
        }
    }
    
    // Enhanced chart implementations with futuristic design
    private var enhancedBarChart: some View {
        Chart {
            ForEach(data) { item in
                BarMark(
                    x: .value("Date", item.formattedDate),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                    .foregroundStyle(Color.gray.opacity(0.3))
                AxisValueLabel()
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
        }
        .transition(.opacity.animation(.easeInOut(duration: animationDuration)))
    }
    
    private var enhancedLineChart: some View {
        Chart {
            ForEach(data) { item in
                LineMark(
                    x: .value("Date", item.formattedDate),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                
                PointMark(
                    x: .value("Date", item.formattedDate),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(Color.white)
                .shadow(color: gradientColors[0].opacity(0.5), radius: 3, x: 0, y: 0)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                    .foregroundStyle(Color.gray.opacity(0.3))
                AxisValueLabel()
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
        }
        .transition(.opacity.animation(.easeInOut(duration: animationDuration)))
    }
    
    private var enhancedAreaChart: some View {
        Chart {
            ForEach(data) { item in
                AreaMark(
                    x: .value("Date", item.formattedDate),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [gradientColors[0].opacity(0.7), gradientColors[1].opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                LineMark(
                    x: .value("Date", item.formattedDate),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [5, 5]))
                    .foregroundStyle(Color.gray.opacity(0.3))
                AxisValueLabel()
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
        }
        .transition(.opacity.animation(.easeInOut(duration: animationDuration)))
    }
    
    private var enhancedPieChart: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                SectorMark(
                    angle: .value("Value", item.value),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .foregroundStyle(pieChartColors[index % pieChartColors.count])
                .annotation(position: .overlay) {
                    Text("\(Int(item.value))")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private var enhancedProgressChart: some View {
        let totalValue = data.reduce(0) { $0 + $1.value }
        let targetValue = data.first?.targetValue ?? 100
        let progress = min(totalValue / targetValue, 1.0)
        
        return VStack {
            ZStack {
                // Background circle
                Circle()
                    .stroke(DesignSystem.Colors.dividers, lineWidth: 20)
                    .opacity(0.3)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                DesignSystem.Colors.primaryAction,
                                DesignSystem.Colors.secondaryAction
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progress)
                
                // Center text
                VStack(spacing: DesignSystem.Spacing.xxs) {
                    Text("\(Int(progress * 100))%")
                        .font(DesignSystem.Typography.title1)
                        .fontWeight(.bold)
                    
                    Text("\(Int(totalValue))/\(Int(targetValue))")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .padding(DesignSystem.Spacing.m)
        }
    }
    
    // MARK: - Legend View
    
    private var legendView: some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            if chartType == .pie {
                // For pie charts, show category-based legend
                let categories = Array(Set(data.compactMap { $0.category ?? "Unknown" }))
                if !categories.isEmpty {
                    ForEach(categories, id: \.self) { category in
                        legendItem(
                            color: categoryColor(for: category, index: categories.firstIndex(of: category) ?? 0),
                            label: category
                        )
                    }
                } else {
                    legendItem(
                        color: DesignSystem.Colors.primaryAction,
                        label: "No categories"
                    )
                }
            } else {
                // For other charts, show value-based legend
                legendItem(
                    color: DesignSystem.Colors.primaryAction,
                    label: "Value"
                )
                
                // Only show target if any data point has a non-zero target value
                if data.contains(where: { $0.targetValue > 0 && $0.targetValue != $0.value }) {
                    legendItem(
                        color: DesignSystem.Colors.accent,
                        label: "Target"
                    )
                }
            }
        }
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
                .cornerRadius(2)
            
            Text(label)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
    }
    
    private func categoryColor(for category: String, index: Int = 0) -> Color {
        // Use the index to get a color from the pieChartColors array
        return pieChartColors[index % pieChartColors.count]
    }
}

// MARK: - Supporting Types

/// Chart types supported by CTProgressChart
enum ChartType {
    case bar
    case line
    case area
    case pie
    case progress
}

/// Data point for progress charts
struct ProgressDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let targetValue: Double
    let category: String?
    
    init(date: Date, value: Double, targetValue: Double = 0, category: String? = nil) {
        self.date = date
        self.value = value
        self.targetValue = targetValue
        self.category = category
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Bar chart
            CTProgressChart(
                data: sampleProgressData(),
                chartType: .bar,
                title: "Daily Task Completion",
                subtitle: "Last 7 days"
            )
            
            // Line chart
            CTProgressChart(
                data: sampleProgressData(),
                chartType: .line,
                title: "Progress Trend",
                subtitle: "Tasks completed over time"
            )
            
            // Area chart
            CTProgressChart(
                data: sampleProgressData(),
                chartType: .area,
                title: "Cumulative Progress",
                subtitle: "Building momentum"
            )
            
            // Pie chart
            CTProgressChart(
                data: sampleCategoryData(),
                chartType: .pie,
                title: "Task Distribution",
                subtitle: "By category"
            )
            
            // Progress chart
            CTProgressChart(
                data: [ProgressDataPoint(date: Date(), value: 75, targetValue: 100)],
                chartType: .progress,
                title: "Overall Completion",
                subtitle: "75% complete"
            )
        }
        .padding()
    }
    .background(DesignSystem.Colors.background)
}

// Sample data for preview
private func sampleProgressData() -> [ProgressDataPoint] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    
    return (0..<7).map { day in
        let date = calendar.date(byAdding: .day, value: -day, to: today)!
        let value = Double.random(in: 3...8)
        return ProgressDataPoint(date: date, value: value, targetValue: 8)
    }.reversed()
}

private func sampleCategoryData() -> [ProgressDataPoint] {
    [
        ProgressDataPoint(date: Date(), value: 45, category: "Workout"),
        ProgressDataPoint(date: Date(), value: 30, category: "Nutrition"),
        ProgressDataPoint(date: Date(), value: 15, category: "Water"),
        ProgressDataPoint(date: Date(), value: 10, category: "Reading")
    ]
} 