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
    return CelebrityProfile(
      id: map['id'] as int,
      name: map['name'] as String,
      dynasty: map['dynasty'] as String,
      bioShort: map['bio_short'] as String,
      bioFul: map['bio_ful'] as String,
      avatarUrl: map['avatar_url'] as String,
      topic: List<String>.from(map['topic'] as List<dynamic>? ?? const []),
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
