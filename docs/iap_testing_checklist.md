# IAP Testing Checklist

A comprehensive verification checklist for testing the In-App Purchase system in French Vanilla.

## Pre-Flight Checks

### Platform Configuration
- [ ] All 3 products created in App Store Connect with correct IDs
- [ ] All 3 products created in Google Play Console with correct IDs
- [ ] Product IDs match exactly: `com.loosetie.frenchvanilla.{thank_you|play|collector}`
- [ ] Products marked as "Non-consumable" (iOS) or "One-time purchase" (Android)
- [ ] Pricing configured for all products on both platforms
- [ ] iOS products submitted for review (required even for sandbox)
- [ ] Google Play products published to internal testing track

### Test Account Setup
- [ ] iOS sandbox test account created in App Store Connect
- [ ] Android license tester email added in Google Play Console
- [ ] Test account signed in on test device
- [ ] NOT using personal Apple ID or Google account

### Device Preparation
- [ ] Testing on real iOS device (not simulator)
- [ ] Testing on real Android device (not emulator)
- [ ] Device signed out of personal App Store/Play Store account
- [ ] Signed in with test account
- [ ] Previous test purchases cleared (if applicable)
- [ ] App installed via Xcode/Android Studio (not TestFlight/Play Store initially)

### Build Verification
- [ ] App builds successfully for iOS
- [ ] App builds successfully for Android
- [ ] Bundle ID matches: `LooseTie.Frenchvanilla` (iOS) / `com.loosetie.frenchvanilla` (Android)
- [ ] IAP service initializes without errors (check console logs)
- [ ] No runtime errors on app launch

## UI Component Tests

### Credits Screen - Initial State (No Purchase)
- [ ] Heart icon not visible (no tier owned)
- [ ] Tapping area shows no heart or shows upgrade prompt
- [ ] No Collector customization option visible

### Purchase Menu - Display
- [ ] Menu opens when tapping heart area in Credits screen
- [ ] Bottom sheet displays correctly with drag handle
- [ ] Header text: "Support French Vanilla"
- [ ] Description text displays
- [ ] All 3 tier cards display:
  - [ ] Thank You Tier card with red heart preview
  - [ ] Play Tier card with blue heart preview
  - [ ] Collector Tier card with rainbow heart preview
- [ ] Product prices display correctly (not $0.00, not loading forever)
- [ ] "Restore Purchases" button visible at bottom
- [ ] Cards are tappable

### Purchase Menu - Error States
- [ ] If IAP not available: Error message displays with retry button
- [ ] If products fail to load: Error message displays with retry button
- [ ] Retry button reloads products successfully
- [ ] Network errors handled gracefully

### Purchase Menu - Loading States
- [ ] Loading spinner shows while fetching products
- [ ] Purchase button shows loading state during purchase
- [ ] "Processing..." text appears during active purchase
- [ ] Restore button shows loading state during restore

### Heart Icons
- [ ] Red heart renders as solid red (Thank You tier)
- [ ] Blue heart renders as solid blue (Play tier)
- [ ] Rainbow heart renders with gradient (Collector tier default)
- [ ] Guild hearts render with 2-color gradients (if Collector customized)
- [ ] Tri-color hearts render with 3-color gradients (if Collector customized)
- [ ] Heart icons scale properly at different sizes

## Purchase Flow Tests

### Test 1: Purchase Thank You Tier
- [ ] Tap Thank You tier card in purchase menu
- [ ] Platform payment UI appears (App Store / Google Play)
- [ ] Enter sandbox account credentials if prompted
- [ ] Confirm purchase in platform UI
- [ ] Success dialog appears: "Thank you for your support! You're now a Thank You supporter."
- [ ] Tap "Close" button in success dialog
- [ ] Purchase menu closes automatically
- [ ] Credits screen now shows RED heart icon
- [ ] Reopen purchase menu
- [ ] Thank You tier shows "PURCHASED" badge
- [ ] Other tiers still purchasable

### Test 2: Purchase Play Tier
**Prerequisites:** Clear Thank You purchase or use fresh test account
- [ ] Tap Play tier card in purchase menu
- [ ] Platform payment UI appears
- [ ] Confirm purchase
- [ ] Success dialog: "Thank you for your support! You're now a Play supporter."
- [ ] Purchase menu closes
- [ ] Credits screen shows BLUE heart icon
- [ ] Reopen purchase menu
- [ ] Play tier shows "PURCHASED" badge
- [ ] Thank You tier NOT marked as purchased (only one tier owned at a time)
- [ ] Collector tier still purchasable

