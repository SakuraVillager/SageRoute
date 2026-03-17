class CelebrityProfile {
  final int id;
  final String name;
  final String dynasty;
  final String bioShort;
  final String bioFul;
  final String avatarUrl;
  final List<String> topic;

  const CelebrityProfile({
    required this.id,
    required this.name,
    required this.dynasty,
    required this.bioShort,
    required this.bioFul,
    required this.avatarUrl,
    required this.topic,
  });

  factory CelebrityProfile.fromMap(Map<String, dynamic> map) {
    final rawTopic = map['topic'];

    return CelebrityProfile(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: (map['name'] ?? '').toString(),
      dynasty: (map['dynasty'] ?? '').toString(),
      bioShort: (map['bio_short'] ?? '').toString(),
      bioFul: (map['bio_ful'] ?? map['bio_full'] ?? '').toString(),
      avatarUrl: (map['avatar_url'] ?? '').toString(),
      topic: rawTopic is List
          ? rawTopic.map((item) => item.toString()).toList(growable: false)
          : const <String>[],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dynasty': dynasty,
      'bio_short': bioShort,
      'bio_ful': bioFul,
      'avatar_url': avatarUrl,
      'topic': topic,
    };
  }
}
