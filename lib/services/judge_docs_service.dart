import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/mtr_rule.dart';
import '../models/ipg_infraction.dart';

/// Service for loading and caching MTR and IPG judge documents.
class JudgeDocsService {
  static final JudgeDocsService _instance = JudgeDocsService._internal();
  factory JudgeDocsService() => _instance;
  JudgeDocsService._internal();

  // MTR cache
  MtrIndex? _mtrIndex;
  final Map<String, MtrSection> _mtrSectionCache = {};

  // IPG cache
  IpgIndex? _ipgIndex;
  final Map<String, IpgSection> _ipgSectionCache = {};

  // MTR methods

  /// Load the MTR index (table of contents)
  Future<MtrIndex> loadMtrIndex() async {
    if (_mtrIndex != null) return _mtrIndex!;

    final jsonString = await rootBundle.loadString('assets/judgedocs/mtr_index.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    _mtrIndex = MtrIndex.fromJson(jsonData);
    return _mtrIndex!;
  }

  /// Load a specific MTR section by section key (e.g., "mtr_section_1" or "mtr_appendix_a")
  Future<MtrSection> loadMtrSectionByKey(String sectionKey) async {
    // Check cache using section key as string
    if (_mtrSectionCache.containsKey(sectionKey)) {
      return _mtrSectionCache[sectionKey]!;
    }

    final jsonString = await rootBundle.loadString(
      'assets/judgedocs/$sectionKey.json'
    );
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    final sectionData = MtrSection.fromJson(jsonData);
    _mtrSectionCache[sectionKey] = sectionData;
    return sectionData;
  }

  /// Load a specific MTR section by number (1-10) or appendix letter (A-F)
  Future<MtrSection> loadMtrSection(dynamic sectionNumber) async {
    String sectionKey;
    if (sectionNumber is int) {
      sectionKey = 'mtr_section_$sectionNumber';
    } else if (sectionNumber is String) {
      sectionKey = 'mtr_appendix_${sectionNumber.toLowerCase()}';
    } else {
      throw ArgumentError('Invalid section number: $sectionNumber');
    }

    return loadMtrSectionByKey(sectionKey);
  }

  /// Get all MTR sections
  Future<List<MtrSection>> getAllMtrSections() async {
    final index = await loadMtrIndex();
    final sections = <MtrSection>[];

    for (final sectionInfo in index.sections) {
      final section = await loadMtrSection(sectionInfo.sectionNumber);
      sections.add(section);
    }

    return sections;
  }

  /// Find a specific MTR rule by number (e.g., "1.1")
  Future<MtrRule?> findMtrRule(String ruleNumber) async {
    // Parse section number from rule number (e.g., "1.1" -> section 1)
    final parts = ruleNumber.split('.');
    if (parts.isEmpty) return null;

    final sectionNumber = int.tryParse(parts[0]);
    if (sectionNumber == null || sectionNumber < 1 || sectionNumber > 10) {
      return null;
    }

    final section = await loadMtrSection(sectionNumber);

    // Find the rule
    for (final rule in section.rules) {
      if (rule.number == ruleNumber) {
        return rule;
      }
    }

    return null;
  }

  // IPG methods

  /// Load the IPG index (table of contents)
  Future<IpgIndex> loadIpgIndex() async {
    if (_ipgIndex != null) return _ipgIndex!;

    final jsonString = await rootBundle.loadString('assets/judgedocs/ipg_index.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    _ipgIndex = IpgIndex.fromJson(jsonData);
    return _ipgIndex!;
  }

  /// Load a specific IPG section by section key (e.g., "ipg_section_1" or "ipg_appendix_a")
  Future<IpgSection> loadIpgSectionByKey(String sectionKey) async {
    // Check cache using section key as string
    if (_ipgSectionCache.containsKey(sectionKey)) {
      return _ipgSectionCache[sectionKey]!;
    }

    final jsonString = await rootBundle.loadString(
      'assets/judgedocs/$sectionKey.json'
    );
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    final sectionData = IpgSection.fromJson(jsonData);
    _ipgSectionCache[sectionKey] = sectionData;
    return sectionData;
  }

  /// Load a specific IPG section by number (1-4) or appendix letter (A-B)
  Future<IpgSection> loadIpgSection(dynamic sectionNumber) async {
    String sectionKey;
    if (sectionNumber is int) {
      sectionKey = 'ipg_section_$sectionNumber';
    } else if (sectionNumber is String) {
      sectionKey = 'ipg_appendix_${sectionNumber.toLowerCase()}';
    } else {
      throw ArgumentError('Invalid section number: $sectionNumber');
    }

    return loadIpgSectionByKey(sectionKey);
  }

  /// Get all IPG sections
  Future<List<IpgSection>> getAllIpgSections() async {
    final index = await loadIpgIndex();
    final sections = <IpgSection>[];

    for (final sectionInfo in index.sections) {
      final section = await loadIpgSection(sectionInfo.sectionNumber);
      sections.add(section);
    }

    return sections;
  }

  /// Find a specific IPG infraction by number (e.g., "2.1")
  Future<IpgInfraction?> findIpgInfraction(String infractionNumber) async {
    // Parse section number from infraction number (e.g., "2.1" -> section 2)
    final parts = infractionNumber.split('.');
    if (parts.isEmpty) return null;

    final sectionNumber = int.tryParse(parts[0]);
    if (sectionNumber == null || sectionNumber < 1 || sectionNumber > 4) {
      return null;
    }

    final section = await loadIpgSection(sectionNumber);

    // Find the infraction
    for (final infraction in section.infractions) {
      if (infraction.number == infractionNumber) {
        return infraction;
      }
    }

    return null;
  }

  /// Clear all caches (useful for testing or memory management)
  void clearCache() {
    _mtrIndex = null;
    _mtrSectionCache.clear();
    _ipgIndex = null;
    _ipgSectionCache.clear();
  }
}
