// AIMatrix Digital Rain View for iOS
// Copyright (c) 2025 AIMatrix - aimatrix.com

import SwiftUI
import UIKit

// MARK: - Drop Model
struct MatrixDrop {
    var x: Int
    var y: CGFloat
    var speed: CGFloat
    var length: Int
    var characters: [Character]
    
    static let characterSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ"
    
    init(column: Int, maxY: CGFloat) {
        self.x = column
        self.y = CGFloat.random(in: -20...0)
        self.speed = CGFloat.random(in: 0.3...1.5)
        self.length = Int.random(in: 5...35)
        self.characters = (0..<length).map { _ in
            MatrixDrop.characterSet.randomElement()!
        }
    }
    
    mutating func update(speedMultiplier: CGFloat, maxY: CGFloat, charHeight: CGFloat) {
        y += speed * speedMultiplier
        
        // Randomly change characters
        for i in 0..<characters.count {
            if Double.random(in: 0...1) < 0.05 {
                characters[i] = MatrixDrop.characterSet.randomElement()!
            }
        }
        
        // Reset if off screen
        if y - CGFloat(length) > maxY / charHeight {
            reset(maxY: maxY)
        }
    }
    
    mutating func reset(maxY: CGFloat) {
        y = CGFloat.random(in: -20...0)
        speed = CGFloat.random(in: 0.3...1.5)
        length = Int.random(in: 5...35)
        characters = (0..<length).map { _ in
            MatrixDrop.characterSet.randomElement()!
        }
    }
}

// MARK: - Configuration
enum ColorScheme: String, CaseIterable {
    case green = "Green"
    case blue = "Blue"
    case red = "Red"
    case yellow = "Yellow"
    case cyan = "Cyan"
    case purple = "Purple"
    case orange = "Orange"
    case pink = "Pink"
    
    var color: Color {
        switch self {
        case .green: return Color(red: 0, green: 1, blue: 0)
        case .blue: return Color(red: 0, green: 0.8, blue: 1)
        case .red: return Color(red: 1, green: 0, blue: 0)
        case .yellow: return Color(red: 1, green: 1, blue: 0)
        case .cyan: return Color(red: 0, green: 1, blue: 1)
        case .purple: return Color(red: 0.8, green: 0, blue: 1)
        case .orange: return Color(red: 1, green: 0.6, blue: 0)
        case .pink: return Color(red: 1, green: 0.41, blue: 0.71)
        }
    }
}

enum SpeedSetting: String, CaseIterable {
    case slow = "Slow"
    case normal = "Normal"
    case fast = "Fast"
    case veryFast = "Very Fast"
    
    var multiplier: CGFloat {
        switch self {
        case .slow: return 0.5
        case .normal: return 1.0
        case .fast: return 1.5
        case .veryFast: return 2.0
        }
    }
}

enum DensitySetting: String, CaseIterable {
    case sparse = "Sparse"
    case normal = "Normal"
    case dense = "Dense"
    
    var percentage: CGFloat {
        switch self {
        case .sparse: return 0.3
        case .normal: return 0.5
        case .dense: return 0.7
        }
    }
}

// MARK: - Matrix Rain View
struct MatrixRainView: View {
    @State private var drops: [MatrixDrop] = []
    @State private var timer: Timer?
    
    @AppStorage("colorScheme") private var colorScheme: String = ColorScheme.green.rawValue
    @AppStorage("speed") private var speed: String = SpeedSetting.normal.rawValue
    @AppStorage("density") private var density: String = DensitySetting.normal.rawValue
    @AppStorage("fontSize") private var fontSize: CGFloat = 16
    
    private let charWidth: CGFloat = 12
    private var charHeight: CGFloat { fontSize * 1.2 }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black
                    .ignoresSafeArea()
                
                // Matrix rain canvas
                Canvas { context, size in
                    drawDrops(context: context, size: size)
                }
                .ignoresSafeArea()
            }
            .onAppear {
                initializeDrops(size: geometry.size)
                startAnimation()
            }
            .onDisappear {
                stopAnimation()
            }
        }
    }
    
    private func initializeDrops(size: CGSize) {
        let columns = Int(size.width / charWidth)
        let densityValue = DensitySetting(rawValue: density)?.percentage ?? 0.5
        let numDrops = Int(CGFloat(columns) * densityValue)
        
        // Select random columns
        var availableColumns = Array(0..<columns)
        availableColumns.shuffle()
        
        drops = []
        for i in 0..<min(numDrops, availableColumns.count) {
            var drop = MatrixDrop(column: availableColumns[i], maxY: size.height)
            drop.y = CGFloat.random(in: -size.height/charHeight...size.height/charHeight)
            drops.append(drop)
        }
    }
    
    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { _ in
            updateDrops()
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateDrops() {
        let speedMultiplier = SpeedSetting(rawValue: speed)?.multiplier ?? 1.0
        let screenHeight = UIScreen.main.bounds.height
        
        for i in 0..<drops.count {
            drops[i].update(
                speedMultiplier: speedMultiplier,
                maxY: screenHeight,
                charHeight: charHeight
            )
        }
    }
    
    private func drawDrops(context: GraphicsContext, size: CGSize) {
        let selectedColor = ColorScheme(rawValue: colorScheme)?.color ?? Color.green
        
        for drop in drops {
            for (index, char) in drop.characters.enumerated() {
                let charY = drop.y - CGFloat(index)
                
                // Only draw if on screen
                if charY >= 0 && charY * charHeight < size.height {
                    // Calculate intensity
                    let intensity = max(0.1, 1.0 - CGFloat(index) / CGFloat(drop.length))
                    
                    // Head character is white
                    let color = index == 0 ? Color.white : selectedColor.opacity(intensity)
                    
                    // Draw character
                    let text = Text(String(char))
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(color)
                    
                    let position = CGPoint(
                        x: CGFloat(drop.x) * charWidth,
                        y: charY * charHeight
                    )
                    
                    context.draw(text, at: position)
                }
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @AppStorage("colorScheme") private var colorScheme: String = ColorScheme.green.rawValue
    @AppStorage("speed") private var speed: String = SpeedSetting.normal.rawValue
    @AppStorage("density") private var density: String = DensitySetting.normal.rawValue
    @AppStorage("fontSize") private var fontSize: CGFloat = 16
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Display Options") {
                    Picker("Color Scheme", selection: $colorScheme) {
                        ForEach(ColorScheme.allCases, id: \.rawValue) { scheme in
                            Text(scheme.rawValue).tag(scheme.rawValue)
                        }
                    }
                    
                    Picker("Speed", selection: $speed) {
                        ForEach(SpeedSetting.allCases, id: \.rawValue) { setting in
                            Text(setting.rawValue).tag(setting.rawValue)
                        }
                    }
                    
                    Picker("Density", selection: $density) {
                        ForEach(DensitySetting.allCases, id: \.rawValue) { setting in
                            Text(setting.rawValue).tag(setting.rawValue)
                        }
                    }
                    
                    HStack {
                        Text("Font Size")
                        Slider(value: $fontSize, in: 10...30, step: 2)
                        Text("\(Int(fontSize))")
                            .frame(width: 30)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("6.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Visit aimatrix.com", destination: URL(string: "https://aimatrix.com")!)
                }
            }
            .navigationTitle("AIMatrix Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Main App
struct ContentView: View {
    @State private var showSettings = false
    
    var body: some View {
        ZStack {
            MatrixRainView()
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .statusBar(hidden: true)
    }
}

// MARK: - App Entry Point
@main
struct AIMatrixApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}