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
  final Map<int, MtrSection> _mtrSectionCache = {};

  // IPG cache
  IpgIndex? _ipgIndex;
  final Map<int, IpgSection> _ipgSectionCache = {};

  // MTR methods

  /// Load the MTR index (table of contents)
  Future<MtrIndex> loadMtrIndex() async {
    if (_mtrIndex != null) return _mtrIndex!;

    final jsonString = await rootBundle.loadString('assets/judgedocs/mtr_index.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    _mtrIndex = MtrIndex.fromJson(jsonData);
    return _mtrIndex!;
  }

  /// Load a specific MTR section (1-8)
  Future<MtrSection> loadMtrSection(int sectionNumber) async {
    if (_mtrSectionCache.containsKey(sectionNumber)) {
      return _mtrSectionCache[sectionNumber]!;
    }

    final jsonString = await rootBundle.loadString(
      'assets/judgedocs/mtr_section_$sectionNumber.json'
    );
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    final sectionData = MtrSection.fromJson(jsonData);
    _mtrSectionCache[sectionNumber] = sectionData;
    return sectionData;
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
    if (sectionNumber == null || sectionNumber < 1 || sectionNumber > 8) {
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

  /// Load a specific IPG section (1-4)
  Future<IpgSection> loadIpgSection(int sectionNumber) async {
    if (_ipgSectionCache.containsKey(sectionNumber)) {
      return _ipgSectionCache[sectionNumber]!;
    }

    final jsonString = await rootBundle.loadString(
      'assets/judgedocs/ipg_section_$sectionNumber.json'
    );
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    final sectionData = IpgSection.fromJson(jsonData);
    _ipgSectionCache[sectionNumber] = sectionData;
    return sectionData;
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
