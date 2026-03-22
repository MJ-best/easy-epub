import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../domain/entities/book_document.dart';

class ImportedEpubStyle {
  const ImportedEpubStyle({
    required this.sourceName,
    required this.stylesheet,
    this.referenceTitle,
    this.referenceAuthor,
    this.fonts = const [],
    this.structureReference = const [],
    this.styleClassHints = const StyleClassHints(),
    this.warnings = const [],
  });

  final String sourceName;
  final String stylesheet;
  final String? referenceTitle;
  final String? referenceAuthor;
  final List<ImportedFontAsset> fonts;
  final List<StructureReferenceEntry> structureReference;
  final StyleClassHints styleClassHints;
  final List<String> warnings;
}

class EpubStyleImportService {
  Future<ImportedEpubStyle> importFromBytes({
    required Uint8List epubBytes,
    required String sourceName,
  }) async {
    final warnings = <String>[];
    final archive = ZipDecoder().decodeBytes(epubBytes, verify: false);
    final containerXml = _readTextFile(archive, 'META-INF/container.xml');
    final opfPath = _extractOpfPath(containerXml) ?? _fallbackOpfPath(archive);

    if (opfPath == null) {
      throw Exception('OPF 파일을 찾을 수 없습니다.');
    }

    final opfText = _readTextFile(archive, opfPath);
    final opfDirectory = _parentDirectory(opfPath);
    final manifest = _parseManifest(opfText);

    final stylesheetBundle = _extractStylesheetBundle(
      archive,
      manifest,
      opfDirectory,
      warnings,
    );
    final structureReference = _extractStructureReference(
      archive,
      manifest,
      opfDirectory,
      warnings,
    );

    return ImportedEpubStyle(
      sourceName: sourceName,
      stylesheet: stylesheetBundle.stylesheet,
      referenceTitle: _extractTagText(opfText, 'dc:title'),
      referenceAuthor: _extractTagText(opfText, 'dc:creator'),
      fonts: stylesheetBundle.fonts,
      structureReference: structureReference,
      styleClassHints: _extractStyleClassHints(stylesheetBundle.stylesheet),
      warnings: warnings,
    );
  }

  _StylesheetBundle _extractStylesheetBundle(
    Archive archive,
    List<_ManifestItem> manifest,
    String opfDirectory,
    List<String> warnings,
  ) {
    _ManifestItem? cssItem = _firstWhereOrNull(
      manifest,
      (item) => item.mediaType == 'text/css' || item.href.endsWith('.css'),
    );
    String cssText = '';
    String cssPath = '';

    if (cssItem != null) {
      cssPath = _resolvePath(opfDirectory, cssItem.href);
      cssText = _readTextFile(archive, cssPath);
    }

    if (cssText.trim().isEmpty) {
      final fallback = _firstWhereOrNull(
        archive.files,
        (file) => file.name.toLowerCase().endsWith('.css'),
      );
      if (fallback != null) {
        cssPath = fallback.name;
        cssText = _decodeBytes(_fileBytes(fallback));
        warnings.add('OPF manifest에서 CSS를 찾지 못해 ${fallback.name}를 사용했습니다.');
      }
    }

    if (cssText.trim().isEmpty) {
      warnings.add('대표 stylesheet를 찾지 못해 기본 템플릿을 유지합니다.');
      return const _StylesheetBundle(stylesheet: '', fonts: []);
    }

    return _rewriteStylesheetAndExtractFonts(
      archive: archive,
      manifest: manifest,
      opfDirectory: opfDirectory,
      cssPath: cssPath,
      stylesheet: cssText,
      warnings: warnings,
    );
  }

