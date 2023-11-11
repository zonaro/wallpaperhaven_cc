import 'package:flutter_test/flutter_test.dart';

import 'package:wallpaperhaven_cc/wallpaperhaven_cc.dart';

void main() {
  test('get wallpapers', () async {
    var t = await WallhavenClient.searchWallpapers("pokemon");
    assert(t.data.isNotEmpty);
  });
}
