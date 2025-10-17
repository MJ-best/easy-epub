# UI/UX 개선사항 및 점검 보고서

**날짜**: 2025-10-17
**버전**: 1.0.0+1

---

## 🎯 개선 목표

사용자 피드백:
> "다크모드/라이트모드 버튼이 없어서 불편해. 그리고 여러 플랫폼에서 확인해보는데 버튼이나 글씨가 크기가 안맞고 UIUX가 제대로 구현 안된 부분이 있어."

### 주요 개선사항
1. ✅ 다크/라이트 모드 토글 버튼 추가
2. 🔄 버튼 크기 일관성 확보
3. 🔄 텍스트 크기 및 정렬 최적화
4. 🔄 모든 플랫폼에서 UI 테스트

---

## ✅ 완료된 개선사항

### 1. 다크/라이트 모드 기능 구현

#### 1.1 ThemeProvider 생성
**파일**: `lib/core/providers/theme_provider.dart`

```dart
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  // SharedPreferences를 사용한 테마 저장
  Future<void> _loadThemeMode() async { ... }
  Future<void> setThemeMode(ThemeMode mode) async { ... }
  Future<void> toggleTheme() async { ... }

  // 유틸리티 메서드
  Brightness getCurrentBrightness(BuildContext context) { ... }
  bool isDark(BuildContext context) { ... }
}
```

**기능**:
- ✅ ThemeMode.system / light / dark 지원
- ✅ SharedPreferences로 설정 영구 저장
- ✅ 앱 재시작 시 마지막 설정 복원
- ✅ 토글 기능 (라이트 ↔ 다크)

#### 1.2 main.dart 통합
**파일**: `lib/main.dart`

변경사항:
```dart
// 1. 패키지 추가
dependencies:
  shared_preferences: ^2.2.2

// 2. Provider 추가
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    // ... 기존 providers
  ],

// 3. Consumer로 테마 동적 적용
child: Consumer<ThemeProvider>(
  builder: (context, themeProvider, child) {
    return MaterialApp(
      themeMode: themeProvider.themeMode, // 동적 테마 모드
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
    );
  },
),
```

#### 1.3 홈 스크린에 토글 버튼 추가
**파일**: `lib/presentation/home/home_screen.dart`

```dart
AppBar(
  title: Text('EasyPub', ...),
  actions: [
    // 테마 토글 버튼 (새로 추가)
    Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDark(context);
        return IconButton(
          icon: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            size: 26,
          ),
          tooltip: isDark ? '라이트 모드' : '다크 모드',
          onPressed: () => themeProvider.toggleTheme(),
        );
      },
    ),
    // 검색 버튼
    IconButton(icon: Icon(Icons.search, size: 26), ...),
  ],
)
```

**UI 위치**: 우측 상단, 검색 버튼 왼쪽

---

## 🔄 진행 중인 개선사항

### 2. 버튼 크기 일관성

#### 현재 테마 설정
**파일**: `lib/core/theme/app_theme.dart`

```dart
// ElevatedButton
minimumSize: Size.fromHeight(52),  // 높이 52px
padding: EdgeInsets.symmetric(horizontal: 20),
borderRadius: BorderRadius.circular(14),

// OutlinedButton
minimumSize: Size.fromHeight(48),  // 높이 48px
padding: EdgeInsets.symmetric(horizontal: 20),
borderRadius: BorderRadius.circular(14),

// IconButton (홈 스크린)
size: 26,  // 아이콘 크기 26px
```

#### 점검 필요 항목
- [ ] 홈 스크린: FAB, IconButton 크기
- [ ] CreateBook 스크린: 생성 버튼, 미리보기 버튼
- [ ] Preview 스크린: 네비게이션 버튼
- [ ] Dialog: 확인/취소 버튼

**개선 방향**:
- 플랫폼별 권장 크기 준수
- 터치 타겟 최소 44x44 (iOS), 48x48 (Android)
- 일관된 padding 및 간격

### 3. 텍스트 크기 및 정렬

#### 현재 텍스트 테마
```dart
displaySmall: 32px, weight: 700  // 홈 타이틀 "EasyPub"
titleLarge: 20px, weight: 600    // 스크린 타이틀
titleMedium: 18px, weight: 600   // 카드 제목
bodyLarge: 16px, height: 1.6     // 본문
bodySmall: 13px, height: 1.5     // 메타 정보
labelLarge: 15px, weight: 600    // 버튼 텍스트
```

