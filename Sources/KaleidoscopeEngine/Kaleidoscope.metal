#include <metal_stdlib>
using namespace metal;

#define M_2xPI 6.2831853h
#define M_PI 3.14159265h
#define M_PI_2 1.570796325h
#define M_PI_3 1.0471975512h
#define M_PI_6 0.5235987756h
#define M_3xPI_2 4.7123889804h
#define M_PI_4 0.7853981625h
#define M_2xPI_3 2.09439510239h
#define M_SQRT3_2 0.8660254038h

enum FillMode {
    tile = 0,
    blank = 1,
};

    
half gammaToLinear(half value) {
    if (value <= 0.04045h) {
        return value / 12.92h;
    } else {
        return pow((value + 0.055h) / 1.055h, 2.4h);
    }
}
    
half linearToGamma(half value) {
    if (value <= 0.0031308h) {
        return value * 12.92h;
    } else {
        return 1.055h * pow(value, 0.41667h) - 0.055h;
    }
}
    
half3 linearColor(half3 gammaColor) {
    return half3(
                 gammaToLinear(gammaColor.x),
                 gammaToLinear(gammaColor.y),
                 gammaToLinear(gammaColor.z));
}
    
half3 gammaColor(half3 linearColor) {
    return half3(
                 linearToGamma(linearColor.x),
                 linearToGamma(linearColor.y),
                 linearToGamma(linearColor.z));
}

ushort2 verticallyReflectedCoordinate(ushort2 gid, half2 offset) {
    unsigned short sectionStartY = (ushort)offset.y;
    unsigned short directionY = gid.y - sectionStartY;
    ushort2 coord = ushort2(gid.x, sectionStartY - directionY);
    
    return coord;
}
    
ushort2 translatedCoordinate(half2 hGid, half2 positionInSquare, half2 targetPosition) {
    half2 hDirection = hGid - positionInSquare;
    half2 hCoord = targetPosition + hDirection;
    return ushort2(hCoord);
}

kernel void kaleidoscope(
    texture2d<float, access::read> textureIn [[texture(0)]],
    texture2d<float, access::write> textureOut [[texture(1)]],
    constant float& count       [[buffer(0)]],
    constant float& dtartAngle  [[buffer(1)]],
    constant FillMode& fillMode [[buffer(2)]],
    constant float2& normOffset [[buffer(3)]],
    ushort2 gid [[thread_position_in_grid]]
) {
    const float2 hGid = (float2)gid;
    const half hCount = (half)count;
    const half h2xCount = hCount * 2;
    const float internalAngle = M_2xPI / hCount;
    const float h2xInternalAngle = (M_2xPI / h2xCount);
    
    float startAngle = dtartAngle;
    
    half2 size = half2(textureIn.get_width(), textureIn.get_height());
    half2 offset = (half2)normOffset * size;
    
    // Normalized between -.5 … 0 … +.5
    half2 centeredCoordinate = (half2)hGid - offset;
    float2 centeredNormCoordinate = (float2)(centeredCoordinate / size);
    
    float angle = M_PI - atan2(centeredNormCoordinate.y, centeredNormCoordinate.x) + startAngle;
    
    float derivedSection = (floor(angle / h2xInternalAngle));
    float section = fmod(derivedSection + 1, (float)h2xCount);
    
    bool shouldReflect = ((int)section % 2 == 1);
    
    if (shouldReflect) {
        startAngle = -startAngle;
    }
    
    half thetaIndex = hCount - floor((half)section / 2);
    float theta = thetaIndex * internalAngle + startAngle + dtartAngle;
    float2 coordOffset = float2(0, 1);
    
    if ((short)section == 0 || (short)section == 1) {
        theta = startAngle + dtartAngle;
        coordOffset = float2(0);
    }
    
    float2x2 rotationMatrix = float2x2(cos(theta), -sin(theta), sin(theta), cos(theta));
    float2 fRotatedCoord = (rotationMatrix * centeredNormCoordinate) * (float2)size + (float2)offset + coordOffset;
    
    switch (fillMode) {
        case FillMode::tile:
            if (fRotatedCoord.x < 0) {
                fRotatedCoord.x = size.x - fRotatedCoord.x;
            }
            if (fRotatedCoord.y < 0) {
                fRotatedCoord.y = size.y - fRotatedCoord.y;
            }
            break;
        case FillMode::blank:
            if (fRotatedCoord.x < 0 || fRotatedCoord.y < 0) {
                textureOut.write(float4(0), gid);
                return;
            }
            break;
    }
    
    ushort2 rotatedCoord = ushort2(fRotatedCoord.x, fRotatedCoord.y);
    
    ushort2 coord;
    if (shouldReflect) {
        coord = verticallyReflectedCoordinate(rotatedCoord, offset);
    } else {
        coord = rotatedCoord;
    }
    
    ushort2 wrapCoord = ushort2(coord.x % textureIn.get_width(), coord.y % textureIn.get_height());
    
    float4 color = textureIn.read(wrapCoord);
    
    textureOut.write(color, gid);
}

