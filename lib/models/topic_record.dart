/// `Topic` 表模型。
/// 对应字段：id, created_at, celebrity, name, description
class TopicRecord {
  final int id;
  final DateTime? createdAt;
  final String? celebrity;
  final String name;
  final String? description;

  const TopicRecord({
    required this.id,
    required this.createdAt,
    required this.celebrity,
    required this.name,
    required this.description,
  });

  factory TopicRecord.fromMap(Map<String, dynamic> map) {
    return TopicRecord(
      id: (map['id'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
      celebrity: map['celebrity']?.toString(),
      name: (map['name'] ?? '').toString(),
      description: map['description']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt?.toIso8601String(),
      'celebrity': celebrity,
      'name': name,
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicRecord &&
          other.id == id &&
          other.createdAt == createdAt &&
          other.celebrity == celebrity &&
          other.name == name &&
          other.description == description;

  @override
  int get hashCode => Object.hash(
        id,
        createdAt,
        celebrity,
        name,
        description,
      );

  TopicRecord copyWith({
    int? id,
    DateTime? createdAt,
    String? celebrity,
    String? name,
    String? description,
  }) =>
      TopicRecord(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        celebrity: celebrity ?? this.celebrity,
        name: name ?? this.name,
        description: description ?? this.description,
      );

  @override
  String toString() =>
      'TopicRecord('
      'id: $id, '
      'createdAt: $createdAt, '
      'celebrity: $celebrity, '
      'name: $name, '
      'description: $description'
      ')';
}
