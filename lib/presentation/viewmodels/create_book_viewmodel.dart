import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/epub_preview_models.dart';
import '../../data/models/book_document_mapper.dart';
import '../../data/models/ebook_model.dart';
import '../../data/models/template_type.dart';
import '../../data/services/epub_generator_service_v2.dart';
import '../../data/services/epub_style_import_service.dart';
import '../../domain/entities/book_document.dart';
import '../../domain/repositories/ebook_repository.dart';

class EbookGenerationResult {
  const EbookGenerationResult({
    required this.ebook,
    required this.epub,
  });

  final EbookModel ebook;
  final EpubBuildResult epub;
}

class CreateBookViewModel extends ChangeNotifier {
  CreateBookViewModel(
    this._repository,
    this._epubGenerator,
    this._styleImportService,
  );

  static const Uuid _uuid = Uuid();

  final EbookRepository _repository;
  final EpubGeneratorServiceV2 _epubGenerator;
  final EpubStyleImportService _styleImportService;

  BookDocument _document = BookDocument.empty();
  String? _editingEbookId;
  String _previewDraftId = _uuid.v4();
  bool _isBusy = false;
  String? _error;
  List<String> _importWarnings = const [];

  BookDocument get document => _document;
  String get title => _document.title;
  String get author => _document.author;
  String get content => _document.rawMarkdown;
  String? get editingEbookId => _editingEbookId;
  bool get isEditing => _editingEbookId != null;
  Uint8List? get coverImageBytes => _document.coverBytes;
  String? get coverImageMimeType => _document.coverMimeType;
  TemplateType get selectedTemplate =>
      TemplateType.fromString(_document.templateType);
  bool get isGenerating => _isBusy;
  String? get error => _error;
  List<String> get importWarnings => List.unmodifiable(_importWarnings);
  String? get importedStyleSourceName => _document.customCssSourceName;
  String? get importedStyleReferenceTitle => _document.styleReferenceTitle;
  String? get importedStyleReferenceAuthor => _document.styleReferenceAuthor;
  bool get hasImportedStyle => _document.hasCustomCss;
  bool get hasImportedFonts => _document.hasImportedFonts;
  int get importedFontCount => _document.importedFonts.length;
  List<StructureReferenceEntry> get structureReference =>
      List.unmodifiable(_document.structureReference);
  StyleClassHints get styleClassHints => _document.styleClassHints;
  int get chapterCount => _document.chapters.length;
  bool get hasStructureTemplate => structureReference.isNotEmpty;
  BookDocument get previewDocument => _normalizedDocument(
        id: _editingEbookId ?? _previewDraftId,
        createdAt: _document.metadata.createdAt,
        modifiedAt: _document.metadata.modifiedAt,
      );

  void setTitle(String value) {
    _document = _document.updateTitle(value).touch();
    notifyListeners();
  }

  void setAuthor(String value) {
    _document = _document.updateAuthor(value).touch();
    notifyListeners();
  }

  void setContent(String value) {
    _document = _document.updateMarkdown(value).touch();
    notifyListeners();
  }

  void setCoverImage({
    String? path,
    Uint8List? bytes,
    String? mimeType,
  }) {
    _document = _document
        .updateCover(
          bytes: bytes,
          mimeType: mimeType,
          fileName: path,
        )
        .touch();
    notifyListeners();
  }

  void clearCoverImage() {
    _document = _document.copyWith(clearCover: true).touch();
    notifyListeners();
  }

  void selectTemplate(TemplateType template) {
    _document = _document.updateTemplateType(template.name).touch();
    notifyListeners();
  }

  String? validate() {
    if (_document.title.trim().isEmpty) {
      return 'titleRequired';
    }
    if (_document.rawMarkdown.trim().isEmpty) {
      return 'contentRequired';
    }
    return null;
  }

  Future<ImportedEpubStyle?> applyImportedEpubStyle({
    required Uint8List bytes,
    required String sourceName,
  }) async {
    _isBusy = true;
    _error = null;
    notifyListeners();

    try {
      final imported = await _styleImportService.importFromBytes(
        epubBytes: bytes,
        sourceName: sourceName,
      );

      _document = _document
          .applyStyleReference(
            css: imported.stylesheet,
            sourceName: imported.sourceName,
            referenceTitle: imported.referenceTitle,
            referenceAuthor: imported.referenceAuthor,
            fonts: imported.fonts,
            structureReference: imported.structureReference,
            styleClassHints: imported.styleClassHints,
          )
          .touch();
      _importWarnings = imported.warnings;
      _isBusy = false;
      notifyListeners();
      return imported;
    } catch (e) {
      _error = 'styleImportFailed';
      _isBusy = false;
      notifyListeners();
      return null;
    }
  }

  Future<EbookModel?> saveDraft() async {
    final normalizedTitle = _resolveTitle(_document.title);
    if (_document.rawMarkdown.trim().isEmpty &&
        _document.author.trim().isEmpty &&
        normalizedTitle == '제목 없는 전자책' &&
        !_document.hasCover) {
      _error = 'contentRequired';
      notifyListeners();
      return null;
    }

    _isBusy = true;
    _error = null;
    notifyListeners();

    try {
      final existingId = _editingEbookId ?? _previewDraftId;
      final existing = _editingEbookId == null
          ? null
          : await _repository.getEbookById(_editingEbookId!);
      final normalizedDocument = _normalizedDocument(
        id: existingId,
        createdAt: existing?.toBookDocument().metadata.createdAt ??
            _document.metadata.createdAt,
        modifiedAt: _document.metadata.modifiedAt,
      );
      final ebook = ebookModelFromDocument(
        id: existingId,
        document: normalizedDocument,
        epubFilePath: existing?.epubFilePath,
      );

      if (_editingEbookId == null) {
        await _repository.saveEbook(ebook);
        _editingEbookId = ebook.id;
      } else {
        await _repository.updateEbook(ebook);
      }

      _document = normalizedDocument;
      _isBusy = false;
      notifyListeners();
      return ebook;
    } catch (e) {
      _error = 'errorOccurred';
      _isBusy = false;
      notifyListeners();
      return null;
    }
  }

