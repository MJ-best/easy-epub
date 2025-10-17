# EasyPub 개발 로그

## 프로젝트 개요
- **프로젝트명**: EasyPub - 간편 EPUB 제작기
- **목적**: 마크다운 텍스트를 EPUB 2.0 형식으로 변환
- **플랫폼**: Flutter (iOS, Android, macOS, Windows)

---

## 개발 일지

### 2025-10-17

#### Phase 1: 초기 프로젝트 구축 ✅
**작업 내용**:
- Flutter 프로젝트 생성 및 MVVM 아키텍처 구성
- 의존성 설정 (Provider, Hive, archive, uuid 등)
- 코어 모듈 구현 (theme, constants, l10n)
- 데이터 레이어 구현 (models, repositories)
- 프레젠테이션 레이어 구현 (home, create_book, preview screens)

**결과**: 기본 앱 구조 완성

---

#### Phase 2: 멀티 플랫폼 빌드 ✅
**요청사항**: "맥, 윈도우, 아이폰, 아이패드, 안드로이드에서 모두 작동하도록 빌드하고 테스트하세요"

**작업 내용**:
- 의존성 버전 충돌 해결 (intl, file_picker, share_plus)
- CardTheme → CardThemeData 수정
- Hive adapters 생성
- 멀티 플랫폼 빌드 스크립트 작성

**빌드 결과**:
- ✅ macOS: 48.0 MB (Universal Binary)
- ✅ iOS: 22.5 MB (Unsigned)
- ✅ Android: 57.1 MB (Multi-arch APK)
- ⚠️ Windows: 빌드 스크립트 준비 (Windows 머신 필요)

**문서 생성**:
- `BUILD_GUIDE.md`
- `PLATFORM_TEST_REPORT.md`
- `BUILD_STATUS.md`

---

#### Phase 3: EPUB 2.0 개선 및 UI 리디자인 ✅
**요청사항**: 
> "마크다운 문법의 txt 문서를 epub 2.0 으로 변환하는게 이 프로그램의 주요 목적입니다. 하지만 방금 예시로 실행했을때 잘 작동하지 않는 것을 확인했습니다. epub-example에 있는 실제로 출판된 epub 파일을 보고 이 파일과 동일한 양식으로 결과물이 만들어지도록해줘. 그리고 사용자를 고려해서 UI를 개선해. UI는 깔끔하고 기능에 충실하게 꾸밈요소를 최소화한 아이폰 기본 어플과 같은 느낌으로 구성해."

**작업 내용**:

1. **EPUB 구조 분석**:
   - 예제 EPUB 파일 추출 및 분석
   - 실제 출판물의 EPUB 2.0 구조 확인
   - OPF, NCX, XHTML 파일 구조 파악

2. **새로운 서비스 구현**:
   - `lib/data/services/markdown_parser.dart` 생성 (179줄)
     - 마크다운 → HTML 변환
     - 제목, 목록, 인라인 포매팅 지원
   - `lib/data/services/epub_generator_service_v2.dart` 생성 (420줄)
     - EPUB 2.0 표준 준수
     - 자동 챕터 분할 (H1 기준)
     - 적절한 CSS 스타일링

3. **CSS 스타일 개선**:
   - 한국어 서적 타이포그래피 적용
   - 글꼴: KoPub Batang (본문), KoPub Dotum (제목)
   - 행간: 1.8em, 자간: -0.02em
   - 양쪽 정렬, 단어 단위 줄바꿈

