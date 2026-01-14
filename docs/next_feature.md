# Next Feature: In-App Purchase System

## Feature Overview
Add a tiered supporter system allowing users to support French Vanilla development and unlock exclusive tier-based features. Each tier is represented by a unique heart badge on the Credits screen, which persists across devices via App Store/Play Store.

## Purchase Tiers
1. **Thank You Tier**: $1.99 USD → Red heart (Icons.favorite, MagicColors.magicRedDark)
2. **Play Tier**: $5.49 USD → Blue heart (Icons.favorite, MagicColors.magicBlueDark)
3. **Collector Tier**: $26.99 USD → Customizable heart (default: 3-color rainbow gradient)

**Important Behaviors**:
- Users can purchase multiple tiers independently
- Each tier grants its badge PLUS all lower tier badges
- Hearts accumulate and display side by side (e.g., Collector shows ❤️💙🌈)
- Higher tiers include all lower tier benefits (Collector includes Play and Thank You features)
- **Collector tier unlocks heart customization** - choose from 25 Magic: The Gathering color combinations
- Future features will be gated by tier (e.g., custom app icons for Play tier and above)

---

## UI Components & Layout

### 1. French Vanilla Credits Card - Heart Icon Display

**Current Layout** (credits_screen.dart:93-98):
```
French Vanilla
Version X.X.X (XX)
```

**New Layout**:
```
French Vanilla    [HEART(S)]
Version X.X.X (XX)
```

**Implementation Details**:
- Hearts displayed on the same line as "French Vanilla" title
- Layout: `Row` with `spaceBetween` - title on left, heart row on right
- Heart configurations by purchase state:
  - **No purchases**: Empty heart outline (Icons.favorite_border)
  - **Thank You only**: Red filled heart (Icons.favorite, MagicColors.magicRedDark)
  - **Play only**: Blue filled heart (Icons.favorite, MagicColors.magicBlueDark)
  - **Collector only**: Rainbow filled heart (ShaderMask gradient, customizable)
  - **Thank You + Play**: ❤️💙 (side by side, 4px gap)
  - **Thank You + Collector**: ❤️🌈
  - **Play + Collector**: 💙🌈
  - **All three**: ❤️💙🌈
  - **Higher tier includes lower**: Buying Collector automatically shows all three hearts

**Interaction Behavior - Heart Tap Opens Contextual Modal**:

- **No tier (empty heart)**: Opens supporter info modal
  - Title: "Support French Vanilla"
  - Body: "Unlock supporter hearts and exclusive features. Choose from three tiers to show your support and help keep French Vanilla ad-free."
  - CTA button: "View Supporter Tiers" → Opens purchase menu
  - Secondary button: "Not Now" → Closes modal

- **Thank You tier**: Opens tier status modal
  - Title: "Thank You Supporter"
  - Body: "You've unlocked the Thank You heart! ❤️"
  - CTA button: "Upgrade to Play Tier" → Opens purchase menu (scrolled to Play tier)
  - Secondary button: "Close" → Closes modal

- **Play tier**: Opens tier status modal
  - Title: "Play Supporter"
  - Body: "You've unlocked the Thank You and Play hearts! ❤️💙"
  - CTA button: "Upgrade to Collector Tier" → Opens purchase menu (scrolled to Collector tier)
  - Secondary button: "Close" → Closes modal

- **Collector tier**: Opens tier status modal WITH customization
  - Title: "Collector Supporter"
  - Body: "You've unlocked all supporter hearts! ❤️💙🌈 Customize your Collector heart below."
  - Primary button: "Customize Heart" → Opens heart customization screen
  - Secondary button: "Close" → Closes modal

---

### 2. Heart Tap Modals

**Modal Layouts by Tier**:

```
┌─────────────────────────────────────┐
│  Support French Vanilla             │  ← No tier
│                                     │
│  Unlock supporter hearts and        │
│  exclusive features. Choose from    │
│  three tiers to show your support   │
│  and help keep French Vanilla       │
│  ad-free.                           │
│                                     │
│  [View Supporter Tiers]             │
│  [Not Now]                          │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  Thank You Supporter                │  ← Thank You tier
│                                     │
│  You've unlocked the Thank You      │
│  heart! ❤️                          │
│                                     │
│  [Upgrade to Play Tier]             │
│  [Close]                            │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  Play Supporter                     │  ← Play tier
│                                     │
│  You've unlocked the Thank You and  │
│  Play hearts! ❤️💙                  │
│                                     │
│  [Upgrade to Collector Tier]        │
│  [Close]                            │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  Collector Supporter                │  ← Collector tier
│                                     │
│  You've unlocked all supporter      │
│  hearts! ❤️💙🌈 Customize your       │
│  Collector heart below.             │
│                                     │
│  [Customize Heart]                  │
│  [Close]                            │
└─────────────────────────────────────┘
```

---

### 3. Heart Customization (Collector Tier Exclusive)

**Access**: Tap on hearts when Collector tier is owned → Modal shows "Customize Heart" button

**Customization Screen UI**:
```
┌─────────────────────────────────────┐
│  ← Customize Collector Heart        │
│                                     │
│  [Preview: Large heart with         │
│   selected gradient/color]          │
│                                     │
│  Mono Colors                        │
│  ┌──────────────────────────────┐  │
│  │ [W] [U] [B] [R] [G]           │  │ ← 5 mono colors
│  └──────────────────────────────┘  │
│                                     │
│  Guild Colors (2-color)             │
│  ┌──────────────────────────────┐  │
│  │ [WU] [WB] [UR] [UB] [BR]      │  │
│  │ [BG] [RG] [RW] [GW] [GU]      │  │ ← 10 guilds
│  └──────────────────────────────┘  │
│                                     │
│  Tri-Color Combos                   │
│  ┌──────────────────────────────┐  │
│  │ [Shards: WUB, UBR, BRG...]    │  │
│  │ [Wedges: WBG, URW, BGU...]    │  │ ← 10 tri-color
│  └──────────────────────────────┘  │
│                                     │
│  [Save] [Cancel]                    │
└─────────────────────────────────────┘
```

