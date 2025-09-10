#import <ScreenSaver/ScreenSaver.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface MetalMatrixView : ScreenSaverView <MTKViewDelegate> {
    MTKView *metalView;
    id<MTLDevice> device;
    id<MTLCommandQueue> commandQueue;
    id<MTLRenderPipelineState> pipelineState;
    id<MTLBuffer> vertexBuffer;
    float time;
}
@end

@implementation MetalMatrixView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setupMetal];
        [self setAnimationTimeInterval:1.0/60.0];
    }
    return self;
}

- (void)setupMetal {
    // Create Metal device
    device = MTLCreateSystemDefaultDevice();
    if (!device) {
        NSLog(@"Metal is not supported on this device");
        return;
    }
    
    // Create MTKView
    metalView = [[MTKView alloc] initWithFrame:self.bounds device:device];
    metalView.delegate = self;
    metalView.clearColor = MTLClearColorMake(0, 0, 0, 1); // Black background
    metalView.preferredFramesPerSecond = 60;
    metalView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addSubview:metalView];
    
    // Create command queue
    commandQueue = [device newCommandQueue];
    
    // Create simple vertex shader and fragment shader
    NSString *shaderSource = @""
        "#include <metal_stdlib>\n"
        "using namespace metal;\n"
        "\n"
        "struct Vertex {\n"
        "    float4 position [[position]];\n"
        "    float4 color;\n"
        "};\n"
        "\n"
        "vertex Vertex vertex_main(uint vid [[vertex_id]],\n"
        "                          constant float &time [[buffer(0)]]) {\n"
        "    Vertex out;\n"
        "    float angle = time + float(vid) * 2.0 * 3.14159 / 3.0;\n"
        "    out.position = float4(cos(angle) * 0.5, sin(angle) * 0.5, 0, 1);\n"
        "    out.color = float4(0, 1, 0, 1);\n"
        "    return out;\n"
        "}\n"
        "\n"
        "fragment float4 fragment_main(Vertex in [[stage_in]]) {\n"
        "    return in.color;\n"
        "}\n";
    
    NSError *error = nil;
    id<MTLLibrary> library = [device newLibraryWithSource:shaderSource options:nil error:&error];
    if (!library) {
        NSLog(@"Failed to create shader library: %@", error);
        return;
    }
    
    id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertex_main"];
    id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragment_main"];
    
    // Create pipeline state
    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.vertexFunction = vertexFunction;
    pipelineDescriptor.fragmentFunction = fragmentFunction;
    pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat;
    
    pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if (!pipelineState) {
        NSLog(@"Failed to create pipeline state: %@", error);
        return;
    }
    
    // Create vertex buffer for time uniform
    vertexBuffer = [device newBufferWithLength:sizeof(float) options:MTLResourceStorageModeShared];
    time = 0;
}

- (void)drawRect:(NSRect)rect {
    // Metal rendering happens in mtkView:drawableSizeWillChange: and drawInMTKView:
}

- (void)animateOneFrame {
    time += 0.016; // ~60 FPS
    [metalView setNeedsDisplay:YES];
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    // Handle view resize if needed
}

- (void)drawInMTKView:(MTKView *)view {
    if (!device || !commandQueue || !pipelineState) {
        return;
    }
    
    // Update time buffer
    float *timePtr = (float *)[vertexBuffer contents];
    *timePtr = time;
    
    // Get current drawable
    id<CAMetalDrawable> drawable = view.currentDrawable;
    if (!drawable) {
        return;
    }
    
    // Create command buffer
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    
    // Create render pass descriptor
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (!renderPassDescriptor) {
        return;
    }
    
    // Create render encoder
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [renderEncoder setRenderPipelineState:pipelineState];
    [renderEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
    
    // Draw a simple triangle
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    
    [renderEncoder endEncoding];
    
    // Present and commit
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

@end