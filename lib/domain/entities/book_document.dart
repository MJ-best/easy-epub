import 'dart:convert';
import 'dart:typed_data';

class BookDocument {
  BookDocument({
    required this.schemaVersion,
    required this.metadata,
    required this.body,
    required this.presentation,
    this.cover,
  });

  factory BookDocument.empty() {
    final now = DateTime.now();
    return BookDocument(
      schemaVersion: 1,
      metadata: BookMetadata(
        id: '',
        title: '',
        author: '',
        language: 'ko',
        createdAt: now,
        modifiedAt: now,
      ),
      body: const BookBody(
        sourceFormat: 'markdown',
        sourceMarkdown: '',
      ),
      presentation: const BookPresentation(templateType: 'novel'),
    );
  }

  factory BookDocument.fromJson(Map<String, dynamic> json) {
    return BookDocument(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      metadata: BookMetadata.fromJson(
        (json['metadata'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      body: BookBody.fromJson(
        (json['body'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      presentation: BookPresentation.fromJson(
        (json['presentation'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      cover: json['cover'] is Map<String, dynamic>
          ? BookCover.fromJson(json['cover'] as Map<String, dynamic>)
          : json['cover'] is Map
              ? BookCover.fromJson(
                  (json['cover'] as Map).cast<String, dynamic>(),
                )
              : null,
    );
  }

  final int schemaVersion;
  final BookMetadata metadata;
  final BookBody body;
  final BookPresentation presentation;
  final BookCover? cover;

  String get title => metadata.title;
  String get author => metadata.author;
  String get language => metadata.language;
  String get rawMarkdown => body.sourceMarkdown;
  String get templateType => presentation.templateType;
  String? get customCss => presentation.customCss;
  String? get customCssSourceName => presentation.customCssSourceName;
  String? get styleReferenceTitle => presentation.referenceTitle;
  String? get styleReferenceAuthor => presentation.referenceAuthor;
  List<ImportedFontAsset> get importedFonts => presentation.importedFonts;
  List<StructureReferenceEntry> get structureReference =>
      presentation.structureReference;
  StyleClassHints get styleClassHints => presentation.styleClassHints;
  Uint8List? get coverBytes => cover?.bytes;
  String? get coverMimeType => cover?.mimeType;
  bool get hasCover => cover?.bytes.isNotEmpty == true;
  bool get hasCustomCss => customCss?.trim().isNotEmpty == true;
  bool get hasImportedFonts => importedFonts.isNotEmpty;
  bool get hasStructureReference => structureReference.isNotEmpty;

  List<BookChapter> get chapters => BookStructureParser.splitChapters(
        body.sourceMarkdown,
        fallbackTitle: metadata.title.trim().isEmpty ? '본문' : metadata.title,
        structureReference: structureReference,
      );

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'metadata': metadata.toJson(),
      'body': body
          .normalized(
            chapters: chapters,
          )
          .toJson(),
      'presentation': presentation.toJson(),
      if (cover != null) 'cover': cover!.toJson(),
    };
  }

  BookDocument copyWith({
    int? schemaVersion,
    BookMetadata? metadata,
    BookBody? body,
    BookPresentation? presentation,
    BookCover? cover,
    bool clearCover = false,
  }) {
    return BookDocument(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
      body: body ?? this.body,
      presentation: presentation ?? this.presentation,
      cover: clearCover ? null : cover ?? this.cover,
    );
  }

  BookDocument updateTitle(String value) {
    return copyWith(
      metadata: metadata.copyWith(title: value),
    );
  }

  BookDocument updateAuthor(String value) {
    return copyWith(
      metadata: metadata.copyWith(author: value),
    );
  }

  BookDocument updateMarkdown(String value) {
    return copyWith(
      body: body.copyWith(sourceMarkdown: value),
    );
  }

  BookDocument updateTemplateType(String value) {
    return copyWith(
      presentation: presentation.copyWith(templateType: value),
    );
  }

  BookDocument updateCustomCss({
    String? css,
    String? sourceName,
    String? referenceTitle,
    String? referenceAuthor,
    List<ImportedFontAsset>? fonts,
    List<StructureReferenceEntry>? structureReference,
    StyleClassHints? styleClassHints,
  }) {
    return applyStyleReference(
      css: css,
      sourceName: sourceName,
      referenceTitle: referenceTitle,
      referenceAuthor: referenceAuthor,
      fonts: fonts ?? presentation.importedFonts,
      structureReference: structureReference ?? presentation.structureReference,
      styleClassHints: styleClassHints ?? presentation.styleClassHints,
    );
  }

  BookDocument applyStyleReference({
    String? css,
    String? sourceName,
    String? referenceTitle,
    String? referenceAuthor,
    List<ImportedFontAsset> fonts = const [],
    List<StructureReferenceEntry> structureReference = const [],
    StyleClassHints styleClassHints = const StyleClassHints(),
  }) {
    return copyWith(
      presentation: presentation.copyWith(
        customCss: css,
        customCssSourceName: sourceName,
        referenceTitle: referenceTitle,
        referenceAuthor: referenceAuthor,
        importedFonts: fonts,
        structureReference: structureReference,
        styleClassHints: styleClassHints,
      ),
    );
  }

  BookDocument clearStyleReference({
    bool clearStructureReference = true,
  }) {
    return copyWith(
      presentation: BookPresentation(
        templateType: presentation.templateType,
        structureReference: clearStructureReference
            ? const []
            : presentation.structureReference,
      ),
    );
  }

  String buildStructureReferenceMarkdown({
    bool includeBodyPlaceholders = true,
  }) {
    if (structureReference.isEmpty) {
      return '';
    }

    return structureReference
        .map(
          (entry) => _buildStructureEntryMarkdown(
            entry,
            includeBodyPlaceholder: includeBodyPlaceholders,
          ),
        )
        .join('\n\n')
        .trim();
  }

  String _buildStructureEntryMarkdown(
    StructureReferenceEntry entry, {
    required bool includeBodyPlaceholder,
  }) {
    final level = entry.level.clamp(1, 3);
    final headingPrefix = '#' * level;
    final buffer = StringBuffer()..writeln('$headingPrefix ${entry.title}');

    if (includeBodyPlaceholder) {
      buffer.write(_bodyPlaceholderForLevel(level));
    }

    return buffer.toString().trimRight();
  }

  String _bodyPlaceholderForLevel(int level) {
    switch (level) {
      case 1:
        return '\n\n챕터 내용을 작성하세요.';
      case 2:
        return '\n\n섹션 내용을 작성하세요.';
      case 3:
      default:
        return '\n\n세부 내용을 작성하세요.';
    }
  }

  BookDocument updateCover({
    Uint8List? bytes,
    String? mimeType,
    String? fileName,
  }) {
    if (bytes == null || bytes.isEmpty) {
      return copyWith(clearCover: true);
    }

    return copyWith(
      cover: BookCover(
        fileName: fileName ?? 'cover',
        mimeType: mimeType ?? 'image/jpeg',
        bytes: bytes,
      ),
    );
  }

  BookDocument withIdentity({
    required String id,
    required DateTime createdAt,
    required DateTime modifiedAt,
  }) {
    return copyWith(
      metadata: metadata.copyWith(
        id: id,
        createdAt: createdAt,
        modifiedAt: modifiedAt,
      ),
    );
  }

  BookDocument touch([DateTime? at]) {
    return copyWith(
      metadata: metadata.copyWith(
        modifiedAt: at ?? DateTime.now(),
      ),
    );
  }
}

class BookMetadata {
  const BookMetadata({
    required this.id,
    required this.title,
    required this.author,
    required this.language,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory BookMetadata.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return BookMetadata(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      language: json['language'] as String? ?? 'ko',
      createdAt: _parseDate(json['createdAt']) ?? now,
      modifiedAt: _parseDate(json['modifiedAt']) ?? now,
    );
  }

  final String id;
  final String title;
  final String author;
  final String language;
  final DateTime createdAt;
  final DateTime modifiedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'language': language,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }

  BookMetadata copyWith({
    String? id,
    String? title,
    String? author,
    String? language,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return BookMetadata(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }
}

class BookBody {
  const BookBody({
    required this.sourceFormat,
    required this.sourceMarkdown,
    this.chapters = const [],
  });

  factory BookBody.fromJson(Map<String, dynamic> json) {
    final chapters = (json['chapters'] as List? ?? const [])
        .whereType<Map>()
        .map((entry) => BookChapter.fromJson(entry.cast<String, dynamic>()))
        .toList();

    return BookBody(
      sourceFormat: json['sourceFormat'] as String? ?? 'markdown',
      sourceMarkdown: json['sourceMarkdown'] as String? ?? '',
      chapters: chapters,
    );
  }

  final String sourceFormat;
  final String sourceMarkdown;
  final List<BookChapter> chapters;

  Map<String, dynamic> toJson() {
    return {
      'sourceFormat': sourceFormat,
      'sourceMarkdown': sourceMarkdown,
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
    };
  }

  BookBody copyWith({
    String? sourceFormat,
    String? sourceMarkdown,
    List<BookChapter>? chapters,
  }) {
    return BookBody(
      sourceFormat: sourceFormat ?? this.sourceFormat,
      sourceMarkdown: sourceMarkdown ?? this.sourceMarkdown,
      chapters: chapters ?? this.chapters,
    );
  }

  BookBody normalized({
    required List<BookChapter> chapters,
  }) {
    return copyWith(chapters: chapters);
  }
}

class BookPresentation {
  const BookPresentation({
    required this.templateType,
    this.customCss,
    this.customCssSourceName,
    this.referenceTitle,
    this.referenceAuthor,
    this.importedFonts = const [],
    this.structureReference = const [],
    this.styleClassHints = const StyleClassHints(),
  });

  factory BookPresentation.fromJson(Map<String, dynamic> json) {
    return BookPresentation(
      templateType: json['templateType'] as String? ?? 'novel',
      customCss: json['customCss'] as String?,
      customCssSourceName: json['customCssSourceName'] as String?,
      referenceTitle: json['referenceTitle'] as String?,
      referenceAuthor: json['referenceAuthor'] as String?,
      importedFonts: (json['importedFonts'] as List? ?? const [])
          .whereType<Map>()
          .map((entry) =>
              ImportedFontAsset.fromJson(entry.cast<String, dynamic>()))
          .toList(),
      structureReference: (json['structureReference'] as List? ?? const [])
          .whereType<Map>()
          .map((entry) =>
              StructureReferenceEntry.fromJson(entry.cast<String, dynamic>()))
          .toList(),
      styleClassHints: json['styleClassHints'] is Map<String, dynamic>
          ? StyleClassHints.fromJson(
              json['styleClassHints'] as Map<String, dynamic>)
          : json['styleClassHints'] is Map
              ? StyleClassHints.fromJson(
                  (json['styleClassHints'] as Map).cast<String, dynamic>(),
                )
              : const StyleClassHints(),
    );
  }

  final String templateType;
  final String? customCss;
  final String? customCssSourceName;
  final String? referenceTitle;
  final String? referenceAuthor;
  final List<ImportedFontAsset> importedFonts;
  final List<StructureReferenceEntry> structureReference;
  final StyleClassHints styleClassHints;

  Map<String, dynamic> toJson() {
    return {
      'templateType': templateType,
      if (customCss != null) 'customCss': customCss,
      if (customCssSourceName != null)
        'customCssSourceName': customCssSourceName,
      if (referenceTitle != null) 'referenceTitle': referenceTitle,
      if (referenceAuthor != null) 'referenceAuthor': referenceAuthor,
      if (importedFonts.isNotEmpty)
        'importedFonts': importedFonts.map((font) => font.toJson()).toList(),
      if (structureReference.isNotEmpty)
        'structureReference':
            structureReference.map((entry) => entry.toJson()).toList(),
      if (!styleClassHints.isEmpty) 'styleClassHints': styleClassHints.toJson(),
    };
  }

  BookPresentation copyWith({
    String? templateType,
    String? customCss,
    String? customCssSourceName,
    String? referenceTitle,
    String? referenceAuthor,
    List<ImportedFontAsset>? importedFonts,
    List<StructureReferenceEntry>? structureReference,
    StyleClassHints? styleClassHints,
  }) {
    return BookPresentation(
      templateType: templateType ?? this.templateType,
      customCss: customCss ?? this.customCss,
      customCssSourceName: customCssSourceName ?? this.customCssSourceName,
      referenceTitle: referenceTitle ?? this.referenceTitle,
      referenceAuthor: referenceAuthor ?? this.referenceAuthor,
      importedFonts: importedFonts ?? this.importedFonts,
      structureReference: structureReference ?? this.structureReference,
      styleClassHints: styleClassHints ?? this.styleClassHints,
    );
  }
}

class StyleClassHints {
  const StyleClassHints({
    this.headingLevel1 = const [],
    this.headingLevel2 = const [],
    this.headingLevel3 = const [],
    this.paragraph = const [],
    this.blockquote = const [],
    this.unorderedList = const [],
    this.orderedList = const [],
  });

  factory StyleClassHints.fromJson(Map<String, dynamic> json) {
    List<String> readList(String key) {
      return (json[key] as List? ?? const [])
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    }

    return StyleClassHints(
      headingLevel1: readList('headingLevel1'),
      headingLevel2: readList('headingLevel2'),
      headingLevel3: readList('headingLevel3'),
      paragraph: readList('paragraph'),
      blockquote: readList('blockquote'),
      unorderedList: readList('unorderedList'),
      orderedList: readList('orderedList'),
    );
  }

  final List<String> headingLevel1;
  final List<String> headingLevel2;
  final List<String> headingLevel3;
  final List<String> paragraph;
  final List<String> blockquote;
  final List<String> unorderedList;
  final List<String> orderedList;

  bool get isEmpty =>
      headingLevel1.isEmpty &&
      headingLevel2.isEmpty &&
      headingLevel3.isEmpty &&
      paragraph.isEmpty &&
      blockquote.isEmpty &&
      unorderedList.isEmpty &&
      orderedList.isEmpty;

  List<String> classesForHeading(int level) {
    switch (level) {
      case 1:
        return headingLevel1;
      case 2:
        return headingLevel2;
      case 3:
      default:
        return headingLevel3;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (headingLevel1.isNotEmpty) 'headingLevel1': headingLevel1,
      if (headingLevel2.isNotEmpty) 'headingLevel2': headingLevel2,
      if (headingLevel3.isNotEmpty) 'headingLevel3': headingLevel3,
      if (paragraph.isNotEmpty) 'paragraph': paragraph,
      if (blockquote.isNotEmpty) 'blockquote': blockquote,
      if (unorderedList.isNotEmpty) 'unorderedList': unorderedList,
      if (orderedList.isNotEmpty) 'orderedList': orderedList,
    };
  }
}

class ImportedFontAsset {
  const ImportedFontAsset({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
    required this.originalHref,
  });

  factory ImportedFontAsset.fromJson(Map<String, dynamic> json) {
    final encodedBytes = json['bytes'] as String? ?? '';
    return ImportedFontAsset(
      fileName: json['fileName'] as String? ?? 'font.ttf',
      mimeType: json['mimeType'] as String? ?? 'font/ttf',
      originalHref: json['originalHref'] as String? ?? '',
      bytes: encodedBytes.isEmpty
          ? Uint8List(0)
          : Uint8List.fromList(base64Decode(encodedBytes)),
    );
  }

  final String fileName;
  final String mimeType;
  final Uint8List bytes;
  final String originalHref;

  String get dataUri => 'data:$mimeType;base64,${base64Encode(bytes)}';

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'mimeType': mimeType,
      'originalHref': originalHref,
      'bytes': base64Encode(bytes),
    };
  }
}

class StructureReferenceEntry {
  const StructureReferenceEntry({
    required this.level,
    required this.title,
  });

  factory StructureReferenceEntry.fromJson(Map<String, dynamic> json) {
    return StructureReferenceEntry(
      level: json['level'] as int? ?? 1,
      title: json['title'] as String? ?? '',
    );
  }

  final int level;
  final String title;

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'title': title,
    };
  }
}

class BookCover {
  const BookCover({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  factory BookCover.fromJson(Map<String, dynamic> json) {
    final encodedBytes = json['bytes'] as String? ?? '';
    return BookCover(
      fileName: json['fileName'] as String? ?? 'cover',
      mimeType: json['mimeType'] as String? ?? 'image/jpeg',
      bytes: encodedBytes.isEmpty
          ? Uint8List(0)
          : Uint8List.fromList(base64Decode(encodedBytes)),
    );
  }

  final String fileName;
  final String mimeType;
  final Uint8List bytes;

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'mimeType': mimeType,
      'bytes': base64Encode(bytes),
    };
  }
}

class BookChapter {
  const BookChapter({
    required this.id,
    required this.order,
    required this.title,
    required this.markdown,
    required this.blocks,
  });

  factory BookChapter.fromJson(Map<String, dynamic> json) {
    return BookChapter(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 1,
      title: json['title'] as String? ?? '본문',
      markdown: json['markdown'] as String? ?? '',
      blocks: (json['blocks'] as List? ?? const [])
          .whereType<Map>()
          .map((entry) => BookBlock.fromJson(entry.cast<String, dynamic>()))
          .toList(),
    );
  }

  final String id;
  final int order;
  final String title;
  final String markdown;
  final List<BookBlock> blocks;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'title': title,
      'markdown': markdown,
      'blocks': blocks.map((block) => block.toJson()).toList(),
    };
  }
}

class BookBlock {
  const BookBlock({
    required this.type,
    required this.text,
    this.level,
  });

  factory BookBlock.fromJson(Map<String, dynamic> json) {
    return BookBlock(
      type: json['type'] as String? ?? 'paragraph',
      text: json['text'] as String? ?? '',
      level: json['level'] as int?,
    );
  }

  final String type;
  final String text;
  final int? level;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'text': text,
      if (level != null) 'level': level,
    };
  }
}

class BookStructureParser {
  static bool hasExplicitChapters(
    String markdown, {
    List<StructureReferenceEntry> structureReference = const [],
  }) {
    final headingLevel = _structuralHeadingLevel(
      structureReference: structureReference,
    );
    final headingPrefix = '#' * headingLevel;
    return RegExp('^${RegExp.escape(headingPrefix)}\\s+', multiLine: true)
        .hasMatch(markdown);
  }

