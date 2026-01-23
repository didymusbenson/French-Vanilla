import 'package:flutter_test/flutter_test.dart';
import 'package:frenchvanilla/models/glossary_term.dart';
import 'package:frenchvanilla/services/rules_parser.dart';

void main() {
  group('RulesParser Glossary Classification', () {
    test('Classifies obsolete terms correctly', () {
      const content = '''
Glossary

Old Term
(Obsolete) Some definition.

''';
      final terms = RulesParser.parseGlossary(content);
      expect(terms.first.type, GlossaryTermType.obsolete);
    });

    test('Classifies tokens correctly', () {
      const content = '''
Glossary

Treasure Token
A token that does something.

''';
      final terms = RulesParser.parseGlossary(content);
      expect(terms.first.type, GlossaryTermType.token);
    });

    test('Classifies keywords correctly', () {
      const content = '''
Glossary

Flying
A keyword ability. See rule 702.9.

''';
      final terms = RulesParser.parseGlossary(content);
      expect(terms.first.type, GlossaryTermType.keyword);
    });

    test('Classifies keyword actions correctly', () {
      const content = '''
Glossary

Destroy
To put into graveyard. See rule 701.7.

''';
      final terms = RulesParser.parseGlossary(content);
      expect(terms.first.type, GlossaryTermType.keywordAction);
    });

    test('Classifies card types correctly', () {
      const content = '''
Glossary

Creature
A card type. See rule 302.

Artifact
Another card type. See rule 301.

''';
      final terms = RulesParser.parseGlossary(content);
      expect(terms[0].type, GlossaryTermType.cardType);
      expect(terms[1].type, GlossaryTermType.cardType);
    });

    test('Classifies zones correctly', () {
      const content = '''
Glossary

Graveyard
A zone. See rule 404.

''';
      final terms = RulesParser.parseGlossary(content);
      expect(terms.first.type, GlossaryTermType.zone);
    });

    test('Classifies phases and steps correctly', () {
      const content = '''
Glossary

Upkeep Step
Part of the turn.

Combat Phase
Another part.

''';
      final terms = RulesParser.parseGlossary(content);
      expect(terms[0].type, GlossaryTermType.phaseStep);
      expect(terms[1].type, GlossaryTermType.phaseStep);
    });

    test('Classifies other terms correctly', () {
      const content = '''
Glossary

Random Term
Some general definition.

''';
      final terms = RulesParser.parseGlossary(content);
      expect(terms.first.type, GlossaryTermType.other);
    });
    
    test('Priority: Obsolete takes precedence', () {
      const content = '''
Glossary

Old Keyword
(Obsolete) Was a keyword. See rule 702.1.

''';
      final terms = RulesParser.parseGlossary(content);
      expect(terms.first.type, GlossaryTermType.obsolete);
    });
  });
}
