import 'package:hive/hive.dart';

part 'ebook_model.g.dart';

/// Hive model for eBook storage
@HiveType(typeId: 0)
class EbookModel extends HiveObject {
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

  /// Convert to domain entity
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'content': content,
      'coverImagePath': coverImagePath,
      'templateType': templateType,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'epubFilePath': epubFilePath,
    };
  }

  /// Create from JSON
  factory EbookModel.fromJson(Map<String, dynamic> json) {
    return EbookModel(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      content: json['content'] as String,
      coverImagePath: json['coverImagePath'] as String?,
      templateType: json['templateType'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      epubFilePath: json['epubFilePath'] as String?,
    );
  }

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
