import 'package:flutter_test/flutter_test.dart';
import 'package:sageroute/services/share_links.dart';

void main() {
  const id = '20000000-0000-0000-0000-000000000001';
  final token = 'a' * 64;
  test(
    'one public URL maps to the same invitation in web and native schemes',
    () {
      final link = ShareLinks.invite(token);
      expect(link.toString(), 'https://sageroute.jijiz.cn/invite/$token');
      final location = ShareLinks.appLocation(link)!;
      expect(location, '/invite/$token');
      expect(ShareLinks.appLocation(ShareLinks.appUri(location)), location);
      expect(
        ShareLinks.appLocation(ShareLinks.post(id)),
        '/discover/posts/$id',
      );
      expect(
        ShareLinks.appLocation(Uri.parse('sageroute://routes/$id')),
        '/routes/$id',
      );
    },
  );
  test(
    'untrusted hosts, auth callbacks, invalid IDs and external paths are ignored',
    () {
      for (final url in [
        'https://evil.example/invite/$token',
        'http://sageroute.jijiz.cn/invite/$token',
        'https://sageroute.jijiz.cn/invite/short',
        'sageroute://auth/callback?code=secret',
        'sageroute://routes/new',
        'sageroute://discover/posts/not-a-uuid',
        'https://sageroute.jijiz.cn/invite/$token/extra',
      ]) {
        expect(ShareLinks.appLocation(Uri.parse(url)), isNull, reason: url);
      }
      expect(() => ShareLinks.invite('../auth'), throwsArgumentError);
      expect(() => ShareLinks.post('invalid'), throwsArgumentError);
    },
  );
}
