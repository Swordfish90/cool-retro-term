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

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D bloomSource;

float min2(vec2 v) { return min(v.x, v.y); }
float max2(vec2 v) { return max(v.x, v.y); }
float rgb2grey(vec3 v) { return dot(v, vec3(0.21, 0.72, 0.04)); }

vec2 distortCoordinates(vec2 coords){
    vec2 paddedCoords = coords * (vec2(1.0) + frameSize * 2.0) - frameSize;
    vec2 cc = (paddedCoords - vec2(0.5));
    float dist = dot(cc, cc) * screenCurvature;
    return (paddedCoords + cc * (1.0 + dist) * dist);
}

vec3 convertWithChroma(vec3 inColor) {
    vec3 outColor = fontColor.rgb * rgb2grey(inColor);
    if (chromaColor != 0.0) {
        outColor = fontColor.rgb * mix(vec3(rgb2grey(inColor)), inColor, chromaColor);
    }
    return outColor;
}

void main() {
    vec2 cc = vec2(0.5) - qt_TexCoord0;

    float shownDraw = 1.0;
    float isReflection = 0.0;
    float isScreen = 1.0;

    vec2 txt_coords = qt_TexCoord0;
    if (screenCurvature > 0.0 || frameSize > 0.0) {
        vec2 curvatureCoords = distortCoordinates(qt_TexCoord0);
        shownDraw = max2(step(vec2(0.0), curvatureCoords) - step(vec2(1.0), curvatureCoords));
        isScreen = min2(step(vec2(0.0), curvatureCoords) - step(vec2(1.0), curvatureCoords));
        isReflection = shownDraw - isScreen;
        txt_coords = -2.0 * curvatureCoords + 3.0 * step(vec2(0.0), curvatureCoords) * curvatureCoords - 3.0 * step(vec2(1.0), curvatureCoords) * curvatureCoords;
    }

    vec3 txt_color = texture(source, txt_coords).rgb;

    if (rbgShift > 0.0) {
        vec2 displacement = vec2(12.0, 0.0) * rbgShift;
        vec3 rightColor = texture(source, txt_coords + displacement).rgb;
        vec3 leftColor = texture(source, txt_coords - displacement).rgb;
        txt_color.r = leftColor.r * 0.10 + rightColor.r * 0.30 + txt_color.r * 0.60;
        txt_color.g = leftColor.g * 0.20 + rightColor.g * 0.20 + txt_color.g * 0.60;
        txt_color.b = leftColor.b * 0.30 + rightColor.b * 0.10 + txt_color.b * 0.60;
    }

    txt_color += vec3(0.0001);
    float greyscale_color = rgb2grey(txt_color);

    vec3 finalColor;
    if (chromaColor > 0.0) {
        vec3 foregroundColor = mix(fontColor.rgb, txt_color * fontColor.rgb / greyscale_color, chromaColor);
        finalColor = mix(backgroundColor.rgb, foregroundColor, greyscale_color * shownDraw);
    } else {
        finalColor = mix(backgroundColor.rgb, fontColor.rgb, greyscale_color * shownDraw);
    }

    vec4 bloomFullColor = texture(bloomSource, txt_coords);
    vec3 bloomColor = convertWithChroma(bloomFullColor.rgb);
    float bloomAlpha = bloomFullColor.a;

    if (bloom > 0.0) {
        vec3 bloomOnScreen = bloomColor * isScreen;
        finalColor += clamp(bloomOnScreen * bloom * bloomAlpha, 0.0, 0.5);
    }

    if (frameShininess > 0.0) {
        float shine = clamp(frameShininess, 0.0, 1.0);
        vec3 reflectionColor = mix(bloomColor, finalColor, shine * 0.5);
        finalColor = mix(finalColor, reflectionColor, isReflection);
    }

    finalColor *= screen_brightness;
    fragColor = vec4(finalColor, qt_Opacity);
}
