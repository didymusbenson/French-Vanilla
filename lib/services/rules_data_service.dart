import 'dart:convert';
import 'content_resolver.dart';
import '../models/section_data.dart';
import '../models/rule.dart';
import '../models/glossary_term.dart';
import 'rules_parser.dart';
import '../models/mtr_rule.dart';
import '../models/ipg_infraction.dart';
import 'judge_docs_service.dart';
import '../models/card.dart';

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
  final _judgeDocsService = JudgeDocsService();

  /// Load the index/table of contents
  Future<SectionData> loadIndex() async {
    if (_indexData != null) return _indexData!;

    final jsonString =
        await ContentResolver.instance.loadString('rules', 'index.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    _indexData = SectionData.fromJson(jsonData);
    return _indexData!;
  }

  /// Load a specific section (1-9)
  Future<SectionData> loadSection(int sectionNumber) async {
    if (_sectionCache.containsKey(sectionNumber)) {
      return _sectionCache[sectionNumber]!;
    }

    final jsonString = await ContentResolver.instance
        .loadString('rules', 'section_$sectionNumber.json');
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

    final jsonString =
        await ContentResolver.instance.loadString('rules', 'glossary.json');
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

    final jsonString =
        await ContentResolver.instance.loadString('rules', 'credits.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    _creditsData = SectionData.fromJson(jsonData);
    return _creditsData!;
  }

  /// Drop all cached rules data so the next access reloads from the (possibly
  /// just-updated) active source. Called after an over-the-air rules update.
  void reset() {
    _indexData = null;
    _sectionCache.clear();
    _rulesCache.clear();
    _glossaryData = null;
    _glossaryTerms = null;
    _creditsData = null;
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
            relevanceScore: _calculateRelevanceScore(
              query: lowerQuery,
              title: rule.title,
              titleMatch: true,
            ),
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
              relevanceScore: _calculateRelevanceScore(
                query: lowerQuery,
                content: subruleGroup.content,
                contentMatch: true,
              ),
            ));
          }
        }
      }
    }

    // Search glossary
    final glossaryTerms = await getGlossaryTerms();
    for (final term in glossaryTerms) {
      final termMatches = term.term.toLowerCase().contains(lowerQuery);
      final definitionMatches = term.definition.toLowerCase().contains(lowerQuery);

      if (termMatches || definitionMatches) {
        results.add(SearchResult(
          type: SearchResultType.glossary,
          title: term.term,
          snippet: _extractSnippet(term.definition, lowerQuery),
          glossaryTerm: term,
          relevanceScore: _calculateRelevanceScore(
            query: lowerQuery,
            title: term.term,
            content: term.definition,
            titleMatch: termMatches,
            contentMatch: definitionMatches && !termMatches,
          ),
        ));
      }
    }

    // Search MTR
    final mtrSections = await _judgeDocsService.getAllMtrSections();
    for (final section in mtrSections) {
      for (final rule in section.rules) {
        final titleMatches = rule.title.toLowerCase().contains(lowerQuery);
        final contentMatches = rule.content.toLowerCase().contains(lowerQuery);
        if (titleMatches || contentMatches) {
          results.add(SearchResult(
            type: SearchResultType.mtr,
            title: '${rule.number} ${rule.title}',
            snippet: contentMatches
                ? _extractSnippet(rule.content, lowerQuery)
                : rule.title,
            mtrRule: rule,
            mtrSectionNumber: section.sectionNumber,
            mtrSectionTitle: section.title,
            relevanceScore: _calculateRelevanceScore(
              query: lowerQuery,
              title: rule.title,
              content: rule.content,
              titleMatch: titleMatches,
              contentMatch: contentMatches && !titleMatches,
            ),
          ));
        }
      }
    }

    // Search IPG
    final ipgSections = await _judgeDocsService.getAllIpgSections();
    for (final section in ipgSections) {
      for (final infraction in section.infractions) {
        // Title match takes priority
        if (infraction.title.toLowerCase().contains(lowerQuery)) {
          results.add(SearchResult(
            type: SearchResultType.ipg,
            title: '${infraction.number} ${infraction.cleanTitle}',
            snippet: infraction.definition != null
                ? _extractSnippet(infraction.definition!, lowerQuery)
                : infraction.title,
            ipgInfraction: infraction,
            relevanceScore: _calculateRelevanceScore(
              query: lowerQuery,
              title: infraction.cleanTitle,
              titleMatch: true,
            ),
          ));
          continue;
        }

        // Search through definition, examples, philosophy, and upgrade
        final searchableFields = [
          infraction.definition,
          ...infraction.examples,
          infraction.philosophy,
          infraction.upgrade,
        ];

        for (final field in searchableFields) {
          if (field != null && field.toLowerCase().contains(lowerQuery)) {
            results.add(SearchResult(
              type: SearchResultType.ipg,
              title: '${infraction.number} ${infraction.cleanTitle}',
              snippet: _extractSnippet(field, lowerQuery),
              ipgInfraction: infraction,
              relevanceScore: _calculateRelevanceScore(
                query: lowerQuery,
                content: field,
                contentMatch: true,
              ),
            ));
            break; // Only add one result per infraction
          }
        }
      }
    }

    // Sort by relevance score (highest first)
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

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

  /// Calculate relevance score for search results
  /// Higher scores = better matches
  int _calculateRelevanceScore({
    required String query,
    String? title,
    String? content,
    bool titleMatch = false,
    bool contentMatch = false,
  }) {
    final lowerQuery = query.toLowerCase();
    final wordBoundaryRegex = RegExp(r'\b' + RegExp.escape(lowerQuery) + r'\b');

    if (title != null && titleMatch) {
      final lowerTitle = title.toLowerCase();

      // Exact match (after normalizing)
      if (lowerTitle == lowerQuery) {
        return 100;
      }

      // Word boundary match (exact word in title)
      // e.g., "layers" matches "Layers" but not "Players"
      if (wordBoundaryRegex.hasMatch(lowerTitle)) {
        return 90;
      }

      // Title starts with query
      if (lowerTitle.startsWith(lowerQuery)) {
        return 75;
      }

      // Title contains query (substring match)
      if (lowerTitle.contains(lowerQuery)) {
        return 50;
      }
    }

    // Content match - check for word boundaries first
    if (contentMatch && content != null) {
      final lowerContent = content.toLowerCase();

      // Word boundary in content (exact word match)
      // Ranks higher than substring in title to prioritize exact terms
      if (wordBoundaryRegex.hasMatch(lowerContent)) {
        return 60;
      }

      // Substring in content
      return 10;
    }

    return 0;
  }
}

enum SearchResultType {
  rule,
  glossary,
  mtr,
  ipg,
  card,
}

class SearchResult {
  final SearchResultType type;
  final int? sectionNumber;
  final String title;
  final String snippet;
  final Rule? rule;
  final SubruleGroup? subruleGroup;
  final GlossaryTerm? glossaryTerm;
  final MtrRule? mtrRule;
  final Object? mtrSectionNumber; // dynamic: int or String for appendices
  final String? mtrSectionTitle;
  final IpgInfraction? ipgInfraction;
  final MagicCard? card;
  final Ruling? cardRuling;
  final int relevanceScore;

  SearchResult({
    required this.type,
    this.sectionNumber,
    required this.title,
    required this.snippet,
    this.rule,
    this.subruleGroup,
    this.glossaryTerm,
    this.mtrRule,
    this.mtrSectionNumber,
    this.mtrSectionTitle,
    this.ipgInfraction,
    this.card,
    this.cardRuling,
    this.relevanceScore = 0,
  });
}