  static List<BookChapter> splitChapters(
    String markdown, {
    required String fallbackTitle,
    List<StructureReferenceEntry> structureReference = const [],
  }) {
    final normalized = markdown.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');
    final chapters = <BookChapter>[];
    final buffer = StringBuffer();
    var currentTitle = fallbackTitle.trim().isEmpty ? '본문' : fallbackTitle;
    var index = 1;
    var sawExplicitChapter = false;
    final structuralHeadingLevel =
        _structuralHeadingLevel(structureReference: structureReference);

    void flushChapter() {
      final content = buffer.toString().trim();
      if (content.isEmpty && !sawExplicitChapter && chapters.isNotEmpty) {
        buffer.clear();
        return;
      }

      chapters.add(
        BookChapter(
          id: 'chapter-${index.toString().padLeft(2, '0')}',
          order: index,
          title: currentTitle.trim().isEmpty ? '챕터 $index' : currentTitle,
          markdown: content,
          blocks: splitBlocks(content),
        ),
      );
      index += 1;
      buffer.clear();
    }

    for (final line in lines) {
      final trimmed = line.trim();
      final headingLevel = _headingLevel(trimmed);
      if (headingLevel == structuralHeadingLevel) {
        if (buffer.toString().trim().isNotEmpty || chapters.isNotEmpty) {
          flushChapter();
        }
        currentTitle = trimmed.substring(structuralHeadingLevel + 1).trim();
        sawExplicitChapter = true;
        continue;
      }
      buffer.writeln(line);
    }

    if (buffer.toString().trim().isNotEmpty || chapters.isEmpty) {
      flushChapter();
    }

    return chapters;
  }

