#import <ScreenSaver/ScreenSaver.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>

// Vertex structure for GPU rendering
typedef struct {
    simd_float2 position;
    simd_float2 texCoord;
    float brightness;
    float charIndex;
} MatrixVertex;

// Matrix drop structure for efficient GPU updates
typedef struct {
    simd_float2 position;
    float speed;
    float length;
    float startTime;
    float padding; // Align to 16 bytes
} MatrixDrop;

@interface AIMatrixGPUView : ScreenSaverView <MTKViewDelegate> {
    // Metal rendering objects
    MTKView *metalView;
    id<MTLDevice> device;
    id<MTLCommandQueue> commandQueue;
    id<MTLRenderPipelineState> textPipelineState;
    id<MTLComputePipelineState> updatePipelineState;
    
    // GPU buffers for ultra-smooth performance
    id<MTLBuffer> vertexBuffer;
    id<MTLBuffer> dropBuffer;
    id<MTLBuffer> uniformBuffer;
    
    // Font texture atlas for GPU text rendering
    id<MTLTexture> fontTexture;
    NSMutableDictionary *charMap;
    
    // Animation timing
    CFTimeInterval lastTime;
    float currentTime;
    
    // Matrix parameters
    int numColumns;
    int maxDrops;
    NSString *matrixText;
}
@end

@implementation AIMatrixGPUView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        matrixText = @"aimatrix.com - the agentic twin platform.... ";
        [self setupMetal];
        [self createFontTexture];
        [self setupMatrixData];
        [self setAnimationTimeInterval:1.0/120.0]; // High frequency for ultra-smooth updates
        lastTime = CACurrentMediaTime();
        currentTime = 0.0f;
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
    
    // Create MTKView for GPU rendering
    metalView = [[MTKView alloc] initWithFrame:self.bounds device:device];
    metalView.delegate = self;
    metalView.clearColor = MTLClearColorMake(0, 0, 0, 1); // Black background
    metalView.preferredFramesPerSecond = 60; // Lock to 60 FPS
    metalView.presentsWithTransaction = NO; // Reduce latency
    metalView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addSubview:metalView];
    
    // Create command queue
    commandQueue = [device newCommandQueue];
    commandQueue.label = @"AIMatrix Command Queue";
    
    [self createShaders];
}