**Color Options (25 total)**:

**Mono Colors (5)**:
- White (W): Solid `magic_white_dark`
- Blue (U): Solid `magic_blue_dark`
- Black (B): Solid `magic_black_dark`
- Red (R): Solid `magic_red_dark`
- Green (G): Solid `magic_green_dark`

**Guild Colors - 2-Color Gradients (10)**:
- Azorius (WU): `magic_white_dark` → `magic_blue_dark`
- Orzhov (WB): `magic_white_dark` → `magic_black_dark`
- Izzet (UR): `magic_blue_dark` → `magic_red_dark`
- Dimir (UB): `magic_blue_dark` → `magic_black_dark`
- Rakdos (BR): `magic_black_dark` → `magic_red_dark`
- Golgari (BG): `magic_black_dark` → `magic_green_dark`
- Gruul (RG): `magic_red_dark` → `magic_green_dark`
- Boros (RW): `magic_red_dark` → `magic_white_dark`
- Selesnya (GW): `magic_green_dark` → `magic_white_dark`
- Simic (GU): `magic_green_dark` → `magic_blue_dark`

**Tri-Color Combos - 3-Color Gradients (10)**:

*Shards (5)*:
- Esper (WUB): `magic_white_dark` → `magic_blue_dark` → `magic_black_dark`
- Grixis (UBR): `magic_blue_dark` → `magic_black_dark` → `magic_red_dark`
- Jund (BRG): `magic_black_dark` → `magic_red_dark` → `magic_green_dark`
- Naya (RGW): `magic_red_dark` → `magic_green_dark` → `magic_white_dark`
- Bant (GWU): `magic_green_dark` → `magic_white_dark` → `magic_blue_dark`

*Wedges (5)*:
- Abzan (WBG): `magic_white_dark` → `magic_black_dark` → `magic_green_dark`
- Jeskai (URW): `magic_blue_dark` → `magic_red_dark` → `magic_white_dark`
- Sultai (BGU): `magic_black_dark` → `magic_green_dark` → `magic_blue_dark`
- Mardu (RWB): `magic_red_dark` → `magic_white_dark` → `magic_black_dark`
- Temur (GUR): `magic_green_dark` → `magic_blue_dark` → `magic_red_dark`

**Implementation Notes**:
- Selected heart color persists to SharedPreferences: `collector_heart_style`
- Grid layout for color swatches with preview
- Each swatch shows mini heart icon with that gradient/color
- Large preview at top updates in real-time as user taps options
- Save button applies selection and returns to Credits screen
- Hearts on Credits screen immediately reflect new choice

**Default**: Collector tier defaults to Rainbow (Red → `magic_red_dark`, Yellow → `#FFD700`, Blue → `magic_blue_dark`) until user customizes

**Note**: Rainbow default uses a generic yellow (`#FFD700`) as an intermediate color since it's not part of the Magic color palette

---

### 4. "Support French Vanilla" Button

**Location**: French Vanilla card, immediately after "View Open Source Licenses" button (after credits_screen.dart:137)

**Styling**: Match existing `OutlinedButton.icon` style:
```dart
OutlinedButton.icon(
  onPressed: () => _showPurchaseMenu(),
  icon: const Icon(Icons.favorite_border),
  label: const Text('Support French Vanilla'),
)
```

**Behavior**: Opens purchase menu bottom sheet

---

### 5. Purchase Menu Bottom Sheet

**Trigger Points**:
1. "Support French Vanilla" button tap
2. "View Supporter Tiers" button in supporter info modal (no tier)
3. "Upgrade to [Tier]" button in tier status modals (Thank You or Play tier)

**UI Layout**:
```
┌───────────────────────────────────────────┐
│  Support French Vanilla                   │
│  Help keep French Vanilla ad-free and     │
│  buy a pack for the dev.                  │
│                                           │
│  ┌────────────────────────────────────┐  │
│  │  Thank You Tier        $1.99        │  │
│  │  ❤️ Red Heart                       │  │
│  │  Unlock tier-exclusive features     │  │
│  │  [✓ PURCHASED] ← if owned           │  │
│  └────────────────────────────────────┘  │
│                                           │
│  ┌────────────────────────────────────┐  │
│  │  Play Tier             $5.49        │  │
│  │  💙 Blue Heart                      │  │
│  │  Includes Thank You + Play perks    │  │
│  │  [✓ PURCHASED] ← if owned           │  │
│  └────────────────────────────────────┘  │
│                                           │
│  ┌────────────────────────────────────┐  │
│  │  Collector Tier        $26.99       │  │
│  │  🌈 Customizable Heart              │  │
│  │  Includes all tier perks            │  │
│  │  + Heart customization!             │  │
│  │  [✓ PURCHASED] ← if owned           │  │
│  └────────────────────────────────────┘  │
│                                           │
│  [Restore Purchases]                      │
│  [Cancel]                                 │
└───────────────────────────────────────────┘
```

**Card States**:
- **Unpurchased**: Full opacity, tappable, shows price
- **Already Purchased**: Slightly dimmed (0.6 opacity), shows "✓ Purchased" badge, still tappable (shows "already purchased" message)

**Restore Purchases Button**:
- Always visible
- TextButton style, smaller than purchase cards
- Shows loading indicator during restore
- Success/failure toast messages

**Smart Scrolling**:
- When opened via "Upgrade to Play Tier" CTA: Automatically scrolls to Play tier card (or highlights it)
- When opened via "Upgrade to Collector Tier" CTA: Automatically scrolls to Collector tier card
- When opened via "Support French Vanilla" button: Shows all tiers from top