  _StylesheetBundle _rewriteStylesheetAndExtractFonts({
    required Archive archive,
    required List<_ManifestItem> manifest,
    required String opfDirectory,
    required String cssPath,
    required String stylesheet,
    required List<String> warnings,
  }) {
    final cssDirectory = _parentDirectory(cssPath);
    final importedFonts = <ImportedFontAsset>[];
    final seenPaths = <String, ImportedFontAsset>{};
    var fontIndex = 1;
    var warnedForNonFontAssets = false;

    final rewritten = stylesheet.replaceAllMapped(
      RegExp(r'url\(([^)]+)\)', caseSensitive: false),
      (match) {
        final rawValue = (match.group(1) ?? '').trim();
        final cleanedValue = _stripWrappingQuotes(rawValue);
        if (cleanedValue.isEmpty ||
            cleanedValue.startsWith('data:') ||
            cleanedValue.startsWith('http://') ||
            cleanedValue.startsWith('https://')) {
          return match.group(0) ?? '';
        }

        final sanitizedValue =
            cleanedValue.split('#').first.split('?').first.trim();
        if (sanitizedValue.isEmpty) {
          return match.group(0) ?? '';
        }

        final resolvedPath = _resolvePath(cssDirectory, sanitizedValue);
        final manifestItem = _findManifestItemByResolvedPath(
            manifest, opfDirectory, resolvedPath);

        if (_isFontAsset(
          path: resolvedPath,
          mediaType: manifestItem?.mediaType,
        )) {
          final existing = seenPaths[resolvedPath];
          if (existing != null) {
            return 'url("../Fonts/${existing.fileName}")';
          }

          final file = _findFile(archive, resolvedPath);
          if (file == null) {
            warnings.add('폰트 파일을 찾지 못했습니다: $resolvedPath');
            return match.group(0) ?? '';
          }

          final fileName = _allocateFontFileName(
            resolvedPath,
            index: fontIndex,
          );
          fontIndex += 1;

          final font = ImportedFontAsset(
            fileName: fileName,
            mimeType: manifestItem?.mediaType ?? _guessMimeType(resolvedPath),
            bytes: _fileBytes(file),
            originalHref: sanitizedValue,
          );
          seenPaths[resolvedPath] = font;
          importedFonts.add(font);
          return 'url("../Fonts/$fileName")';
        }

        if (_looksLikeImageAsset(resolvedPath) && !warnedForNonFontAssets) {
          warnedForNonFontAssets = true;
          warnings.add('이미지 기반 CSS 자산은 제외했습니다. 폰트와 스타일만 가져옵니다.');
        }

        return match.group(0) ?? '';
      },
    );

    return _StylesheetBundle(
      stylesheet: rewritten,
      fonts: importedFonts,
    );
  }

  List<StructureReferenceEntry> _extractStructureReference(
    Archive archive,
    List<_ManifestItem> manifest,
    String opfDirectory,
    List<String> warnings,
  ) {
    final ncxItem = _firstWhereOrNull(
      manifest,
      (item) => item.mediaType == 'application/x-dtbncx+xml',
    );
    if (ncxItem != null) {
      final ncxPath = _resolvePath(opfDirectory, ncxItem.href);
      final ncxText = _readTextFile(archive, ncxPath);
      final parsed = _parseNcxStructure(ncxText);
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }

    final navItem = _firstWhereOrNull(
      manifest,
      (item) =>
          item.properties.contains('nav') ||
          item.href.toLowerCase().contains('nav'),
    );
    if (navItem != null) {
      final navPath = _resolvePath(opfDirectory, navItem.href);
      final navText = _readTextFile(archive, navPath);
      final parsed = _parseNavStructure(navText);
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }

    warnings.add('목차 구조를 찾지 못했습니다. CSS와 폰트만 가져왔습니다.');
    return const [];
  }

  List<StructureReferenceEntry> _parseNcxStructure(String ncxText) {
    final entries = <StructureReferenceEntry>[];
    final tokenPattern = RegExp(
      r'<navPoint\b[^>]*>|</navPoint>|<text>([^<]+)</text>',
      caseSensitive: false,
    );
    var level = 0;

    for (final match in tokenPattern.allMatches(ncxText)) {
      final token = match.group(0) ?? '';
      if (token.toLowerCase().startsWith('<navpoint')) {
        level += 1;
        continue;
      }
      if (token.toLowerCase() == '</navpoint>') {
        if (level > 0) {
          level -= 1;
        }
        continue;
      }

      final text = _decodeEntities(match.group(1)?.trim());
      if (level > 0 && text != null && text.isNotEmpty) {
        entries.add(StructureReferenceEntry(level: level, title: text));
      }
    }

    return entries;
  }

  List<StructureReferenceEntry> _parseNavStructure(String navText) {
    final entries = <StructureReferenceEntry>[];
    final tokenPattern = RegExp(
      r'<ol\b[^>]*>|</ol>|<a\b[^>]*>([\s\S]*?)</a>',
      caseSensitive: false,
    );
    var level = 0;

    for (final match in tokenPattern.allMatches(navText)) {
      final token = match.group(0) ?? '';
      if (token.toLowerCase().startsWith('<ol')) {
        level += 1;
        continue;
      }
      if (token.toLowerCase() == '</ol>') {
        if (level > 0) {
          level -= 1;
        }
        continue;
      }

      final rawTitle = match.group(1);
      final title = _stripHtml(_decodeEntities(rawTitle?.trim()) ?? '');
      if (title.isNotEmpty) {
        entries.add(
          StructureReferenceEntry(level: level == 0 ? 1 : level, title: title),
        );
      }
    }

    return entries;
  }

