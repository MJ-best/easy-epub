# EasyPub 설치 및 실행 가이드

## 사전 요구사항

1. **Flutter SDK 설치** (3.0.0 이상)
   ```bash
   flutter --version
   ```

2. **개발 환경 설정**
   - Android Studio 또는 VS Code
   - iOS 개발 시 Xcode (macOS만 해당)

## 설치 단계

### 1. 의존성 설치

```bash
cd easy-epub
flutter pub get
```

### 2. 폰트 파일 추가

`assets/fonts/` 디렉토리에 다음 폰트 파일을 추가하세요:
- NotoSansKR-Regular.ttf
- NotoSansKR-Bold.ttf

폰트 다운로드: https://fonts.google.com/noto/specimen/Noto+Sans+KR

### 3. Hive 코드 생성

Hive TypeAdapter를 생성하기 위해 다음 명령을 실행하세요:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

이 명령은 `lib/data/models/ebook_model.g.dart` 파일을 생성합니다.

### 4. 앱 실행

```bash
# 사용 가능한 디바이스 확인
flutter devices

# 앱 실행
flutter run
```

특정 디바이스에서 실행:
```bash
flutter run -d <device_id>
```

## 문제 해결

### 1. Hive 코드 생성 오류

```bash
# 캐시 정리 후 재생성
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. 폰트 로드 오류

`pubspec.yaml`의 폰트 경로가 올바른지 확인하고, 실제 폰트 파일이 `assets/fonts/` 디렉토리에 있는지 확인하세요.

임시로 폰트를 제거하려면:
1. `pubspec.yaml`의 `fonts` 섹션 주석 처리
2. `lib/core/theme/app_theme.dart`에서 `fontFamily: 'NotoSansKR'` 제거

### 3. 의존성 충돌

```bash
flutter pub upgrade --major-versions
```

### 4. iOS 빌드 오류

```bash
cd ios
pod install
cd ..
flutter run
```

## 개발 환경 설정

### VS Code

권장 확장 프로그램:
- Flutter
- Dart
- Error Lens

`.vscode/settings.json`:
```json
{
  "dart.lineLength": 100,
  "editor.formatOnSave": true,
  "editor.rulers": [100]
}
```

### Android Studio

권장 플러그인:
- Flutter
- Dart

## 빌드

### Android APK 빌드

```bash
flutter build apk --release
```

결과 파일: `build/app/outputs/flutter-apk/app-release.apk`

### iOS IPA 빌드

```bash
flutter build ios --release
```

## 테스트

```bash
# 모든 테스트 실행
flutter test

# 특정 테스트 파일 실행
flutter test test/unit/ebook_repository_test.dart

# 커버리지와 함께 실행
flutter test --coverage
```

## 코드 품질

### 린트 실행

```bash
flutter analyze
```

### 포맷팅

```bash
# 모든 Dart 파일 포맷
dart format lib/ test/

# 특정 파일만 포맷
dart format lib/main.dart
```

## 주요 파일 구조

```
lib/
├── main.dart                          # 앱 진입점
├── core/
│   ├── constants/app_constants.dart   # 앱 상수
│   ├── theme/app_theme.dart           # Material 3 테마
│   └── l10n/                          # 다국어 리소스
├── data/
│   ├── models/
│   │   ├── ebook_model.dart           # Hive 모델
│   │   └── template_type.dart         # 템플릿 정의
│   ├── repositories/
│   │   └── ebook_repository_impl.dart # Repository 구현
│   └── services/
│       └── epub_generator_service.dart # EPUB 생성 서비스
├── domain/
│   └── repositories/
│       └── ebook_repository.dart      # Repository 인터페이스
└── presentation/
    ├── home/home_screen.dart          # 홈 화면
    ├── create_book/
    │   └── create_book_screen.dart    # 전자책 생성 화면
    ├── preview/preview_screen.dart    # 미리보기 화면
    └── viewmodels/                    # ViewModel 레이어
        ├── library_viewmodel.dart
        └── create_book_viewmodel.dart
```

## 다음 단계

1. 폰트 파일 추가
2. `flutter pub run build_runner build` 실행
3. `flutter run` 으로 앱 실행
4. 첫 전자책 만들어보기!

## 참고 자료

- [Flutter 공식 문서](https://flutter.dev/docs)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Material Design 3](https://m3.material.io/)
- [Provider 패키지](https://pub.dev/packages/provider)
- [Hive 문서](https://docs.hivedb.dev/)
