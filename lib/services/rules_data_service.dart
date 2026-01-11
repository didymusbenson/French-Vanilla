import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/section_data.dart';
import '../models/rule.dart';
import '../models/glossary_term.dart';
import 'rules_parser.dart';

class RulesDataService {
  static final RulesDataService _instance = RulesDataService._internal();
  factory RulesDataService() => _instance;
  RulesDataService._internal();

  // Cache for loaded data
  SectionData? _indexData;
  final Map<int, SectionData> _sectionCache = {};
  final Map<int, List<Rule>> _rulesCache = {};
  SectionData? _glossaryData;
  List<GlossaryTerm>? _glossaryTerms;
  SectionData? _creditsData;

  /// Load the index/table of contents
  Future<SectionData> loadIndex() async {
    if (_indexData != null) return _indexData!;

    final jsonString = await rootBundle.loadString('assets/rulesdocs/index.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    _indexData = SectionData.fromJson(jsonData);
    return _indexData!;
  }

  /// Load a specific section (1-9)
  Future<SectionData> loadSection(int sectionNumber) async {
    if (_sectionCache.containsKey(sectionNumber)) {
      return _sectionCache[sectionNumber]!;
    }

    final jsonString = await rootBundle.loadString(
      'assets/rulesdocs/section_$sectionNumber.json'
    );
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    final sectionData = SectionData.fromJson(jsonData);
    _sectionCache[sectionNumber] = sectionData;
    return sectionData;
  }

  /// Get parsed rules for a section
  Future<List<Rule>> getRulesForSection(int sectionNumber) async {
    if (_rulesCache.containsKey(sectionNumber)) {
      return _rulesCache[sectionNumber]!;
    }

    final sectionData = await loadSection(sectionNumber);
    final rules = RulesParser.parseSection(sectionData.content);
    _rulesCache[sectionNumber] = rules;
    return rules;
  }

  /// Load glossary
  Future<SectionData> loadGlossary() async {
    if (_glossaryData != null) return _glossaryData!;

    final jsonString = await rootBundle.loadString('assets/rulesdocs/glossary.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    _glossaryData = SectionData.fromJson(jsonData);
    return _glossaryData!;
  }

  /// Get parsed glossary terms
  Future<List<GlossaryTerm>> getGlossaryTerms() async {
    if (_glossaryTerms != null) return _glossaryTerms!;

    final glossaryData = await loadGlossary();
    _glossaryTerms = RulesParser.parseGlossary(glossaryData.content);
    return _glossaryTerms!;
  }

  /// Load credits
  Future<SectionData> loadCredits() async {
    if (_creditsData != null) return _creditsData!;

    final jsonString = await rootBundle.loadString('assets/rulesdocs/credits.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    _creditsData = SectionData.fromJson(jsonData);
    return _creditsData!;
  }

  /// Search across all rules content
  Future<List<SearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final results = <SearchResult>[];
    final lowerQuery = query.toLowerCase();

    // Search through all sections
    for (int i = 1; i <= 9; i++) {
      final rules = await getRulesForSection(i);

      for (final rule in rules) {
        // Check if rule title matches
        if (rule.title.toLowerCase().contains(lowerQuery)) {
          results.add(SearchResult(
            type: SearchResultType.rule,
            sectionNumber: i,
            title: '${rule.number}. ${rule.title}',
            snippet: rule.title,
            rule: rule,
          ));
          continue; // Don't also search subrules if title matches
        }

        // Search through subrule groups
        for (final subruleGroup in rule.subruleGroups) {
          if (subruleGroup.content.toLowerCase().contains(lowerQuery)) {
            results.add(SearchResult(
              type: SearchResultType.rule,
              sectionNumber: i,
              title: '${rule.number}. ${rule.title} → ${subruleGroup.number}',
              snippet: _extractSnippet(subruleGroup.content, lowerQuery),
              rule: rule,
              subruleGroup: subruleGroup,
            ));
          }
        }
      }
    }

    // Search glossary
    final glossaryTerms = await getGlossaryTerms();
    for (final term in glossaryTerms) {
      if (term.term.toLowerCase().contains(lowerQuery) ||
          term.definition.toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          type: SearchResultType.glossary,
          title: term.term,
          snippet: _extractSnippet(term.definition, lowerQuery),
          glossaryTerm: term,
        ));
      }
    }

    return results;
  }

  String _extractSnippet(String content, String query, {int contextLength = 100}) {
    final lowerContent = content.toLowerCase();
    final index = lowerContent.indexOf(query);

    if (index == -1) {
      return content.length > contextLength
        ? '${content.substring(0, contextLength)}...'
        : content;
    }

    final start = (index - contextLength ~/ 2).clamp(0, content.length);
    final end = (index + query.length + contextLength ~/ 2).clamp(0, content.length);

    var snippet = content.substring(start, end);
    if (start > 0) snippet = '...$snippet';
    if (end < content.length) snippet = '$snippet...';

    return snippet;
  }
}

enum SearchResultType {
  rule,
  glossary,
}

class SearchResult {
  final SearchResultType type;
  final int? sectionNumber;
  final String title;
  final String snippet;
  final Rule? rule;
  final SubruleGroup? subruleGroup;
  final GlossaryTerm? glossaryTerm;

  SearchResult({
    required this.type,
    this.sectionNumber,
    required this.title,
    required this.snippet,
    this.rule,
    this.subruleGroup,
    this.glossaryTerm,
  });
}
