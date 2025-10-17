import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/ebook_model.dart';
import '../../data/models/template_type.dart';
import '../../domain/repositories/ebook_repository.dart';
import '../../data/services/epub_generator_service.dart';

/// ViewModel for eBook creation screen
/// Handles eBook creation logic and state
class CreateBookViewModel extends ChangeNotifier {
  final EbookRepository _repository;
  final EpubGeneratorService _epubGenerator;

  CreateBookViewModel(this._repository, this._epubGenerator);

  static const Uuid _uuid = Uuid();

  String _title = '';
  String _author = '';
  String _content = '';
  String? _coverImagePath;
  TemplateType _selectedTemplate = TemplateType.novel;
  bool _isGenerating = false;
  String? _error;

  String get title => _title;
  String get author => _author;
  String get content => _content;
  String? get coverImagePath => _coverImagePath;
  TemplateType get selectedTemplate => _selectedTemplate;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  /// Update title
  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  /// Update author
  void setAuthor(String value) {
    _author = value;
    notifyListeners();
  }

  /// Update content
  void setContent(String value) {
    _content = value;
    notifyListeners();
  }

  /// Update cover image path
  void setCoverImagePath(String? path) {
    _coverImagePath = path;
    notifyListeners();
  }

  /// Select template
  void selectTemplate(TemplateType template) {
    _selectedTemplate = template;
    notifyListeners();
  }

  /// Validate inputs
  String? validate() {
    if (_title.trim().isEmpty) {
      return 'titleRequired';
    }
    if (_content.trim().isEmpty) {
      return 'contentRequired';
    }
    return null;
  }

  /// Generate and save eBook
  Future<EbookModel?> createEbook() async {
    final validationError = validate();
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return null;
    }

    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      // Create eBook model
      final ebook = EbookModel(
        id: _uuid.v4(),
        title: _title.trim(),
        author: _author.trim().isEmpty ? 'Unknown' : _author.trim(),
        content: _content.trim(),
        coverImagePath: _coverImagePath,
        templateType: _selectedTemplate.name,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      // Generate EPUB file
      final epubPath = await _epubGenerator.generateEpub(ebook);
      final ebookWithPath = ebook.copyWith(epubFilePath: epubPath);

      // Save to repository
      await _repository.saveEbook(ebookWithPath);

      _isGenerating = false;
      notifyListeners();

      return ebookWithPath;
    } catch (e) {
      _error = 'errorOccurred';
      _isGenerating = false;
      notifyListeners();
      return null;
    }
  }

  /// Reset form
  void reset() {
    _title = '';
    _author = '';
    _content = '';
    _coverImagePath = null;
    _selectedTemplate = TemplateType.novel;
    _error = null;
    notifyListeners();
  }

  /// Load existing eBook for editing
  Future<void> loadEbook(String id) async {
    final ebook = await _repository.getEbookById(id);
    if (ebook != null) {
      _title = ebook.title;
      _author = ebook.author;
      _content = ebook.content;
      _coverImagePath = ebook.coverImagePath;
      _selectedTemplate = TemplateType.fromString(ebook.templateType);
      notifyListeners();
    }
  }
}