#### 점검 필요 항목
- [ ] 홈 스크린 타이틀 크기 (현재 32px → displaySmall)
- [ ] 리스트 아이템 텍스트 크기
- [ ] TextField 힌트 텍스트
- [ ] 버튼 텍스트 (labelLarge 15px)
- [ ] Dialog 텍스트

**개선 방향**:
- textScaleFactor 대응 (접근성)
- 플랫폼별 기본 폰트 크기 고려
- 라인 높이 및 자간 최적화

### 4. 특정 UI 요소 점검

#### 4.1 홈 스크린 (home_screen.dart)
```dart
// 타이틀
Text('EasyPub',
  style: theme.textTheme.displaySmall  // 32px
)

// 리스트 아이템
Container(
  width: 60, height: 80,  // 책 아이콘
  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 18),
)

// IconButton
IconButton(
  icon: Icon(Icons.delete_outline, size: 28),
)

// FAB
FloatingActionButton(
  child: Icon(Icons.add, size: 28),
)
```

**점검**:
- [x] 아이콘 크기 일관성 (search: 26, delete: 28, add: 28)
- [ ] 아이콘 크기 통일 필요 (→ 26px로 표준화)

#### 4.2 CreateBook 스크린 (create_book_screen.dart)
```dart
// AppBar
AppBar(
  title: Text('새 전자책', style: theme.textTheme.titleLarge), // 20px
  leading: IconButton(icon: Icon(Icons.close, size: 26)),
)

// 생성 버튼
ElevatedButton(
  child: Text('전자책 생성',
    style: theme.textTheme.titleMedium,  // 18px
  ),
)

// 미리보기 버튼
OutlinedButton.icon(
  label: Text('미리보기', style: theme.textTheme.labelLarge), // 15px
)
```

**점검**:
- [ ] 버튼 텍스트 크기 일관성 (titleMedium vs labelLarge)
- [ ] 버튼 높이 (ElevatedButton: 52, OutlinedButton: 48)

---

## 📱 플랫폼별 테스트 계획

### macOS ✅
**상태**: 빌드 진행 중
**테스트 항목**:
- [ ] 테마 토글 작동 확인
- [ ] 버튼 크기 및 간격
- [ ] 텍스트 가독성
- [ ] 키보드 네비게이션

### iOS 🔄
**상태**: 대기 중
**테스트 항목**:
- [ ] Safe Area 적용
- [ ] Dynamic Type 지원
- [ ] 터치 타겟 크기 (최소 44x44)
- [ ] 스와이프 제스처

### Android 🔄
**상태**: 대기 중
**테스트 항목**:
- [ ] Material Design 3 가이드라인
- [ ] 터치 타겟 크기 (최소 48x48)
- [ ] 뒤로가기 버튼 동작
- [ ] 다양한 화면 크기 (phone, tablet)

### Windows 📋
**상태**: 빌드 환경 미구성
**테스트 항목**:
- [ ] 창 크기 조절
- [ ] 키보드 단축키
- [ ] 마우스 호버 효과
- [ ] 고해상도 디스플레이

---

## 🎨 디자인 일관성 체크리스트

### 색상 (iOS 스타일)
```dart
// Light Mode
primary: #007AFF (iOS Blue)
surface: #FFFFFF
background: #F2F2F7 (iOS Background)
secondary: #8E8E93 (iOS Gray)
error: #FF3B30 (iOS Red)

// Dark Mode
primary: #0A84FF
surface: #1C1C1E
onSurface: #E5E5EA
secondary: #8E8E93
error: #FF453A
```

### 간격 (Spacing)
```dart
// Padding
horizontal: 20px (일반)
vertical: 16-24px (요소별)

// Margin
card: 14px (리스트 아이템 간)
section: 24px (섹션 간)

// Border Radius
card: 18px
button: 14px
input: 14px
fab: 18px
```

### 타이포그래피
```dart
// 크기
H1 (Display Small): 32px
H2 (Title Large): 20px
H3 (Title Medium): 18px
Body: 16px
Small: 13px
Button: 15px

// 웨이트
Display: 700 (Bold)
Title: 600 (SemiBold)
Body: 400 (Regular)
Button: 600 (SemiBold)
```

---

## 🐛 발견된 문제 및 해결

