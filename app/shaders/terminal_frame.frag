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

float min2(vec2 v) { return min(v.x, v.y); }
float max2(vec2 v) { return max(v.x, v.y); }
float prod2(vec2 v) { return v.x * v.y; }
float sum2(vec2 v) { return v.x + v.y; }

vec2 distortCoordinates(vec2 coords){
    vec2 cc = (coords - vec2(0.5));
    float dist = dot(cc, cc) * screenCurvature;
    return (coords + cc * (1.0 + dist) * dist);
}

vec2 positiveLog(vec2 x) {
    return clamp(log(x), vec2(0.0), vec2(100.0));
}

void main() {
    vec2 staticCoords = qt_TexCoord0;
    vec2 coords = distortCoordinates(staticCoords) * (vec2(1.0) + margin * 2.0) - margin;

    vec2 vignetteCoords = staticCoords * (1.0 - staticCoords.yx);
    float vignette = pow(prod2(vignetteCoords) * 15.0, 0.25);

    vec3 color = frameColor.rgb * vec3(1.0 - vignette);
    float alpha = 0.0;

    float frameShadow = max2(positiveLog(-coords * frameShadowCoeff + vec2(1.0)) + positiveLog(coords * frameShadowCoeff - (vec2(frameShadowCoeff) - vec2(1.0))));
    frameShadow = max(sqrt(frameShadow), 0.0);
    color *= frameShadow;
    alpha = sum2(1.0 - step(vec2(0.0), coords) + step(vec2(1.0), coords));
    alpha = clamp(alpha, 0.0, 1.0);
    alpha *= mix(1.0, 0.9, frameShadow);

    float screenShadow = 1.0 - prod2(positiveLog(coords * screenShadowCoeff + vec2(1.0)) * positiveLog(-coords * screenShadowCoeff + vec2(screenShadowCoeff + 1.0)));
    alpha = max(0.8 * screenShadow, alpha);

    fragColor = vec4(color * alpha, alpha) * qt_Opacity;
}
