# EasyPub - Platform Build Guide

Complete guide for building EasyPub on all supported platforms.

## ✅ Supported Platforms

- **macOS** (Intel & Apple Silicon)
- **Windows** (x64)
- **iOS** (iPhone & iPad)
- **Android** (ARM & x86)

## 🔧 Prerequisites

### All Platforms
- Flutter SDK 3.0.0 or higher
- Dart SDK (included with Flutter)
- Git

### Platform-Specific Requirements

#### macOS
- macOS 10.14 or higher
- Xcode 12.0 or higher
- CocoaPods (`sudo gem install cocoapods`)

#### Windows
- Windows 10/11 (64-bit)
- Visual Studio 2022 with C++ desktop development workload
- Windows SDK 10.0.17763.0 or higher

#### iOS
- macOS with Xcode 12.0+
- iOS Deployment Target: 12.0+
- Valid Apple Developer account (for distribution)

#### Android
- Android SDK
- Android Studio or Android SDK Command-line Tools
- Java JDK 11 or higher
- Min SDK: 21 (Android 5.0)
- Target SDK: 34

## 🚀 Quick Start

### Automated Build (macOS/Linux/iOS/Android)

```bash
# Make script executable
chmod +x scripts/build_all.sh

# Run automated build
./scripts/build_all.sh
```

This will build:
- macOS app (.app)
- iOS app (.app) [unsigned]
- Android APK (.apk)

Output files will be in `build_output/` directory.

### Windows Build

On a Windows machine:

```batch
scripts\build_windows.bat
```

Output will be in `build\windows\x64\runner\Release\`

## 📱 Platform-Specific Build Instructions

### macOS

```bash
# Install dependencies
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Build for macOS
flutter build macos --release

# Output location
build/macos/Build/Products/Release/easypub.app

# To run
open build/macos/Build/Products/Release/easypub.app
```

**Creating DMG Installer:**
```bash
# Using create-dmg (install via brew)
brew install create-dmg

create-dmg \
  --volname "EasyPub" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --app-drop-link 600 185 \
  "EasyPub-macOS.dmg" \
  "build/macos/Build/Products/Release/easypub.app"
```

### iOS (iPhone/iPad)

```bash
# Install dependencies
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Install pods
cd ios && pod install && cd ..

# Build unsigned (for testing)
flutter build ios --release --no-codesign

# Output location
build/ios/iphoneos/Runner.app
```

**For App Store Distribution:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your development team
3. Update bundle identifier
4. Archive and upload to App Store Connect

**Minimum iOS Version:** 12.0

### Android

```bash
# Install dependencies
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Build APK
flutter build apk --release

# Output location
build/app/outputs/flutter-apk/app-release.apk

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Output location
build/app/outputs/bundle/release/app-release.aab
```

**Signing for Release:**

1. Create keystore:
```bash
keytool -genkey -v -keystore ~/easypub-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias easypub
```

2. Create `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=easypub
storeFile=<path-to-keystore>
```

3. Update `android/app/build.gradle` with signing config

### Windows

```batch
REM Install dependencies
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

REM Build for Windows
flutter build windows --release

REM Output location
REM build\windows\x64\runner\Release\
```

**Creating Installer:**

Using Inno Setup:
1. Install [Inno Setup](https://jrsoftware.org/isdl.php)
2. Create installer script (see `scripts/windows_installer.iss`)
3. Compile the script

## 🧪 Testing Builds

### macOS
```bash
open build/macos/Build/Products/Release/easypub.app
```

### iOS (Simulator)
```bash
flutter build ios --debug
open -a Simulator
flutter install
```

### Android (Emulator/Device)
```bash
flutter install  # with device connected
```

### Windows
```batch
build\windows\x64\runner\Release\easypub.exe
```

## 📦 Build Output Sizes

Approximate sizes after build:

| Platform | Size (Release) |
|----------|----------------|
| macOS    | ~48 MB         |
| iOS      | ~22 MB         |
| Android  | ~54 MB (APK)   |
| Windows  | ~45 MB         |

## 🔍 Troubleshooting

### Common Issues

#### "Pod install failed"
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

#### "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### "Hive adapter not found"
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

#### "Code signing error" (iOS/macOS)
- Ensure you have a valid Apple Developer account
- Update team ID in Xcode
- Check provisioning profiles

### Platform-Specific Issues

#### macOS Entitlements
If network or file access fails:
- Check `macos/Runner/DebugProfile.entitlements`
- Check `macos/Runner/Release.entitlements`
- Ensure required permissions are granted

#### Android Permissions
If file picker fails:
- Check `android/app/src/main/AndroidManifest.xml`
- Add required permissions (already configured)

#### Windows Firewall
If network access is blocked:
- Allow app through Windows Firewall
- Check antivirus settings

## 🎯 Build Flags

### Debug vs Release

**Debug Build:**
- Larger size
- Slower performance
- Hot reload enabled
- Debug symbols included

```bash
flutter build <platform> --debug
```

**Release Build:**
- Optimized size
- Better performance
- No debug symbols
- Tree-shaking enabled

```bash
flutter build <platform> --release
```

### Additional Flags

```bash
# Verbose output
flutter build <platform> --verbose

# Specific target
flutter build <platform> --target=lib/main.dart

# Obfuscate (Android/iOS)
flutter build apk --obfuscate --split-debug-info=/<directory>
```

## 📄 Build Information

### Version Management

Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1
#         |     |
#         |     +-- Build number
#         +-------- Version name
```

### Build Variants

#### Android
```bash
# Debug
flutter build apk --debug

# Profile
flutter build apk --profile

# Release
flutter build apk --release
```

## 🔐 Code Signing

### iOS/macOS
- Requires Apple Developer Program membership
- Configure in Xcode project settings
- Use automatic signing (recommended) or manual

### Android
- Use keystore for signing
- Store keystore securely
- Never commit keystore to version control

### Windows
- Optional: Use Authenticode certificate
- Improves user trust
- Recommended for distribution

## 📊 CI/CD Integration

### GitHub Actions Example
See `.github/workflows/build.yml` for automated builds

### Supported CI Platforms
- GitHub Actions ✅
- GitLab CI ✅
- Travis CI ✅
- CircleCI ✅

## 🆘 Support

For build issues:
1. Check Flutter doctor: `flutter doctor -v`
2. Review error logs
3. Check GitHub Issues
4. Consult Flutter documentation

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Desktop](https://docs.flutter.dev/desktop)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Flutter Android Deployment](https://docs.flutter.dev/deployment/android)

---

**Last Updated:** 2025-10-17
**Flutter Version:** 3.35.5
**Dart Version:** 3.9.2
