import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Resolves a data file to either a downloaded override (when a newer version
/// has been fetched over-the-air) or the bundled asset.
///
/// The data services ([RulesDataService], [JudgeDocsService],
/// [CardDataService]) load every JSON file through here, so the rest of the
/// app stays agnostic about where the bytes came from. An override "wins" only
/// when its version is strictly greater than the bundled version; otherwise it
/// is treated as stale, deleted (self-healing), and the bundled asset is used.
class ContentResolver {
  ContentResolver._();
  static final ContentResolver instance = ContentResolver._();

  /// Asset directory backing each content category's bundled files. (MTR and
  /// IPG share the judgedocs asset dir, but use separate override dirs and
  /// distinct filename prefixes, so they never collide.)
  static const Map<String, String> assetDirs = {
    'rules': 'assets/rulesdocs',
    'mtr': 'assets/judgedocs',
    'ipg': 'assets/judgedocs',
    'rulings': 'assets/carddata',
  };

  static const String manifestAsset = 'assets/content_manifest.json';

  // Per-session memo of the active override dir for each category. A stored
  // value of null means "no valid override — read from bundled assets".
  final Map<String, String?> _activeDir = {};
  Map<String, dynamic>? _bundledManifest;

  /// Load [fileName] for [category], preferring a valid override.
  Future<String> loadString(String category, String fileName) async {
    final dir = await _resolveDir(category);
    if (dir != null) {
      final file = File('$dir/$fileName');
      if (await file.exists()) return file.readAsString();
    }
    return rootBundle.loadString('${assetDirs[category]}/$fileName');
  }

  /// Forget the cached resolution for [category]. Call after a download or
  /// revert so the next load re-evaluates which source wins.
  void invalidate(String category) => _activeDir.remove(category);

  Future<Map<String, dynamic>> _manifest() async {
    _bundledManifest ??=
        jsonDecode(await rootBundle.loadString(manifestAsset))
            as Map<String, dynamic>;
    return _bundledManifest!;
  }

  Map<String, dynamic>? _categoryEntry(
      Map<String, dynamic> manifest, String category) {
    final cats = manifest['categories'] as Map<String, dynamic>?;
    return cats?[category] as Map<String, dynamic>?;
  }

  /// Version of the bundled (shipped-with-the-app) data for [category].
  Future<int> bundledVersion(String category) async {
    final entry = _categoryEntry(await _manifest(), category);
    return (entry?['version'] as int?) ?? 0;
  }

  Future<Directory> overrideDir(String category) async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/content/$category');
  }

  Future<File> overrideMarker(String category) async =>
      File('${(await overrideDir(category)).path}/.manifest.json');

  /// True when a downloaded override is currently installed for [category].
  Future<bool> hasOverride(String category) async =>
      (await overrideMarker(category)).exists();

  /// The version actually in use for [category] — the higher of bundled vs. a
  /// valid override.
  Future<int> activeVersion(String category) async {
    final bundled = await bundledVersion(category);
    return (await _validOverrideVersion(category, bundled)) ?? bundled;
  }

  /// The "updated" display date for the active source of [category].
  Future<String?> activeUpdatedDate(String category) async {
    final bundled = await bundledVersion(category);
    try {
      final marker = await overrideMarker(category);
      if (await marker.exists()) {
        final m =
            jsonDecode(await marker.readAsString()) as Map<String, dynamic>;
        if ((m['version'] as int? ?? 0) > bundled) {
          return m['updated'] as String?;
        }
      }
    } catch (_) {
      // fall through to bundled date
    }
    return _categoryEntry(await _manifest(), category)?['updated'] as String?;
  }

  /// Returns the override version if a valid (newer-than-bundled) override is
  /// present, else null. Deletes stale/corrupt overrides as a side effect.
  Future<int?> _validOverrideVersion(String category, int bundled) async {
    try {
      final marker = await overrideMarker(category);
      if (!await marker.exists()) return null;
      final m = jsonDecode(await marker.readAsString()) as Map<String, dynamic>;
      final version = m['version'] as int? ?? 0;
      if (version > bundled) return version;
      // Bundled has caught up to (or passed) the override — it's dead weight.
      await deleteOverride(category);
      return null;
    } catch (_) {
      // Corrupt marker — wipe and fall back to bundled.
      await deleteOverride(category);
      return null;
    }
  }

  Future<String?> _resolveDir(String category) async {
    if (_activeDir.containsKey(category)) return _activeDir[category];
    final bundled = await bundledVersion(category);
    final overrideVersion = await _validOverrideVersion(category, bundled);
    final result =
        overrideVersion != null ? (await overrideDir(category)).path : null;
    _activeDir[category] = result;
    return result;
  }

  /// Delete any override for [category] (best-effort) and clear its memo.
  Future<void> deleteOverride(String category) async {
    try {
      final dir = await overrideDir(category);
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {
      // Best-effort; never throw from a load path.
    }
    _activeDir.remove(category);
  }
}