int thetaPhaseIndexFromRightStripeIndex(int index) {
    int size = 3;
    int phase = (int)fmod((half)index, (half)size); // -2 -1 0 1 2
    
    if (phase < 0) {
        phase = size + phase; // 1 2 0 1 2
    }
    
    return (phase * 2) % 3;
}

half acuteAngle(half angle) {
    if (angle < 0) {
        angle = M_2xPI - fmod(abs(angle), M_2xPI);
    }
    
    if (angle > M_PI) {
        angle = fmod(angle, M_PI);
    }
    
    if (angle > M_PI_2) {
        return M_PI_2 - (angle - M_PI_2);
    }
    
    return angle;
}
    
kernel void triangleKaleidoscopeSpecialized(
    texture2d<float, access::read> textureIn [[texture(0)]],
    texture2d<float, access::write> textureOut [[texture(1)]],
    constant float& triSize     [[buffer(0)]],
    constant float& decayFactor [[buffer(1)]],
    constant float2& normOffset [[buffer(2)]],
    ushort2 gid [[thread_position_in_grid]]
) {
    const float2 hGid = (float2)gid;
    const half hTriSize = (half)triSize;
    const half hTriSize_2 = hTriSize / 2;
    const half hTriHeight = hTriSize * M_SQRT3_2;
    const half hTriHeight_2 = hTriHeight / 2;
    const half2 triangleSize = half2(hTriSize, hTriHeight);
    const half2 triangleSize_2 = half2(hTriSize_2, hTriHeight_2);
    const half2 size = half2(textureIn.get_width(), textureIn.get_height());
    
    const half2 offset = (half2)normOffset * size;
    
    half2 centerLineIndex = (size / half2(hTriHeight_2));
    half2 centerLinePosition = half2(floor(centerLineIndex.x) * hTriHeight + hTriHeight_2, floor(centerLineIndex.y) * hTriHeight);
    
    half2 centerDiscrepancy = offset - centerLinePosition;
    
    half2 alignLatticeTopLeftOffset = half2(0, hTriHeight_2);

    half2 triangleOffset = offset - centerDiscrepancy;

    half2 centeredCoordinate = (half2)hGid - offset;
    half2 centeredTriangleCoordinate = centeredCoordinate - alignLatticeTopLeftOffset;
    
    float angledStripeCos = M_SQRT3_2;      // Result of cos(gridTheta);
    float angledStripeSin = 0.5f;           // Result of sin(gridTheta);

    float2x2 rotationMatrixLeft = float2x2(angledStripeCos, angledStripeSin, -angledStripeSin, angledStripeCos);
    float2x2 rotationMatrixRight = float2x2(angledStripeCos, -angledStripeSin, angledStripeSin, angledStripeCos);
    
    float2 fRotatedCoordLeft = (rotationMatrixLeft * (float2)centeredTriangleCoordinate) + (float2)triangleOffset;
    float2 fRotatedCoordRight = (rotationMatrixRight * (float2)centeredTriangleCoordinate) + (float2)triangleOffset;
    
    half angledStripeIndexCenterOffset = floor(size.x / hTriHeight_2);

    half stripeIndexVertTop = floor(centeredTriangleCoordinate.y / hTriHeight);
    half stripeIndexVertCenter = stripeIndexVertTop + 1;

    half stripeIndexLeft = floor(fRotatedCoordLeft.x / hTriHeight) - angledStripeIndexCenterOffset;
    half stripeIndexRight = floor(fRotatedCoordRight.x / hTriHeight) - angledStripeIndexCenterOffset;

    half index = stripeIndexRight + stripeIndexLeft;

    bool isOddRow = (int)abs(fmod(stripeIndexVertTop, 2.0h)) == 0;
    bool isFlipped = isOddRow
        ? (int)fmod(abs(index), 2.0h) == 0
        : (int)fmod(abs(index), 2.0h) == 1;

    half2 centerTrianglePosition = offset - triangleSize_2;
    
    half2 trianglePositionCenterIndex = half2(stripeIndexLeft + stripeIndexRight, stripeIndexVertCenter);
    half2 trianglePositionCenterOffset = trianglePositionCenterIndex * half2(triangleSize_2.x, triangleSize.y);
    
    half2 trianglePosition = centerTrianglePosition + trianglePositionCenterOffset;

    half2 rotationCenter = offset;
    
    ushort2 translatedCoord = translatedCoordinate((half2)hGid, trianglePosition, centerTrianglePosition);
    
    if (isFlipped) {
        centerTrianglePosition.y += hTriHeight_2;
        translatedCoord = verticallyReflectedCoordinate(translatedCoord, centerTrianglePosition);
    }
    
    int leftStripeThetaIndex = (int)fmod(stripeIndexLeft - stripeIndexRight, 3);
    if (leftStripeThetaIndex < 0) {
        leftStripeThetaIndex = 3 + leftStripeThetaIndex;
    }
    int thetaIndex = (thetaPhaseIndexFromRightStripeIndex(stripeIndexRight) + leftStripeThetaIndex) % 3;
    half thetaStep = M_2xPI_3;
    half thetaBase = (half)thetaIndex * thetaStep;
    half theta = thetaBase;
    
    half thetaAcute = acuteAngle(theta);
    
    half triangleCenterOffsetXSign = sign(sin(thetaBase));
    
    half2 translatedCenteredCoord = half2(translatedCoord) - rotationCenter;
    float2 translatedCenteredNormCoord = (float2)(translatedCenteredCoord);
    float2 triangleCenter = float2(hTriSize_2, hTriHeight_2);
    
    float2x2 rotationMatrix = float2x2(cos(theta), sin(theta), -sin(theta), cos(theta));
    float2x2 rotationMatrixAcute = float2x2(cos(thetaAcute), sin(thetaAcute), sin(thetaAcute), cos(thetaAcute));
    
    float2 triangleCenterOffset = ((rotationMatrixAcute * (float2)triangleCenter) - (float2)triangleCenter);
    
    triangleCenterOffset.x *= triangleCenterOffsetXSign;
        
    float2 fRotatedCoord = (rotationMatrix * translatedCenteredNormCoord) + (float2)rotationCenter + (float2)triangleCenterOffset;
    ushort2 rotatedCoord = ushort2(fRotatedCoord);
    
    float4 color = textureIn.read(rotatedCoord);
    
    half decayDistance = abs(stripeIndexLeft) + abs(stripeIndexRight) + abs(stripeIndexVertCenter);
    half easedDecay = (decayFactor < 0.3024) ? pow(1.2h, (half)decayFactor) - 1 : pow((half)decayFactor, 2.4h);
    half decay = easedDecay * decayDistance;
    
    half3 colorLin = gammaColor((half3)color.xyz);
    colorLin -= half3(decay);
    color.xyz = (float3)linearColor(colorLin);
    
    textureOut.write(color, gid);
  
}
    