  static int _structuralHeadingLevel({
    required List<StructureReferenceEntry> structureReference,
  }) {
    if (structureReference.isEmpty) {
      return 1;
    }

    final candidate = structureReference
        .map((entry) => entry.level)
        .where((level) => level > 0 && level <= 3)
        .fold<int?>(null, (current, level) {
      if (current == null || level < current) {
        return level;
      }
      return current;
    });

    return candidate ?? 1;
  }

  static int? _headingLevel(String line) {
    if (line.startsWith('### ')) {
      return 3;
    }
    if (line.startsWith('## ')) {
      return 2;
    }
    if (line.startsWith('# ')) {
      return 1;
    }
    return null;
  }

  static List<BookBlock> splitBlocks(String markdown) {
    final normalized = markdown.trim();
    if (normalized.isEmpty) {
      return const [];
    }

    final parts = normalized.split(RegExp(r'\n\s*\n+'));
    final blocks = <BookBlock>[];

    for (final rawPart in parts) {
      final part = rawPart.trim();
      if (part.isEmpty) {
        continue;
      }

      final lines = part.split('\n');
      final firstLine = lines.first.trim();
      final isHeading = firstLine.startsWith('# ');
      final isSubHeading =
          firstLine.startsWith('## ') || firstLine.startsWith('### ');

      if ((isHeading || isSubHeading) && lines.length > 1) {
        blocks.add(_detectBlock(firstLine));
        final remainder = lines.skip(1).join('\n').trim();
        if (remainder.isNotEmpty) {
          blocks.add(_detectBlock(remainder));
        }
        continue;
      }

      blocks.add(_detectBlock(part));
    }

    return blocks;
  }