### Test 3: Purchase Collector Tier
**Prerequisites:** Clear previous purchases or use fresh test account
- [ ] Tap Collector tier card in purchase menu
- [ ] Platform payment UI appears
- [ ] Confirm purchase
- [ ] Success dialog: "Thank you for your support! You're now a Collector supporter."
- [ ] Purchase menu closes
- [ ] Credits screen shows RAINBOW heart icon (default)
- [ ] Heart icon is now TAPPABLE (tap it)
- [ ] Heart Customization screen opens
- [ ] Reopen purchase menu
- [ ] Collector tier shows "PURCHASED" badge

### Test 4: Already Purchased Protection
**Prerequisites:** Own at least one tier
- [ ] Open purchase menu
- [ ] Tap tier card that's already purchased
- [ ] Snackbar appears: "You already own this tier!"
- [ ] No purchase dialog appears
- [ ] No charge attempted

### Test 5: User Cancels Purchase
- [ ] Tap any unpurchased tier card
- [ ] Platform payment UI appears
- [ ] Tap "Cancel" in platform UI
- [ ] Purchase menu remains open
- [ ] No success dialog appears
- [ ] No error message appears
- [ ] Tier remains unpurchased
- [ ] Can retry purchase

### Test 6: Purchase Error Handling
- [ ] Trigger payment error (disconnect network, use expired card, etc.)
- [ ] Error snackbar appears: "Purchase failed: [error message]"
- [ ] Purchase menu remains open
- [ ] Tier remains unpurchased
- [ ] Can retry purchase

## Restore Purchases Tests

### Test 7: Restore on Same Device
**Prerequisites:** Own at least one tier, then clear app data/reinstall
- [ ] Install fresh copy of app
- [ ] Open Credits screen - no hearts visible
- [ ] Open purchase menu
- [ ] All tiers show as unpurchased
- [ ] Tap "Restore Purchases" button
- [ ] Loading indicator appears
- [ ] Success snackbar: "Purchases restored successfully!"
- [ ] Owned tier(s) now show "PURCHASED" badge
- [ ] Close and reopen purchase menu - state persists
- [ ] Credits screen shows correct heart icon
- [ ] Collector customization available if Collector tier owned

### Test 8: Restore on New Device
**Prerequisites:** Purchase on Device A, then install on Device B with same account
- [ ] Install app on second device
- [ ] Sign in with same test account
- [ ] Open purchase menu
- [ ] Tap "Restore Purchases"
- [ ] Purchases sync successfully
- [ ] Correct tier marked as purchased
- [ ] Credits screen shows correct heart

### Test 9: Restore with No Purchases
**Prerequisites:** Fresh test account with no purchases
- [ ] Open purchase menu
- [ ] Tap "Restore Purchases"
- [ ] Success snackbar appears (no error)
- [ ] All tiers remain unpurchased
- [ ] No crashes or errors

## Heart Customization Tests (Collector Tier Only)

### Test 10: Access Control
**Prerequisites:** No Collector tier owned
- [ ] Attempt to navigate to /heart-customization route
- [ ] Access denied dialog appears
- [ ] Dialog text: "Heart customization is available exclusively for Collector tier supporters..."
- [ ] Screen closes automatically after tapping OK

**Prerequisites:** Own Collector tier
- [ ] Tap Collector heart icon in Credits screen
- [ ] Heart Customization screen opens successfully
- [ ] No access denied dialog

### Test 11: Customization Interface
**Prerequisites:** Own Collector tier
- [ ] Open Heart Customization screen
- [ ] Large preview heart shows at top (default: Rainbow)
- [ ] Preview shows current selection name below heart
- [ ] Four sections visible:
  - [ ] "Mono Colors" - 5 hearts (White, Blue, Black, Red, Green)
  - [ ] "Guild Colors (2-color)" - 10 hearts (guilds)
  - [ ] "Tri-Color Combos" - 10 hearts (shards + wedges)
  - [ ] "Special" - 1 heart (Rainbow)
- [ ] Currently selected heart has blue border and highlighted background
- [ ] All hearts render correctly with proper colors/gradients
- [ ] Bottom buttons: "Cancel" and "Save"