kernel void triangleKaleidoscopeSpecializedWithRotation(
    texture2d<float, access::read> textureIn [[texture(0)]],
    texture2d<float, access::write> textureOut [[texture(1)]],
    constant float& triSize     [[buffer(0)]],
    constant float& startAngle  [[buffer(1)]],
    ushort2 gid [[thread_position_in_grid]]
) {
    const float2 hGid = (float2)gid;
    const half hTriSize = (half)triSize;
    const half hTriSize_2 = hTriSize / 2;
    const half hTriHeight = hTriSize * M_SQRT3_2;
    const half hTriHeight_2 = hTriHeight / 2;
    const half2 triangleSize = half2(hTriSize, hTriHeight);
    const half2 triangleSize_2 = half2(hTriSize_2, hTriHeight_2);
    const half2 size = half2(textureIn.get_width(), textureIn.get_height());
    const float gridTheta = M_PI_6;
    const float verticalStripeAngle = startAngle;
    
    float2x2 rotatedSizeMatrix = float2x2(cos(gridTheta), sin(gridTheta), sin(gridTheta), cos(gridTheta));
    const float2 rotatedBoundedSize = rotatedSizeMatrix * float2(size);
    
    const half2 offset = 0.5h * size;
    
    // Center offset for left and right stripes
    half2 centerLineIndex = (size / half2(hTriHeight_2));
    half2 centerLinePosition = half2(floor(centerLineIndex.x) * hTriHeight + hTriHeight_2, floor(centerLineIndex.y) * hTriHeight);
    half2 centerDiscrepancy = offset - centerLinePosition;
    half2 triangleOffset = offset - centerDiscrepancy;
    
    half2 alignLatticeTopLeftOffset = half2(0, hTriHeight_2);

    half2 centeredCoordinate = (half2)hGid - offset;
    half2 centeredTriangleCoordinate = centeredCoordinate - alignLatticeTopLeftOffset;
    
    float angledStripeCosL = cos(-gridTheta + startAngle);
    float angledStripeSinL = sin(-gridTheta + startAngle);
    float angledStripeCosR = cos(gridTheta + startAngle);
    float angledStripeSinR = sin(gridTheta + startAngle);

    float2x2 rotationMatrixLeft = float2x2(angledStripeCosL, -angledStripeSinL, angledStripeSinL, angledStripeCosL);
    float2x2 rotationMatrixRight = float2x2(angledStripeCosR, -angledStripeSinR, angledStripeSinR, angledStripeCosR);
    
    float2x2 rotationMatrixVert = float2x2(cos(verticalStripeAngle), -sin(verticalStripeAngle), sin(verticalStripeAngle), cos(verticalStripeAngle));
    
    float2 fRotatedCoordLeft = (rotationMatrixLeft * (float2)centeredTriangleCoordinate) + (float2)triangleOffset;
    float2 fRotatedCoordRight = (rotationMatrixRight * (float2)centeredTriangleCoordinate) + (float2)triangleOffset;
    
    float2 fRotatedCoordVert = (rotationMatrixVert * (float2)centeredTriangleCoordinate) + (float2)triangleOffset;
    
    half angledStripeIndexCenterOffset = floor(size.x / hTriHeight_2);
    
    half numRows = floor(size.y / hTriHeight);
    half numIndicesLeft = floor(rotatedBoundedSize.x / hTriHeight);
    half numIndicesRight = floor(rotatedBoundedSize.y / hTriHeight);

    half stripeIndexVertTop = floor(fRotatedCoordVert.y / hTriHeight) - angledStripeIndexCenterOffset;
    half stripeIndexVertCenter = stripeIndexVertTop + 1;

    half stripeIndexLeft = floor(fRotatedCoordLeft.x / hTriHeight) - angledStripeIndexCenterOffset;
    half stripeIndexRight = floor(fRotatedCoordRight.x / hTriHeight) - angledStripeIndexCenterOffset;

    half index = stripeIndexRight + stripeIndexLeft;

    bool isOddRow = (int)abs(fmod(stripeIndexVertTop, 2.0h)) == 0;
    bool isFlipped = isOddRow
        ? (int)fmod(abs(index), 2.0h) == 0
        : (int)fmod(abs(index), 2.0h) == 1;

    half2 centerTrianglePosition = offset - triangleSize_2;
    
    half2 trianglePositionCenterOffset = half2(stripeIndexLeft + stripeIndexRight, stripeIndexVertCenter) * half2(triangleSize_2.x, triangleSize.y);
    
    half2 trianglePosition = centerTrianglePosition + trianglePositionCenterOffset;

    half2 rotationCenter = ceil(offset);
    
    ushort2 translatedCoord = translatedCoordinate((half2)hGid, trianglePosition, centerTrianglePosition);
    
    if (isFlipped) {
        centerTrianglePosition.y += hTriHeight_2;
        translatedCoord = verticallyReflectedCoordinate(translatedCoord, centerTrianglePosition);
    }
    
    int leftStripeThetaIndex = (int)fmod(stripeIndexLeft - stripeIndexRight, 3);
    if (leftStripeThetaIndex < 0) {
        leftStripeThetaIndex = 3 + leftStripeThetaIndex;
    }
    int thetaIndex = (thetaPhaseIndexFromRightStripeIndex(stripeIndexRight) + leftStripeThetaIndex) % 3;
    half thetaStep = M_2xPI_3;
    half thetaBase = (half)thetaIndex * thetaStep;
    half theta = thetaBase;// + startAngle;
    
    half thetaAcute = acuteAngle(theta);
    
    half triangleCenterOffsetXSign = sign(sin(thetaBase));
    
    half2 translatedCenteredCoord = half2(translatedCoord) - rotationCenter;
    float2 translatedCenteredNormCoord = (float2)(translatedCenteredCoord);
    float2 triangleCenter = float2(hTriSize_2, hTriHeight_2);
    
    float2x2 rotationMatrix = float2x2(cos(theta), sin(theta), -sin(theta), cos(theta));
    float2x2 rotationMatrixAcute = float2x2(cos(thetaAcute), sin(thetaAcute), sin(thetaAcute), cos(thetaAcute));
    
    float2 triangleCenterOffset = ((rotationMatrixAcute * (float2)triangleCenter) - (float2)triangleCenter);
    
    triangleCenterOffset.x *= triangleCenterOffsetXSign;
        
    float2 fRotatedCoord = (rotationMatrix * translatedCenteredNormCoord) + (float2)rotationCenter + (float2)triangleCenterOffset;
    ushort2 rotatedCoord = ushort2(fRotatedCoord);
    
    float4 color = textureIn.read(rotatedCoord);
    
    //FIXME: Optimalization, no need to calculate everything else if to be overriden here anyway.
//    if (stripeIndexLeft == 0 && stripeIndexRight == 0 && !isFlipped) {
//        color = textureIn.read(translatedCoord);
//    }
    
//    color = float4(float3((stripeIndexVertCenter + numRows / 2) / numRows, (stripeIndexLeft + numIndicesLeft / 2) / numIndicesLeft, (stripeIndexRight + numIndicesRight / 2) / numIndicesRight), 1);
    
    // Is odd row
//    color = float4(float3(isOddRow ? 1 : 0, stripeIndexVertCenter / numRows, 0), 1);
    
    // Is flipped, and rectangular copy regions
//    color = float4(float3(isFlipped ? 1 : 0, stripeIndexVertCenter / numRows,0), 1);
    
    textureOut.write(color, gid);
  
}
    