**Purchase Success Behavior**:
- After successful purchase, bottom sheet transforms into a success modal
- Modal shows: "Thank you for your support! You're now a [tier name] supporter."
- Single "Close" button dismisses modal and returns to Credits screen
- Hearts update immediately on Credits screen behind modal (visible when dismissed)

---

## User Journeys

### Journey 1: First-Time Purchaser (Thank You Tier)
1. User navigates to Credits screen
2. Sees "French Vanilla ♡" (empty heart)
3. Taps empty heart
4. Supporter info modal opens: "Support French Vanilla" with description
5. User taps "View Supporter Tiers" button
6. Purchase menu opens with promotional message
7. Taps "Thank You Tier $1.99" card
8. Platform payment sheet appears (App Store / Google Play)
9. User completes purchase
10. Purchase menu transforms into success modal: "Thank you for your support! You're now a Thank You supporter."
11. User taps "Close"
12. Returns to Credits screen
13. Credits screen updates: "French Vanilla ❤️" (red heart)
14. User later taps red heart → Modal shows "Thank You Supporter" with upgrade CTA

### Journey 2: Upgrading to Collector Tier
1. User already has red heart (Thank You tier purchased)
2. Returns to Credits screen later
3. Taps red heart
4. Modal shows: "Thank You Supporter - You've unlocked the Thank You heart! ❤️" with "Upgrade to Play Tier" button
5. User taps "Upgrade to Play Tier" (or taps "Support French Vanilla" button instead)
6. Purchase menu opens (scrolls to Play tier if opened via upgrade button)
7. User decides to jump to Collector tier instead ($26.99)
8. Taps Collector tier card
9. Platform payment sheet appears
10. User completes purchase
11. Purchase menu transforms into success modal
12. Returns to Credits screen
13. Credits screen updates: "French Vanilla ❤️💙🌈" (all three hearts, since Collector includes all lower tiers)
14. Tapping hearts now shows "Collector Supporter" modal with "Customize Heart" button

### Journey 3: Buying Multiple Tiers Individually
1. User has Thank You tier (❤️)
2. Later purchases Play tier ($5.49)
3. Credits screen updates: "French Vanilla ❤️💙"
4. Later purchases Collector tier ($26.99)
5. Credits screen updates: "French Vanilla ❤️💙🌈" (all three)

### Journey 4: Device Change / Reinstall
1. User reinstalls app on new device
2. Credits screen shows empty heart (local state lost)
3. User taps "Support French Vanilla"
4. Taps "Restore Purchases" button
5. Platform verifies past purchases
6. App restores purchase state
7. Hearts reappear: ❤️, 💙, and/or 🌈 based on purchase history
8. Toast: "Purchases restored successfully"

### Journey 5: Attempting Duplicate Purchase
1. User with Collector tier tries to buy Thank You again
2. Taps already-purchased item in menu
3. Alert dialog: "You've already purchased the Thank You tier. Thank you for your support!"
4. No charge occurs

### Journey 6: Heart Customization (Collector Tier)
1. User purchases Collector tier ($26.99)
2. Purchase menu transforms into success modal
3. Returns to Credits screen
4. Credits screen updates: "French Vanilla ❤️💙🌈" (rainbow heart by default)
5. User taps on hearts
6. Modal opens: "Collector Supporter - You've unlocked all supporter hearts! ❤️💙🌈 Customize your Collector heart below."
7. User taps "Customize Heart" button
8. Heart customization screen opens showing 25 Magic: The Gathering color combinations
9. User browses categories: Mono Colors (5), Guild Colors (10), Tri-Color Combos (10)
10. Large preview at top updates in real-time as user taps different swatches
11. User selects "Grixis (UBR)" swatch - preview shows Blue → Black → Red gradient
12. Taps "Save"
13. Returns to Credits screen
14. Rainbow heart is now replaced with Grixis-colored heart (❤️💙[Grixis colors])
15. Customization persists across app restarts
16. On new device: After restore purchases, customized heart style also restores

### Journey 7: Future Feature Unlocking
1. App update adds "Custom App Icons" feature gated to Play tier and above
2. User with Thank You tier only (❤️) tries to access custom icons
3. Feature shows: "This feature requires Play tier or higher"
4. User can tap to open purchase menu
5. User purchases Play tier ($5.49)
6. Custom app icons feature immediately unlocks
7. Credits screen updates: "French Vanilla ❤️💙"

---

## Technical Implementation

### Platform Requirements
- **iOS**: App Store In-App Purchases (StoreKit)
- **Android**: Google Play Billing Library
- **Flutter Package**: `in_app_purchase` (official Flutter plugin)

### Purchase Product IDs
```dart
static const String thankYouId = 'com.loosetie.frenchvanilla.thank_you';
static const String playId = 'com.loosetie.frenchvanilla.play';
static const String collectorId = 'com.loosetie.frenchvanilla.collector';
```

### Product Descriptions (for App Store / Play Console)
**Thank You Tier**:
> "Unlock the Thank You supporter badge. As a Thank You supporter, exclusive features released for this tier will be automatically unlocked in your app."

**Play Tier**:
> "Unlock the Play supporter badge. As a Play supporter, exclusive features released for this tier (and all Thank You tier features) will be automatically unlocked in your app."

**Collector Tier**:
> "Unlock the Collector supporter badge with customizable heart colors. Choose from 25 Magic: The Gathering color combinations (mono colors, guilds, shards, and wedges). As a Collector supporter, all exclusive features released for any supporter tier will be automatically unlocked in your app."

### Purchase Type
- **Non-consumable purchases** (one-time, permanent)
- Stored in user's platform account
- Survive app deletion, reinstall, device changes
- Free to restore via platform APIs

