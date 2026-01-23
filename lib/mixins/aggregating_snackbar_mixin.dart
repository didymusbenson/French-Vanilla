import 'dart:async';
import 'package:flutter/material.dart';

/// Mixin that provides aggregating snackbar functionality to prevent sequential snackbar queuing.
///
/// Instead of showing multiple snackbars that queue up, this mixin:
/// - Shows a single snackbar that updates in place
/// - Aggregates counts when the same message is triggered multiple times
/// - Resets the timer on each new trigger
/// - Dismisses cleanly after inactivity
///
/// Usage:
/// ```dart
/// showAggregatingSnackBar('Bookmark added');
/// ```
mixin AggregatingSnackBarMixin<T extends StatefulWidget> on State<T> {
  int _snackBarCounter = 0;
  Timer? _snackBarTimer;
  String? _currentSnackBarMessage;

  /// Shows an aggregating snackbar that counts multiple triggers
  ///
  /// If the same message is triggered multiple times before the snackbar dismisses,
  /// the count will be shown in parentheses (e.g., "Bookmark added (3)")
  void showAggregatingSnackBar(String baseMessage) {
    // Cancel existing timer
    _snackBarTimer?.cancel();

    // If this is a different message, reset the counter
    if (_currentSnackBarMessage != baseMessage) {
      _snackBarCounter = 0;
      _currentSnackBarMessage = baseMessage;
    }

    // Increment counter
    _snackBarCounter++;

    // Hide current snackbar immediately (no animation)
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Build message with count if > 1
    final message = _snackBarCounter > 1
        ? '$baseMessage ($_snackBarCounter)'
        : baseMessage;

    // Show new snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );

    // Set timer to reset counter after snackbar would dismiss
    _snackBarTimer = Timer(const Duration(seconds: 2), () {
      _snackBarCounter = 0;
      _currentSnackBarMessage = null;
    });
  }

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    super.dispose();
  }
}
