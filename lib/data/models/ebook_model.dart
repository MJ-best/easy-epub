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
    required this.templateType,
    required this.createdAt,
    required this.modifiedAt,
    this.epubFilePath,
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
  String templateType;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime modifiedAt;

  @HiveField(8)
  String? epubFilePath;

  /// Copy with method for immutability
  EbookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? content,
    String? coverImagePath,
    String? templateType,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? epubFilePath,
  }) {
    return EbookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      content: content ?? this.content,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      templateType: templateType ?? this.templateType,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      epubFilePath: epubFilePath ?? this.epubFilePath,
    );
  }
}
