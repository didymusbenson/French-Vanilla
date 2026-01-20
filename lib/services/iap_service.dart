import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing in-app purchases in French Vanilla.
///
/// This service handles three tiers of non-consumable purchases:
/// - Thank You: Base support tier with red heart badge
/// - Play: Mid-tier with blue heart badge and additional features
/// - Collector: Premium tier with rainbow heart badge and all features
///
/// Purchase Flow:
/// 1. Initialize service on app start to restore previous purchases
/// 2. Query available products from app store
/// 3. User selects product to purchase
/// 4. Handle purchase completion and verification
/// 5. Cache purchase state locally for offline access
/// 6. Sync with platform receipts when online
///
/// Singleton pattern ensures consistent state across the app.
class IAPService {
  // Singleton instance
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  // Product IDs - must match IDs configured in App Store Connect and Google Play Console
  static const String thankYouId = 'com.loosetie.frenchvanilla.thank_you';
  static const String playId = 'com.loosetie.frenchvanilla.play';
  static const String collectorId = 'com.loosetie.frenchvanilla.collector';

  // SharedPreferences keys for local purchase cache
  static const String _thankYouKey = 'purchased_thank_you';
  static const String _playKey = 'purchased_play';
  static const String _collectorKey = 'purchased_collector';

  // IAP plugin instance
  final InAppPurchase _iap = InAppPurchase.instance;

  // Purchase stream subscription
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // Cached purchase state
  bool _hasThankYou = false;
  bool _hasPlay = false;
  bool _hasCollector = false;

  // Available products from the store
  List<ProductDetails> _products = [];

  // Stream controller to notify UI of purchase updates
  final _purchaseController = StreamController<PurchaseDetails>.broadcast();
  Stream<PurchaseDetails> get purchaseStream => _purchaseController.stream;

  // Initialization state
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize the IAP service.
  ///
  /// This should be called once on app startup. It:
  /// 1. Checks if IAP is available on the device
  /// 2. Loads cached purchase state from SharedPreferences
  /// 3. Sets up purchase stream listener
  /// 4. Queries and verifies purchases with the platform
  ///
  /// Returns true if initialization succeeded, false otherwise.
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Check if IAP is available on this device
      final available = await _iap.isAvailable();
      if (!available) {
        debugPrint('IAP not available on this device');
        return false;
      }

      // Load cached purchase state from local storage
      await _loadCachedPurchases();

