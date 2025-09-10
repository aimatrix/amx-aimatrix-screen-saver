#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
    float brightness [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
    float brightness;
};

// Vertex shader - runs on GPU
vertex VertexOut vertexShader(VertexIn in [[stage_in]],
                              constant float4x4& mvpMatrix [[buffer(0)]]) {
    VertexOut out;
    out.position = mvpMatrix * float4(in.position, 0.0, 1.0);
    out.texCoord = in.texCoord;
    out.brightness = in.brightness;
    return out;
}

// Fragment shader - runs on GPU for each pixel
fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               texture2d<float> fontTexture [[texture(0)]],
                               constant float3& rainColor [[buffer(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear,
                                     min_filter::linear);
    
    // Sample the character texture
    float4 texColor = fontTexture.sample(textureSampler, in.texCoord);
    
    // Apply Matrix green color with brightness
    float3 color = rainColor * in.brightness;
    
    // Add glow effect for leading edge
    if (in.brightness > 0.9) {
        color = float3(0.9, 1.0, 0.9);  // Bright white-green for head
    }
    
    return float4(color, texColor.a * in.brightness);
}

// Compute shader for particle physics (optional, for ultra smooth motion)
kernel void updateDrops(device float2* positions [[buffer(0)]],
                       device float* speeds [[buffer(1)]],
                       constant float& deltaTime [[buffer(2)]],
                       uint id [[thread_position_in_grid]]) {
    float2 pos = positions[id];
    float speed = speeds[id];
    
    // Update position with smooth interpolation
    pos.y += speed * deltaTime * 60.0;  // 60 fps normalized
    
    // Wrap around when reaching bottom
    if (pos.y > 1080.0) {  // Assuming 1080p screen
        pos.y = -100.0;
    }
    
    positions[id] = pos;
}