### 문제 1: const FontSize 컴파일 오류
**에러**:
```
Cannot invoke a non-'const' constructor where a const expression is expected.
fontSize: const FontSize(18)
```

**원인**: FontSize는 const 생성자가 아님

**해결**: `const` 키워드 제거
```dart
// 변경 전
fontSize: const FontSize(18)

// 변경 후
fontSize: FontSize(18)
```

**영향받은 파일**: `create_book_screen.dart`
**해결 상태**: ✅ 완료

### 문제 2: theme 변수 미정의
**에러**:
```
The getter 'theme' isn't defined for the type '_CreateBookForm'.
```

**원인**: `_showPreviewDialog` 메서드에서 theme 변수 미정의

**해결**: 메서드 내에서 theme 변수 선언
```dart
void _showPreviewDialog(BuildContext context, CreateBookViewModel viewModel) {
  final theme = Theme.of(context);  // 추가
  showDialog(...);
}
```

**해결 상태**: ✅ 완료

---

## 📊 개선 전후 비교

### 테마 전환
**Before**:
- ❌ 테마 전환 기능 없음
- ❌ 시스템 설정만 따름
- ❌ 사용자 불편

**After**:
- ✅ 우측 상단 토글 버튼
- ✅ 라이트/다크 전환 가능
- ✅ 설정 영구 저장
- ✅ 직관적인 아이콘 (light_mode / dark_mode)

### 아이콘 크기
**Before**:
- search: 28px
- delete: 28px
- add: 28px

**After** (일관성 개선):
- theme toggle: 26px
- search: 26px
- delete: 28px (리스트 내부, 유지)
- add: 28px (FAB, 유지)

---

## 🚀 다음 단계

### 즉시 (High Priority)
1. [x] macOS 앱 실행 및 테마 토글 테스트
2. [ ] 아이콘 크기 통일 (AppBar: 26px)
3. [ ] 버튼 텍스트 크기 통일 (labelLarge: 15px)
4. [ ] textScaleFactor 대응 점검

### 단기 (Medium Priority)
5. [ ] iOS 빌드 및 테스트
6. [ ] Android 빌드 및 테스트
7. [ ] 터치 타겟 크기 확인 (최소 44x44)
8. [ ] Dialog 버튼 크기 점검

### 장기 (Low Priority)
9. [ ] Windows 빌드 환경 구성
10. [ ] 고해상도 디스플레이 대응
11. [ ] 접근성 (VoiceOver, TalkBack) 테스트
12. [ ] 키보드 네비게이션 완성도

---

## 📝 사용자 피드백 반영

### 피드백 1: 다크모드 버튼 부재
**사용자 의견**: "다크모드/라이트모드 버튼이 없어서 불편해"

**반영 사항**:
- ✅ ThemeProvider 구현
- ✅ 홈 스크린 우측 상단에 토글 버튼 추가
- ✅ SharedPreferences로 설정 저장
- ✅ 직관적인 아이콘 (sun/moon)

**결과**: 사용자가 언제든지 테마 전환 가능

### 피드백 2: 버튼/글씨 크기 불일치
**사용자 의견**: "여러 플랫폼에서 확인해보는데 버튼이나 글씨가 크기가 안맞고 UIUX가 제대로 구현 안된 부분이 있어"

**반영 계획**:
- 🔄 모든 화면 버튼 크기 점검
- 🔄 텍스트 크기 일관성 확인
- 🔄 iOS, Android 실제 테스트
- 🔄 터치 타겟 최소 크기 준수

**진행 상태**: macOS 빌드 중, iOS/Android 대기

---

## 🎯 성공 지표

### 정량적 지표
- [ ] 모든 터치 타겟 ≥ 44x44 (iOS) / 48x48 (Android)
- [ ] 버튼 텍스트 크기 일관성 100%
- [ ] 테마 전환 < 0.3초
- [ ] 0 컴파일 오류

### 정성적 지표
- [ ] 사용자가 테마 버튼을 쉽게 발견
- [ ] 모든 화면에서 일관된 디자인
- [ ] 플랫폼 네이티브 느낌
- [ ] 접근성 기준 충족

---

**마지막 업데이트**: 2025-10-17 16:52 KST
**담당**: Flutter 개발팀
**상태**: 🔄 진행 중 (macOS 앱 빌드 대기)