### State Persistence
**Primary Source of Truth**: Platform purchase receipts (App Store / Play Store)

**Local Cache** (for quick UI updates):
- SharedPreferences: `purchased_thank_you`, `purchased_play`, `purchased_collector` (bool flags)
- Updated immediately after successful purchase
- Checked on app launch and Credits screen init
- Validated against platform receipts periodically

**Purchase Verification Flow**:
1. App launch: Check local cache for quick UI render
2. Background: Query platform for actual purchase receipts
3. Sync: Update local cache if discrepancies found
4. Restore: Force sync from platform, override local cache

### Feature Gating Logic
```dart
// Example implementation in IAPService
bool hasThankYouTier() => _hasPurchase(thankYouId);
bool hasPlayTier() => _hasPurchase(playId);
bool hasCollectorTier() => _hasPurchase(collectorId);

bool canAccessThankYouFeatures() => hasThankYouTier() || hasPlayTier() || hasCollectorTier();
bool canAccessPlayFeatures() => hasPlayTier() || hasCollectorTier();
bool canAccessCollectorFeatures() => hasCollectorTier();

// For UI rendering: Collector tier gets all hearts
bool shouldShowRedHeart() => hasThankYouTier() || hasPlayTier() || hasCollectorTier();
bool shouldShowBlueHeart() => hasPlayTier() || hasCollectorTier();
bool shouldShowRainbowHeart() => hasCollectorTier();
```

---

## Magic Color Constants

Define these color constants in the app (e.g., `lib/constants/colors.dart`):

```dart
// Magic: The Gathering Color Identity Colors
class MagicColors {
  // White (Plains)
  static const Color magicWhiteLight = Color(0xFFF8E7B9); // rgb(248, 231, 185)
  static const Color magicWhiteDark = Color(0xFFF9FAF4);  // rgb(249, 250, 244)

  // Blue (Island)
  static const Color magicBlueLight = Color(0xFFB3CEEA);  // rgb(179, 206, 234)
  static const Color magicBlueDark = Color(0xFF0E68AB);   // rgb(14, 104, 171)

  // Black (Swamp)
  static const Color magicBlackLight = Color(0xFFA69F9D); // rgb(166, 159, 157)
  static const Color magicBlackDark = Color(0xFF150B00);  // rgb(21, 11, 0)

  // Red (Mountain)
  static const Color magicRedLight = Color(0xFFEB9F82);   // rgb(235, 159, 130)
  static const Color magicRedDark = Color(0xFFD3202A);    // rgb(211, 32, 42)

  // Green (Forest)
  static const Color magicGreenLight = Color(0xFFC4D3CA); // rgb(196, 211, 202)
  static const Color magicGreenDark = Color(0xFF00733E);  // rgb(0, 115, 62)
}
```

**Usage**:
- All heart colors use the `*Dark` variants for better contrast and visibility
- Light variants available for future features (backgrounds, themes, etc.)

---

## Heart Rendering System

### Technical Approach
Use `ShaderMask` with `LinearGradient` over `Icons.favorite` for all gradient hearts:

```dart
// Example: Default Rainbow (3-color)
ShaderMask(
  shaderCallback: (Rect bounds) {
    return LinearGradient(
      colors: [
        MagicColors.magicRedDark,
        Color(0xFFFFD700), // Generic yellow for rainbow
        MagicColors.magicBlueDark,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(bounds);
  },
  child: Icon(
    Icons.favorite,
    color: Colors.white, // Base color for shader mask
    size: 24,
  ),
)

// Example: Solid color (Thank You tier - red)
Icon(
  Icons.favorite,
  color: MagicColors.magicRedDark,
  size: 24,
)

// Example: 2-color gradient (Guild - Azorius)
ShaderMask(
  shaderCallback: (Rect bounds) {
    return LinearGradient(
      colors: [
        MagicColors.magicWhiteDark,
        MagicColors.magicBlueDark,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(bounds);
  },
  child: Icon(
    Icons.favorite,
    color: Colors.white,
    size: 24,
  ),
)
```

### Heart Style Data Model

```dart
class HeartStyle {
  final String id;
  final String name;
  final HeartStyleType type; // solid, gradient2, gradient3
  final List<Color> colors;

  const HeartStyle({
    required this.id,
    required this.name,
    required this.type,
    required this.colors,
  });

  // Factory constructors for all 25 Magic combinations
  static HeartStyle white() => HeartStyle(
    id: 'mono_white',
    name: 'White',
    type: HeartStyleType.solid,
    colors: [MagicColors.magicWhiteDark],
  );

  static HeartStyle azorius() => HeartStyle(
    id: 'guild_azorius',
    name: 'Azorius',
    type: HeartStyleType.gradient2,
    colors: [MagicColors.magicWhiteDark, MagicColors.magicBlueDark],
  );

  static HeartStyle grixis() => HeartStyle(
    id: 'tri_grixis',
    name: 'Grixis',
    type: HeartStyleType.gradient3,
    colors: [
      MagicColors.magicBlueDark,
      MagicColors.magicBlackDark,
      MagicColors.magicRedDark,
    ],
  );

  // ... etc for all 25 Magic combos
}

enum HeartStyleType {
  solid,      // Single color
  gradient2,  // Two-color gradient
  gradient3,  // Three-color gradient
}
```