- (void)createShaders {
    NSError *error = nil;
    
    // Enhanced Metal shaders for text rendering
    NSString *shaderSource = @""
        "#include <metal_stdlib>\n"
        "#include <simd/simd.h>\n"
        "using namespace metal;\n"
        "\n"
        "struct Vertex {\n"
        "    float2 position;\n"
        "    float2 texCoord;\n"
        "    float brightness;\n"
        "    float charIndex;\n"
        "};\n"
        "\n"
        "struct VertexOut {\n"
        "    float4 position [[position]];\n"
        "    float2 texCoord;\n"
        "    float brightness;\n"
        "};\n"
        "\n"
        "struct Uniforms {\n"
        "    float4x4 projectionMatrix;\n"
        "    float time;\n"
        "    float2 screenSize;\n"
        "};\n"
        "\n"
        "// Vertex shader - transforms positions for GPU\n"
        "vertex VertexOut vertex_main(device const Vertex* vertices [[buffer(0)]],\n"
        "                             constant Uniforms& uniforms [[buffer(1)]],\n"
        "                             uint vid [[vertex_id]]) {\n"
        "    VertexOut out;\n"
        "    \n"
        "    Vertex vert = vertices[vid];\n"
        "    \n"
        "    // Convert from screen coordinates to NDC\n"
        "    float2 ndc;\n"
        "    ndc.x = (vert.position.x / uniforms.screenSize.x) * 2.0 - 1.0;\n"
        "    ndc.y = 1.0 - (vert.position.y / uniforms.screenSize.y) * 2.0;\n"
        "    \n"
        "    out.position = float4(ndc, 0.0, 1.0);\n"
        "    out.texCoord = vert.texCoord;\n"
        "    out.brightness = vert.brightness;\n"
        "    \n"
        "    return out;\n"
        "}\n"
        "\n"
        "// Fragment shader - renders text with Matrix green glow\n"
        "fragment float4 fragment_main(VertexOut in [[stage_in]],\n"
        "                              texture2d<float> fontTexture [[texture(0)]]) {\n"
        "    constexpr sampler textureSampler(mag_filter::linear,\n"
        "                                     min_filter::linear,\n"
        "                                     address::clamp_to_edge);\n"
        "    \n"
        "    // Sample the font texture\n"
        "    float4 textColor = fontTexture.sample(textureSampler, in.texCoord);\n"
        "    \n"
        "    // Matrix green color with brightness modulation\n"
        "    float3 greenColor;\n"
        "    if (in.brightness > 0.9) {\n"
        "        // Head of the trail - bright white-green\n"
        "        greenColor = float3(0.9, 1.0, 0.9);\n"
        "    } else if (in.brightness > 0.7) {\n"
        "        // Bright green\n"
        "        greenColor = float3(0.0, 1.0, 0.2) * in.brightness;\n"
        "    } else {\n"
        "        // Fading trail\n"
        "        greenColor = float3(0.0, 0.8, 0.0) * in.brightness;\n"
        "    }\n"
        "    \n"
        "    // Add subtle glow effect\n"
        "    float glow = smoothstep(0.3, 1.0, in.brightness);\n"
        "    greenColor += float3(0.0, 0.3, 0.0) * glow;\n"
        "    \n"
        "    // Apply alpha for smooth blending\n"
        "    float alpha = textColor.a * in.brightness;\n"
        "    \n"
        "    return float4(greenColor, alpha);\n"
        "}\n"
        "\n"
        "// Compute shader for ultra-smooth drop updates\n"
        "kernel void update_drops(device MatrixDrop* drops [[buffer(0)]],\n"
        "                        constant float& deltaTime [[buffer(1)]],\n"
        "                        constant float& screenHeight [[buffer(2)]],\n"
        "                        constant float& currentTime [[buffer(3)]],\n"
        "                        uint id [[thread_position_in_grid]]) {\n"
        "    MatrixDrop drop = drops[id];\n"
        "    \n"
        "    // Update position with smooth interpolation\n"
        "    drop.position.y += drop.speed * deltaTime * 60.0;\n"
        "    \n"
        "    // Reset when off screen\n"
        "    if (drop.position.y > screenHeight + 200.0) {\n"
        "        drop.position.y = -200.0 - (float(id % 500));\n"
        "        drop.startTime = currentTime;\n"
        "        // Randomize speed for variation\n"
        "        drop.speed = 80.0 + sin(currentTime + float(id)) * 40.0;\n"
        "    }\n"
        "    \n"
        "    drops[id] = drop;\n"
        "}\n";
    
    // Create shader library
    id<MTLLibrary> library = [device newLibraryWithSource:shaderSource options:nil error:&error];
    if (!library) {
        NSLog(@"Failed to create shader library: %@", error);
        return;
    }
    
    // Create render pipeline for text
    id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertex_main"];
    id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragment_main"];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.label = @"Text Rendering Pipeline";
    pipelineDescriptor.vertexFunction = vertexFunction;
    pipelineDescriptor.fragmentFunction = fragmentFunction;
    pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat;
    
    // Enable alpha blending for smooth trails
    pipelineDescriptor.colorAttachments[0].blendingEnabled = YES;
    pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    
    textPipelineState = [device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if (!textPipelineState) {
        NSLog(@"Failed to create text pipeline state: %@", error);
        return;
    }
    
    // Create compute pipeline for drop updates
    id<MTLFunction> updateFunction = [library newFunctionWithName:@"update_drops"];
    updatePipelineState = [device newComputePipelineStateWithFunction:updateFunction error:&error];
    if (!updatePipelineState) {
        NSLog(@"Failed to create compute pipeline state: %@", error);
    }
}

- (void)createFontTexture {
    // Create font texture atlas for GPU text rendering
    NSFont *font = [NSFont fontWithName:@"Menlo" size:16];
    if (!font) {
        font = [NSFont monospacedSystemFontOfSize:16 weight:NSFontWeightMedium];
    }
    
    // Calculate texture size for all characters
    int textureSize = 512; // 512x512 texture atlas
    int charSize = 32; // Each character is 32x32 pixels
    int charsPerRow = textureSize / charSize;
    
    // Create bitmap context for font rendering
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(NULL, textureSize, textureSize, 8, textureSize, colorSpace, kCGImageAlphaNone);
    CGColorSpaceRelease(colorSpace);
    
    // Set font properties
    CGContextSetTextDrawingMode(context, kCGTextFill);
    CGContextSetGrayFillColor(context, 1.0, 1.0); // White text
    
    // Render each character to texture atlas
    charMap = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < matrixText.length; i++) {
        unichar c = [matrixText characterAtIndex:i];
        NSString *charString = [NSString stringWithCharacters:&c length:1];
        
        int x = (i % charsPerRow) * charSize;
        int y = (i / charsPerRow) * charSize;
        
        // Store texture coordinates
        CGRect texRect = CGRectMake((float)x / textureSize, (float)y / textureSize, 
                                   (float)charSize / textureSize, (float)charSize / textureSize);
        charMap[charString] = [NSValue valueWithRect:texRect];
        
        // Render character to texture
        CFStringRef string = (__bridge CFStringRef)charString;
        CFAttributedStringRef attrString = CFAttributedStringCreate(NULL, string, NULL);
        CTLineRef line = CTLineCreateWithAttributedString(attrString);
        
        CGContextSetTextPosition(context, x + 4, y + 8); // Add padding
        CTLineDraw(line, context);
        
        CFRelease(line);
        CFRelease(attrString);
    }
    
    // Create Metal texture from bitmap
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm
                                                                                                  width:textureSize
                                                                                                 height:textureSize
                                                                                              mipmapped:NO];
    textureDescriptor.usage = MTLTextureUsageShaderRead;
    fontTexture = [device newTextureWithDescriptor:textureDescriptor];
    
    // Copy image data to texture
    size_t bytesPerRow = CGImageGetBytesPerRow(image);
    CFDataRef dataRef = CGDataProviderCopyData(CGImageGetDataProvider(image));
    const void *data = CFDataGetBytePtr(dataRef);
    
    [fontTexture replaceRegion:MTLRegionMake2D(0, 0, textureSize, textureSize)
                   mipmapLevel:0
                     withBytes:data
                   bytesPerRow:bytesPerRow];
    
    CFRelease(dataRef);
    CGImageRelease(image);
}

