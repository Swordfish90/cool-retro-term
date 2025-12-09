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
    float screenShadowCoeff;
    float frameShadowCoeff;
    vec4 frameColor;
    vec2 margin;
    float prevLastUpdate;
};

layout(binding = 1) uniform sampler2D txt_source;
layout(binding = 2) uniform sampler2D burnInSource;

float rgb2grey(vec3 v) {
    return dot(v, vec3(0.21, 0.72, 0.04));
}

void main() {
    vec2 coords = qt_TexCoord0;

    vec3 txtColor = texture(txt_source, coords).rgb;
    vec4 accColor = texture(burnInSource, coords);

    float prevMask = accColor.a;
    float currMask = rgb2grey(txtColor);

    float blurDecay = clamp((burnInLastUpdate - prevLastUpdate) * burnInTime, 0.0, 1.0);
    blurDecay = max(0.0, blurDecay - prevMask);
    vec3 blurColor = accColor.rgb - vec3(blurDecay);
    vec3 color = max(blurColor, txtColor);

    fragColor = vec4(color, currMask) * qt_Opacity;
}