### Test 12: Style Selection
**Prerequisites:** Own Collector tier, Heart Customization screen open
- [ ] Tap a mono-color heart (e.g., Red)
- [ ] Large preview updates instantly to show Red heart
- [ ] Preview label updates to "Red"
- [ ] Red heart swatch shows selected border
- [ ] Previous selection loses selected border
- [ ] Tap a guild heart (e.g., Izzet - blue/red)
- [ ] Large preview shows 2-color gradient
- [ ] Preview label updates to "Izzet"
- [ ] Tap a tri-color heart (e.g., Jund - black/red/green)
- [ ] Large preview shows 3-color gradient
- [ ] Preview label updates to "Jund"
- [ ] Selection persists while navigating sections

### Test 13: Save Customization
**Prerequisites:** Own Collector tier, Heart Customization screen open
- [ ] Select a different heart than current (e.g., Gruul)
- [ ] Tap "Save" button
- [ ] Success snackbar: "Gruul heart style saved!"
- [ ] Screen closes automatically
- [ ] Credits screen shows new Gruul heart icon
- [ ] Reopen Heart Customization screen
- [ ] Gruul is pre-selected
- [ ] Close app completely and relaunch
- [ ] Credits screen still shows Gruul heart
- [ ] Selection persisted across app restart

### Test 14: Cancel Without Saving
**Prerequisites:** Own Collector tier, saved style is Rainbow
- [ ] Open Heart Customization screen
- [ ] Rainbow is selected (current saved style)
- [ ] Change selection to Boros
- [ ] Tap "Cancel" button
- [ ] Confirmation dialog appears: "Discard Changes?"
- [ ] Dialog text: "You have unsaved changes. Are you sure you want to discard them?"
- [ ] Tap "Continue Editing"
- [ ] Dialog closes, still on customization screen
- [ ] Boros still selected
- [ ] Tap "Cancel" again
- [ ] Confirmation dialog appears again
- [ ] Tap "Discard"
- [ ] Screen closes
- [ ] Credits screen still shows Rainbow heart (not Boros)
- [ ] Reopen customization - Rainbow is selected