- (void)setupMatrixData {
    // Calculate matrix dimensions
    numColumns = (int)(self.bounds.size.width / 12); // 12 pixels per column
    maxDrops = numColumns;
    
    // Create GPU buffers
    NSUInteger vertexBufferSize = sizeof(MatrixVertex) * maxDrops * 50 * 6; // Max 50 chars per drop, 6 vertices per char
    vertexBuffer = [device newBufferWithLength:vertexBufferSize options:MTLResourceStorageModeShared];
    vertexBuffer.label = @"Vertex Buffer";
    
    NSUInteger dropBufferSize = sizeof(MatrixDrop) * maxDrops;
    dropBuffer = [device newBufferWithLength:dropBufferSize options:MTLResourceStorageModeShared];
    dropBuffer.label = @"Drop Buffer";
    
    uniformBuffer = [device newBufferWithLength:64 options:MTLResourceStorageModeShared]; // For projection matrix and time
    uniformBuffer.label = @"Uniform Buffer";
    
    // Initialize matrix drops
    MatrixDrop *drops = (MatrixDrop *)[dropBuffer contents];
    for (int i = 0; i < maxDrops; i++) {
        drops[i].position = simd_make_float2(i * 12 + 6, -200 - (i % 500));
        drops[i].speed = 80.0f + (float)(arc4random_uniform(60));
        drops[i].length = 15.0f + (float)(arc4random_uniform(20));
        drops[i].startTime = 0.0f;
    }
}

