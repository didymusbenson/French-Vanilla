# IAP Testing - Complete Guide & Checklist

**Status**: Platforms configured. Ready for device testing.

This document consolidates platform setup instructions, testing procedures, and verification checklist for the In-App Purchase system.

---

## Part 1: Platform Setup

### iOS Setup

#### 1. Create Sandbox Test Account
**Important:** Never use your personal Apple ID for testing IAP!

1. Go to App Store Connect → Users and Access → Sandbox
2. Create sandbox tester:
   - Email: Use unique email (can use +addressing: yourname+sandbox1@gmail.com)
   - This doesn't need to be a real Apple ID, only for sandbox
3. Save credentials - you'll need them on device

#### 2. Configure Products in App Store Connect
1. Navigate to App Store Connect → French Vanilla → In-App Purchases
2. Create 3 products (Type: **Non-Consumable**):
   - **Thank You Tier**: `com.loosetie.frenchvanilla.thank_you`
   - **Play Tier**: `com.loosetie.frenchvanilla.play`
   - **Collector Tier**: `com.loosetie.frenchvanilla.collector`
3. Products work immediately in sandbox (no review needed for testing)

#### 3. Test on iOS Device (NOT Simulator)
1. Sign out of App Store in Settings → Media & Purchases
2. Install app via Xcode
3. Make purchase - sandbox sign-in prompt will appear
4. Enter sandbox credentials

---

### Android Setup

#### 1. Configure Products in Google Play Console
1. Go to Play Console → French Vanilla → Monetize → In-app products
2. Create 3 products (Status: **Active**):
   - Product ID: `thank_you` → Name: `Thank You Tier`
   - Product ID: `play` → Name: `Play Tier`
   - Product ID: `collector` → Name: `Collector Tier`
3. Products are immediately available for testing

#### 2. Set Up Internal Testing Track
1. Create internal test release: Release → Testing → Internal testing
2. Upload APK/AAB
3. Add tester emails (your test Google accounts)
4. Get opt-in URL and download app on test device

#### 3. Add License Testers
- Settings → License testing → Add Gmail addresses
- Allows testing without publishing to production

---

## Part 2: Testing Procedures

### Basic Purchase Flow Test

**Objective**: Verify complete purchase from start to finish

**Steps**:
1. Launch app, navigate to Credits screen
2. Verify no heart badge visible (fresh install)
3. Open purchase menu
4. Verify UI loads: 3 tier cards, prices, "Restore Purchases" button
5. Tap "Play Tier" card
6. Platform purchase dialog appears (App Store/Google Play)
7. Complete purchase, authenticate
8. Success dialog: "Thank you for your support! You're now a Play supporter."
9. Purchase menu closes automatically
10. Credits screen shows **BLUE heart icon**
11. Reopen purchase menu - Play tier shows "PURCHASED" badge
12. Force quit and relaunch - blue heart persists

---

### Purchase Restoration Test

**Objective**: Verify purchases restore after reinstall

**Steps**:
1. Make purchase (own at least one tier)
2. Delete app and reinstall
3. Open purchase menu - all tiers appear unpurchased
4. Tap "Restore Purchases"
5. Success snackbar: "Purchases restored successfully!"
6. Owned tier now shows PURCHASED badge
7. Credits screen shows correct heart badge

---

### Heart Customization Test (Collector Only)

**Prerequisites**: Must own Collector tier

**Steps**:
1. In Credits screen, tap Collector heart icon
2. Heart Customization screen opens
3. Verify 4 sections: Mono Colors (5), Guild Colors (10), Tri-Color (10), Special (1)
4. Tap "Gruul" heart (red/green)
5. Large preview updates instantly
6. Tap "Save"
7. Success snackbar: "Gruul heart style saved!"
8. Credits screen shows Gruul heart
9. Force quit and relaunch - Gruul heart persists

**Test Cancel Without Saving**:
1. Open customization, select different heart
2. Tap "Cancel" (X button)
3. Confirmation dialog: "Discard Changes?"
4. Tap "Discard"
5. Credits screen shows original heart (not new selection)

---

## Part 3: Verification Checklist

### Pre-Flight Checks
- [ ] All 3 products created in App Store Connect
- [ ] All 3 products created in Google Play Console
- [ ] Product IDs match exactly
- [ ] Products marked as Non-consumable/One-time purchase
- [ ] Pricing configured on both platforms
- [ ] Test accounts created and ready
- [ ] Testing on real devices (not simulators)

### UI Component Tests
- [ ] Purchase menu displays with all 3 tier cards
- [ ] Product prices load correctly (not $0.00)
- [ ] Heart icons render: red (Thank You), blue (Play), rainbow (Collector)
- [ ] "Restore Purchases" button visible
- [ ] Loading states show during operations

