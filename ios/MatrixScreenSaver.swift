import SwiftUI
import Foundation

struct MatrixScreenSaver: View {
    @State private var rainDrops: [Int] = []
    @State private var animationTimer: Timer?
    @State private var selectedColor: Color = .green
    @State private var fontSize: CGFloat = 16
    @State private var speed: Double = 0.1
    @State private var columns: Int = 0
    
    let colors: [String: Color] = [
        "Green": .green,
        "Blue": .blue,
        "Red": .red,
        "Yellow": .yellow,
        "Cyan": .cyan,
        "Purple": .purple,
        "White": .white
    ]
    
    let greekCharacters = ["Α", "Β", "Γ", "Δ", "Ε", "Ζ", "Η", "Θ", "Ι", "Κ", "Λ", "Μ", "Ν", "Ξ", "Ο", "Π", "Ρ", "Σ", "Τ", "Υ", "Φ", "Χ", "Ψ", "Ω", "α", "β", "γ", "δ", "ε", "ζ", "η", "θ", "ι", "κ", "λ", "μ", "ν", "ξ", "ο", "π", "ρ", "σ", "τ", "υ", "φ", "χ", "ψ", "ω"]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background with trail effect
                Rectangle()
                    .fill(Color.black.opacity(0.05))
                    .ignoresSafeArea()
                
                // Matrix rain columns
                ForEach(0..<rainDrops.count, id: \.self) { i in
                    if i < rainDrops.count {
                        Text(greekCharacters.randomElement() ?? "Α")
                            .font(.system(size: fontSize, family: .monospaced))
                            .foregroundColor(selectedColor)
                            .position(
                                x: CGFloat(i) * fontSize + fontSize/2,
                                y: geometry.size.height - (CGFloat(rainDrops[i]) * fontSize)
                            )
                    }
                }
                
                // Configuration panel
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Color:")
                                    .foregroundColor(.white)
                                Picker("Color", selection: $selectedColor) {
                                    ForEach(colors.keys.sorted(), id: \.self) { key in
                                        Text(key).tag(colors[key]!)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            HStack {
                                Text("Size:")
                                    .foregroundColor(.white)
                                Slider(value: $fontSize, in: 10...30, step: 2)
                                    .frame(width: 100)
                                Text("\(Int(fontSize))px")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                            
                            HStack {
                                Text("Speed:")
                                    .foregroundColor(.white)
                                Slider(value: $speed, in: 0.05...0.3, step: 0.025)
                                    .frame(width: 100)
                                Text("\(String(format: "%.2fx", 1.0/speed))")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    Spacer()
                }
            }
        }
        .onAppear {
            initializeColumns(width: UIScreen.main.bounds.width)
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
        .onChange(of: fontSize) { _ in
            initializeColumns(width: UIScreen.main.bounds.width)
        }
    }
    
    private func initializeColumns(width: CGFloat) {
        columns = Int(width / fontSize)
        rainDrops = Array(0..<columns).map { _ in 1 }
    }
    
    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { _ in
            updateDrops()
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func updateDrops() {
        let screenHeight = UIScreen.main.bounds.height
        
        // Update each column's drop position (like original algorithm)
        for i in 0..<rainDrops.count {
            // Reset drop when it reaches bottom with probability (like original)
            if CGFloat(rainDrops[i]) * fontSize > screenHeight && Double.random(in: 0...1) > 0.975 {
                rainDrops[i] = 0
            }
            rainDrops[i] += 1
        }
    }
}

#Preview {
    MatrixScreenSaver()
}