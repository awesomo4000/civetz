#!/bin/bash

# Cross-compile civetz for multiple platforms
# Creates binaries in zig-out/bin/ with platform-specific names

set -e  # Exit on error

echo "🔨 Building civetz for multiple platforms..."
echo ""

# Create output directory
mkdir -p zig-out/bin

# Define platforms
PLATFORMS=(
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-windows"
    "aarch64-windows"
    "x86_64-freebsd"
    "aarch64-freebsd"
    "x86_64-netbsd"
    "aarch64-netbsd"
    "x86_64-macos"
    "aarch64-macos"
)

# Track successful builds
SUCCESS_COUNT=0
FAILED_BUILDS=""

# Build each platform
for PLATFORM in "${PLATFORMS[@]}"; do
    # Parse architecture and OS
    ARCH="${PLATFORM%%-*}"
    OS="${PLATFORM##*-}"

    # Set output name based on platform
    if [ "$OS" = "windows" ]; then
        OUTPUT_NAME="civetz-${OS}-${ARCH}.exe"
    else
        OUTPUT_NAME="civetz-${OS}-${ARCH}"
    fi

    echo "📦 Building for ${PLATFORM}..."

    # Build with ReleaseSmall optimization
    if zig build -Dtarget="${PLATFORM}" -Doptimize=ReleaseSmall 2>/dev/null; then
        # Move the binary to the platform-specific name
        if [ "$OS" = "windows" ]; then
            mv zig-out/bin/civetz.exe "zig-out/bin/${OUTPUT_NAME}" 2>/dev/null || mv zig-out/bin/civetz "zig-out/bin/${OUTPUT_NAME}"
        else
            mv zig-out/bin/civetz "zig-out/bin/${OUTPUT_NAME}"
        fi

        # Get file size
        if [ -f "zig-out/bin/${OUTPUT_NAME}" ]; then
            SIZE=$(ls -lh "zig-out/bin/${OUTPUT_NAME}" | awk '{print $5}')
            echo "  ✅ ${OUTPUT_NAME} (${SIZE})"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo "  ⚠️  Build succeeded but output not found"
            FAILED_BUILDS="${FAILED_BUILDS}${PLATFORM}, "
        fi
    else
        echo "  ❌ Failed to build for ${PLATFORM}"
        FAILED_BUILDS="${FAILED_BUILDS}${PLATFORM}, "
    fi
    echo ""
done

# Summary
echo "="
echo "📊 Build Summary"
echo "================"
echo "✅ Successfully built: ${SUCCESS_COUNT}/${#PLATFORMS[@]} platforms"

if [ -n "$FAILED_BUILDS" ]; then
    echo "❌ Failed builds: ${FAILED_BUILDS%, }"
fi

echo ""
echo "📁 Output binaries:"
ls -lh zig-out/bin/civetz-* 2>/dev/null | awk '{print "   " $9 " (" $5 ")"}'