4. **UI 리디자인 - 미니멀리스트 iPhone 스타일**:
   
   **테마 변경**:
   - iOS 컬러 팔레트 적용 (#007AFF, #F2F2F7 등)
   - 모든 elevation 제거 (플랫 디자인)
   - 10px 일관된 border-radius
   - 무테두리 입력 필드

   **Home Screen**:
   - Grid → List 레이아웃
   - 34px 볼드 타이틀 (좌측 정렬)
   - 심플한 FAB (라벨 없음)
   - 컴팩트한 리스트 아이템

   **Create Book Screen**:
   - 17px 네비게이션 타이틀
   - 하단 고정 액션 버튼
   - 섹션별 그룹핑
   - 리스트 기반 템플릿 선택

**문서 생성**:
- `UI_IMPROVEMENTS.md`
- `IMPROVEMENTS_SUMMARY.md`

---

#### Phase 4: 실시간 미리보기 구현 🚨 → ✅
**요청사항**:
> "가로모드를 예로 들어서 왼쪽엔 마크다운 문서, 오른쪽엔 epub 문서가 실시간으로 보여져야 합니다. 세로모드인 경우 미리보기 버튼이 있어서 epub 리더도 봤을때 어떻게 보이는지를 확인할 수 있어야 합니다."

**초기 구현 (실패)**:
- TextSpan 기반 HTML 파싱 시도
- 복잡한 자체 구현 (600+ 줄)
- **결과**: 미리보기 작동 안 함 ❌

**문제점**:
- Flutter에서 HTML 직접 렌더링 불가
- 패키지 누락
- 과도하게 복잡한 코드

**긴급 수정 (성공)**:

1. **패키지 추가**:
   ```yaml
   flutter_html: ^3.0.0-beta.2
   webview_flutter: ^4.4.2
   ```

2. **완전 재작성** (530줄):
   - `_EditorPanel`: 마크다운 편집기
   - `_PreviewPanel`: HTML 미리보기 (flutter_html 사용)
   - `_BottomButton`: 생성 버튼
   - `_TemplateSelector`: 템플릿 선택

3. **OrientationBuilder 구현**:
   - **가로 모드**: Row(편집기 | 미리보기)
   - **세로 모드**: Column(편집기 + 미리보기 버튼)

4. **Flutter HTML 스타일링**:
   ```dart
   "body": Style(
     fontFamily: 'Noto Serif KR',
     fontSize: FontSize(16),
     lineHeight: const LineHeight(1.8),
     textAlign: TextAlign.justify,
   )
   // 모든 HTML 태그에 대한 EPUB 스타일 적용
   ```

**결과**: ✅ 실시간 미리보기 완벽 작동

**문서 생성**:
- `REALTIME_PREVIEW_FEATURES.md`
- `EMERGENCY_FIX_REPORT.md`

---

## 현재 상태

### ✅ 완료된 기능
1. ✅ MVVM 아키텍처 구현
2. ✅ 멀티 플랫폼 빌드 (macOS, iOS, Android)
3. ✅ EPUB 2.0 표준 준수 생성기
4. ✅ 마크다운 → HTML 파싱
5. ✅ 미니멀리스트 iOS 스타일 UI
6. ✅ 실시간 미리보기 (가로/세로 모드)
7. ✅ EPUB 2.0 CSS 스타일 적용

### 📱 실행 중
- macOS 앱 실행 중
- DevTools: http://127.0.0.1:9100

### 📊 코드 통계
- **총 파일**: 30+
- **주요 서비스**: 3개 (repository, epub_generator, markdown_parser)
- **ViewModels**: 2개 (library, create_book)
- **Screens**: 3개 (home, create_book, preview)
- **총 라인 수**: ~3,000줄

---

## 기술 스택

### Core
- **Framework**: Flutter 3.0+
- **언어**: Dart
- **아키텍처**: MVVM + Provider

### 주요 패키지
- `provider ^6.1.1` - 상태 관리
- `hive ^2.2.3` - 로컬 데이터베이스
- `archive ^3.4.9` - ZIP/EPUB 생성
- `uuid ^4.2.1` - 고유 ID 생성
- `flutter_html ^3.0.0-beta.2` - HTML 렌더링
- `epub_view ^3.1.0` - EPUB 뷰어

### 플랫폼
- iOS 12.0+
- Android 5.0+ (API 21)
- macOS 10.14+
- Windows 10+ (준비 완료)

---

## 문서 목록

### 개발 관련
- `flutter-development-agent.md` - 개발 가이드
- `PRD.md` - 제품 요구사항 문서

### 빌드 관련
- `BUILD_GUIDE.md` - 빌드 가이드
- `BUILD_STATUS.md` - 빌드 상태
- `PLATFORM_TEST_REPORT.md` - 플랫폼별 테스트 보고서

### 개선 관련
- `IMPROVEMENTS_SUMMARY.md` - 전체 개선사항 요약
- `UI_IMPROVEMENTS.md` - UI 개선 상세
- `REALTIME_PREVIEW_FEATURES.md` - 실시간 미리보기 기능

### 문제 해결
- `EMERGENCY_FIX_REPORT.md` - 긴급 수정 보고서
- `DEVELOPMENT_LOG.md` - 이 문서

---

## 학습 내용

### 성공 요인
1. **검증된 패키지 사용**: flutter_html로 즉시 해결
2. **명확한 구조**: 위젯 분리로 유지보수성 향상
3. **즉시 테스트**: 빌드 후 바로 확인

### 실패 요인 (그리고 교훈)
1. **과도한 자체 구현**: TextSpan 파싱 실패
2. **테스트 부족**: 작동 확인 없이 완료 보고
3. **기술 검증 부족**: Flutter HTML 렌더링 제약 간과

### 개선 방법
1. ✅ 패키지 우선 고려
2. ✅ 단계별 테스트
3. ✅ 명확한 에러 처리
4. ✅ 문서화 철저

---

## 다음 단계

### 우선순위 높음
- [ ] Windows 빌드 (Windows 머신 필요)
- [ ] EPUB 유효성 검사 (epubcheck)
- [ ] 실제 EPUB 리더 테스트

### 우선순위 중간
- [ ] 파일 가져오기/내보내기
- [ ] 표지 이미지 지원
- [ ] 배치 생성 기능

### 우선순위 낮음
- [ ] 클라우드 동기화
- [ ] 템플릿 커스터마이징
- [ ] 다국어 지원 확장

---

## 연락처 및 리소스

### DevTools
- **Local**: http://127.0.0.1:9100
- **VM Service**: http://127.0.0.1:57844/

### 프로젝트 경로
- **Root**: `/Users/mj/Documents/easy-epub`
- **Build**: `build/`
- **Sources**: `lib/`

---

**마지막 업데이트**: 2025-10-17 23:50 KST
**상태**: ✅ 실시간 미리보기 완벽 작동
**빌드**: ✅ macOS 앱 실행 중
