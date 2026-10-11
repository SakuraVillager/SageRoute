/// `Article` 表的初版阅读内容模型。
///
/// 对应字段：id、created_at、topic、title、summary、content、cover_image_url。
class ArticleRecord {
  const ArticleRecord({
    required this.id,
    required this.createdAt,
    required this.topic,
    required this.title,
    required this.summary,
    required this.content,
    required this.coverImageUrl,
  });

  final int id;
  final DateTime? createdAt;
  final String topic;
  final String title;
  final String summary;
  final String content;
  final String coverImageUrl;

  factory ArticleRecord.fromMap(Map<String, dynamic> map) => ArticleRecord(
    id: (map['id'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
    topic: (map['topic'] ?? '').toString(),
    title: (map['title'] ?? '').toString(),
    summary: (map['summary'] ?? '').toString(),
    content: (map['content'] ?? '').toString(),
    coverImageUrl: (map['cover_image_url'] ?? map['coverImageUrl'] ?? '')
        .toString(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'created_at': createdAt?.toIso8601String(),
    'topic': topic,
    'title': title,
    'summary': summary,
    'content': content,
    'cover_image_url': coverImageUrl,
  };

  ArticleRecord copyWith({
    int? id,
    DateTime? createdAt,
    String? topic,
    String? title,
    String? summary,
    String? content,
    String? coverImageUrl,
  }) => ArticleRecord(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    topic: topic ?? this.topic,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    content: content ?? this.content,
    coverImageUrl: coverImageUrl ?? this.coverImageUrl,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticleRecord &&
          other.id == id &&
          other.createdAt == createdAt &&
          other.topic == topic &&
          other.title == title &&
          other.summary == summary &&
          other.content == content &&
          other.coverImageUrl == coverImageUrl;

  @override
  int get hashCode =>
      Object.hash(id, createdAt, topic, title, summary, content, coverImageUrl);

  @override
  String toString() =>
      'ArticleRecord(id: $id, topic: $topic, title: $title, summary: $summary)';
}
