import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/heart_style.dart';
import '../widgets/heart_icon.dart';
import '../services/iap_service.dart';

/// Full-screen customization interface for Collector tier supporters
///
/// Allows selection from 26 different heart styles:
/// - 5 mono-color hearts (WUBRG)
/// - 10 guild hearts (two-color combinations)
/// - 10 tri-color hearts (shards + wedges)
/// - 1 rainbow heart (default)
///
/// Changes are saved to SharedPreferences and persist across app restarts.
class HeartCustomizationScreen extends StatefulWidget {
  const HeartCustomizationScreen({super.key});

  @override
  State<HeartCustomizationScreen> createState() =>
      _HeartCustomizationScreenState();
}

class _HeartCustomizationScreenState extends State<HeartCustomizationScreen> {
  // Currently selected style (updates in real-time as user taps)
  HeartStyle? _selectedStyle;

  // Original style when screen was opened (for cancel functionality)
  HeartStyle? _originalStyle;

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoadStyle();
  }

  /// Check Collector tier access and load saved style
  Future<void> _checkAccessAndLoadStyle() async {
    // Verify user has Collector tier access
    final hasAccess = IAPService().hasCollectorTier();

    if (!hasAccess) {
      // User doesn't have access - show error and close screen
      if (mounted) {
        await _showAccessDeniedDialog();
        if (mounted) {
          Navigator.pop(context);
        }
      }
      return;
    }

    // Load the saved style from SharedPreferences
    await _loadSavedStyle();
  }

  /// Load the currently saved heart style from SharedPreferences
  Future<void> _loadSavedStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final styleId = prefs.getString('collector_heart_style') ?? 'rainbow';

    setState(() {
      _selectedStyle = HeartStyle.getAllStyles().firstWhere(
        (s) => s.id == styleId,
        orElse: () => HeartStyle.rainbow(),
      );
      _originalStyle = _selectedStyle;
      _isLoading = false;
    });
  }

  /// Save the selected style to SharedPreferences
  Future<void> _saveStyle() async {
    if (_selectedStyle == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('collector_heart_style', _selectedStyle!.id);

    if (mounted) {
      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedStyle!.name} heart style saved!'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Return true to indicate save was successful
      Navigator.pop(context, true);
    }
  }

  /// Handle cancel action - optionally confirm if style changed
  void _handleCancel() {
    // Check if style was changed
    if (_selectedStyle?.id != _originalStyle?.id) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue Editing'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(this.context, false); // Close screen
              },
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    } else {
      // No changes, just close
      Navigator.pop(context, false);
    }
  }

  /// Show error dialog when user doesn't have Collector tier access
  Future<void> _showAccessDeniedDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Collector Tier Required'),
        content: const Text(
          'Heart customization is available exclusively for Collector tier supporters. '
          'Please purchase the Collector tier to access this feature.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Customize Collector Heart'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Collector Heart'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handleCancel,
        ),
      ),
      body: Column(
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Large preview at top
                  _buildPreviewSection(),
                  const SizedBox(height: 32),

                  // Mono colors section
                  _buildMonoColorsSection(),
                  const SizedBox(height: 24),

                  // Guild colors section
                  _buildGuildColorsSection(),
                  const SizedBox(height: 24),

                  // Tri-color combos section
                  _buildTriColorSection(),
                  const SizedBox(height: 24),

                  // Rainbow special section
                  _buildRainbowSection(),
                ],
              ),
            ),
          ),

          // Bottom action buttons
          _buildBottomButtons(),
        ],
      ),
    );
  }

  /// Large preview section showing currently selected style
  Widget _buildPreviewSection() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _selectedStyle != null
                ? HeartIcon(style: _selectedStyle!, size: 128)
                : const SizedBox(width: 128, height: 128),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedStyle?.name ?? 'None',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  /// Mono-color hearts section (5 options)
  Widget _buildMonoColorsSection() {
    final monoStyles = [
      HeartStyle.white(),
      HeartStyle.blue(),
      HeartStyle.black(),
      HeartStyle.red(),
      HeartStyle.green(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mono Colors',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildSwatchGrid(monoStyles),
      ],
    );
  }

  /// Guild colors section (10 two-color combinations)
  Widget _buildGuildColorsSection() {
    final guildStyles = [
      HeartStyle.azorius(),
      HeartStyle.orzhov(),
      HeartStyle.izzet(),
      HeartStyle.dimir(),
      HeartStyle.rakdos(),
      HeartStyle.golgari(),
      HeartStyle.gruul(),
      HeartStyle.boros(),
      HeartStyle.selesnya(),
      HeartStyle.simic(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Guild Colors (2-color)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildSwatchGrid(guildStyles),
      ],
    );
  }

  /// Tri-color combos section (shards + wedges)
  Widget _buildTriColorSection() {
    final triColorStyles = [
      // Shards
      HeartStyle.esper(),
      HeartStyle.grixis(),
      HeartStyle.jund(),
      HeartStyle.naya(),
      HeartStyle.bant(),
      // Wedges
      HeartStyle.abzan(),
      HeartStyle.jeskai(),
      HeartStyle.sultai(),
      HeartStyle.mardu(),
      HeartStyle.temur(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tri-Color Combos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildSwatchGrid(triColorStyles),
      ],
    );
  }

  /// Rainbow special section (default)
  Widget _buildRainbowSection() {
    final rainbowStyle = HeartStyle.rainbow();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Special',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildSwatchGrid([rainbowStyle]),
      ],
    );
  }

  /// Build a grid of heart swatches
  Widget _buildSwatchGrid(List<HeartStyle> styles) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: styles.map((style) => _buildSwatch(style)).toList(),
    );
  }

  /// Build a single tappable heart swatch
  Widget _buildSwatch(HeartStyle style) {
    final isSelected = _selectedStyle?.id == style.id;

    return InkWell(
      onTap: () => setState(() => _selectedStyle = style),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                )
              : Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.surface,
        ),
        child: Center(
          child: HeartIcon(style: style, size: 40),
        ),
      ),
    );
  }

  /// Bottom action buttons (Cancel and Save)
  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _handleCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: _saveStyle,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
