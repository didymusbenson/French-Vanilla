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

    test('Classifies counters correctly', () {
      const content = '''
Glossary

Poison Counter
A counter that kills you. See rule 122.

Energy Symbol
See rule 107.
''';
      // Note: Energy Symbol currently falls to Other unless definition matches rule 122?
      // Wait, "Rule 122" is the key. Energy Symbol def in real glossary is:
      // "The energy symbol {E} represents one energy counter... See rule 122..."
      
      const content2 = '''
Glossary

Energy Symbol
See rule 122.
''';

      final terms = RulesParser.parseGlossary(content);
      expect(terms[0].type, GlossaryTermType.counter);
      
      final terms2 = RulesParser.parseGlossary(content2);
      expect(terms2[0].type, GlossaryTermType.counter);
    });

    test('Classifies counter mechanics correctly', () {
      const content = '''
Glossary

Adapt
keyword action that puts +1/+1 counters on a creature.

Wither
deals damage to creatures in the form of -1/-1 counters.
''';
      final terms = RulesParser.parseGlossary(content);
      expect(terms[0].type, GlossaryTermType.counter, reason: 'Adapt should be counter type');
      expect(terms[1].type, GlossaryTermType.counter, reason: 'Wither should be counter type');
    });

    test('Classifies multiplayer terms correctly', () {
      const content = '''
Glossary

Two-Headed Giant Variant
See rule 810.

Commander
See rule 903.
''';
      final terms = RulesParser.parseGlossary(content);
      expect(terms[0].type, GlossaryTermType.multiplayer);
      expect(terms[1].type, GlossaryTermType.multiplayer);
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
