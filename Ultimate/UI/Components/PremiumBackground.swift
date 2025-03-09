import SwiftUI

/// Animated background element
struct AnimatedBackgroundElement: View {
    let size: CGFloat
    let position: CGPoint
    let hue: Double
    let delay: Double
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    @State private var rotation: Double = 0
    
    var body: some View {
        Circle()
            .fill(
                .linearGradient(
                    colors: [
                        Color(hue: hue, saturation: 0.6, brightness: 0.9),
                        Color(hue: hue + 0.1, saturation: 0.7, brightness: 0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .position(position)
            .opacity(opacity)
            .scaleEffect(scale)
            .blur(radius: 30)
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(delay)) {
                    scale = 1.2
                    opacity = 0.5
                }
                
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false).delay(delay)) {
                    rotation = 360
                }
            }
            .rotationEffect(.degrees(rotation))
    }
}

/// Premium animated background
struct PremiumBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base color - adapts to color scheme
                Color(colorScheme == .dark ? .black : .white)
                    .ignoresSafeArea()
                
                // Animated elements
                AnimatedBackgroundElement(
                    size: 300,
                    position: CGPoint(x: geometry.size.width * 0.2, y: geometry.size.height * 0.2),
                    hue: 0.6, // Blue
                    delay: 0
                )
                
                AnimatedBackgroundElement(
                    size: 250,
                    position: CGPoint(x: geometry.size.width * 0.8, y: geometry.size.height * 0.3),
                    hue: 0.3, // Green
                    delay: 0.5
                )
                
                AnimatedBackgroundElement(
                    size: 200,
                    position: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.7),
                    hue: 0.9, // Pink
                    delay: 1.0
                )
                
                // Subtle overlay - adapts to color scheme
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    ZStack {
        PremiumBackground()
        
        VStack {
            Text("Premium Background")
                .font(.title)
                .fontWeight(.bold)
            
            Text("With animated elements")
                .font(.subheadline)
        }
        .padding()
        .appleMaterial(style: .regular)
    }
} 