### Persistence
- SharedPreferences key: `collector_heart_style` (stores HeartStyle.id)
- Default for Collector tier: `rainbow` (MagicColors.magicRedDark → #FFD700 → MagicColors.magicBlueDark)
- On restore purchases: Load saved style from SharedPreferences

### Customization Screen Implementation
- GridView of heart swatches (5-6 per row, adjust based on screen size)
- Each swatch is a small heart with that style applied
- Tap to select → large preview updates in real-time
- Categories: Mono Colors (5), Guild Colors (10), Tri-Color Combos (10)
- Search/filter optional (nice-to-have for future)

---

## Data Models

### Purchase State (Enum)
```dart
enum PurchaseStatus {
  notPurchased,
  pending,      // Payment in progress
  purchased,
  restored,     // Restored from platform
  error         // Purchase failed
}
```

### Purchase Item Model
```dart
class PurchaseItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final IconData heartIcon;
  final Color heartColor;
  final PurchaseStatus status;
}
```

---

## Service Architecture

### IAPService (In-App Purchase Service)
**Responsibilities**:
- Initialize `in_app_purchase` plugin
- Listen to purchase stream
- Handle purchase transactions
- Restore purchases
- Query product details (prices, descriptions)
- Maintain local purchase state cache
- Provide feature gating checks

**Key Methods**:
```dart
class IAPService {
  // Initialization
  Future<void> initialize();
  Stream<PurchaseStatus> get purchaseStream;

  // Purchase operations
  Future<bool> buyProduct(String productId);
  Future<void> restorePurchases();
  Future<void> completePurchase(PurchaseDetails details);

  // Tier ownership checks
  bool hasThankYouTier();
  bool hasPlayTier();
  bool hasCollectorTier();

  // Feature gating
  bool canAccessThankYouFeatures();
  bool canAccessPlayFeatures();
  bool canAccessCollectorFeatures();

  // UI rendering helpers
  bool shouldShowRedHeart();
  bool shouldShowBlueHeart();
  bool shouldShowRainbowHeart();
  List<SupporterTier> getOwnedTiers();
}
```

---

## Edge Cases & Error Handling

### Error Scenarios
1. **Platform unavailable** (emulator, region restrictions)
   - Show message: "In-app purchases are not available on this device"
   - Hide "Support French Vanilla" button

2. **Network failure during purchase**
   - Platform handles retry automatically
   - Show loading indicator until resolved
   - Timeout after 30 seconds → show error toast

3. **User cancels payment**
   - Dismiss purchase menu silently
   - No error message (expected behavior)

4. **Purchase pending** (requires parental approval, etc.)
   - Show message: "Purchase is pending approval"
   - Hearts remain in previous state until approved
   - Check status on next app launch

5. **Restore finds no purchases**
   - Toast: "No previous purchases found"
   - Hearts remain empty

6. **Restore finds purchases**
   - Toast: "Purchases restored successfully"
   - Update hearts immediately

7. **Price loading failure**
   - Show "Support French Vanilla" button, but...
   - Purchase menu shows generic error: "Unable to load prices. Check your connection."
   - Retry button in menu

### Platform-Specific Edge Cases

**iOS**:
- User needs to be signed into App Store account
- Alert if not signed in: "Please sign in to the App Store to make purchases"

**Android**:
- Google Play Services must be up to date
- Alert if outdated: "Please update Google Play Services"

---

## Testing Requirements

### Manual Testing Checklist

**Purchase Flow**:
- [ ] Purchase Thank You tier → red heart appears
- [ ] Purchase Play tier → blue heart appears
- [ ] Purchase Collector tier → all three hearts appear (❤️💙🌈 with rainbow default)
- [ ] Purchase Thank You, then Play → both hearts appear (❤️💙)
- [ ] Purchase Thank You, then Collector → all three hearts appear
- [ ] Tap "Support French Vanilla" button → purchase menu opens
- [ ] Successful purchase → menu transforms into success modal
- [ ] Attempt duplicate purchase → prevented with message
- [ ] Restore purchases → hearts reappear correctly
- [ ] Delete app + reinstall → restore brings hearts back
- [ ] Cancel payment → no errors, menu dismisses cleanly
- [ ] Network loss during purchase → recovers gracefully

**Heart Modal Interactions**:
- [ ] Tap empty heart (no tier) → Supporter info modal opens with "View Supporter Tiers" CTA
- [ ] In supporter info modal, tap "View Supporter Tiers" → Purchase menu opens
- [ ] In supporter info modal, tap "Not Now" → Modal closes
- [ ] Tap heart with Thank You tier → Modal shows tier status with "Upgrade to Play Tier" CTA
- [ ] In Thank You modal, tap "Upgrade to Play Tier" → Purchase menu opens (scrolled to Play tier)
- [ ] Tap heart with Play tier → Modal shows tier status with "Upgrade to Collector Tier" CTA
- [ ] In Play modal, tap "Upgrade to Collector Tier" → Purchase menu opens (scrolled to Collector tier)
- [ ] Tap heart with Collector tier → Modal shows tier status with "Customize Heart" button
- [ ] In Collector modal, tap "Customize Heart" → Customization screen opens
- [ ] All modals have working "Close" buttons

**Heart Customization** (Collector tier):
- [ ] Customize button only appears for Collector supporters
- [ ] Customization screen opens with grid of all 25 options
- [ ] Large preview updates in real-time when selecting swatches
- [ ] All 5 mono-color options render correctly
- [ ] All 10 guild (2-color) gradients render correctly
- [ ] All 10 tri-color (shards + wedges) gradients render correctly
- [ ] Save button applies selection and returns to Credits
- [ ] Customized heart appears on Credits screen immediately
- [ ] Customized heart persists after app restart
- [ ] Customized heart persists after restore purchases on new device
- [ ] Cancel button discards changes and returns to Credits

**General**:
- [ ] Feature gating works correctly (heart customization only for Collector)
- [ ] All gradient hearts render correctly on both iOS and Android
- [ ] Hearts scale properly on different screen sizes

### Platform Testing
- [ ] iOS sandbox environment (test account)
- [ ] Android test track (internal testing)
- [ ] Verify prices display in user's local currency
- [ ] Test on devices in different regions

---

## Tier-Exclusive Features

### Implemented in v1
**Collector Tier**:
- ✅ **Heart Customization** - Choose from 25 Magic: The Gathering color combinations (5 mono-colors, 10 guilds, 10 tri-color combos)

### Future Feature Examples (Not In Scope for v1)
Once IAP system is implemented, future updates can gate additional features by tier:

**Thank You Tier Examples**:
- Special "Thank You" badge next to bookmarked rules
- Early access to beta features

**Play Tier Examples**:
- Custom app icons (2-3 alternate icons)
- Color theme customization (app-wide themes)
- Export bookmarks to PDF

**Collector Tier Examples**:
- Advanced search filters (regex, boolean operators)
- Rule comparison view (compare different rule versions)
- Full app theme customization (custom colors, fonts)
- Rule annotations/personal notes

**Implementation**: Features check `IAPService.canAccessPlayFeatures()` etc.

### Considered: "Heart Bar" System
**Concept**: Allow recurring purchases, each adds another heart to a growing collection.
- **Example**: 1 heart = $1, 5 hearts = $5, 10 hearts = $10 (visual progress bar)
- **Benefits**: Encourages repeat support, gamification
- **Challenges**: Consumable vs non-consumable complexity, UI scaling with many hearts

**Decision**: Deferred. Starting with three-tier system for v1. Can revisit if users request more support options.

### Considered: Subscription Model
**Concept**: Monthly/yearly supporter subscription with exclusive features
- **Benefits**: Recurring revenue
- **Challenges**: Requires ongoing value delivery (new features, content updates)

**Decision**: Not aligned with French Vanilla's mission (free, comprehensive rules access). One-time tip jar better fits the ethos.

---

## Implementation Phases

### Phase 1: Infrastructure ✅ PENDING
- [ ] Add `in_app_purchase` dependency to pubspec.yaml
- [ ] Configure App Store Connect (iOS)
  - Create 3 non-consumable in-app purchase products
  - Set prices: Thank You ($1.99), Play ($5.49), Collector ($26.99)
  - Add product descriptions (see Technical Implementation section)
  - Submit for review if needed
- [ ] Configure Google Play Console (Android)
  - Create 3 one-time purchase products
  - Set prices and descriptions
- [ ] Create `IAPService` class with tier checking methods
- [ ] Implement purchase stream listeners
- [ ] Test with sandbox accounts (iOS) and test track (Android)

### Phase 2: UI Implementation ✅ PENDING
- [ ] Add heart icons to Credits screen title (credits_screen.dart:93-98)
  - Implement heart row with dynamic rendering (empty vs filled)
  - Create heart rendering widget system (solid colors + gradients)
  - Handle tap interactions (heart → contextual modal)
- [ ] Create contextual modals for heart tap
  - Supporter info modal (no tier) - with "View Supporter Tiers" CTA
  - Thank You tier status modal - with "Upgrade to Play Tier" CTA
  - Play tier status modal - with "Upgrade to Collector Tier" CTA
  - Collector tier status modal - with "Customize Heart" button
- [ ] Add "Support French Vanilla" button (after line 137)
- [ ] Create purchase menu bottom sheet
  - Add promotional message: "Help keep French Vanilla ad-free and buy a pack for the dev."
  - Implement 3 purchase tier cards
  - Implement purchase cards with loading states
  - Handle purchased state (✓ badge, dimmed)
  - Update Collector card to mention heart customization
  - Implement smart scrolling (scroll to specific tier when opened via upgrade CTA)
- [ ] Add "Restore Purchases" functionality
- [ ] Create purchase success modal (replaces purchase menu after successful purchase)

### Phase 2.5: Heart Customization Feature ✅ PENDING
- [ ] Create `HeartStyle` model with all 25 Magic color options
  - 5 mono-color options (W, U, B, R, G) using `magic_{color}_dark`
  - 10 two-color guilds (Azorius, Orzhov, Izzet, etc.)
  - 10 three-color shards & wedges (Esper, Grixis, Jund, etc.)
  - Define all color constants from provided RGB values
- [ ] Create heart customization screen
  - Full-screen view with large preview at top
  - Categorized GridView of heart swatches (3 sections: Mono, Guild, Tri-Color)
  - Real-time preview updates on selection
  - Save/Cancel buttons
- [ ] Implement heart style persistence
  - Save selected style to SharedPreferences
  - Load on app launch
  - Apply to Collector heart on Credits screen
- [ ] Create reusable heart widget that accepts HeartStyle
  - Handles solid colors
  - Handles 2-color gradients (topLeft → bottomRight)
  - Handles 3-color gradients (topLeft → center → bottomRight)

### Phase 3: Purchase Flow ✅ PENDING
- [ ] Wire up purchase initiation for all 3 tiers
- [ ] Handle purchase success/failure callbacks
- [ ] Implement "higher tier includes lower tier" logic
- [ ] Update UI immediately on purchase (heart rendering)
- [ ] Transform purchase menu into thank you modal on success
- [ ] Persist purchase state to SharedPreferences (3 keys)
- [ ] Add error handling and user feedback (toasts, alerts)
- [ ] Implement feature gating helper methods

### Phase 4: Testing & Polish ✅ PENDING
- [ ] Test all user journeys (see checklist above)
- [ ] Test on physical iOS device (sandbox)
- [ ] Test on physical Android device (test track)
- [ ] Handle edge cases (network loss, cancellation, etc.)
- [ ] Add analytics (optional: track purchase funnel)

### Phase 5: Submission ✅ PENDING
- [ ] App Store review (mention IAP in review notes)
- [ ] Google Play review
- [ ] Monitor for purchase issues post-launch

---

## Open Questions

### Resolved ✅
1. ~~**Icon choice for "Support French Vanilla" button**~~ → `Icons.favorite_border` ✅
2. ~~**Heart icon implementation**~~ → `Icons.favorite` with colors + gradient for rainbow ✅
3. ~~**Purchase menu dismissal**~~ → Transforms into dismissable "Thank You" modal ✅
4. ~~**Promotional messaging**~~ → "Help keep French Vanilla ad-free and buy a pack for the dev." ✅
5. ~~**Number of tiers**~~ → 3 tiers (Thank You, Play, Collector) ✅
6. ~~**Pricing**~~ → $1.99, $5.49, $26.99 ✅
7. ~~**App Store compliance**~~ → Verified compliant with tip jar + badge + feature gating model ✅
8. ~~**Rainbow gradient colors**~~ → Simplified 3-color (Red→Yellow→Blue) ✅
9. ~~**Collector tier flagship feature**~~ → Heart customization with 25+ color options ✅

### Still Open

**General**:
1. **Analytics**: Track purchase funnel? (menu opens, purchase attempts, completions, tier distribution, popular heart colors)
2. **Heart size on Credits screen**: Should hearts be same size as title text, or slightly larger for emphasis?
3. **Thank you modal details**: Should it list specific features the user unlocked, or just show tier name?

**Heart Customization**:
4. ~~**Exact Magic color hex codes**~~ → ✅ Provided (see color table above)
5. **Gradient direction**: All gradients topLeft→bottomRight for consistency, or vary by combo?
6. **Category naming**: Use Magic terms ("Guild Colors", "Shards", "Wedges") or more generic ("Two-Color", "Three-Color")?
7. **Swatch size**: How large should each heart swatch be in the grid? (32px? 40px? 48px?)
8. **Rainbow default yellow**: Use generic `#FFD700` or pick a different shade for the default rainbow heart?

---

## App Store & Play Store Compliance

### Verified Compliant ✅
This implementation has been verified against current App Store and Google Play Store policies:

**Apple App Store**:
- ✅ Tip jars explicitly permitted since June 2017 (Guideline 3.1.3(a))
- ✅ Non-consumable IAPs can unlock features and badges
- ✅ Product descriptions clearly state immediate value (badge) + ongoing value (tier features)
- ✅ Similar implementations approved: Apollo for Reddit, PickleJar Live (with achievement badges)
- ✅ No violations of "future perks" guidelines (features are retroactively unlocked, not promised)

**Google Play Store**:
- ✅ One-time purchases allowed for digital goods
- ✅ No restrictions on supporter badges or tip jar implementations
- ✅ More lenient than Apple regarding IAP implementations

### Key Compliance Points
1. **Immediate Tangible Value**: Each tier provides an immediate heart badge
2. **Clear Descriptions**: Product descriptions accurately state what users receive
3. **No Vague Promises**: "Exclusive features for this tier" is accurate and not misleading
4. **Standard Model**: Same as "Pro" or "Lifetime" purchases that unlock features over time
5. **Non-Consumable**: One-time purchase, permanent, restorable across devices

### References
- App Store Review Guidelines Section 3.1 (In-App Purchase)
- PickleJar Live (App Store): Approved app with "loyalty rewards, achievement badges" for supporters
- Apollo for Reddit: Successfully implemented tip jar since 2017

---

# Development Log (Previous Work)

## Recent Work (2026-01-13)

### Bookmarks Feature - COMPLETED
- ✅ Created `FavoritesService` with SharedPreferences persistence
- ✅ Created `BookmarksScreen` with edit mode, swipe-to-delete, batch operations
- ✅ Added bookmark icons to all rule subrule cards and glossary term cards
- ✅ Integrated bookmarks tab into home navigation (index 2)
- ✅ Implemented preview bottom sheets for bookmarked rules and glossary terms
- ✅ Added navigation from bookmarks to full rule/glossary views with highlighting

### UI/UX Improvements - COMPLETED
- ✅ Redesigned cards with header layout (subrule number on left, bookmark icon on right)
- ✅ Removed redundant subrule numbers from card content body
- ✅ Implemented clickable inline rule references (e.g., "rule 702.9a" → navigate to rule)
- ✅ Added long-press context menus (bookmark/copy/share) to rules and glossary
- ✅ Fixed scroll positioning for rule navigation (alignment: 0.01)
- ✅ Added glossary term highlighting and scroll-to on navigation
- ✅ Fixed share functionality with iPad popover positioning

### Technical Debt
- ⚠️ Remove debug print statements before release (rule_detail_screen.dart: `_scrollToSubrule`, `initState`, `_buildSubruleContent`)

---

# Next Feature: Initial App Development

## Project Overview
**French Vanilla** is a Magic: The Gathering rules reference application targeting iOS and Android. The app will serve as a quick-lookup wiki for players to search and browse information about MTG rules, specifically focusing on Rule 702 (keyword abilities).

## Current Status
- Flutter project initialized
- Project naming conventions configured:
  - iOS: `LooseTie.Frenchvanilla`
  - Android: `com.loosetie.frenchvanilla`
  - Package: `frenchvanilla`
- Source material: `docs/rule702.md` (content to be populated)

## Assumptions & Technical Requirements

### App Architecture
- **Platform**: Flutter (iOS & Android)
- **State Management**: TBD (likely Provider or Riverpod, following doubling-season patterns)
- **Data Storage**: Local (embedded rules data, no backend required initially)
- **Search**: Full-text search capability for quick rule lookup
- **Navigation**: Simple, intuitive navigation appropriate for reference material

### Core Features (Assumed)
1. **Browse Rules**: List/scroll view of all Rule 702 keyword abilities
2. **Search Functionality**: Quick search to find specific keywords or rules
3. **Rule Detail View**: Detailed explanation of each keyword ability
4. **Offline Access**: All data embedded in app for offline use
5. **Clean UI**: Simple, readable interface suitable for quick reference during gameplay

### Data Structure (Assumed)
- Rule 702 contains keyword abilities (Flying, Trample, Lifelink, etc.)
- Each keyword likely needs:
  - Name
  - Full rules text
  - Examples (optional)
  - Related keywords/cross-references (optional)

### UI/UX Assumptions
- Home screen with search bar and categorized/alphabetical list
- Tap to view detailed rule text
- Search filters/highlights matching text
- Dark mode support (following iOS/Android system preferences)
- Accessibility considerations (font scaling, screen readers)

### Technical Dependencies (Estimated)
- Search functionality (built-in or package like `flutter_search_bar`)
- Local data storage (JSON embedded in assets, or SQLite for complex queries)
- Markdown rendering (if rules text uses formatting)
- Share functionality (copy rule text, share with friends)

---

## Search Functionality Refinements (2026-01-11)

### Issues Addressed & Solutions

#### 1. Bottom Sheet Auto-Sizing
**Problem**: Search result preview used `DraggableScrollableSheet` which allowed dragging and used fixed screen proportions instead of content-based sizing.

**Solution**: Replaced with `ConstrainedBox` + `Column` with `mainAxisSize.min` for auto-sizing to content (up to 90% screen height max).

**Implementation**: `lib/screens/search_screen.dart:319-404`

---

#### 2. Recent Searches Feature
**Problem**: Search screen showed empty state with no context for users.

**Solution**: Implemented persistent search history with SharedPreferences.

**Features**:
- Stores last 15 searches with query + result count + timestamp
- Deduplicates (moves existing query to top on re-search)
- Recent searches list appears in empty state
- "Clear Search History" button with confirmation dialog
- Tap to immediately re-run cached search

**Implementation**:
- Service: `lib/services/search_history_service.dart`
- UI: `lib/screens/search_screen.dart:168-204`
- Dependencies: `shared_preferences: ^2.3.3`

---

#### 3. Scroll-to-Subrule Functionality

**Problem**: Navigation from search result preview to full rule detail had inconsistent scrolling behavior:
- Small rules (< 10 subrules): ✅ Worked correctly
- Medium rules (10-50 subrules): ⚠️ Sometimes worked, sometimes cut off by app bar
- Large rules (> 50 subrules): ❌ Failed completely - didn't scroll to target

**Root Cause**: `ListView` uses lazy rendering - only builds visible widgets. For large rules like 702 (189 subrule groups), the target widget's GlobalKey had no context attached because it wasn't rendered yet.

**Initial Attempted Solution**: Two-phase scroll approach:
1. Jump to estimated position to trigger rendering
2. Wait for widget to build
3. Use `Scrollable.ensureVisible()` for precise scroll

**Result**: Still failed for rule 702 - widget never rendered even after 5 frame attempts.

**Final Solution**:
- Replaced `ListView` with `SingleChildScrollView` + `Column`
- All widgets render upfront (no lazy loading)
- GlobalKeys always have contexts immediately
- Added 8px offset adjustment to prevent app bar overlap
- Simple, reliable scroll logic

**Performance Impact**: Noticeable lag when opening large rules (especially 702 with 189 subrule groups).

**Implementation**: `lib/screens/rule_detail_screen.dart:56-129, 262-296`

---

#### 4. Performance Optimizations

**Problem**: Rule 702 (752 subrules across 189 subrule groups) takes ~1-2 seconds to build and render all widgets.

**Solution**: Hybrid approach combining preloading + loading indicators

**Strategy**:
1. **Preload on Preview Sheet Open** - When user taps search result and opens preview, immediately call `getRulesForSection()` to cache data in background while they read preview
2. **Loading Indicator for Large Rules** - Show overlay with spinner + "Loading rule..." text for rules with >50 subrule groups
3. **Smart Hiding** - Loading indicator automatically dismisses after widgets build and scroll completes

**Threshold**: 50 subrules (affects only the 3 largest rules, see below)

**Implementation**:
- Preloading: `lib/screens/search_screen.dart:320-324`
- Loading state: `lib/screens/rule_detail_screen.dart:24, 35-61, 107-123, 286-304`

---

#### 5. Rules Analysis - Performance Context

**Top 5 Rules by Subrule Group Count**:
1. **Rule 702** (Section 7): **752 subrules** - Keyword Abilities
2. **Rule 701** (Section 7): **284 subrules** - Keyword Actions
3. **Rule 712** (Section 7): **58 subrules** - Handling "Illegal" Actions
4. **Rule 107** (Section 1): **49 subrules** - Numbers and Symbols
5. **Rule 903** (Section 9): **49 subrules** - Commander

**Performance Impact**:
- Rules 702, 701, and 712 will show loading indicator (>50 threshold)
- All other rules load instantly without indicator
- Section 7 dominates because it contains all keyword abilities and actions
- Rule 702 is 2.5x larger than #2, explaining why it was the primary performance issue

**Note**: Each "subrule" here is a subrule GROUP (e.g., 702.90 = Flying, which contains 702.90, 702.90a, 702.90b, etc.). The actual number of individual subrule lines is higher.

---

### Technical Debt / Future Considerations

1. **Remove Debug Logging**: Production build should remove extensive debug print statements added during scroll debugging
   - **NEW (2026-01-13)**: Remove additional debug logging in `rule_detail_screen.dart` (`_scrollToSubrule` method, `initState`, `_buildSubruleContent`) before release
2. **Profile Widget Building**: Could optimize `_buildSubruleContent()` method - potential caching of parsed text
3. **Consider Virtualization Alternative**: For massive rules, could explore `flutter_sticky_header` or custom slivers with better lazy loading support
4. **Adjust Threshold**: Monitor real-world usage to see if 50 subrule threshold is optimal
5. **Loading Animation**: Could make loading indicator more sophisticated (progress bar, animated content placeholder)


