/// eBook template types as defined in PRD
enum TemplateType {
  novel,
  essay,
  manual;

  /// Get display name for template
  String get displayName {
    switch (this) {
      case TemplateType.novel:
        return '소설형';
      case TemplateType.essay:
        return '수필형';
      case TemplateType.manual:
        return '매뉴얼형';
    }
  }

  /// Human-readable description for UI preview
  String get description {
    switch (this) {
      case TemplateType.novel:
        return '세리프 서체와 여백을 강조한 전통적인 독서 경험';
      case TemplateType.essay:
        return '가독성 높은 산세리프 서체와 균형 잡힌 문단 구성';
      case TemplateType.manual:
        return '정보 전달을 위한 구조화된 제목과 리스트 스타일';
    }
  }

  /// Get CSS styles for template
  String get cssStyle {
    switch (this) {
      case TemplateType.novel:
        return '''
          body {
            font-family: 'Noto Serif KR', serif;
            font-size: 1.1em;
            line-height: 1.8;
            text-align: justify;
            padding: 2em;
            color: #2c2c2c;
          }
          h1, h2 {
            text-align: center;
            margin-top: 2em;
            margin-bottom: 1em;
            font-weight: bold;
          }
          p {
            text-indent: 1em;
            margin-bottom: 0.8em;
          }
        ''';
      case TemplateType.essay:
        return '''
          body {
            font-family: 'Noto Sans KR', sans-serif;
            font-size: 1em;
            line-height: 1.7;
            padding: 1.5em;
            color: #333;
          }
          h1, h2 {
            margin-top: 1.5em;
            margin-bottom: 0.8em;
            font-weight: 600;
          }
          p {
            margin-bottom: 1em;
          }
        ''';
      case TemplateType.manual:
        return '''
          body {
            font-family: 'Noto Sans KR', sans-serif;
            font-size: 0.95em;
            line-height: 1.6;
            padding: 1em;
            color: #1a1a1a;
          }
          h1 {
            background-color: #f0f0f0;
            padding: 0.5em;
            border-left: 4px solid #6750A4;
            font-size: 1.5em;
            margin-top: 1em;
            margin-bottom: 0.5em;
          }
          h2 {
            border-bottom: 2px solid #e0e0e0;
            padding-bottom: 0.3em;
            margin-top: 1.2em;
            margin-bottom: 0.6em;
            font-size: 1.3em;
          }
          p {
            margin-bottom: 0.8em;
          }
          ul, ol {
            margin-left: 1.5em;
            margin-bottom: 1em;
          }
        ''';
    }
  }

  /// Convert from string
  static TemplateType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'novel':
        return TemplateType.novel;
      case 'essay':
        return TemplateType.essay;
      case 'manual':
        return TemplateType.manual;
      default:
        return TemplateType.novel;
    }
  }
}
