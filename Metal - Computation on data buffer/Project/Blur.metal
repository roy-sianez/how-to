#include <metal_stdlib>
using namespace metal;

#define index2D(x, y, width) ((y) * (width)) + (x)

kernel void boxBlur(
    device const uint  &blurSize, // must be odd
    device const uint  &bufferWidth,
    device const uint  &bufferHeight,
    device const uchar *const inBuffer,
    device       uchar *const outBuffer,
    uint index [[thread_position_in_grid]]
) {
    const uint bufferSize = bufferWidth * bufferHeight;
    if (index >= bufferSize) return;
    const uint currentX = index % bufferWidth;
    const uint currentY = index / bufferWidth;
    ushort total = 0;
    const int blurSpan = blurSize / 2;
    for (int dx = -blurSpan; dx <= blurSpan; dx++)
    for (int dy = -blurSpan; dy <= blurSpan; dy++) {
        const int readIndex = index2D(
            clamp((int)currentX + dx, (int)0, (int)bufferWidth - 1),
            clamp((int)currentY + dy, (int)0, (int)bufferWidth - 1),
            (int)bufferWidth);
        total += inBuffer[readIndex];
    }
    outBuffer[index] = total / (blurSize * blurSize);
}
