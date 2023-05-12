#include <flutter/runtime_effect.glsl>

out vec4 fragColor;
uniform sampler2D image;
uniform sampler2D depthImage;
uniform vec2 size;
uniform vec2 canvasSize;
uniform float xDisp;
uniform float yDisp;
uniform float zDisp;
uniform float effectIntensity;

void main() {
    // Box fit: cover
    vec2 fittedImageSize = vec2(0.0, 0.0);
    vec2 imageCoord = vec2(0.0, 0.0);
    vec2 fragCoord = FlutterFragCoord();
    if (canvasSize.x / canvasSize.y > size.x / size.y) {
        fittedImageSize = vec2(canvasSize.x, canvasSize.x * size.y / size.x);
        imageCoord = vec2(fragCoord.x, fragCoord.y + fittedImageSize.y/2.0 - canvasSize.y/2.0);
    } else {
        fittedImageSize = vec2(canvasSize.y * size.x / size.y, canvasSize.y);
        imageCoord = vec2(fragCoord.x + fittedImageSize.x/2.0 - canvasSize.x/2.0, fragCoord.y);
    }
    vec2 uv = imageCoord / fittedImageSize;

    // Depth sample at this pixel 
    vec4 depthSample = texture(depthImage, uv);
    float depthAverage = (depthSample.r + depthSample.g + depthSample.b)/3.0;

    // -1 to 1 so that close/far points go in different directions
    float depth = (depthAverage - 0.5) * 2.0;

    // Image sample at the displaced point in XY (depth amplifies the displacement)
    vec2 displacedUv = (imageCoord.xy - depth * vec2(xDisp, yDisp)*effectIntensity) / fittedImageSize;

    // Z displacement
    displacedUv = (displacedUv - vec2(0.5)) * 2.0;
    displacedUv =  displacedUv * (1.0 - depthAverage * zDisp);
    displacedUv = (displacedUv) / 2.0 + vec2(0.5);

    // Sample image at displaced location
    // vec4 imageSample = texture(image, uv);
    vec4 displacedImageSample = texture(image, displacedUv);
    fragColor = displacedImageSample;
}