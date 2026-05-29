import 'package:flutter/foundation.dart';

class CelebrityProfile {
  final int id;
  final String name;
  final String dynasty;
  final String bioShort;
  final String bioFull;
  final String avatarUrl;
  final List<String> topic;

  const CelebrityProfile({
    required this.id,
    required this.name,
    required this.dynasty,
    required this.bioShort,
    required this.bioFull,
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
      bioFull: (map['bio_ful'] ?? map['bio_full'] ?? '').toString(),
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
      'bio_full': bioFull,
      'avatar_url': avatarUrl,
      'topic': topic,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CelebrityProfile &&
          other.id == id &&
          other.name == name &&
          other.dynasty == dynasty &&
          other.bioShort == bioShort &&
          other.bioFull == bioFull &&
          other.avatarUrl == avatarUrl &&
          listEquals(other.topic, topic);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        dynasty,
        bioShort,
        bioFull,
        avatarUrl,
        Object.hashAll(topic),
      );

  CelebrityProfile copyWith({
    int? id,
    String? name,
    String? dynasty,
    String? bioShort,
    String? bioFull,
    String? avatarUrl,
    List<String>? topic,
  }) =>
      CelebrityProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        dynasty: dynasty ?? this.dynasty,
        bioShort: bioShort ?? this.bioShort,
        bioFull: bioFull ?? this.bioFull,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        topic: topic ?? this.topic,
      );

  @override
  String toString() =>
      'CelebrityProfile(id: $id, name: $name, dynasty: $dynasty, bioShort: $bioShort, bioFull: $bioFull, avatarUrl: $avatarUrl, topic: $topic)';
}