- (void)updateVertexBuffer {
    MatrixVertex *vertices = (MatrixVertex *)[vertexBuffer contents];
    MatrixDrop *drops = (MatrixDrop *)[dropBuffer contents];
    
    int vertexIndex = 0;
    
    for (int dropIndex = 0; dropIndex < maxDrops; dropIndex++) {
        MatrixDrop drop = drops[dropIndex];
        
        for (int charIndex = 0; charIndex < (int)drop.length; charIndex++) {
            float charY = drop.position.y + charIndex * 16;
            
            // Skip if off screen
            if (charY < -32 || charY > self.bounds.size.height + 32) continue;
            
            // Calculate brightness (brighter at head)
            float brightness = 1.0f - ((float)charIndex / drop.length);
            if (charIndex == 0) brightness = 1.0f; // Head is always bright
            
            // Get character texture coordinates
            unichar c = [matrixText characterAtIndex:(charIndex + dropIndex) % matrixText.length];
            NSString *charString = [NSString stringWithCharacters:&c length:1];
            CGRect texRect = [charMap[charString] rectValue];
            
            // Create quad (2 triangles = 6 vertices)
            float x = drop.position.x;
            float y = charY;
            float w = 12;
            float h = 16;
            
            // Triangle 1
            vertices[vertexIndex++] = (MatrixVertex){simd_make_float2(x, y), simd_make_float2(texRect.origin.x, texRect.origin.y), brightness, charIndex};
            vertices[vertexIndex++] = (MatrixVertex){simd_make_float2(x + w, y), simd_make_float2(texRect.origin.x + texRect.size.width, texRect.origin.y), brightness, charIndex};
            vertices[vertexIndex++] = (MatrixVertex){simd_make_float2(x, y + h), simd_make_float2(texRect.origin.x, texRect.origin.y + texRect.size.height), brightness, charIndex};
            
            // Triangle 2
            vertices[vertexIndex++] = (MatrixVertex){simd_make_float2(x + w, y), simd_make_float2(texRect.origin.x + texRect.size.width, texRect.origin.y), brightness, charIndex};
            vertices[vertexIndex++] = (MatrixVertex){simd_make_float2(x + w, y + h), simd_make_float2(texRect.origin.x + texRect.size.width, texRect.origin.y + texRect.size.height), brightness, charIndex};
            vertices[vertexIndex++] = (MatrixVertex){simd_make_float2(x, y + h), simd_make_float2(texRect.origin.x, texRect.origin.y + texRect.size.height), brightness, charIndex};
        }
    }
}

- (void)animateOneFrame {
    CFTimeInterval currentFrameTime = CACurrentMediaTime();
    float deltaTime = (float)(currentFrameTime - lastTime);
    lastTime = currentFrameTime;
    currentTime += deltaTime;
    
    [metalView setNeedsDisplay:YES];
}

#pragma mark - MTKViewDelegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    // Update uniform buffer with new screen size
    typedef struct {
        simd_float4x4 projectionMatrix;
        float time;
        simd_float2 screenSize;
    } Uniforms;
    
    Uniforms *uniforms = (Uniforms *)[uniformBuffer contents];
    uniforms->screenSize = simd_make_float2(size.width, size.height);
    
    // Simple orthographic projection
    uniforms->projectionMatrix = simd_matrix(
        simd_make_float4(2.0f/size.width, 0, 0, 0),
        simd_make_float4(0, -2.0f/size.height, 0, 0),
        simd_make_float4(0, 0, 1, 0),
        simd_make_float4(-1, 1, 0, 1)
    );
}

