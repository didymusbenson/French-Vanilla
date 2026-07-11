import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'content_resolver.dart';

/// Remote location of the published content. Points at the `master` branch of
/// the public repo — every pushed commit becomes the live snapshot, so
/// publishing is just `git push` (no separate CDN).
class RemoteContent {
  static const String _rawBase =
      'https://raw.githubusercontent.com/didymusbenson/French-Vanilla/master';
  static const String manifestUrl = '$_rawBase/assets/content_manifest.json';
  static String archiveUrl(String archive) => '$_rawBase/archives/$archive';
}

/// One category's entry in the remote manifest.
class CategoryManifest {
  final String key;
  final String label;
  final int version;
  final String archive;
  final String sha256;
  final int size;
  final String? updated;
  final List<String> files;

  const CategoryManifest({
    required this.key,
    required this.label,
    required this.version,
    required this.archive,
    required this.sha256,
    required this.size,
    required this.updated,
    required this.files,
  });

  factory CategoryManifest.fromJson(String key, Map<String, dynamic> json) {
    return CategoryManifest(
      key: key,
      label: json['label'] as String? ?? key,
      version: json['version'] as int? ?? 0,
      archive: json['archive'] as String? ?? '$key.zip',
      sha256: json['sha256'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      updated: json['updated'] as String?,
      files: (json['files'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

/// Result of comparing one remote category against the locally-active version.
class CategoryUpdate {
  final CategoryManifest remote;
  final int currentVersion;
  final bool hasOverride;

  const CategoryUpdate({
    required this.remote,
    required this.currentVersion,
    required this.hasOverride,
  });

  bool get available => remote.version > currentVersion;
}

/// Stateless check / download / revert helpers for over-the-air content
/// updates. Composes with the caller's own progress UI. Failures throw so the
/// UI can surface a message; a failed download never corrupts the live
/// override (the new copy is staged and swapped in atomically).
class ContentUpdateService {
  ContentUpdateService._();
  static final ContentUpdateService instance = ContentUpdateService._();

  final Dio _dio = Dio();

  /// Fetch the remote manifest and diff every category against the version
  /// currently active on this device. Throws on network / parse failure.
  Future<List<CategoryUpdate>> checkForUpdates() async {
    final response = await _dio.get<String>(
      RemoteContent.manifestUrl,
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );
    if (response.statusCode != 200 || response.data == null) {
      throw Exception('Server returned ${response.statusCode}');
    }

    final manifest = jsonDecode(response.data!) as Map<String, dynamic>;
    final cats = manifest['categories'] as Map<String, dynamic>? ?? {};

    final updates = <CategoryUpdate>[];
    for (final entry in cats.entries) {
      final remote = CategoryManifest.fromJson(
          entry.key, entry.value as Map<String, dynamic>);
      final current =
          await ContentResolver.instance.activeVersion(entry.key);
      final hasOverride =
          await ContentResolver.instance.hasOverride(entry.key);
      updates.add(CategoryUpdate(
        remote: remote,
        currentVersion: current,
        hasOverride: hasOverride,
      ));
    }
    return updates;
  }

  /// Download, verify, and install one category's archive, reporting progress
  /// in the range [0.0, 1.0]. Throws on network error, integrity mismatch, or
  /// IO failure — the existing override (if any) is preserved until the new
  /// content is fully staged.
  Future<void> downloadCategory(
    CategoryManifest cat, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final tmpDir = await getTemporaryDirectory();
    final tmpZip = File('${tmpDir.path}/${cat.key}_${cat.version}.zip');

    try {
      await _dio.download(
        RemoteContent.archiveUrl(cat.archive),
        tmpZip.path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
      );

      final bytes = await tmpZip.readAsBytes();
      final actualSha = sha256.convert(bytes).toString();
      if (cat.sha256.isNotEmpty && actualSha != cat.sha256) {
        throw Exception('Integrity check failed for ${cat.label}');
      }

      // Extract into a staging dir, then swap, so a mid-extract failure can
      // never leave a half-written override live.
      final overrideDir = await ContentResolver.instance.overrideDir(cat.key);
      final staging = Directory('${overrideDir.path}__staging');
      if (await staging.exists()) await staging.delete(recursive: true);
      await staging.create(recursive: true);

      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        if (!file.isFile) continue;
        final name = file.name.split('/').last; // flatten any nested paths
        final out = File('${staging.path}/$name');
        await out.writeAsBytes(file.content as List<int>, flush: true);
      }

      // Write the marker LAST: its presence guarantees a complete file set.
      final marker = File('${staging.path}/.manifest.json');
      await marker.writeAsString(jsonEncode({
        'version': cat.version,
        'sha256': cat.sha256,
        'size': cat.size,
        'updated': cat.updated,
      }));

      if (await overrideDir.exists()) await overrideDir.delete(recursive: true);
      await staging.rename(overrideDir.path);

      ContentResolver.instance.invalidate(cat.key);
    } finally {
      if (await tmpZip.exists()) await tmpZip.delete();
    }
  }

  /// Remove the downloaded override for [category], reverting to the bundled
  /// data on the next load.
  Future<void> revertCategory(String category) async {
    await ContentResolver.instance.deleteOverride(category);
  }
}
