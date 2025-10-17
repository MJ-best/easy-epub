import '../../data/models/ebook_model.dart';

/// Abstract repository interface for eBook operations
/// Following Repository Pattern as per guidelines
abstract class EbookRepository {
  /// Get all eBooks from storage
  Future<List<EbookModel>> getAllEbooks();

  /// Get specific eBook by ID
  Future<EbookModel?> getEbookById(String id);

  /// Save new eBook
  Future<void> saveEbook(EbookModel ebook);

  /// Update existing eBook
  Future<void> updateEbook(EbookModel ebook);

  /// Delete eBook by ID
  Future<void> deleteEbook(String id);

  /// Search eBooks by title or author
  Future<List<EbookModel>> searchEbooks(String query);

  /// Clear all eBooks (for testing purposes)
  Future<void> clearAll();
}