  List<_ManifestItem> _parseManifest(String opfText) {
    final items = <_ManifestItem>[];
    final itemPattern = RegExp(r'<item\b([^>]+)/?>', caseSensitive: false);

    for (final match in itemPattern.allMatches(opfText)) {
      final rawAttributes = match.group(1) ?? '';
      final attributes = _parseAttributes(rawAttributes);
      final href = attributes['href'];
      final mediaType = attributes['media-type'];
      if (href == null || mediaType == null) {
        continue;
      }
      items.add(
        _ManifestItem(
          id: attributes['id'] ?? '',
          href: href,
          mediaType: mediaType,
          properties: attributes['properties'] ?? '',
        ),
      );
    }

    return items;
  }

  StyleClassHints _extractStyleClassHints(String stylesheet) {
    if (stylesheet.trim().isEmpty) {
      return const StyleClassHints();
    }

    final headingLevel1 = <String>{};
    final headingLevel2 = <String>{};
    final headingLevel3 = <String>{};
    final paragraph = <String>{};
    final blockquote = <String>{};
    final unorderedList = <String>{};
    final orderedList = <String>{};

    final selectorPattern = RegExp(r'([^{]+)\{', multiLine: true);
    for (final match in selectorPattern.allMatches(stylesheet)) {
      final selectorGroup = match.group(1);
      if (selectorGroup == null) {
        continue;
      }

      final selectors = selectorGroup
          .split(',')
          .map((selector) => selector.trim())
          .where((selector) => selector.isNotEmpty);

      for (final selector in selectors) {
        headingLevel1.addAll(_collectClassesForElement(selector, 'h1'));
        headingLevel2.addAll(_collectClassesForElement(selector, 'h2'));
        headingLevel3.addAll(_collectClassesForElement(selector, 'h3'));
        paragraph.addAll(_collectClassesForElement(selector, 'p'));
        blockquote.addAll(_collectClassesForElement(selector, 'blockquote'));
        unorderedList.addAll(_collectClassesForElement(selector, 'ul'));
        orderedList.addAll(_collectClassesForElement(selector, 'ol'));
      }
    }

    return StyleClassHints(
      headingLevel1: headingLevel1.toList(growable: false),
      headingLevel2: headingLevel2.toList(growable: false),
      headingLevel3: headingLevel3.toList(growable: false),
      paragraph: paragraph.toList(growable: false),
      blockquote: blockquote.toList(growable: false),
      unorderedList: unorderedList.toList(growable: false),
      orderedList: orderedList.toList(growable: false),
    );
  }

