import 'package:hive/hive.dart';
import '../../domain/repositories/ebook_repository.dart';
import '../models/ebook_model.dart';
import '../../core/constants/app_constants.dart';

/// Implementation of EbookRepository using Hive
class EbookRepositoryImpl implements EbookRepository {
  late Box<EbookModel> _ebookBox;

  /// Initialize Hive box
  Future<void> init() async {
    _ebookBox = await Hive.openBox<EbookModel>(AppConstants.EBOOK_BOX_NAME);
  }

  @override
  Future<List<EbookModel>> getAllEbooks() async {
    return _ebookBox.values.toList()
      ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
  }

  @override
  Future<EbookModel?> getEbookById(String id) async {
    return _ebookBox.get(id);
  }

  @override
  Future<void> saveEbook(EbookModel ebook) async {
    await _ebookBox.put(ebook.id, ebook);
  }

  @override
  Future<void> updateEbook(EbookModel ebook) async {
    final updatedEbook = ebook.copyWith(
      modifiedAt: DateTime.now(),
    );
    await _ebookBox.put(ebook.id, updatedEbook);
  }

  @override
  Future<void> deleteEbook(String id) async {
    await _ebookBox.delete(id);
  }

  @override
  Future<List<EbookModel>> searchEbooks(String query) async {
    final allEbooks = await getAllEbooks();
    return allEbooks.where((ebook) {
      final titleMatch = ebook.title.toLowerCase().contains(query.toLowerCase());
      final authorMatch = ebook.author.toLowerCase().contains(query.toLowerCase());
      return titleMatch || authorMatch;
    }).toList();
  }

  @override
  Future<void> clearAll() async {
    await _ebookBox.clear();
  }
}
