import ScreenSaver
import Metal
import MetalKit
import simd

class AIMatrixMetalView: ScreenSaverView {
    
    private var metalDevice: MTLDevice!
    private var metalLayer: CAMetalLayer!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var timer: Timer?
    
    // Matrix rain parameters
    private var drops: [MatrixDrop] = []
    private let maxDrops = 10  // Only 10 drops for ultra smooth
    
    struct MatrixDrop {
        var x: Float
        var y: Float
        var speed: Float
        var length: Int
        var characters: [Character]
        var brightness: [Float]
    }
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setupMetal()
        setupDrops()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMetal()
        setupDrops()
    }
    
    private func setupMetal() {
        // Get the default GPU
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported")
            return
        }
        metalDevice = device
        
        // Create Metal layer
        metalLayer = CAMetalLayer()
        metalLayer.device = metalDevice
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = self.bounds
        
        // Enable vsync for smooth animation
        metalLayer.displaySyncEnabled = true
        metalLayer.maximumDrawableCount = 3  // Triple buffering
        
        self.layer = metalLayer
        self.wantsLayer = true
        
        // Create command queue
        commandQueue = device.makeCommandQueue()
        
        // Setup render pipeline
        setupRenderPipeline()
    }
    
    private func setupRenderPipeline() {
        let library = metalDevice.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
        
        // Enable blending for transparency
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            pipelineState = try metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state: \(error)")
        }
    }
    
    private func setupDrops() {
        drops.removeAll()
        let spacing = Float(bounds.width) / Float(maxDrops)
        
        for i in 0..<maxDrops {
            var drop = MatrixDrop(
                x: Float(i) * spacing + spacing/2,
                y: Float.random(in: -500...0),
                speed: Float.random(in: 1...3),
                length: Int.random(in: 10...20),
                characters: [],
                brightness: []
            )
            
            // Fill with random characters
            for j in 0..<drop.length {
                drop.characters.append(Character.random())
                // Brightness: bright at bottom (end), dim at top (start)
                drop.brightness.append(Float(j) / Float(drop.length))
            }
            
            drops.append(drop)
        }
    }
    
    override func startAnimation() {
        super.startAnimation()
        
        // Use DisplayLink for perfect vsync
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            self.renderFrame()
        }
    }
    
    override func stopAnimation() {
        super.stopAnimation()
        timer?.invalidate()
        timer = nil
    }
    
    private func renderFrame() {
        guard let drawable = metalLayer.nextDrawable(),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = createRenderPassDescriptor(for: drawable) else {
            return
        }
        
        // Update drop positions
        updateDrops()
        
        // Render using GPU
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Draw each drop using GPU
        for drop in drops {
            drawDrop(drop, with: renderEncoder)
        }
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func updateDrops() {
        for i in 0..<drops.count {
            drops[i].y += drops[i].speed
            
            // Reset if off screen
            if drops[i].y > Float(bounds.height) + 500 {
                drops[i].y = Float.random(in: -500...0)
                drops[i].speed = Float.random(in: 1...3)
            }
        }
    }
    
    private func drawDrop(_ drop: MatrixDrop, with encoder: MTLRenderCommandEncoder) {
        // This would draw each character of the drop using GPU shaders
        // The actual vertex and fragment shaders would handle the rendering
    }
    
    private func createRenderPassDescriptor(for drawable: CAMetalDrawable) -> MTLRenderPassDescriptor {
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = drawable.texture
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        descriptor.colorAttachments[0].storeAction = .store
        return descriptor
    }
}

extension Character {
    static func random() -> Character {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()αβγδεζηθικλμνξοπρστυφχψω"
        return characters.randomElement()!
    }
}