import 'package:flutter_test/flutter_test.dart';

import 'package:whisper_cue_landing/main.dart';

void main() {
  test('uses Deacon for headings and Graphik for body text', () {
    expect(WhisperCueLandingApp.deaconStyle().fontFamily, 'Deacon');
    expect(WhisperCueLandingApp.graphikStyle().fontFamily, 'Graphik');
  });
}
