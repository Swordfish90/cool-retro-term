#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 1) in float vBrightness;
layout(location = 2) in float vDistortionScale;
layout(location = 3) in float vDistortionFreq;

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

layout(binding = 0) uniform sampler2D noiseSource;
layout(binding = 1) uniform sampler2D screenBuffer;
layout(binding = 2) uniform sampler2D burnInSource;
layout(binding = 3) uniform sampler2D frameSource;

float min2(vec2 v) { return min(v.x, v.y); }
float prod2(vec2 v) { return v.x * v.y; }
float sum2(vec2 v) { return v.x + v.y; }
float rgb2grey(vec3 v) { return dot(v, vec3(0.21, 0.72, 0.04)); }

vec3 applyRasterization(vec2 screenCoords, vec3 texel, vec2 virtualRes, float intensity, int mode) {
    if (intensity <= 0.0 || mode == 0) {
        return texel;
    }

    const float INTENSITY = 0.30;
    const float BRIGHTBOOST = 0.30;

    if (mode == 1) { // scanline
        vec3 pixelHigh = ((1.0 + BRIGHTBOOST) - (0.2 * texel)) * texel;
        vec3 pixelLow  = ((1.0 - INTENSITY) + (0.1 * texel)) * texel;

        vec2 coords = fract(screenCoords * virtualRes) * 2.0 - vec2(1.0);
        float mask = 1.0 - abs(coords.y);

        vec3 rasterizationColor = mix(pixelLow, pixelHigh, mask);
        return mix(texel, rasterizationColor, intensity);
    } else if (mode == 2) { // pixel
        vec3 pixelHigh = ((1.0 + BRIGHTBOOST) - (0.2 * texel)) * texel;
        vec3 pixelLow  = ((1.0 - INTENSITY) + (0.1 * texel)) * texel;

        vec2 coords = fract(screenCoords * virtualRes) * 2.0 - vec2(1.0);
        coords = coords * coords;
        float mask = 1.0 - coords.x - coords.y;

        vec3 rasterizationColor = mix(pixelLow, pixelHigh, mask);
        return mix(texel, rasterizationColor, intensity);
    } else if (mode == 3) { // subpixel
        const float SUBPIXELS = 3.0;
        vec3 offsets = vec3(3.141592654) * vec3(0.5, 0.5 - 2.0 / 3.0, 0.5 - 4.0 / 3.0);

        vec2 omega = vec2(3.141592654) * vec2(2.0) * virtualRes;
        vec2 angle = screenCoords * omega;
        vec3 xfactors = (SUBPIXELS + sin(angle.x + offsets)) / (SUBPIXELS + 1.0);

        vec3 result = texel * xfactors;
        vec3 pixelHigh = ((1.0 + BRIGHTBOOST) - (0.2 * result)) * result;
        vec3 pixelLow  = ((1.0 - INTENSITY) + (0.1 * result)) * result;

        vec2 coords = fract(screenCoords * virtualRes) * 2.0 - vec2(1.0);
        float mask = 1.0 - abs(coords.y);

        vec3 rasterizationColor = mix(pixelLow, pixelHigh, mask);
        return mix(texel, rasterizationColor, intensity);
    }

    return texel;
}

float randomPass(vec2 coords){
    return fract(smoothstep(-120.0, 0.0, coords.y - (virtualResolution.y + 120.0) * fract(time * 0.15)));
}

vec2 barrel(vec2 v, vec2 cc) {
    float distortion = dot(cc, cc) * screenCurvature;
    return (v - cc * (1.0 + distortion) * distortion);
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
    float distance = length(cc);

    vec2 staticCoords = barrel(qt_TexCoord0, cc);
    vec2 coords = qt_TexCoord0;

    float dst = sin((coords.y + time) * vDistortionFreq);
    coords.x += dst * vDistortionScale;

    vec4 noiseTexel = texture(noiseSource, scaleNoiseSize * coords + vec2(fract(time / 0.051), fract(time / 0.237)));

    vec2 txt_coords = coords + (noiseTexel.ba - vec2(0.5)) * jitterDisplacement * jitter;

    float color = 0.0001;
    color += noiseTexel.a * staticNoise * (1.0 - distance * 1.3);
    color += randomPass(coords * virtualResolution) * glowingLine;

    vec3 txt_color = texture(screenBuffer, txt_coords).rgb;

    if (burnIn > 0.0) {
        vec4 txt_blur = texture(burnInSource, staticCoords);
        float blurDecay = clamp((time - burnInLastUpdate) * burnInTime, 0.0, 1.0);
        vec3 burnInColor = 0.65 * (txt_blur.rgb - vec3(blurDecay));
        txt_color = max(txt_color, convertWithChroma(burnInColor));
    }

    txt_color += fontColor.rgb * vec3(color);
    txt_color = applyRasterization(staticCoords, txt_color, virtualResolution, rasterizationIntensity, rasterizationMode);

    vec3 finalColor = txt_color;
    float brightness = mix(1.0, vBrightness, step(0.0, flickering));
    finalColor *= brightness;

    finalColor += vec3(ambientLight) * (1.0 - distance) * (1.0 - distance);

    if (displayTerminalFrame > 0.0) {
        vec4 frameColor = texture(frameSource, qt_TexCoord0);
        finalColor = mix(finalColor, frameColor.rgb, frameColor.a);
    }

    fragColor = vec4(finalColor, qt_Opacity);
}
