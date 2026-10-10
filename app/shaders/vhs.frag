#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform ubuf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float vhsBleed;
    float vhsJitter;
    float vhsHeadSwitch;
};

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D noiseSource;

// Correct NTSC/FCC YIQ color space transformation
vec3 rgb2yiq(vec3 c) {
    return vec3(
        0.299 * c.r + 0.587 * c.g + 0.114 * c.b,
        0.5959 * c.r - 0.2744 * c.g - 0.3216 * c.b,
        0.2115 * c.r - 0.5229 * c.g + 0.3114 * c.b
    );
}

vec3 yiq2rgb(vec3 c) {
    return vec3(
        c.x + 0.956 * c.y + 0.621 * c.z,
        c.x - 0.272 * c.y - 0.647 * c.z,
        c.x - 1.106 * c.y + 1.703 * c.z
    );
}

float hash12(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec3 origColor = texture(source, uv).rgb;

    if (vhsBleed <= 0.0 && vhsJitter <= 0.0 && vhsHeadSwitch <= 0.0) {
        fragColor = vec4(origColor, qt_Opacity);
        return;
    }

    // 1. Head-switching artifact at the very bottom of the screen (bottom ~2.5% scanlines)
    float bottomRegion = smoothstep(0.97, 1.0, uv.y) * vhsHeadSwitch;
    if (bottomRegion > 0.0) {
        float headWave = sin(uv.y * 450.0 + time * 30.0) * 0.015;
        float headNoise = (hash12(vec2(floor(uv.y * 450.0), floor(time * 60.0))) - 0.5) * 0.02;
        uv.x += (headWave + headNoise) * bottomRegion;
    }

    // 2. Subtle horizontal tape wobble / timebase jitter across scanlines
    if (vhsJitter > 0.0) {
        float tapeWobble = (hash12(vec2(floor(uv.y * 480.0), floor(time * 30.0))) - 0.5) * 0.003 * vhsJitter;
        uv.x += tapeWobble;
    }

    // 3. Luminance (Y) sampling: crisp text with gentle analog tape response
    float yOffset = 0.0006 * vhsBleed;
    vec3 sampleY = texture(source, clamp(uv, 0.0, 1.0)).rgb * 0.75
                 + texture(source, clamp(uv - vec2(yOffset, 0.0), 0.0, 1.0)).rgb * 0.17
                 + texture(source, clamp(uv - vec2(yOffset * 2.0, 0.0), 0.0, 1.0)).rgb * 0.08;
    float y = rgb2yiq(sampleY).x;

    // 4. Chrominance I (orange-cyan) horizontal smear
    float iStep = (0.0015 + 0.0035 * vhsBleed);
    vec3 sampleI = vec3(0.0);
    float iWeightSum = 0.0;
    for (int k = 0; k < 7; k++) {
        float w = exp(-float(k) * 0.35);
        sampleI += texture(source, clamp(uv - vec2(float(k) * iStep, 0.0), 0.0, 1.0)).rgb * w;
        iWeightSum += w;
    }
    sampleI /= iWeightSum;
    float i = rgb2yiq(sampleI).y;

    // 5. Chrominance Q (green-magenta) wider horizontal smear (Q has 1/3 bandwidth of I)
    float qStep = (0.0025 + 0.007 * vhsBleed);
    vec3 sampleQ = vec3(0.0);
    float qWeightSum = 0.0;
    for (int k = 0; k < 11; k++) {
        float w = exp(-float(k) * 0.25);
        sampleQ += texture(source, clamp(uv - vec2(float(k) * qStep, 0.0), 0.0, 1.0)).rgb * w;
        qWeightSum += w;
    }
    sampleQ /= qWeightSum;
    float q = rgb2yiq(sampleQ).z;

    // 6. Convert YIQ back to RGB
    vec3 vhsColor = yiq2rgb(vec3(y, i, q));

    // 7. Clamp to [0.0, 1.0] to guarantee no negative colors or explosions
    vhsColor = clamp(vhsColor, 0.0, 1.0);

    // Blend with original color based on bleed strength
    vec3 finalColor = mix(origColor, vhsColor, clamp(vhsBleed * 1.2, 0.0, 1.0));
    fragColor = vec4(clamp(finalColor, 0.0, 1.0), qt_Opacity);
}
