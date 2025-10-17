#!/bin/bash

# EasyPub Multi-Platform Build Script
# Builds for macOS, iOS, Android
# Windows must be built on a Windows machine

set -e

echo "========================================="
echo "EasyPub Multi-Platform Build Script"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Build directory
BUILD_OUTPUT="build_output"
mkdir -p "$BUILD_OUTPUT"

echo "Step 1: Getting dependencies..."
flutter pub get

echo ""
echo "Step 2: Generating Hive adapters..."
flutter pub run build_runner build --delete-conflicting-outputs

echo ""
echo "${GREEN}=========================================${NC}"
echo "${GREEN}Building for macOS...${NC}"
echo "${GREEN}=========================================${NC}"
flutter build macos --release
if [ -d "build/macos/Build/Products/Release/easypub.app" ]; then
    cp -r "build/macos/Build/Products/Release/easypub.app" "$BUILD_OUTPUT/"
    echo "${GREEN}✓ macOS build successful${NC}"
    echo "  Output: $BUILD_OUTPUT/easypub.app"
else
    echo "${YELLOW}⚠ macOS build failed${NC}"
fi

echo ""
echo "${GREEN}=========================================${NC}"
echo "${GREEN}Building for iOS (iPhone/iPad)...${NC}"
echo "${GREEN}=========================================${NC}"
flutter build ios --release --no-codesign
if [ -d "build/ios/iphoneos/Runner.app" ]; then
    cp -r "build/ios/iphoneos/Runner.app" "$BUILD_OUTPUT/EasyPub-iOS.app"
    echo "${GREEN}✓ iOS build successful${NC}"
    echo "  Output: $BUILD_OUTPUT/EasyPub-iOS.app"
    echo "  Note: Code signing required for deployment"
else
    echo "${YELLOW}⚠ iOS build failed${NC}"
fi

echo ""
echo "${GREEN}=========================================${NC}"
echo "${GREEN}Building for Android (APK)...${NC}"
echo "${GREEN}=========================================${NC}"
flutter build apk --release
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    cp "build/app/outputs/flutter-apk/app-release.apk" "$BUILD_OUTPUT/EasyPub-Android.apk"
    echo "${GREEN}✓ Android build successful${NC}"
    echo "  Output: $BUILD_OUTPUT/EasyPub-Android.apk"
else
    echo "${YELLOW}⚠ Android build failed${NC}"
fi

echo ""
echo "${GREEN}=========================================${NC}"
echo "${GREEN}Build Summary${NC}"
echo "${GREEN}=========================================${NC}"
echo "Build artifacts saved to: $BUILD_OUTPUT/"
echo ""
echo "Available builds:"
ls -lh "$BUILD_OUTPUT/" 2>/dev/null || echo "No builds available"
echo ""
echo "${YELLOW}Note: Windows build must be run on Windows machine${NC}"
echo "Use scripts/build_windows.bat on Windows"
echo ""
echo "${GREEN}Build complete!${NC}"
