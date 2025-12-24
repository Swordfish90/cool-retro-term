#version 440

#ifndef CRT_RGB_SHIFT
#define CRT_RGB_SHIFT 1
#endif
#ifndef CRT_BLOOM
#define CRT_BLOOM 1
#endif
#ifndef CRT_FRAME_SHININESS
#define CRT_FRAME_SHININESS 1
#endif
#ifndef CRT_CURVATURE
#define CRT_CURVATURE 1
#endif

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform ubuf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float screenCurvature;
    float rbgShift;
    float frameShininess;
    float frameSize;
    float screen_brightness;
    float bloom;
};

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D bloomSource;

float min2(vec2 v) { return min(v.x, v.y); }
float max2(vec2 v) { return max(v.x, v.y); }
vec2 distortCoordinates(vec2 coords){
    vec2 paddedCoords = coords * (vec2(1.0) + frameSize * 2.0) - frameSize;
    vec2 cc = (paddedCoords - vec2(0.5));
    float dist = dot(cc, cc) * screenCurvature;
    return (paddedCoords + cc * (1.0 + dist) * dist);
}

void main() {
    vec2 cc = vec2(0.5) - qt_TexCoord0;

    float shownDraw = 1.0;
    float isReflection = 0.0;
    float isScreen = 1.0;

    vec2 txt_coords = qt_TexCoord0;
#if CRT_CURVATURE == 1
    vec2 curvatureCoords = distortCoordinates(qt_TexCoord0);
    shownDraw = max2(step(vec2(0.0), curvatureCoords) - step(vec2(1.0), curvatureCoords));
    isScreen = min2(step(vec2(0.0), curvatureCoords) - step(vec2(1.0), curvatureCoords));
    isReflection = shownDraw - isScreen;
    txt_coords = curvatureCoords * (-1.0 + 2.0 * step(vec2(0.0), curvatureCoords) - 2.0 * step(vec2(1.0), curvatureCoords));
#endif

    vec3 txt_color = texture(source, txt_coords).rgb;

#if CRT_RGB_SHIFT == 1
    vec2 displacement = vec2(12.0, 0.0) * rbgShift;
    vec3 rightColor = texture(source, txt_coords + displacement).rgb;
    vec3 leftColor = texture(source, txt_coords - displacement).rgb;
    txt_color.r = leftColor.r * 0.10 + rightColor.r * 0.30 + txt_color.r * 0.60;
    txt_color.g = leftColor.g * 0.20 + rightColor.g * 0.20 + txt_color.g * 0.60;
    txt_color.b = leftColor.b * 0.30 + rightColor.b * 0.10 + txt_color.b * 0.60;
#endif

    vec3 finalColor = txt_color * shownDraw;

    vec3 bloomColor = txt_color;
    float bloomAlpha = 0.0;
#if CRT_BLOOM == 1 || CRT_FRAME_SHININESS == 1
    vec4 bloomFullColor = texture(bloomSource, txt_coords);
    bloomColor = bloomFullColor.rgb;
    bloomAlpha = bloomFullColor.a;
#endif

#if CRT_BLOOM == 1
    vec3 bloomOnScreen = bloomColor * isScreen;
    finalColor += clamp(bloomOnScreen * bloom * bloomAlpha, 0.0, 0.5);
    float bloomScale = 1.0 + max(bloom, 0.0);
    finalColor /= bloomScale;
#endif

#if CRT_FRAME_SHININESS == 1
    vec3 reflectionColor = mix(bloomColor, finalColor, frameShininess * 0.5);
    finalColor = mix(finalColor, reflectionColor, isReflection);
#endif

    finalColor *= screen_brightness;
    fragColor = vec4(finalColor, qt_Opacity);
}