### Test 15: Cancel Without Changes
**Prerequisites:** Own Collector tier, Heart Customization screen open
- [ ] Open screen (don't change selection)
- [ ] Tap "Cancel" button
- [ ] NO confirmation dialog appears
- [ ] Screen closes immediately
- [ ] No changes saved

## Edge Case Tests

### Test 16: Offline Purchase State
**Prerequisites:** Own at least one tier
- [ ] Verify purchase shows in Credits screen
- [ ] Turn on Airplane mode
- [ ] Force quit and relaunch app
- [ ] IAP service initializes (check console)
- [ ] Credits screen shows correct heart (from cache)
- [ ] Open purchase menu
- [ ] Owned tier shows "PURCHASED" badge (from cache)
- [ ] Product prices may fail to load (network error)
- [ ] Turn off Airplane mode
- [ ] Pull to refresh or reopen menu
- [ ] Products load successfully

### Test 17: Multiple Rapid Taps
- [ ] Open purchase menu
- [ ] Rapidly tap same tier card 5 times
- [ ] Only one purchase dialog appears
- [ ] Purchase button shows loading state
- [ ] Other tier cards remain tappable

### Test 18: Tier Upgrade Path
**Prerequisites:** Own Thank You tier
- [ ] Open purchase menu
- [ ] Thank You tier shows "PURCHASED"
- [ ] Purchase Play tier
- [ ] Play tier now shows "PURCHASED"
- [ ] Thank You tier NO LONGER shows "PURCHASED"
- [ ] Credits screen shows BLUE heart (Play tier)
- [ ] Only highest owned tier displays

**Follow-up:** Purchase Collector tier
- [ ] Collector tier shows "PURCHASED"
- [ ] Play tier no longer shows "PURCHASED"
- [ ] Credits screen shows customizable heart
- [ ] Only Collector tier displays

### Test 19: Platform Switching
**Prerequisites:** Own tier on iOS
- [ ] Note current tier ownership
- [ ] Install app on Android device
- [ ] Sign in with same account (if applicable)
- [ ] Open purchase menu
- [ ] Tap "Restore Purchases"
- [ ] NOTE: Cross-platform restore may not work (Apple/Google are separate)
- [ ] Document behavior

### Test 20: Persistence After Updates
- [ ] Own a tier and customize heart (if Collector)
- [ ] Note current configuration
- [ ] Simulate app update (rebuild and reinstall)
- [ ] Launch app
- [ ] Verify tier ownership persists
- [ ] Verify heart customization persists (if Collector)
- [ ] Open purchase menu - owned tier still marked purchased

## Platform-Specific Tests

### iOS-Specific

#### Test 21: iOS Sandbox Account
- [ ] Sign out of App Store in Settings
- [ ] Open app and attempt purchase
- [ ] Sandbox sign-in prompt appears
- [ ] Enter sandbox account credentials
- [ ] Purchase completes successfully
- [ ] Sandbox environment indicator visible (if in Settings)

#### Test 22: iOS Parental Approval
- [ ] Use sandbox account with "Ask to Buy" enabled (if available)
- [ ] Initiate purchase
- [ ] Purchase enters "pending" state
- [ ] App handles pending status gracefully
- [ ] No crash or error
- [ ] Approve purchase from parent account
- [ ] Purchase completes
- [ ] Features unlock

#### Test 23: iOS Receipt Validation
- [ ] Check console logs during purchase
- [ ] Verify purchase receipt data logged
- [ ] No errors in receipt handling
- [ ] Purchase completes successfully

### Android-Specific

#### Test 24: Android License Testing
- [ ] Email added to license testers in Play Console
- [ ] Google account on device matches tester email
- [ ] Open purchase menu
- [ ] Products load successfully
- [ ] Prices show correctly (test pricing or free)
- [ ] Purchase completes

#### Test 25: Android Pending Transactions
- [ ] Check for any pending transactions in Play Console
- [ ] If pending exists, complete it
- [ ] Verify app handles completion correctly
- [ ] No duplicate purchases

#### Test 26: Android Billing Client
- [ ] Check console logs for BillingClient connection
- [ ] Verify "Billing client connected" or similar message
- [ ] No "Billing unavailable" errors
- [ ] Product query succeeds

## Console Log Verification

### Expected Success Logs
- [ ] "IAP service initialized successfully"
- [ ] "Loaded cached purchases - Thank You: [bool], Play: [bool], Collector: [bool]"
- [ ] "Restore purchases initiated"
- [ ] "Delivering purchase: [product_id]"
- [ ] No error messages in console during normal flow

### Expected Error Logs (Handled Gracefully)
- [ ] "IAP not available on this device" (simulators/emulators)
- [ ] "Products not found: [ids]" (if platform not configured)
- [ ] "Purchase error: [details]" (user canceled, network issues)
- [ ] App continues functioning despite errors

## SharedPreferences Verification

### Android: View SharedPreferences
```bash
# Connect device and run:
adb shell run-as com.loosetie.frenchvanilla cat /data/data/com.loosetie.frenchvanilla/shared_prefs/FlutterSharedPreferences.xml
```

Expected keys after purchases:
- [ ] `flutter.purchased_thank_you` = true (if owned)
- [ ] `flutter.purchased_play` = true (if owned)
- [ ] `flutter.purchased_collector` = true (if owned)
- [ ] `flutter.collector_heart_style` = "[style_id]" (if customized)

### iOS: View UserDefaults
```bash
# Attach Xcode debugger and check UserDefaults
```

Expected keys match Android equivalent.

## Final Verification

### Production Readiness
- [ ] All tests passed on iOS
- [ ] All tests passed on Android
- [ ] No console errors during normal operation
- [ ] Graceful error handling for all edge cases
- [ ] Purchase persistence works correctly
- [ ] Restore functionality works correctly
- [ ] Customization works and persists
- [ ] UI is polished and responsive
- [ ] Loading states appropriate
- [ ] Error messages user-friendly

### Documentation
- [ ] iap_quick_start.md reviewed
- [ ] iap_implementation_summary.md reviewed
- [ ] iap_testing_guide.md reviewed
- [ ] This checklist completed

### Platform Submission
- [ ] iOS App Store Connect products configured and approved
- [ ] Google Play Console products configured and published
- [ ] Screenshots updated (if showing purchase UI)
- [ ] App privacy details updated (purchases)
- [ ] Ready for TestFlight/Internal Testing
- [ ] Ready for production release

---

**Testing Date:** _____________
**Tester:** _____________
**iOS Version:** _____________
**Android Version:** _____________
**App Version:** _____________
**Test Account Used:** _____________

**Notes:**
