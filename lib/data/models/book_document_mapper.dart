import 'dart:convert';

import '../../domain/entities/book_document.dart';
import 'ebook_model.dart';

extension EbookModelDocumentMapper on EbookModel {
  BookDocument toBookDocument() {
    final rawJson = documentJson;
    if (rawJson != null && rawJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map<String, dynamic>) {
          return BookDocument.fromJson(decoded);
        }
        if (decoded is Map) {
          return BookDocument.fromJson(decoded.cast<String, dynamic>());
        }
      } catch (_) {
        // Fall back to legacy projection when stored JSON is invalid.
      }
    }

    return BookDocument(
      schemaVersion: 1,
      metadata: BookMetadata(
        id: id,
        title: title,
        author: author,
        language: 'ko',
        createdAt: createdAt,
        modifiedAt: modifiedAt,
      ),
      body: BookBody(
        sourceFormat: 'markdown',
        sourceMarkdown: content,
        chapters: BookStructureParser.splitChapters(
          content,
          fallbackTitle: title.trim().isEmpty ? '본문' : title,
        ),
      ),
      presentation: BookPresentation(templateType: templateType),
      cover: coverImageBytes == null || coverImageBytes!.isEmpty
          ? null
          : BookCover(
              fileName: 'cover',
              mimeType: coverImageMimeType ?? 'image/jpeg',
              bytes: coverImageBytes!,
            ),
    );
  }
}

EbookModel ebookModelFromDocument({
  required String id,
  required BookDocument document,
  String? epubFilePath,
}) {
  final normalizedTitle =
      document.title.trim().isEmpty ? '제목 없는 전자책' : document.title.trim();
  final normalizedAuthor =
      document.author.trim().isEmpty ? 'Unknown' : document.author.trim();

  return EbookModel(
    id: id,
    title: normalizedTitle,
    author: normalizedAuthor,
    content: document.rawMarkdown,
    coverImagePath: null,
    coverImageBytes: document.coverBytes,
    coverImageMimeType: document.coverMimeType,
    templateType: document.templateType,
    createdAt: document.metadata.createdAt,
    modifiedAt: document.metadata.modifiedAt,
    epubFilePath: epubFilePath,
    documentJson: jsonEncode(
      document
          .withIdentity(
            id: id,
            createdAt: document.metadata.createdAt,
            modifiedAt: document.metadata.modifiedAt,
          )
          .toJson(),
    ),
  );
}
