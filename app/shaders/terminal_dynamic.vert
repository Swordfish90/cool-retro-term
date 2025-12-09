#version 440

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;

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
    float screenShadowCoeff;
    float frameShadowCoeff;
    vec4 frameColor;
    vec2 margin;
    float prevLastUpdate;
};

layout(binding = 0) uniform sampler2D noiseSource;

layout(location = 0) out vec2 qt_TexCoord0;
layout(location = 1) out float vBrightness;
layout(location = 2) out float vDistortionScale;
layout(location = 3) out float vDistortionFreq;

void main() {
    qt_TexCoord0 = qt_MultiTexCoord0;

    vec2 coords = vec2(fract(time / 2048.0), fract(time / 1048576.0));
    vec4 initialNoiseTexel = texture(noiseSource, coords);

    vBrightness = 1.0 + (initialNoiseTexel.g - 0.5) * flickering;

    float randval = horizontalSyncStrength - initialNoiseTexel.r;
    vDistortionScale = step(0.0, randval) * randval * horizontalSyncStrength * horizontalSync;
    vDistortionFreq = mix(4.0, 40.0, initialNoiseTexel.g) * step(0.0, horizontalSync);

    gl_Position = qt_Matrix * qt_Vertex;
}