  Future<EbookGenerationResult?> generateEbook() async {
    final validationError = validate();
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return null;
    }

    _isBusy = true;
    _error = null;
    notifyListeners();

    try {
      final existingId = _editingEbookId ?? _previewDraftId;
      final existing = _editingEbookId == null
          ? null
          : await _repository.getEbookById(_editingEbookId!);
      final normalizedDocument = _normalizedDocument(
        id: existingId,
        createdAt: existing?.toBookDocument().metadata.createdAt ??
            _document.metadata.createdAt,
        modifiedAt: _document.metadata.modifiedAt,
      );
      final ebook = ebookModelFromDocument(
        id: existingId,
        document: normalizedDocument,
        epubFilePath: existing?.epubFilePath,
      );
      final epub =
          await _epubGenerator.buildEpubFromDocument(normalizedDocument);

      if (_editingEbookId == null) {
        await _repository.saveEbook(ebook);
        _editingEbookId = ebook.id;
      } else {
        await _repository.updateEbook(ebook);
      }

      _document = normalizedDocument;
      _isBusy = false;
      notifyListeners();

      return EbookGenerationResult(ebook: ebook, epub: epub);
    } catch (e) {
      _error = 'errorOccurred';
      _isBusy = false;
      notifyListeners();
      return null;
    }
  }

  void reset() {
    _document = BookDocument.empty();
    _editingEbookId = null;
    _previewDraftId = _uuid.v4();
    _error = null;
    _importWarnings = const [];
    notifyListeners();
  }

  Future<void> loadEbook(String id) async {
    final ebook = await _repository.getEbookById(id);
    if (ebook == null) {
      return;
    }

    _editingEbookId = ebook.id;
    _previewDraftId = ebook.id;
    _document = ebook.toBookDocument().withIdentity(
          id: ebook.id,
          createdAt: ebook.createdAt,
          modifiedAt: ebook.modifiedAt,
        );
    _error = null;
    _importWarnings = const [];
    notifyListeners();
  }

  BookDocument _normalizedDocument({
    required String id,
    required DateTime createdAt,
    required DateTime modifiedAt,
  }) {
    final normalizedTitle = _resolveTitle(_document.title);
    final normalizedAuthor =
        _document.author.trim().isEmpty ? 'Unknown' : _document.author.trim();

    return _document
        .updateTitle(normalizedTitle)
        .updateAuthor(normalizedAuthor)
        .withIdentity(
          id: id,
          createdAt: createdAt,
          modifiedAt: modifiedAt,
        )
        .copyWith(
          body: _document.body.normalized(
            chapters: BookStructureParser.splitChapters(
              _document.rawMarkdown,
              fallbackTitle: normalizedTitle,
              structureReference: _document.structureReference,
            ),
          ),
        );
  }

  Future<EpubPreviewSource> buildPreviewSource() async {
    return _epubGenerator.buildPreviewSource(previewDocument);
  }

  void clearStyleReference() {
    _document = _document.clearStyleReference().touch();
    _importWarnings = const [];
    notifyListeners();
  }

  String buildStructureTemplate({
    bool includeBodyPlaceholders = true,
  }) {
    return _document.buildStructureReferenceMarkdown(
      includeBodyPlaceholders: includeBodyPlaceholders,
    );
  }

  bool applyStructureReferenceToDraft({
    bool replaceExisting = false,
    bool includeBodyPlaceholders = true,
  }) {
    if (structureReference.isEmpty) {
      return false;
    }

    if (!replaceExisting && _document.rawMarkdown.trim().isNotEmpty) {
      return false;
    }

    final scaffold = _document.buildStructureReferenceMarkdown(
      includeBodyPlaceholders: includeBodyPlaceholders,
    );
    if (scaffold.trim().isEmpty) {
      return false;
    }

    _document = _document.updateMarkdown(scaffold).touch();
    notifyListeners();
    return true;
  }

  String buildStructureSnippet(
    StructureReferenceEntry entry, {
    bool includeBodyPlaceholder = true,
  }) {
    final level = entry.level.clamp(1, 3);
    final headingPrefix = '#' * level;
    final buffer = StringBuffer()..writeln('$headingPrefix ${entry.title}');

    if (includeBodyPlaceholder) {
      switch (level) {
        case 1:
          buffer.write('\n\n챕터 내용을 작성하세요.');
          break;
        case 2:
          buffer.write('\n\n섹션 내용을 작성하세요.');
          break;
        case 3:
        default:
          buffer.write('\n\n세부 내용을 작성하세요.');
          break;
      }
    }

    return buffer.toString().trimRight();
  }

  String _resolveTitle(String rawTitle) {
    final normalized = rawTitle.trim();
    return normalized.isEmpty ? '제목 없는 전자책' : normalized;
  }
}
