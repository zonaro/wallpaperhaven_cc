import 'package:flutter_test/flutter_test.dart';
import 'package:wallhaven_cc/wallhaven_client.dart';

void main() {
  test('get wallpapers', () async {
    var t = await WallhavenClient.searchWallpapers("pokemon");
    assert(t.data.isNotEmpty);
  });
}
