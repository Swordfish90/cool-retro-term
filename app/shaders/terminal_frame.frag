#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform ubuf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    vec4 fontColor;
    vec4 backgroundColor;
    float shadowLength;
    vec2 virtualResolution;
    float rasterizationIntensity;
    int rasterizationMode;
    float burnInLastUpdate;
    float burnInTime;
    float burnIn;
    float staticNoise;
    float screenCurvature;
    float glowingLine;
    float chromaColor;
    vec2 jitterDisplacement;
    float ambientLight;
    float jitter;
    float horizontalSync;
    float horizontalSyncStrength;
    float flickering;
    float displayTerminalFrame;
    vec2 scaleNoiseSize;
    float screen_brightness;
    float bloom;
    float rbgShift;
    float frameShadowCoeff;
    float frameShininess;
    vec4 frameColor;
    float frameSize;
    float prevLastUpdate;
};

float min2(vec2 v) { return min(v.x, v.y); }
float max2(vec2 v) { return max(v.x, v.y); }
float prod2(vec2 v) { return v.x * v.y; }
float sum2(vec2 v) { return v.x + v.y; }
float hash(vec2 v) { return fract(sin(dot(v, vec2(12.9898, 78.233))) * 43758.5453); }

vec2 distortCoordinates(vec2 coords){
    vec2 paddedCoords = coords * (vec2(1.0) + frameSize * 2.0) - frameSize;
    vec2 cc = (paddedCoords - vec2(0.5));
    float dist = dot(cc, cc) * screenCurvature;
    return (paddedCoords + cc * (1.0 + dist) * dist);
}

void main() {
    vec2 staticCoords = qt_TexCoord0;
    vec2 coords = distortCoordinates(staticCoords);

    float depth = 1.0 - 5.0 * min(min2(staticCoords), min2(vec2(1.0) - staticCoords));

    float occlusionWidth = 0.025;
    float seamWidth = occlusionWidth;

    float e = min(
        smoothstep(-seamWidth, seamWidth, coords.x - coords.y),
        smoothstep(-seamWidth, seamWidth, coords.x - (1.0 - coords.y))
    );
    float s = min(
        smoothstep(-seamWidth, seamWidth, coords.y - coords.x),
        smoothstep(-seamWidth, seamWidth, coords.x - (1.0 - coords.y))
    );
    float w = min(
        smoothstep(-seamWidth, seamWidth, coords.y - coords.x),
        smoothstep(-seamWidth, seamWidth, (1.0 - coords.x) - coords.y)
    );
    float n = min(
        smoothstep(-seamWidth, seamWidth, coords.x - coords.y),
        smoothstep(-seamWidth, seamWidth, (1.0 - coords.x) - coords.y)
    );

    vec2 clampedCoords = clamp(coords, vec2(0.0), vec2(1.0));
    float innerEdgeDist = length(coords - clampedCoords);
    float occlusion = smoothstep(0.0, occlusionWidth, innerEdgeDist);

    float frameShadow = e * 0.75 + w * 0.75 + n * 0.50 + s * 1.00;
    frameShadow *= sqrt(occlusion) * depth;

    vec3 color = frameColor.rgb * frameShadow;
    float alpha = clamp(sum2(1.0 - step(vec2(0.0), coords) + step(vec2(1.0), coords)), 0.0, 1.0);
    fragColor = vec4(color * alpha, alpha) * qt_Opacity;
}