kernel void triangleKaleidoscopeDebug(
    texture2d<float, access::read> textureIn [[texture(0)]],
    texture2d<float, access::write> textureOut [[texture(1)]],
    constant float& triSize     [[buffer(0)]],
    constant float& dtartAngle  [[buffer(1)]],
    constant FillMode& fillMode [[buffer(2)]],
    ushort2 gid [[thread_position_in_grid]]
) {
    const half angle = M_PI / 3;
    const float fAngle = M_PI / 3;
    const float2 hGid = (float2)gid;
    const half hTriSize = (half)triSize;
    const half hTriSize_2 = hTriSize / 2;
    const half hTriHeight = hTriSize * sin(angle);
    const half hTriHeight_2 = hTriHeight / 2;
    const half2 triangleSize = half2(hTriSize, hTriHeight);
    const half2 triangleSize_2 = half2(hTriSize_2, hTriHeight_2);
    const half2 size = half2(textureIn.get_width(), textureIn.get_height());
    
    const float gridTheta = fAngle / 2;
    const float thetaLeft = -gridTheta;
    const float thetaRight = gridTheta;
    
    float2x2 rotatedSizeMatrix = float2x2(cos(gridTheta), sin(gridTheta), sin(gridTheta), cos(gridTheta));
    const float2 rotatedBoundedSize = rotatedSizeMatrix * float2(size);
    
    const half2 offset = 0.5h * size;
    
    half2 fittingTriangles = size / half2(hTriSize, hTriHeight);
    half2 wholeFittingTriangles = half2(floor(fittingTriangles.x), floor(fittingTriangles.y));
    
    half2 centerLineIndex = (size / half2(hTriHeight)) / 2;
    half2 centerLinePosition = half2(floor(centerLineIndex.x) * hTriHeight + hTriHeight_2, floor(centerLineIndex.y) * hTriHeight);
    
    half2 centerDiscrepancy = half2(0, 0) + half2(1, 1) * (offset - centerLinePosition);
    
    half2 alignLatticeTopLeftOffset = half2(0, hTriHeight_2);
  
    float startAngle = dtartAngle;

    half2 triangleOffset = offset - centerDiscrepancy;

    // Normalized between -.5 … 0 … +.5
    half2 centeredCoordinate = (half2)hGid - offset;
    half2 centeredTriangleCoordinate = centeredCoordinate - alignLatticeTopLeftOffset;//(half2)hGid - triangleOffset + discrepancy;

    float2x2 rotationMatrixLeft = float2x2(cos(thetaLeft), -sin(thetaLeft), sin(thetaLeft), cos(thetaLeft));
    float2 fRotatedCoordLeft = (rotationMatrixLeft * (float2)centeredTriangleCoordinate) + (float2)triangleOffset;

    float2x2 rotationMatrixRight = float2x2(cos(thetaRight), -sin(thetaRight), sin(thetaRight), cos(thetaRight));
    float2 fRotatedCoordRight = (rotationMatrixRight * (float2)centeredTriangleCoordinate) + (float2)triangleOffset;

    // Used by debug below
    half numRows = floor(size.y / hTriHeight);
    half numCols = floor(size.x / hTriSize);
    
    // Used by debug below
    half numIndicesLeft = floor(rotatedBoundedSize.x / hTriHeight);
    half numIndicesRight = floor(rotatedBoundedSize.y / hTriHeight);
    
    
    half leftIndexCenterOffset = floor(size.x / hTriHeight / 2);
    half rightIndexCenterOffset = floor(size.x / hTriHeight / 2);

    half stripeIndexVertTop = floor(centeredTriangleCoordinate.y / hTriHeight);
    half stripeIndexVertCenter = stripeIndexVertTop + 1;

    half stripeIndexLeft = floor(fRotatedCoordLeft.x / hTriHeight) - leftIndexCenterOffset;
    half stripeIndexRight = floor(fRotatedCoordRight.x / hTriHeight) - rightIndexCenterOffset;

    // numIndicesLeft is too small on some sizes.
    half index = stripeIndexRight * (1) + stripeIndexLeft;

    bool isOddRow = (int)abs(fmod(stripeIndexVertTop, 2.0h)) == 0;
    bool isFlipped = isOddRow
        ? (int)fmod(abs(index), 2.0h) == 0
        : (int)fmod(abs(index), 2.0h) == 1;

    // Used by debug below
    half stripeIndexHoriOdd = floor((centeredTriangleCoordinate.x) / hTriSize) + numCols / 2;
    half stripeIndexHoriEven = floor((centeredTriangleCoordinate.x + (hTriSize_2)) / hTriSize) + numCols / 2;
    half stripeIndexHori = !isOddRow
        ? isFlipped ? stripeIndexHoriOdd : stripeIndexHoriEven
        : isFlipped ? stripeIndexHoriEven : stripeIndexHoriOdd;

    half2 centerTrianglePosition = offset - triangleSize_2;
    
    half2 trianglePositionCenterOffset = half2(stripeIndexLeft + stripeIndexRight, stripeIndexVertCenter) * half2(triangleSize_2.x, triangleSize.y);
    
    half2 trianglePosition = centerTrianglePosition + trianglePositionCenterOffset;

    half2 rotationCenter = offset;

    float4 color;
    
    ushort2 translatedCoord = translatedCoordinate((half2)hGid, trianglePosition, centerTrianglePosition);
    
    if (isFlipped) {
        centerTrianglePosition.y += hTriHeight_2;
        translatedCoord = verticallyReflectedCoordinate(translatedCoord, centerTrianglePosition);
    }
    
    int leftStripeThetaIndex = (int)fmod(stripeIndexLeft - stripeIndexRight, 3);
    if (leftStripeThetaIndex < 0) {
        leftStripeThetaIndex = 3 + leftStripeThetaIndex;
    }
    int thetaIndex = (thetaPhaseIndexFromRightStripeIndex(stripeIndexRight) + leftStripeThetaIndex) % 3;
    half thetaStep = M_2xPI / 3.0h;
    half thetaBase = (half)thetaIndex * thetaStep;
    half theta = thetaBase + startAngle;
    
    half thetaAcute = acuteAngle(theta);//abs(asin(sin(theta)));
    
    half triangleCenterOffsetXSign = sign(sin(thetaBase));
    
    half2 translatedCenteredCoord = half2(translatedCoord) - rotationCenter;
    float2 translatedCenteredNormCoord = (float2)(translatedCenteredCoord);
    float2 triangleCenter = float2(hTriSize, hTriHeight);
    
    float2x2 rotationMatrix = float2x2(cos(theta), sin(theta), -sin(theta), cos(theta));
    float2x2 rotationMatrixAcute = float2x2(cos(thetaAcute), sin(thetaAcute), sin(thetaAcute), cos(thetaAcute));
    
    float2 triangleCenterOffset = ((rotationMatrixAcute * (float2)triangleCenter) - (float2)triangleCenter) / 2;
    
    triangleCenterOffset.x *= triangleCenterOffsetXSign;
        
    float2 fRotatedCoord = (rotationMatrix * translatedCenteredNormCoord) + (float2)rotationCenter + (float2)triangleCenterOffset;
    ushort2 rotatedCoord = ushort2(fRotatedCoord);
    
    color = textureIn.read(rotatedCoord);
    
    
//    color = float4(float3(0, stripeIndexVert / numRows, stripeIndexHori / numRows), 1);
    
    // Is odd row
//    color = float4(float3(isOddRow ? 1 : 0, stripeIndexVert / numRows, stripeIndexHori / numRows), 1);
    
    // Vert index
//    color = float4(float3((stripeIndexVert + 1) / numRows, 0, stripeIndexHori / numRows), 1);
//    if (stripeIndexVert + 1 < 0) {
//        color = float4(float3(0.5), 1);
//    }
    
    // Is flipped, and rectangular copy regions
//    color = float4(float3(isFlipped ? 1 : 0, stripeIndexVert / numRows, stripeIndexHori / numRows), 1);
    
    float4 lightColor = float4(float3(208, 222, 241) / 255, 1);
    float4 darkColor = float4(float3(106, 90, 205) / 255, 1);
    
    if (isFlipped) {
        color = lightColor;
    } else {
        color = darkColor;
    }
    
    // Left and right
//    color = float4(float3(0, (stripeIndexLeft + numIndicesLeft / 2) / numIndicesLeft, (stripeIndexRight + numIndicesRight / 2) / numIndicesRight), 1);
    
    // Left
//    color = float4(float3(stripeIndexVert / numRows, (stripeIndexLeft + numIndicesLeft / 2) / numIndicesLeft, 0), 1);
    
//    if (stripeIndexLeft == 0 && stripeIndexRight == 0) {
//        color = float4(1);
//    }

    // Copy over for l,r index 0
//    if (stripeIndexLeft == 0 && stripeIndexRight == 0 && !isFlipped) {
//        color = textureIn.read(gid);
//    }

    textureOut.write(color, gid);
  
}

    kernel void kaleidoscopeCircular(
        texture2d<float, access::read> textureIn [[texture(0)]],
        texture2d<float, access::write> textureOut [[texture(1)]],
        constant float& count       [[buffer(0)]],
        constant float& dtartAngle  [[buffer(1)]],
        constant FillMode& fillMode [[buffer(2)]],
        ushort2 gid [[thread_position_in_grid]]
    ) {
        const float2 hGid = (float2)gid;
        const half hCount = (half)count;
        const half h2xCount = hCount * 2;
        const float internalAngle = M_2xPI / hCount;
        const float h2xInternalAngle = (M_2xPI / h2xCount);
        
        float startAngle = -dtartAngle;
        
        half2 size = half2(textureIn.get_width(), textureIn.get_height());
        half2 offset = 0.5h * size;
        
        // Normalized between -.5 … 0 … +.5
        half2 centeredCoordinate = (half2)hGid - offset;
        float2 centeredNormCoordinate = (float2)(centeredCoordinate / size);
        
        float angle = atan2(centeredNormCoordinate.y, centeredNormCoordinate.x); //+ startAngle;
        
        if (angle < 0) {
            angle = M_2xPI - angle;
        }
        
        angle += startAngle;
        
        float derivedSection = (floor(angle / h2xInternalAngle));
        float section = fmod(derivedSection + hCount + 1, (float)h2xCount);
        
        bool shouldReflect = ((int)section % 2 == 1);
        
        if (!shouldReflect) {
            startAngle = -startAngle;
        }
        
        half thetaIndex = hCount - floor((half)section / 2);
        float theta = thetaIndex * internalAngle + startAngle;
        float2 coordOffset = float2(0, 0);
        
        if ((short)section == 0 || (short)section == 1) {
            theta = startAngle;
            coordOffset = float2(0);
        }
        
        float magn = length(centeredNormCoordinate);
        
        float2 rotatedPoint = float2(magn * cos(theta + angle), magn * sin(theta + angle));
        float2 fRotatedCoord = rotatedPoint * (float2)size + (float2)offset + coordOffset;
        
        switch (fillMode) {
            case FillMode::tile:
                if (fRotatedCoord.x < 0) {
                    fRotatedCoord.x = size.x - fRotatedCoord.x;
                }
                if (fRotatedCoord.y < 0) {
                    fRotatedCoord.y = size.y - fRotatedCoord.y;
                }
                break;
            case FillMode::blank:
                if (fRotatedCoord.x < 0 || fRotatedCoord.y < 0) {
                    textureOut.write(float4(0), gid);
                    return;
                }
                break;
        }
        
        ushort2 rotatedCoord = ushort2(fRotatedCoord.x, fRotatedCoord.y);
        
        ushort2 coord;
        if (!shouldReflect) {
            coord = verticallyReflectedCoordinate(rotatedCoord, offset);
        } else {
            coord = rotatedCoord;
        }
        
        ushort2 wrapCoord = ushort2(coord.x % textureIn.get_width(), coord.y % textureIn.get_height());
        
        float4 color = textureIn.read(wrapCoord);
        
        textureOut.write(color, gid);
    }
