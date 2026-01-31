import 'card_data_service.dart';
import 'judge_docs_service.dart';

/// Service to preload all data in the background on app startup.
/// This ensures instant navigation to all categories.
class DataPreloader {
  static final DataPreloader _instance = DataPreloader._internal();
  factory DataPreloader() => _instance;
  DataPreloader._internal();

  bool _isPreloading = false;
  bool _isComplete = false;

  /// Preload all data in the background
  Future<void> preloadAll() async {
    if (_isPreloading || _isComplete) return;

    _isPreloading = true;

    try {
      // Preload all data in parallel for fastest loading
      await Future.wait([
        _preloadCardRulings(),
        _preloadMtrData(),
        _preloadIpgData(),
      ]);

      _isComplete = true;
    } catch (e) {
      // Log error but don't crash the app
      print('Data preload error: $e');
    } finally {
      _isPreloading = false;
    }
  }

  /// Preload card rulings data
  Future<void> _preloadCardRulings() async {
    try {
      await CardDataService().loadAllCards();
    } catch (e) {
      print('Failed to preload card rulings: $e');
    }
  }

  /// Preload MTR index and metadata
  Future<void> _preloadMtrData() async {
    try {
      await JudgeDocsService().loadMtrIndex();
    } catch (e) {
      print('Failed to preload MTR data: $e');
    }
  }

  /// Preload IPG index and metadata
  Future<void> _preloadIpgData() async {
    try {
      await JudgeDocsService().loadIpgIndex();
    } catch (e) {
      print('Failed to preload IPG data: $e');
    }
  }

  /// Check if preloading is complete
  bool get isComplete => _isComplete;

  /// Check if currently preloading
  bool get isPreloading => _isPreloading;
}
