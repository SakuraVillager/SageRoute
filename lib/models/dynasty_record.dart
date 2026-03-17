/// `Dynasty` 表模型。
class DynastyRecord {
  final int id;
  final String dynasty;

  const DynastyRecord({
    required this.id,
    required this.dynasty,
  });


  factory DynastyRecord.fromMap(Map<String, dynamic> map) {
    return DynastyRecord(
      id: (map['id'] as num?)?.toInt() ?? 0,
      dynasty: (map['dynasty'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dynasty': dynasty,
    };
  }
}