  static BookBlock _detectBlock(String source) {
    final firstLine = source.split('\n').first.trim();

    if (firstLine.startsWith('### ')) {
      return BookBlock(
        type: 'heading',
        text: firstLine.substring(4).trim(),
        level: 3,
      );
    }
    if (firstLine.startsWith('## ')) {
      return BookBlock(
        type: 'heading',
        text: firstLine.substring(3).trim(),
        level: 2,
      );
    }
    if (firstLine.startsWith('# ')) {
      return BookBlock(
        type: 'heading',
        text: firstLine.substring(2).trim(),
        level: 1,
      );
    }
    if (firstLine.startsWith('- ') ||
        firstLine.startsWith('* ') ||
        RegExp(r'^\d+\.\s').hasMatch(firstLine)) {
      return BookBlock(type: 'list', text: source);
    }
    if (firstLine.startsWith('> ') || firstLine.startsWith('<blockquote')) {
      return BookBlock(type: 'quote', text: source);
    }
    if (firstLine.startsWith('|') && firstLine.endsWith('|')) {
      return BookBlock(type: 'table', text: source);
    }
    if (firstLine.startsWith('![')) {
      return BookBlock(type: 'image', text: source);
    }
    if (firstLine.startsWith('<')) {
      return BookBlock(type: 'rawHtml', text: source);
    }
    return BookBlock(type: 'paragraph', text: source);
  }
}

DateTime? _parseDate(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
