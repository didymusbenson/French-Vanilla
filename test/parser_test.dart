import 'package:flutter_test/flutter_test.dart';
import 'package:frenchvanilla/services/rules_parser.dart';

void main() {
  test('Parser extracts subrule groups correctly', () {
    const sampleContent = '''
1. Game Concepts

100. General

100.1. These Magic rules apply to any Magic game with two or more players.

100.1a A two-player game is a game that begins with only two players.

100.1b A multiplayer game is a game that begins with more than two players.

100.2. To play, each player needs their own deck.

100.2a In constructed play, each deck has a minimum deck size of 60 cards.

101. The Magic Golden Rules

101.1. Whenever a card's text directly contradicts these rules, the card takes precedence.
''';

    final rules = RulesParser.parseSection(sampleContent);

    print('Found ${rules.length} rules');
    for (final rule in rules) {
      print('Rule ${rule.number}: ${rule.title}');
      print('  Subrule groups: ${rule.subruleGroups.length}');
      for (final group in rule.subruleGroups) {
        print('    ${group.number}: ${group.content.substring(0, 50)}...');
      }
    }

    expect(rules.length, 2);
    expect(rules[0].number, '100');
    expect(rules[0].title, 'General');
    expect(rules[0].subruleGroups.length, 2);
    expect(rules[0].subruleGroups[0].number, '100.1');
    expect(rules[0].subruleGroups[1].number, '100.2');
  });
}
