import 'dart:typed_data';

import 'package:hive/hive.dart';

part 'ebook_model.g.dart';

/// Hive model for eBook storage
@HiveType(typeId: 0)
class EbookModel extends HiveObject {
  EbookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.content,
    this.coverImagePath,
    this.coverImageBytes,
    this.coverImageMimeType,
    required this.templateType,
    required this.createdAt,
    required this.modifiedAt,
    this.epubFilePath,
    this.documentJson,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String author;

  @HiveField(3)
  String content;

  @HiveField(4)
  String? coverImagePath;

  @HiveField(5)
  Uint8List? coverImageBytes;

  @HiveField(6)
  String? coverImageMimeType;

  @HiveField(7)
  String templateType;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime modifiedAt;

  @HiveField(10)
  String? epubFilePath;

  @HiveField(11)
  String? documentJson;

  /// Copy with method for immutability
  EbookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? content,
    String? coverImagePath,
    Uint8List? coverImageBytes,
    String? coverImageMimeType,
    String? templateType,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? epubFilePath,
    String? documentJson,
  }) {
    return EbookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      content: content ?? this.content,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      coverImageBytes: coverImageBytes ?? this.coverImageBytes,
      coverImageMimeType: coverImageMimeType ?? this.coverImageMimeType,
      templateType: templateType ?? this.templateType,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      epubFilePath: epubFilePath ?? this.epubFilePath,
      documentJson: documentJson ?? this.documentJson,
    );
  }
}
