import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:os_media_controls/os_media_controls.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('media controls accept basic state updates', (
    WidgetTester tester,
  ) async {
    await OsMediaControls.setMetadata(
      const MediaMetadata(
        title: 'Integration Test Track',
        artist: 'OS Media Controls',
        duration: Duration(minutes: 1, seconds: 30),
      ),
    );

    await OsMediaControls.setPlaybackState(
      const MediaPlaybackState(
        state: PlaybackState.paused,
        position: Duration(seconds: 3),
        speed: 0,
      ),
    );

    await OsMediaControls.clear();
  });
}
