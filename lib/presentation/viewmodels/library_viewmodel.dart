import 'package:flutter/foundation.dart';
import '../../data/models/ebook_model.dart';
import '../../domain/repositories/ebook_repository.dart';

/// ViewModel for eBook library screen
/// Follows MVVM pattern with ChangeNotifier for state management
class LibraryViewModel extends ChangeNotifier {
  final EbookRepository _repository;

  LibraryViewModel(this._repository);

  List<EbookModel> _ebooks = [];
  bool _isLoading = false;
  String? _error;

  List<EbookModel> get ebooks => _ebooks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasEbooks => _ebooks.isNotEmpty;

  /// Load all eBooks from repository
  Future<void> loadEbooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ebooks = await _repository.getAllEbooks();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete eBook by ID
  Future<void> deleteEbook(String id) async {
    try {
      await _repository.deleteEbook(id);
      _ebooks.removeWhere((ebook) => ebook.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Search eBooks by query
  Future<void> searchEbooks(String query) async {
    if (query.isEmpty) {
      await loadEbooks();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ebooks = await _repository.searchEbooks(query);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh library
  Future<void> refresh() async {
    await loadEbooks();
  }
}
