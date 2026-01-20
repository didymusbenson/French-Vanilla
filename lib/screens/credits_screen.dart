import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/rules_data_service.dart';
import '../services/iap_service.dart';
import '../widgets/heart_icon.dart';
import '../widgets/purchase_menu.dart';
import '../models/heart_style.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  final _dataService = RulesDataService();
  String? _comprehensiveRulesCredits;
  String _version = '';
  bool _isLoading = true;
  String? _error;
  HeartStyle _collectorHeartStyle = HeartStyle.rainbow();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final creditsData = await _dataService.loadCredits();
      final packageInfo = await PackageInfo.fromPlatform();

      // Load saved collector heart style
      final prefs = await SharedPreferences.getInstance();
      final styleId = prefs.getString('collector_heart_style');
      HeartStyle collectorStyle = HeartStyle.rainbow();
      if (styleId != null) {
        collectorStyle = HeartStyle.getAllStyles().firstWhere(
          (s) => s.id == styleId,
          orElse: () => HeartStyle.rainbow(),
        );
      }

      setState(() {
        _comprehensiveRulesCredits = creditsData.content;
        _version = 'Version ${packageInfo.version} (${packageInfo.buildNumber})';
        _collectorHeartStyle = collectorStyle;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load credits: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // French Vanilla Credits Section
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'French Vanilla',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showSupporterModal,
                        child: _buildHeartRow(),
                      ),
                    ],
                  ),
                  if (_version.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _version,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Developed by Didymus Benson',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Comprehensive Rules content © Wizards of the Coast LLC.\n\n'
                    'French Vanilla is unofficial Fan Content permitted under the Fan '
                    'Content Policy. Not approved/endorsed by Wizards. Portions of the '
                    'materials used are property of Wizards of the Coast. © Wizards of '
                    'the Coast LLC.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => showLicensePage(
                        context: context,
                        applicationName: 'French Vanilla',
                        applicationVersion: _version,
                      ),
                      icon: const Icon(Icons.description),
                      label: const Text('View Open Source Licenses'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showPurchaseMenu,
                      icon: const Icon(Icons.favorite_border),
                      label: const Text('Support French Vanilla'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Comprehensive Rules Credits Section
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comprehensive Rules Credits',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    _comprehensiveRulesCredits ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRow() {
    final iapService = IAPService();

    // Determine which hearts to show
    final showRed = iapService.shouldShowRedHeart();
    final showBlue = iapService.shouldShowBlueHeart();
    final showRainbow = iapService.shouldShowRainbowHeart();

    // If no purchases, show empty heart
    if (!showRed && !showBlue && !showRainbow) {
      return Icon(
        Icons.favorite_border,
        size: 24,
        color: Theme.of(context).colorScheme.primary,
      );
    }

    // Build heart list
    final hearts = <Widget>[];
    if (showRed) {
      hearts.add(HeartIcon(style: HeartStyle.red(), size: 24));
    }
    if (showBlue) {
      hearts.add(HeartIcon(style: HeartStyle.blue(), size: 24));
    }
    if (showRainbow) {
      hearts.add(HeartIcon(style: _collectorHeartStyle, size: 24));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: hearts.map((h) => Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: h,
      )).toList(),
    );
  }

  void _showSupporterModal() {
    final iapService = IAPService();

    if (!iapService.hasThankYouTier() && !iapService.hasPlayTier() && !iapService.hasCollectorTier()) {
      _showPurchaseMenu();
    } else if (iapService.hasCollectorTier()) {
      _showCollectorTierModal();
    } else if (iapService.hasPlayTier()) {
      _showPlayTierModal();
    } else {
      _showThankYouTierModal();
    }
  }

  void _showThankYouTierModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thank You Supporter'),
        content: const Text('You\'ve unlocked the Thank You heart!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _showPurchaseMenu(scrollToTier: 'play');
            },
            child: const Text('Upgrade to Play Tier (\$5.49)'),
          ),
        ],
      ),
    );
  }

  void _showPlayTierModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Play Supporter'),
        content: const Text('You\'ve unlocked the Thank You and Play hearts!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _showPurchaseMenu(scrollToTier: 'collector');
            },
            child: const Text('Upgrade to Collector Tier (\$26.99)'),
          ),
        ],
      ),
    );
  }

  void _showCollectorTierModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Collector Supporter'),
        content: const Text(
          'You\'ve unlocked all supporter hearts! Customize your Collector heart below.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final didSave = await Navigator.pushNamed(context, '/heart-customization');
              if (didSave == true && mounted) {
                // Reload the saved style
                final prefs = await SharedPreferences.getInstance();
                final styleId = prefs.getString('collector_heart_style');
                if (styleId != null) {
                  final style = HeartStyle.getAllStyles().firstWhere(
                    (s) => s.id == styleId,
                    orElse: () => HeartStyle.rainbow(),
                  );
                  setState(() {
                    _collectorHeartStyle = style;
                  });
                }
              }
            },
            child: const Text('Customize Heart'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseMenu({String? scrollToTier}) async {
    final result = await PurchaseMenu.show(context, scrollToTier: scrollToTier);
    if (result == true && mounted) {
      // Reload saved heart style and refresh UI
      final prefs = await SharedPreferences.getInstance();
      final styleId = prefs.getString('collector_heart_style');
      if (styleId != null) {
        final style = HeartStyle.getAllStyles().firstWhere(
          (s) => s.id == styleId,
          orElse: () => HeartStyle.rainbow(),
        );
        setState(() {
          _collectorHeartStyle = style;
        });
      } else {
        setState(() {}); // Refresh to show new hearts
      }
    }
  }
}