  List<String> _collectClassesForElement(String selector, String element) {
    final matches = RegExp(
      '(?:^|[\\s>+~])$element((?:\\.[A-Za-z_][A-Za-z0-9_-]*)+)',
      caseSensitive: false,
    ).allMatches(selector);

    if (matches.isEmpty) {
      return const [];
    }

    final lastMatch = matches.last;
    final suffix = lastMatch.group(1) ?? '';
    return suffix
        .split('.')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, String> _parseAttributes(String rawAttributes) {
    final attributes = <String, String>{};
    final attributePattern = RegExp(r'''([\w:-]+)\s*=\s*["']([^"']*)["']''');

    for (final match in attributePattern.allMatches(rawAttributes)) {
      final key = match.group(1);
      final value = match.group(2);
      if (key != null && value != null) {
        attributes[key] = value;
      }
    }

    return attributes;
  }

  String? _extractOpfPath(String containerXml) {
    return RegExp(
      r'''full-path=["']([^"']+\.opf)["']''',
      caseSensitive: false,
    ).firstMatch(containerXml)?.group(1);
  }

  String? _fallbackOpfPath(Archive archive) {
    final opfFile = _firstWhereOrNull(
      archive.files,
      (file) => file.name.toLowerCase().endsWith('.opf'),
    );
    return opfFile?.name;
  }

  _ManifestItem? _findManifestItemByResolvedPath(
    List<_ManifestItem> manifest,
    String opfDirectory,
    String resolvedPath,
  ) {
    return _firstWhereOrNull(
      manifest,
      (item) => _resolvePath(opfDirectory, item.href) == resolvedPath,
    );
  }

  String _readTextFile(Archive archive, String path) {
    final file = _findFile(archive, path);
    if (file == null) {
      return '';
    }
    return _decodeBytes(_fileBytes(file));
  }

  ArchiveFile? _findFile(Archive archive, String path) {
    final normalizedTarget = path.replaceAll('\\', '/');
    return _firstWhereOrNull(
      archive.files,
      (file) => file.name.replaceAll('\\', '/') == normalizedTarget,
    );
  }

  String _decodeBytes(Uint8List bytes) {
    return utf8.decode(bytes, allowMalformed: true);
  }

  Uint8List _fileBytes(ArchiveFile file) {
    final content = file.content;
    if (content is Uint8List) {
      return content;
    }
    if (content is List<int>) {
      return Uint8List.fromList(content);
    }
    return Uint8List(0);
  }

  String? _extractTagText(String xml, String tagName) {
    final match = RegExp(
      '<$tagName[^>]*>([\\s\\S]*?)</$tagName>',
      caseSensitive: false,
    ).firstMatch(xml);
    return _decodeEntities(match?.group(1)?.trim());
  }

  String? _decodeEntities(String? text) {
    if (text == null || text.isEmpty) {
      return text;
    }
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }

  String _stripHtml(String text) {
    return text.replaceAll(RegExp(r'<[^>]+>'), '').trim();
  }

  String _stripWrappingQuotes(String value) {
    final normalized = value.trim();
    if ((normalized.startsWith('"') && normalized.endsWith('"')) ||
        (normalized.startsWith("'") && normalized.endsWith("'"))) {
      return normalized.substring(1, normalized.length - 1);
    }
    return normalized;
  }

  bool _isFontAsset({
    required String path,
    required String? mediaType,
  }) {
    final normalized = path.toLowerCase();
    if (mediaType != null &&
        (mediaType.startsWith('font/') ||
            mediaType.contains('opentype') ||
            mediaType.contains('truetype') ||
            mediaType.contains('woff'))) {
      return true;
    }

    return normalized.endsWith('.ttf') ||
        normalized.endsWith('.otf') ||
        normalized.endsWith('.woff') ||
        normalized.endsWith('.woff2');
  }

  bool _looksLikeImageAsset(String path) {
    final normalized = path.toLowerCase();
    return normalized.endsWith('.png') ||
        normalized.endsWith('.jpg') ||
        normalized.endsWith('.jpeg') ||
        normalized.endsWith('.gif') ||
        normalized.endsWith('.webp') ||
        normalized.endsWith('.svg');
  }

  String _allocateFontFileName(
    String originalPath, {
    required int index,
  }) {
    final baseName = originalPath.split('/').last;
    final dotIndex = baseName.lastIndexOf('.');
    final stem = dotIndex > 0 ? baseName.substring(0, dotIndex) : 'font_$index';
    final ext = dotIndex > 0 ? baseName.substring(dotIndex) : '.ttf';
    return '${_sanitizeFileName(stem)}_$index$ext';
  }

  String _guessMimeType(String path) {
    final normalized = path.toLowerCase();
    if (normalized.endsWith('.woff2')) {
      return 'font/woff2';
    }
    if (normalized.endsWith('.woff')) {
      return 'font/woff';
    }
    if (normalized.endsWith('.otf')) {
      return 'font/otf';
    }
    return 'font/ttf';
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  String _parentDirectory(String path) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    if (index < 0) {
      return '';
    }
    return normalized.substring(0, index);
  }

  String _resolvePath(String root, String href) {
    final segments = <String>[
      if (root.isNotEmpty) ...root.split('/'),
      ...href.replaceAll('\\', '/').split('/'),
    ];
    final resolved = <String>[];

    for (final segment in segments) {
      if (segment.isEmpty || segment == '.') {
        continue;
      }
      if (segment == '..') {
        if (resolved.isNotEmpty) {
          resolved.removeLast();
        }
        continue;
      }
      resolved.add(segment);
    }

    return resolved.join('/');
  }

  T? _firstWhereOrNull<T>(
    Iterable<T> items,
    bool Function(T item) test,
  ) {
    for (final item in items) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }
}

class _StylesheetBundle {
  const _StylesheetBundle({
    required this.stylesheet,
    required this.fonts,
  });

  final String stylesheet;
  final List<ImportedFontAsset> fonts;
}

class _ManifestItem {
  const _ManifestItem({
    required this.id,
    required this.href,
    required this.mediaType,
    required this.properties,
  });

  final String id;
  final String href;
  final String mediaType;
  final String properties;
}
