# EasyPub - 간편 EPUB 제작기

Flutter 기반의 간단한 EPUB 전자책 생성 애플리케이션입니다.

## 주요 기능

- **EPUB 생성**: 텍스트 입력 후 자동으로 EPUB 전자책 생성
- **템플릿 시스템**: 소설형, 수필형, 매뉴얼형 등 다양한 스타일 제공
- **미리보기**: 내장된 EPUB 뷰어로 실시간 미리보기
- **라이브러리 관리**: 생성된 전자책 목록 관리 및 검색
- **공유 기능**: 생성된 EPUB 파일 공유

## 아키텍처

이 프로젝트는 Flutter 개발 가이드라인을 따르며 다음 구조를 사용합니다:

```
lib/
├── core/           # 공통 유틸리티, 상수, 테마
├── data/           # 데이터 모델, 리포지토리 구현, 서비스
├── domain/         # 비즈니스 로직, 엔티티, 리포지토리 인터페이스
└── presentation/   # UI, 위젯, ViewModel
```

### 핵심 원칙

- **MVVM 패턴**: View-ViewModel 분리로 유지보수성 향상
- **Repository 패턴**: 데이터 접근 추상화
- **Dependency Injection**: Provider를 통한 DI
- **Material 3 디자인**: 최신 Material Design 3 적용
- **접근성**: 시맨틱 레이블, 44x44 터치 타겟, 명암비 준수

## 시작하기

### 1. 의존성 설치

```bash
flutter pub get
```

### 2. Hive 코드 생성

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. 앱 실행

```bash
flutter run
```

## 기술 스택

| 항목 | 기술 |
|------|------|
| Framework | Flutter 3.x |
| 상태 관리 | Provider |
| 로컬 DB | Hive |
| EPUB 뷰어 | epub_view |
| 린팅 | flutter_lints |
| 국제화 | flutter_localizations, intl |

## 개발 가이드

### 코드 스타일

- **Effective Dart** 준수
- 모든 public API 문서화 (`///` 사용)
- 클래스: `UpperCamelCase`
- 함수/변수: `lowerCamelCase`
- 상수: `SCREAMING_SNAKE_CASE`
- Private: `_underscorePrefix`

### 린팅

프로젝트는 `flutter_lints`를 사용하여 코드 품질을 유지합니다:

```bash
flutter analyze
```

### 테스트

```bash
# 단위 테스트
flutter test

# 위젯 테스트
flutter test test/widget/

# 통합 테스트
flutter test test/integration/
```

## 프로젝트 구조 상세

### Data Layer
- `models/`: Hive 데이터 모델
- `repositories/`: Repository 구현
- `services/`: EPUB 생성 등 비즈니스 서비스

### Domain Layer
- `repositories/`: Repository 인터페이스

### Presentation Layer
- `home/`: 홈 화면 (라이브러리)
- `create_book/`: 전자책 생성 화면
- `preview/`: EPUB 미리보기 화면
- `viewmodels/`: ChangeNotifier 기반 ViewModel

### Core Layer
- `constants/`: 앱 상수
- `theme/`: Material 3 테마 설정
- `l10n/`: 다국어 지원 (한국어, 영어)

## 템플릿

### 1. 소설형
- 세리프 글꼴
- 들여쓰기 포함
- 중앙 정렬 제목

### 2. 수필형
- 산세리프 글꼴
- 깔끔한 레이아웃
- 편안한 가독성

### 3. 매뉴얼형
- 구조화된 레이아웃
- 제목 강조
- 목록 지원

## 접근성

이 앱은 다음 접근성 기능을 제공합니다:

- 모든 인터랙티브 요소에 시맨틱 레이블 제공
- 최소 44x44 터치 타겟 크기
- WCAG 명암비 기준 준수
- 다크/라이트 모드 자동 전환

## 라이선스

MIT License

## 기여

Pull Request와 이슈 제보를 환영합니다!

## 문의

이슈 트래커를 통해 버그 리포트나 기능 요청을 해주세요.