- (void)drawInMTKView:(MTKView *)view {
    if (!device || !commandQueue || !textPipelineState) {
        return;
    }
    
    // Get drawable
    id<CAMetalDrawable> drawable = view.currentDrawable;
    if (!drawable) return;
    
    // Create command buffer
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    commandBuffer.label = @"AIMatrix Render Commands";
    
    // Update drops using compute shader for ultra-smooth animation
    if (updatePipelineState) {
        id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
        [computeEncoder setComputePipelineState:updatePipelineState];
        [computeEncoder setBuffer:dropBuffer offset:0 atIndex:0];
        
        float deltaTime = 1.0f/60.0f;
        [computeEncoder setBytes:&deltaTime length:sizeof(float) atIndex:1];
        
        float screenHeight = view.bounds.size.height;
        [computeEncoder setBytes:&screenHeight length:sizeof(float) atIndex:2];
        [computeEncoder setBytes:&currentTime length:sizeof(float) atIndex:3];
        
        MTLSize threadsPerGrid = MTLSizeMake(maxDrops, 1, 1);
        MTLSize threadsPerThreadgroup = MTLSizeMake(MIN(maxDrops, 64), 1, 1);
        [computeEncoder dispatchThreads:threadsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];
        [computeEncoder endEncoding];
    }
    
    // Update vertex buffer with new positions
    [self updateVertexBuffer];
    
    // Update uniforms
    typedef struct {
        simd_float4x4 projectionMatrix;
        float time;
        simd_float2 screenSize;
    } Uniforms;
    
    Uniforms *uniforms = (Uniforms *)[uniformBuffer contents];
    uniforms->time = currentTime;
    uniforms->screenSize = simd_make_float2(view.bounds.size.width, view.bounds.size.height);
    
    // Create render pass
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (!renderPassDescriptor) return;
    
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    renderEncoder.label = @"Text Render Encoder";
    
    // Set pipeline and resources
    [renderEncoder setRenderPipelineState:textPipelineState];
    [renderEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:uniformBuffer offset:0 atIndex:1];
    [renderEncoder setFragmentTexture:fontTexture atIndex:0];
    
    // Draw all text with GPU acceleration
    int totalVertices = 0;
    MatrixDrop *drops = (MatrixDrop *)[dropBuffer contents];
    for (int i = 0; i < maxDrops; i++) {
        totalVertices += (int)drops[i].length * 6; // 6 vertices per character
    }
    
    if (totalVertices > 0) {
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:totalVertices];
    }
    
    [renderEncoder endEncoding];
    
    // Present with vsync for smooth 60 FPS
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

// Configuration sheet
- (BOOL)hasConfigureSheet { 
    return YES; 
}

- (NSWindow *)configureSheet {
    NSWindow *sheet = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 450, 250)
                                                   styleMask:NSWindowStyleMaskTitled
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    
    NSView *contentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 450, 250)];
    
    NSTextField *titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(50, 180, 350, 30)];
    [titleLabel setStringValue:@"AIMatrix Screen Saver v8.0 - GPU Accelerated"];
    [titleLabel setBezeled:NO];
    [titleLabel setDrawsBackground:NO];
    [titleLabel setEditable:NO];
    [titleLabel setAlignment:NSTextAlignmentCenter];
    [titleLabel setFont:[NSFont boldSystemFontOfSize:16]];
    [contentView addSubview:titleLabel];
    
    NSTextField *infoLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(50, 120, 350, 50)];
    [infoLabel setStringValue:@"True GPU acceleration using Metal\nUltra-smooth 60 FPS rendering\nDisplays: aimatrix.com - the agentic twin platform...."];
    [infoLabel setBezeled:NO];
    [infoLabel setDrawsBackground:NO];
    [infoLabel setEditable:NO];
    [infoLabel setAlignment:NSTextAlignmentCenter];
    [contentView addSubview:infoLabel];
    
    NSTextField *techLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(50, 70, 350, 30)];
    [techLabel setStringValue:@"Powered by Metal shaders and GPU compute"];
    [techLabel setBezeled:NO];
    [techLabel setDrawsBackground:NO];
    [techLabel setEditable:NO];
    [techLabel setAlignment:NSTextAlignmentCenter];
    [techLabel setTextColor:[NSColor systemGreenColor]];
    [contentView addSubview:techLabel];
    
    NSButton *okButton = [[NSButton alloc] initWithFrame:NSMakeRect(185, 20, 80, 30)];
    [okButton setTitle:@"OK"];
    [okButton setBezelStyle:NSBezelStyleRounded];
    [okButton setTarget:self];
    [okButton setAction:@selector(closeSheet:)];
    [contentView addSubview:okButton];
    
    [sheet setContentView:contentView];
    return sheet;
}

- (void)closeSheet:(id)sender {
    [[NSApplication sharedApplication] endSheet:[sender window]];
}

@end