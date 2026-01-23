import 'package:flutter_test/flutter_test.dart';
import 'package:frenchvanilla/models/glossary_term.dart';
import 'package:frenchvanilla/services/rules_parser.dart';

void main() {
  group('Glossary Classification', () {
    test('Classifies Casualty correctly as a keyword', () {
      // "Casualty" example provided by user:
      // "Casualty 2. (See 702.153)" -> implicit rule ref
      // Description includes "A keyword ability..."
      const term = 'Casualty';
      const definition =
          'Casualty 2. (See 702.153). A keyword ability that allows...';

      // We need to access the private _classifyGlossaryTerm logic.
      // Since it's private, we test it via parseGlossary public API.
      final content =
          '''
Glossary

$term
$definition
''';
      final terms = RulesParser.parseGlossary(content);

      expect(terms.length, 1);
      expect(terms[0].term, term);
      expect(terms[0].type, GlossaryTermType.keyword);
    });

    test('Classifies implicit keyword actions correctly', () {
      const term = 'Meld';
      const definition =
          'To meld two cards... (See 701.37)'; // Implicit 701 ref

      final content =
          '''
Glossary

$term
$definition
''';
      final terms = RulesParser.parseGlossary(content);
      expect(terms[0].type, GlossaryTermType.keywordAction);
    });

    test('Classifies explicit keyword ability phrase correctly', () {
      const term = 'TestKeyword';
      const definition =
          'This is a keyword ability that does something cool.'; // No rule ref, but has text

      final content =
          '''
Glossary

$term
$definition
''';
      final terms = RulesParser.parseGlossary(content);
      expect(terms[0].type, GlossaryTermType.keyword);
    });
  });
}
