#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform ubuf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float screenCurvature;
    vec4 frameColor;
    float frameSize;
    float screenRadius;
    vec2 viewportSize;
    float ambientLight;
};

float min2(vec2 v) { return min(v.x, v.y); }
float prod2(vec2 v) { return v.x * v.y; }

vec2 distortCoordinates(vec2 coords){
    vec2 paddedCoords = coords * (vec2(1.0) + frameSize * 2.0) - frameSize;
    vec2 cc = (paddedCoords - vec2(0.5));
    float dist = dot(cc, cc) * screenCurvature;
    return (paddedCoords + cc * (1.0 + dist) * dist);
}

float roundedRectSdfPixels(vec2 p, vec2 topLeft, vec2 bottomRight, float radiusPixels) {
    vec2 sizePixels = (bottomRight - topLeft) * viewportSize;
    vec2 centerPixels = (topLeft + bottomRight) * 0.5 * viewportSize;
    vec2 localPixels = p * viewportSize - centerPixels;
    vec2 halfSize = sizePixels * 0.5 - vec2(radiusPixels);
    vec2 d = abs(localPixels) - halfSize;
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - radiusPixels;
}

void main() {
    vec2 staticCoords = qt_TexCoord0;
    vec2 coords = distortCoordinates(staticCoords);

    float depth = 1.0 - 5.0 * min(min2(staticCoords), min2(vec2(1.0) - staticCoords));

    float screenRadiusPixels = screenRadius;
    float edgeSoftPixels = 1.0;

    float seamWidth = max(screenRadiusPixels, 0.5) / min2(viewportSize);

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

    float distPixels = roundedRectSdfPixels(coords, vec2(0.0), vec2(1.0), screenRadiusPixels);
    float frameShadow = (e * 0.66 + w * 0.66 + n * 0.33 + s) * depth;
    frameShadow *= smoothstep(0.0, edgeSoftPixels * 10.0, distPixels);

    float inScreen = smoothstep(0.0, edgeSoftPixels, -distPixels);
    float alpha = mix(mix(0.7, 0.9, ambientLight), mix(0.0, 0.2, ambientLight), inScreen);
    float glass = clamp(ambientLight * pow(prod2(coords * (1.0 - coords.yx)) * 50.0, 0.25) * inScreen, 0.0, 1.0);
    vec3 color = mix(frameColor.rgb * frameShadow, vec3(glass), inScreen);

    fragColor = vec4(color, alpha) * qt_Opacity;
}
