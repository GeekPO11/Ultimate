import SwiftUI

/// A card component for displaying tasks with a modern glass morphism design
struct CTTaskCard: View {
    // MARK: - Properties
    var title: String
    var time: String
    var isCompleted: Bool
    var taskType: TaskType?
    var onToggle: () -> Void
    var onTap: () -> Void
    
    // MARK: - Body
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Task icon
                ZStack {
                    Circle()
                        .fill(taskType?.color.opacity(0.2) ?? Color.gray.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: taskType?.icon ?? "checkmark.circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(taskType?.color ?? Color.gray)
                        .symbolEffect(.pulse, options: .repeating, value: UUID())
                }
                
                // Task details
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(isCompleted ? DesignSystem.Colors.secondaryText : DesignSystem.Colors.primaryText)
                        .strikethrough(isCompleted)
                    
                    Text(time)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Completion toggle
                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .strokeBorder(isCompleted ? taskType?.color ?? Color.gray : Color.secondary.opacity(0.3), lineWidth: 2)
                            .frame(width: 28, height: 28)
                        
                        if isCompleted {
                            Circle()
                                .fill(taskType?.color ?? Color.gray)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.large)
                    .fill(Color.clear)
                    .appleMaterial(style: isCompleted ? .ultraThin : .thin)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.large)
                    .strokeBorder(isCompleted ? taskType?.color.opacity(0.4) ?? Color.gray.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .scaleEffect(isCompleted ? 0.98 : 1.0)
            .animation(.spring(response: 0.3), value: isCompleted)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        CTTaskCard(
            title: "Morning Workout",
            time: "7:00 AM",
            isCompleted: false,
            taskType: .workout,
            onToggle: {},
            onTap: {}
        )
        
        CTTaskCard(
            title: "Drink 1L of Water",
            time: "9:30 AM",
            isCompleted: true,
            taskType: .water,
            onToggle: {},
            onTap: {}
        )
        
        CTTaskCard(
            title: "Read for 30 minutes",
            time: "8:00 PM",
            isCompleted: false,
            taskType: .reading,
            onToggle: {},
            onTap: {}
        )
    }
    .padding()
    .background(PremiumBackground())
} 