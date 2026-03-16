import '../models/celebrity_profile.dart';

class MockCelebrityRepository {
  const MockCelebrityRepository();

  Future<List<CelebrityProfile>> fetchCelebrities() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    return _mockRows.map(CelebrityProfile.fromMap).toList(growable: false);
  }
}

const List<Map<String, dynamic>> _mockRows = [
  {
    'id': 1,
    'name': '苏东坡',
    'dynasty': '北宋',
    'bio_short': '旷达豪迈，词文书画皆精，代表作众多。',
    'bio_ful': '苏轼，字子瞻，号东坡居士。北宋文学家、书画家，与父苏洵、弟苏辙并称“三苏”。',
    'avatar_url': '',
    'topic': [],
  },
  {
    'id': 2,
    'name': '白居易',
    'dynasty': '唐',
    'bio_short': '主张诗歌通俗晓畅，关怀民生，代表作《长恨歌》。',
    'bio_ful': '白居易，字乐天，号香山居士。唐代现实主义诗人，作品语言平易、意蕴深长。',
    'avatar_url': '',
    'topic': [],
  },
  {
    'id': 3,
    'name': '杨万里',
    'dynasty': '南宋',
    'bio_short': '擅写自然与生活，诗风清新活泼，富有童趣与观察力。',
    'bio_ful': '杨万里，字廷秀，号诚斋。南宋诗人，开创“诚斋体”，以描摹景物细致著称。',
    'avatar_url': '',
    'topic': [],
  },
];