### Purchase Flow Tests
- [ ] Can purchase Thank You tier
- [ ] Success dialog appears with correct message
- [ ] Heart badge appears in Credits screen
- [ ] Purchase menu shows "PURCHASED" badge
- [ ] Already purchased protection works (snackbar shown)
- [ ] User can cancel purchase - no error
- [ ] Purchase errors show user-friendly message

### Restore Purchases Tests
- [ ] Fresh install shows no purchases
- [ ] Restore button loads purchases from platform
- [ ] Success snackbar appears
- [ ] Owned tiers marked as PURCHASED
- [ ] Credits screen shows correct heart
- [ ] Restore with no purchases doesn't crash

### Heart Customization Tests (Collector)
- [ ] Non-Collector users can't access customization
- [ ] Collector users can tap heart to open customization
- [ ] All 26 heart styles render correctly
- [ ] Selection updates large preview instantly
- [ ] Save persists across app restarts
- [ ] Cancel without saving discards changes
- [ ] Cancel with no changes closes immediately

### Edge Case Tests
- [ ] Offline mode: purchases persist from cache
- [ ] Multiple rapid taps: only one purchase dialog
- [ ] Tier upgrade: higher tier replaces lower tier display
- [ ] Platform switching: purchases don't cross-restore (expected)
- [ ] App update: purchases and customization persist

### Platform-Specific Tests

**iOS**:
- [ ] Sandbox account sign-in prompt appears
- [ ] Sandbox indicator visible during testing
- [ ] Receipt validation works

**Android**:
- [ ] License tester account recognized
- [ ] Google Play billing client connects
- [ ] Products load from Play Store

### Console Log Verification
- [ ] "IAP service initialized successfully"
- [ ] "Delivering purchase: [product_id]" on purchase
- [ ] No unexpected errors in console
- [ ] Error handling logs are user-friendly

### SharedPreferences Verification

**Expected keys after purchases**:
- `flutter.purchased_thank_you` = true (if owned)
- `flutter.purchased_play` = true (if owned)
- `flutter.purchased_collector` = true (if owned)
- `flutter.collector_heart_style` = "[style_id]" (if customized)

**Android verification**:
```bash
adb shell run-as com.loosetie.frenchvanilla cat /data/data/com.loosetie.frenchvanilla/shared_prefs/FlutterSharedPreferences.xml
```

---

## Part 4: Common Issues & Solutions

### Products Don't Load
**Causes**:
- Product IDs don't match exactly
- Products not configured or not Active
- Bundle/App ID mismatch
- IAP capability missing (iOS)
- Network issues

**Solutions**:
- Verify all IDs match exactly
- Check product status in platform consoles
- Add In-App Purchase capability in Xcode
- Check internet connection

### Purchase Doesn't Complete
**Causes**:
- Pending transactions not handled
- Network interruption
- Sandbox account issues (iOS)

**Solutions**:
- Restore purchases to complete transaction
- Check Play Console for pending orders (Android)
- Create new sandbox account (iOS)

### Restore Doesn't Work
**Causes**:
- No purchases to restore
- Wrong account signed in
- Cross-platform restore attempt
- Network issues

**Solutions**:
- Make test purchase first
- Sign in with correct account
- Note: Apple/Google purchases don't sync
- Verify internet connection

### Customization Not Persisting
**Causes**:
- SharedPreferences not saving
- User tapped Cancel instead of Save
- Collector tier lost (needs restore)

**Solutions**:
- Check console for save errors
- Verify "Save" button was tapped
- Restore purchases first

---

## Part 5: Final Verification

### Production Readiness
- [ ] All tests passed on iOS
- [ ] All tests passed on Android
- [ ] No console errors during normal operation
- [ ] Graceful error handling for all edge cases
- [ ] Purchase persistence works correctly
- [ ] Restore functionality works correctly
- [ ] Customization works and persists
- [ ] UI is polished and responsive

### Platform Submission
- [ ] iOS App Store Connect products configured
- [ ] Google Play Console products configured
- [ ] App privacy details updated (purchases)
- [ ] Ready for TestFlight/Internal Testing
- [ ] Ready for production release

---

## Testing Notes

**Testing Date**: _____________
**Tester**: _____________
**iOS Version**: _____________
**Android Version**: _____________
**App Version**: _____________
**Test Account Used**: _____________

**Issues Found**:

**Notes**:

---

## Quick Reference

### Product IDs
- Thank You: `com.loosetie.frenchvanilla.thank_you`
- Play: `com.loosetie.frenchvanilla.play`
- Collector: `com.loosetie.frenchvanilla.collector`

### Bundle IDs
- iOS: `LooseTie.Frenchvanilla`
- Android: `com.loosetie.frenchvanilla`

### Documentation
- Quick Start: `docs/implemented/iap_quick_start.md`
- Implementation Summary: `docs/implemented/iap_implementation_summary.md`
- This Guide: `docs/implemented/iap_testing_complete.md`

---

**For additional troubleshooting details, see the original separate guides** (now consolidated here).
