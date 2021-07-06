import QtQuick 2.0

QtObject {
    property string rasterizationShader:
        (appSettings.rasterization === appSettings.no_rasterization ? "
            lowp vec3 applyRasterization(vec2 screenCoords, lowp vec3 texel, vec2 virtualResolution, float intensity) {
                return texel;
            }" : "") +

        (appSettings.rasterization === appSettings.scanline_rasterization ? "
            #define INTENSITY 0.30
            #define BRIGHTBOOST 0.30

            lowp vec3 applyRasterization(vec2 screenCoords, lowp vec3 texel, vec2 virtualResolution, float intensity) {
                lowp vec3 pixelHigh = ((1.0 + BRIGHTBOOST) - (0.2 * texel)) * texel;
                lowp vec3 pixelLow  = ((1.0 - INTENSITY) + (0.1 * texel)) * texel;

                vec2 coords = fract(screenCoords * virtualResolution) * 2.0 - vec2(1.0);
                lowp float mask = 1.0 - abs(coords.y);

                lowp vec3 rasterizationColor = mix(pixelLow, pixelHigh, mask);
                return mix(texel, rasterizationColor, intensity);
            }" : "") +

        (appSettings.rasterization === appSettings.pixel_rasterization ? "
            #define INTENSITY 0.30
            #define BRIGHTBOOST 0.30

            lowp vec3 applyRasterization(vec2 screenCoords, lowp vec3 texel, vec2 virtualResolution, float intensity) {
                lowp vec3 result = texel;

                lowp vec3 pixelHigh = ((1.0 + BRIGHTBOOST) - (0.2 * texel)) * texel;
                lowp vec3 pixelLow  = ((1.0 - INTENSITY) + (0.1 * texel)) * texel;

                vec2 coords = fract(screenCoords * virtualResolution) * 2.0 - vec2(1.0);
                coords = coords * coords;
                lowp float mask = 1.0 - coords.x - coords.y;

                lowp vec3 rasterizationColor = mix(pixelLow, pixelHigh, mask);
                return mix(texel, rasterizationColor, intensity);
            }" : "") +

        (appSettings.rasterization === appSettings.subpixel_rasterization ? "
            #define INTENSITY 0.30
            #define BRIGHTBOOST 0.30
            #define SUBPIXELS 3.0
            const vec3 offsets = vec3(3.141592654) * vec3(1.0/2.0,1.0/2.0 - 2.0/3.0,1.0/2.0-4.0/3.0);

            lowp vec3 applyRasterization(vec2 screenCoords, lowp vec3 texel, vec2 virtualResolution, float intensity) {
                vec2 omega = vec2(3.141592654) * vec2(2.0) * virtualResolution;
                vec2 angle = screenCoords * omega;
                vec3 xfactors = (SUBPIXELS + sin(angle.x + offsets)) / (SUBPIXELS + 1.0);

                lowp vec3 result = texel * xfactors;
                lowp vec3 pixelHigh = ((1.0 + BRIGHTBOOST) - (0.2 * result)) * result;
                lowp vec3 pixelLow  = ((1.0 - INTENSITY) + (0.1 * result)) * result;

                vec2 coords = fract(screenCoords * virtualResolution) * 2.0 - vec2(1.0);
                lowp float mask = 1.0 - abs(coords.y);

                lowp vec3 rasterizationColor = mix(pixelLow, pixelHigh, mask);
                return mix(texel, rasterizationColor, intensity);
            }" : "") +

        "\n\n"

    property string min2: "
        float min2(vec2 v) {
            return min(v.x, v.y);
        }\n\n"

    property string rgb2grey: "
        float rgb2grey(vec3 v) {
            return dot(v, vec3(0.21, 0.72, 0.04));
        }\n\n"

    property string max2: "
        float max2(vec2 v) {
            return max(v.x, v.y);
        }\n\n"

    property string prod2: "
        float prod2(vec2 v) {
            return v.x * v.y;
        }\n\n"

    property string sum2: "
        float sum2(vec2 v) {
            return v.x + v.y;
        }\n\n"
}