      // Listen to purchase updates from the platform
      // This stream receives updates for:
      // - New purchases initiated by the user
      // - Restored purchases from previous devices/reinstalls
      // - Pending purchases (e.g., parental approval required)
      // - Failed purchases
      _purchaseSubscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdate,
        onDone: () => _purchaseSubscription?.cancel(),
        onError: (error) => debugPrint('Purchase stream error: $error'),
      );

      // Restore previous purchases from the platform
      // This queries the app store for any past purchases and syncs state
      await restorePurchases();

      _isInitialized = true;
      debugPrint('IAP service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Error initializing IAP: $e');
      return false;
    }
  }

  /// Check if in-app purchases are available on this device.
  ///
  /// Returns false if:
  /// - Device is in a restricted mode (e.g., parental controls)
  /// - App store is not accessible
  /// - Platform doesn't support IAP
  Future<bool> isAvailable() async {
    return await _iap.isAvailable();
  }

  /// Query all available products from the app store.
  ///
  /// Returns a list of ProductDetails containing:
  /// - Product ID
  /// - Localized title and description
  /// - Formatted price in user's currency
  ///
  /// Returns empty list if products can't be fetched.
  Future<List<ProductDetails>> getProducts() async {
    try {
      final Set<String> productIds = {thankYouId, playId, collectorId};

      // Query the app store for product details
      final ProductDetailsResponse response =
          await _iap.queryProductDetails(productIds);

      if (response.error != null) {
        debugPrint('Error querying products: ${response.error}');
        return [];
      }

      // Check if any products were not found
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      return _products;
    } catch (e) {
      debugPrint('Error getting products: $e');
      return [];
    }
  }

  /// Initiate a purchase for the specified product.
  ///
  /// The purchase flow is:
  /// 1. Find the product in our cached list
  /// 2. Create a purchase param object
  /// 3. Initiate the platform purchase UI
  /// 4. Wait for result in _handlePurchaseUpdate
  ///
  /// Throws an exception if the product is not found.
  Future<void> buyProduct(String productId) async {
    // Find the product details
    ProductDetails? product;
    try {
      product = _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      throw Exception('Product not found: $productId');
    }

    // Create purchase parameters
    // applicationUserName can be used to associate purchase with a user account
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
      applicationUserName: null, // Optional: can be used for user identification
    );

    // Initiate the purchase flow
    // This will show the platform's purchase UI (App Store or Google Play)
    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Error buying product: $e');
      rethrow;
    }
  }

  /// Restore previous purchases from the app store.
  ///
  /// This should be called:
  /// - On app initialization
  /// - When user taps a "Restore Purchases" button
  ///
  /// The platform will query the app store for all past purchases
  /// and trigger purchase updates through the purchase stream.
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      debugPrint('Restore purchases initiated');
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      rethrow;
    }
  }

  /// Handle purchase updates from the platform.
  ///
  /// This callback processes:
  /// - PurchaseStatus.pending: Purchase initiated but not complete (e.g., parental approval)
  /// - PurchaseStatus.purchased: Purchase successful and verified
  /// - PurchaseStatus.error: Purchase failed
  /// - PurchaseStatus.restored: Previous purchase restored
  /// - PurchaseStatus.canceled: User canceled the purchase
  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchase in purchaseDetailsList) {
      // Handle different purchase states
      if (purchase.status == PurchaseStatus.pending) {
        // Purchase is pending (e.g., waiting for parental approval)
        debugPrint('Purchase pending: ${purchase.productID}');
      } else if (purchase.status == PurchaseStatus.error) {
        // Purchase failed - show error to user
        debugPrint('Purchase error: ${purchase.error}');
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Purchase successful or restored
        _verifyAndDeliverPurchase(purchase);
      } else if (purchase.status == PurchaseStatus.canceled) {
        // User canceled the purchase
        debugPrint('Purchase canceled: ${purchase.productID}');
      }

      // Always complete the purchase on the platform side
      // This acknowledges receipt and prevents pending purchases from persisting
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }

      // Notify UI listeners of the purchase update
      _purchaseController.add(purchase);
    }
  }

  /// Verify and deliver a purchase.
  ///
  /// In a production app, you should:
  /// 1. Verify the purchase receipt with your backend server
  /// 2. Check the receipt against Apple/Google's verification APIs
  /// 3. Only then unlock the features
  ///
  /// For this app, we do basic verification and cache the purchase locally.
  Future<void> _verifyAndDeliverPurchase(PurchaseDetails purchase) async {
    // TODO: In production, verify receipt with backend server
    // For now, we trust the platform's verification

    final String productId = purchase.productID;
    debugPrint('Delivering purchase: $productId');

    // Update cached state based on product ID
    switch (productId) {
      case thankYouId:
        _hasThankYou = true;
        await _savePurchase(_thankYouKey, true);
        break;
      case playId:
        _hasPlay = true;
        await _savePurchase(_playKey, true);
        break;
      case collectorId:
        _hasCollector = true;
        await _savePurchase(_collectorKey, true);
        break;
      default:
        debugPrint('Unknown product ID: $productId');
    }
  }

  /// Load cached purchase state from SharedPreferences.
  ///
  /// This allows the app to work offline and provide instant
  /// access to purchased features without querying the app store.
  Future<void> _loadCachedPurchases() async {
    final prefs = await SharedPreferences.getInstance();
    _hasThankYou = prefs.getBool(_thankYouKey) ?? false;
    _hasPlay = prefs.getBool(_playKey) ?? false;
    _hasCollector = prefs.getBool(_collectorKey) ?? false;
    debugPrint('Loaded cached purchases - Thank You: $_hasThankYou, Play: $_hasPlay, Collector: $_hasCollector');
  }

  /// Save a purchase to SharedPreferences cache.
  Future<void> _savePurchase(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // ============================================================================
  // TIER OWNERSHIP CHECKS
  // These methods check if the user owns a specific tier
  // ============================================================================

  /// Check if user owns the Thank You tier.
  bool hasThankYouTier() => _hasThankYou;

  /// Check if user owns the Play tier.
  bool hasPlayTier() => _hasPlay;

  /// Check if user owns the Collector tier.
  bool hasCollectorTier() => _hasCollector;

  // ============================================================================
  // FEATURE ACCESS CHECKS
  // Higher tiers include all features from lower tiers
  // ============================================================================

  /// Check if user can access Thank You tier features.
  ///
  /// Returns true if user owns ANY tier (all tiers include Thank You features).
  bool canAccessThankYouFeatures() {
    return _hasThankYou || _hasPlay || _hasCollector;
  }

  /// Check if user can access Play tier features.
  ///
  /// Returns true if user owns Play or Collector tier.
  bool canAccessPlayFeatures() {
    return _hasPlay || _hasCollector;
  }

  /// Check if user can access Collector tier features.
  ///
  /// Returns true only if user owns the Collector tier.
  bool canAccessCollectorFeatures() {
    return _hasCollector;
  }

  // ============================================================================
  // UI HELPERS
  // These methods determine which heart badge to display
  // ============================================================================

  /// Show red heart badge (Thank You tier).
  ///
  /// Returns true if user owns Thank You tier but not higher tiers.
  bool shouldShowRedHeart() {
    return _hasThankYou && !_hasPlay && !_hasCollector;
  }

  /// Show blue heart badge (Play tier).
  ///
  /// Returns true if user owns Play tier but not Collector tier.
  bool shouldShowBlueHeart() {
    return _hasPlay && !_hasCollector;
  }

  /// Show rainbow heart badge (Collector tier).
  ///
  /// Returns true if user owns the premium Collector tier.
  bool shouldShowRainbowHeart() {
    return _hasCollector;
  }

  /// Dispose of resources when service is no longer needed.
  ///
  /// Call this when shutting down the app to properly clean up.
  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseController.close();
  }
}
