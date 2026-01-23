import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frenchvanilla/mixins/rule_link_mixin.dart';

// Helper class to mix in the mixin
class TestWidget extends StatefulWidget {
  const TestWidget({super.key});
  @override
  State<TestWidget> createState() => TestWidgetState();
}

class TestWidgetState extends State<TestWidget> with RuleLinkMixin {
  @override
  Widget build(BuildContext context) => Container();
}

void main() {
  group('RuleLinkMixin', () {
    testWidgets('findRuleLinks extracts matches correctly', (tester) async {
      await tester.pumpWidget(
        const Placeholder(),
      ); // Just to access state? No, needs context helper technically but we are testing logic.
      // Actually, since findRuleLinks is in the mixin on State, we need an instance of the State.

      await tester.pumpWidget(const MaterialApp(home: TestWidget()));
      final state = tester.state<TestWidgetState>(find.byType(TestWidget));

      const text = "See rule 702.9a for flying. Also rule 500.";
      final matches = state.findRuleLinks(text);

      expect(matches.length, 2);
      expect(matches[0].ruleNumber, '702.9a');
      expect(matches[0].text, 'rule 702.9a');
      expect(matches[0].start, 4);

      expect(matches[1].ruleNumber, '500');
      expect(matches[1].text, 'rule 500');

      // Test implicit "See XXX.XXX" pattern
      const text2 = "Casualty 2. (See 702.153)";
      final matches2 = state.findRuleLinks(text2);
      expect(matches2.length, 1);
      expect(matches2[0].ruleNumber, '702.153');
      expect(
        matches2[0].text,
        'See 702.153',
      ); // 'See' is part of the match group 0
    });

    testWidgets('parseTextWithLinks uses pre-calculated links', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TestWidget()));
      final state = tester.state<TestWidgetState>(find.byType(TestWidget));

      const text = "See rule 702.";
      // Manually create a link that doesn't match the text strictly, to prove it uses the passed list
      final fakeMatches = [
        const RuleLinkMatch(
          start: 4,
          end: 13,
          ruleNumber: '999',
          text: 'rule 702.',
        ),
      ];

      final spans = state.parseTextWithLinks(
        text,
        const TextStyle(),
        preCalculatedLinks: fakeMatches,
      );

      // We expect: "See " (plain), "rule 702." (link)
      expect(spans.length, 2);
      expect(spans[1].text, 'rule 702.');
      // The recognizer should be set. We can't easily peek the rule number inside the closure,
      // but if it didn't throw, it successfully used the match.
    });

    testWidgets('parseTextWithLinks correctly highlights search query', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TestWidget()));
      final state = tester.state<TestWidgetState>(find.byType(TestWidget));

      const text = "Flying is a Keyword.";
      final spans = state.parseTextWithLinks(
        text,
        const TextStyle(),
        searchQuery: 'fly',
      );

      // "Fly" (highlighted), "ing is a Keyword." (plain)
      // Note: Implementation might split "Flying" into "Fly" and "ing"
      expect(spans.length, 2);
      expect(spans[0].text, 'Fly');
      // Checking for highlight weight
      expect(spans[0].style!.fontWeight, FontWeight.w900);
    });

    testWidgets('parseTextWithLinks correctly identifies glossary links', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TestWidget()));
      final state = tester.state<TestWidgetState>(find.byType(TestWidget));

      const text = "See Active Player, Nonactive Player Order. Also rule 702.";
      const validTerms = {'Active Player, Nonactive Player Order', 'Casualty'};

      final spans = state.parseTextWithLinks(
        text,
        const TextStyle(),
        validGlossaryTerms: validTerms,
      );

      for (var i = 0; i < spans.length; i++) {
        print('Span $i: "${spans[i].text}"');
      }

      // "See " (plain)
      // "Active Player, Nonactive Player Order" (link)
      // ". Also " (plain)
      // "rule 702." (link)

      // Note: "See " is NOT part of the link text in the glossary regex group 1,
      // but it IS part of group 0.
      // Wait, let's check the implementation of findGlossaryLinks.
      // match.group(0) is the full text "See Term".
      // match.group(1) is "Term".
      // The implementation uses `match.group(0)` as the link text!
      // "matches.add(..., text: match.group(0)!, ...)"
      // So the link will include "See ".

      expect(spans.length, 3);
      // 1. "See Active Player, Nonactive Player Order" (link) -> NO, implementation sorts by start.
      // "See ..." starts at 0.

      expect(spans[0].text, 'See Active Player, Nonactive Player Order');
      // expect(spans[0].style?.color, ...); // check if it has link style

      expect(spans[1].text, '. Also ');
      expect(spans[2].text, 'rule 702.');
    });
  });
}
