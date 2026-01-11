import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Subsection pattern matches correctly', () {
    final pattern = RegExp(r'^\d{3}\.\d+([a-z]|\.)\s');

    // Should match
    expect(pattern.hasMatch('100.1. These Magic rules'), isTrue);
    expect(pattern.hasMatch('100.1a A two-player game'), isTrue);
    expect(pattern.hasMatch('100.1b A multiplayer game'), isTrue);
    expect(pattern.hasMatch('100.2. To play, each player'), isTrue);
    expect(pattern.hasMatch('100.2a In constructed play'), isTrue);

    // Should NOT match
    expect(pattern.hasMatch('These Magic rules'), isFalse);
    expect(pattern.hasMatch('A two-player game'), isFalse);
    expect(pattern.hasMatch('100. General'), isFalse);

    print('All pattern tests passed!');
  });
}
