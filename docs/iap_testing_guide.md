# IAP Testing Guide

A detailed, step-by-step guide for testing In-App Purchases in French Vanilla on both iOS and Android.

---

## Section 1: iOS Testing Setup

### 1.1 Create Sandbox Test Account

**Important:** Never use your personal Apple ID for testing IAP!

1. **Go to App Store Connect**
   - Navigate to: https://appstoreconnect.apple.com
   - Sign in with your developer account

2. **Create Sandbox Tester**
   - Click "Users and Access" in top navigation
   - Click "Sandbox" tab (or "Testers" → "Sandbox Testers")
   - Click the "+" button to add a tester
   - Fill in the form:
     - First Name: Test
     - Last Name: User (or any name)
     - Email: **Must be unique email you control** (can use +addressing: yourname+sandbox1@gmail.com)
     - Password: Create a strong password (you'll need this)
     - Country/Region: Select your test region
     - App Store Territory: Same as country
   - Click "Invite"
   - **IMPORTANT:** This email doesn't need to be a real Apple ID, it's only for sandbox

3. **Save Credentials**
   - Write down the email and password - you'll need them on device
   - You can create multiple sandbox accounts for different test scenarios

### 1.2 Configure Products in App Store Connect

**Critical:** Products must be configured before testing, even in sandbox mode.

1. **Navigate to Your App**
   - Go to App Store Connect → Apps
   - Select "French Vanilla" (or create app if not exists)
   - Bundle ID must be: `LooseTie.Frenchvanilla`

2. **Create In-App Purchases**
   - Click "In-App Purchases" in left sidebar
   - Click "+" to create new IAP

3. **Create Product 1: Thank You Tier**
   - Type: **Non-Consumable**
   - Reference Name: `Thank You Tier`
   - Product ID: `com.loosetie.frenchvanilla.thank_you` (MUST MATCH EXACTLY!)
   - Price: Select tier (e.g., $0.99 or higher)
   - Localized Information:
     - Display Name: `Thank You Tier`
     - Description: `Support French Vanilla and get a red heart badge`
     - Language: English (U.S.)
   - Screenshot: Upload screenshot (required - can be placeholder for testing)
   - Click "Save"

4. **Create Product 2: Play Tier**
   - Type: **Non-Consumable**
   - Reference Name: `Play Tier`
   - Product ID: `com.loosetie.frenchvanilla.play` (MUST MATCH EXACTLY!)
   - Price: Higher tier than Thank You (e.g., $2.99)
   - Localized Information:
     - Display Name: `Play Tier`
     - Description: `Support French Vanilla and get a blue heart badge with additional features`
   - Screenshot: Upload
   - Click "Save"

5. **Create Product 3: Collector Tier**
   - Type: **Non-Consumable**
   - Reference Name: `Collector Tier`
   - Product ID: `com.loosetie.frenchvanilla.collector` (MUST MATCH EXACTLY!)
   - Price: Highest tier (e.g., $4.99)
   - Localized Information:
     - Display Name: `Collector Tier`
     - Description: `Premium support with rainbow heart badge and 26 customizable heart styles`
   - Screenshot: Upload
   - Click "Save"

6. **Submit for Review** (Eventually)
   - In sandbox, products work immediately without review
   - For production/TestFlight, products must be submitted with app
   - Products can be in "Ready to Submit" state for sandbox testing

### 1.3 Test on iOS Device (NOT Simulator)

**Why Physical Device?**
- iOS Simulator has limited IAP support
- Sandbox accounts only work on real devices
- StoreKit Testing (simulator feature) requires different configuration

**Setup Device:**

1. **Sign Out of App Store**
   - Go to Settings → [Your Name] → Media & Purchases
   - Tap "Sign Out" (only for purchases, not iCloud)
   - Alternative: Settings → App Store → Tap Apple ID → Sign Out
   - **Do NOT sign in with sandbox account here!**

2. **Install App via Xcode**
   - Connect device via USB
   - Open project in Xcode
   - Select your device as target
   - Click "Run" (play button)
   - App installs and launches

3. **Test Purchase**
   - In app, open Credits screen
   - Tap to open Purchase Menu
   - Tap a tier card to purchase
   - **Sandbox sign-in prompt will appear**
   - Enter sandbox account email and password
   - **You'll see a "[Sandbox]" indicator at top**
   - Complete purchase
   - Verify success

### 1.4 Common iOS IAP Gotchas

1. **"Cannot connect to iTunes Store"**
   - You're signed in with real Apple ID
   - Solution: Sign out of App Store in Settings
   - Only sign in with sandbox account when prompted

2. **Products Not Loading**
   - Product IDs don't match exactly (check for typos)
   - Products not created in App Store Connect
   - Bundle ID doesn't match
   - IAP capability not enabled (Xcode → Signing & Capabilities → Add "In-App Purchase")
   - Solution: Verify all IDs match exactly

3. **"This In-App Purchase has already been bought. It will be restored for free."**
   - Previous test purchase exists
   - Solution: This is normal for non-consumables, it will restore automatically
   - To clear: Use different sandbox account

4. **Sandbox Account Locked**
   - Too many incorrect password attempts
   - Solution: Create new sandbox account in App Store Connect

5. **Receipt Validation Errors**
   - App is trying to validate with production servers
   - Solution: Use sandbox receipt validation URL: `https://sandbox.itunes.apple.com/verifyReceipt`

6. **Products Show $0.00 Price**
   - App is loading from cache before products load
   - Products failed to query from store
   - Solution: Check console logs for errors, verify network connection

### 1.5 How to Clear iOS Test Purchases

**Option 1: Use Different Sandbox Account**
- Create another sandbox tester in App Store Connect
- Sign in with new account
- Fresh purchase state

**Option 2: Delete and Reinstall App**
- Delete app from device
- Reinstall via Xcode
- Purchases will restore automatically on first launch (this is expected)

**Option 3: Clear Sandbox Purchase History (Limited)**
- Not officially supported by Apple
- Best to use fresh sandbox accounts

---

## Section 2: Android Testing Setup

### 2.1 Configure Products in Google Play Console

1. **Go to Google Play Console**
   - Navigate to: https://play.google.com/console
   - Sign in with developer account

2. **Select Your App**
   - Click on "French Vanilla" (or create if not exists)
   - Application ID must be: `com.loosetie.frenchvanilla`

3. **Navigate to In-App Products**
   - In left sidebar: Monetize → In-app products
   - Click "Create product"

4. **Create Product 1: Thank You Tier**
   - Product ID: `thank_you` (will become `com.loosetie.frenchvanilla.thank_you`)
   - Name: `Thank You Tier`
   - Description: `Support French Vanilla and get a red heart badge`
   - Status: **Active** (toggle to active)
   - Price:
     - Click "Set price"
     - Select base country and price (e.g., USD $0.99)
     - Google converts to all regions automatically
     - Click "Apply"
   - Click "Save"

5. **Create Product 2: Play Tier**
   - Product ID: `play`
   - Name: `Play Tier`
   - Description: `Support French Vanilla and get a blue heart badge with additional features`
   - Status: **Active**
   - Price: Higher tier (e.g., USD $2.99)
   - Click "Save"

6. **Create Product 3: Collector Tier**
   - Product ID: `collector`
   - Name: `Collector Tier`
   - Description: `Premium support with rainbow heart badge and 26 customizable heart styles`
   - Status: **Active**
   - Price: Highest tier (e.g., USD $4.99)
   - Click "Save"

7. **Verify Product Status**
   - All 3 products should show status: **Active**
   - Products are immediately available for testing (no review needed)

### 2.2 Set Up Internal Testing Track

**Why Internal Testing?**
- Test IAP without publishing to production
- Products must be in a release (not draft)
- License testers can make test purchases

**Setup Steps:**

1. **Create Internal Test Release**
   - In Google Play Console, go to: Release → Testing → Internal testing
   - Click "Create new release"
   - Upload APK/AAB:
     - Build in Android Studio (Build → Build Bundle(s) / APK(s) → Build Bundle(s))
     - Upload the .aab file from `build/app/outputs/bundle/release/`
   - Release name: v1.0-internal-test
   - Release notes: "Testing IAP implementation"
   - Click "Save"
   - Click "Review release"
   - Click "Start rollout to Internal testing"

2. **Create Testers List**
   - In Internal testing page, scroll to "Testers" section
   - Click "Create email list" or use existing list
   - Add tester emails (your test Google accounts)
   - Click "Save changes"

3. **Get Opt-In URL**
   - Copy the opt-in URL shown on Internal testing page
   - Open URL on test device (while signed in with tester account)
   - Click "Become a tester"
   - Download app from Play Store

### 2.3 Add Test Users

**Option 1: License Testers (Recommended for Development)**

1. **Add License Testers**
   - Go to: Settings → License testing
   - Scroll to "License testers"
   - Click "Add testers"
   - Add Gmail addresses (one per line)
   - Click "Save changes"

2. **Configure Test Response**
   - For each tester, you can set response:
     - **LICENSED** - Normal behavior
     - **RESPOND_NORMALLY** - Use for IAP testing (allows real purchases)
   - For IAP testing, leave as default or set RESPOND_NORMALLY

**Option 2: Internal Test Track (Recommended for QA)**

1. Use internal test release (from Section 2.2)
2. Add testers to internal testing list
3. Testers download via opt-in link

**Option 3: Test Purchases (Limited)**

- Google allows limited free test purchases
- Reserved for specific testing scenarios

### 2.4 Test on Android Device or Emulator

**Physical Device (Recommended):**

1. **Enable Developer Mode**
   - Go to Settings → About phone
   - Tap "Build number" 7 times
   - Developer options enabled

2. **Enable USB Debugging**
   - Go to Settings → System → Developer options
   - Enable "USB debugging"
   - Connect device via USB

3. **Sign In with Test Account**
   - Ensure device is signed in with Google account
   - Account must be added as license tester in Play Console

4. **Install App**
   - Open project in Android Studio
   - Select connected device
   - Click "Run" (green play button)
   - App installs and launches

**Emulator (Limited IAP Support):**

1. **Create AVD with Google APIs**
   - Tools → AVD Manager → Create Virtual Device
   - Select device with Play Store icon
   - Download system image with Google APIs
   - Start emulator

2. **Sign In to Play Store**
   - Open Play Store app in emulator
   - Sign in with test account (license tester)

3. **Install App**
   - Run from Android Studio
   - Note: Emulator IAP can be unreliable

### 2.5 Common Android IAP Gotchas

1. **"Billing unavailable" or "Item unavailable"**
   - Products not configured in Play Console
   - Products not set to Active status
   - App not installed from Play Store (for some billing versions)
   - Solution:
     - Verify products are Active
     - Upload to Internal Testing track
     - Download via opt-in link

2. **"Authentication is required"**
   - Not signed in to Play Store
   - Account not added as license tester
   - Solution: Sign in with tester account

3. **Products Show as Already Owned**
   - Previous test purchase exists
   - Solution: This is correct for non-consumables, will restore automatically

4. **"You already own this item"**
   - Attempting to purchase again
   - Expected behavior for non-consumables
   - Use different test account for fresh state

5. **BillingClient Connection Issues**
   - Google Play Services not installed (emulator)
   - App not signed with correct key
   - Solution: Use physical device or emulator with Google APIs

6. **Pending Transactions**
   - Previous purchase stuck in pending state
   - Solution:
     - Check Play Console → Order Management
     - Complete or cancel pending orders
     - Call `acknowledgePurchase()` in code (already implemented)

### 2.6 How to Clear Android Test Purchases

**Option 1: Use Different Test Account**
- Add new Gmail account to device
- Add to license testers list
- Test with fresh account

**Option 2: Clear Play Store Data**
- Settings → Apps → Google Play Store → Storage → Clear data
- Sign in again
- Note: May not clear purchase history, only cache

**Option 3: Refund Test Purchases** (Not Recommended)
- Go to Play Console → Order management
- Find test orders
- Issue refunds
- Takes time to process

**Option 4: Use Different Product IDs**
- For extensive testing, create additional test products
- Not ideal for final testing

**Best Practice:**
- Use multiple test accounts
- Each account represents different purchase states

---

## Section 3: Testing the App

### 3.1 Basic Purchase Flow Test

**Objective:** Verify a complete purchase from start to finish

**Steps:**

1. **Launch App**
   - Open French Vanilla
   - Navigate to Credits screen (or wherever heart badges appear)
   - Verify no heart badge visible (fresh install)

2. **Open Purchase Menu**
   - Tap heart area or purchase button
   - Purchase menu slides up from bottom
   - Verify all UI elements load:
     - Header: "Support French Vanilla"
     - Description text
     - 3 tier cards with heart previews
     - Product prices (not $0.00, not loading indefinitely)
     - "Restore Purchases" button

3. **Select Tier**
   - Tap "Play Tier" card (middle tier is good for testing)
   - Platform purchase dialog appears:
     - **iOS:** App Store confirmation sheet
     - **Android:** Google Play bottom sheet
   - Review shows correct product name and price
   - Shows sandbox/test indicator if applicable

4. **Complete Purchase**
   - **iOS:** Authenticate with Face ID/Touch ID or password
   - **Android:** Confirm purchase
   - Wait for processing (can take 2-10 seconds)
   - Watch console logs for:
     ```
     Delivering purchase: com.loosetie.frenchvanilla.play
     ```

5. **Verify Success**
   - Success dialog appears: "Thank you for your support! You're now a Play supporter."
   - Tap "Close" button
   - Purchase menu closes automatically
   - Credits screen now displays **BLUE heart icon**
   - Heart icon is visible and properly rendered

6. **Verify Persistence**
   - Reopen purchase menu
   - Play tier card shows "PURCHASED" badge with checkmark
   - Badge is slightly opaque/disabled appearance
   - Tapping Play tier shows snackbar: "You already own this tier!"
   - Other tiers (Thank You, Collector) still show as available

7. **Test App Restart**
   - Force quit app completely
   - Relaunch app
   - Navigate to Credits screen
   - Blue heart still visible (loaded from SharedPreferences cache)
   - Open purchase menu
   - Play tier still shows PURCHASED

8. **Test Offline Mode**
   - Turn on Airplane mode
   - Force quit and relaunch app
   - Blue heart still visible (offline cache working)
   - Open purchase menu
   - Play tier shows PURCHASED (from cache)
   - Products may fail to load (network error) - this is expected
   - Turn off Airplane mode
   - Refresh/reopen menu
   - Products load successfully

### 3.2 Purchase Restoration Test

**Objective:** Verify purchases restore after reinstall or on new device

**Steps:**

1. **Make Purchase** (if not already done)
   - Complete Test 3.1 above
   - Verify you own a tier (e.g., Play)

2. **Note Current State**
   - Write down which tier you own
   - If Collector tier: note customized heart style
   - Take screenshot for reference

3. **Simulate Fresh Install**
   - **iOS:** Delete app from device, reinstall via Xcode
   - **Android:** Settings → Apps → French Vanilla → Clear data, or uninstall and reinstall
   - Launch app

4. **Verify Fresh State**
   - Credits screen shows no heart badge
   - Open purchase menu
   - All tiers appear unpurchased (no PURCHASED badges)
   - This is expected - cache cleared but purchase exists on platform

5. **Restore Purchases**
   - In purchase menu, tap "Restore Purchases" button
   - Button shows loading indicator
   - Watch console logs:
     ```
     Restore purchases initiated
     Delivering purchase: com.loosetie.frenchvanilla.play
     ```
   - Wait 2-5 seconds

6. **Verify Restoration**
   - Success snackbar appears: "Purchases restored successfully!"
   - Purchase menu updates - Play tier now shows PURCHASED
   - Close purchase menu
   - Credits screen now shows blue heart badge
   - If Collector tier: customization may need to be re-set (only purchase restores, not preferences)

7. **Verify Persistence After Restore**
   - Close and reopen purchase menu
   - Play tier still shows PURCHASED
   - Force quit and relaunch app
   - Heart badge still visible

### 3.3 Heart Customization Test (Collector Tier Only)

**Prerequisites:** Must own Collector tier

**Setup:**
- If you don't own Collector tier, purchase it:
  - Open purchase menu
  - Tap Collector Tier card
  - Complete purchase
  - Verify rainbow heart appears in Credits screen

**Steps:**

1. **Access Customization Screen**
   - In Credits screen, tap the Collector heart icon
   - Heart Customization screen opens (full screen)
   - Verify UI:
     - App bar with "Customize Collector Heart" title
     - Close button (X) in top-left
     - Large heart preview at top (default: Rainbow)
     - Heart name below preview ("Rainbow")
     - Four sections scrollable below

2. **Explore Sections**
   - **Mono Colors Section:**
     - Header: "Mono Colors"
     - 5 hearts: White, Blue, Black, Red, Green
     - All render as solid colors
   - **Guild Colors Section:**
     - Header: "Guild Colors (2-color)"
     - 10 hearts with names like Azorius, Izzet, etc.
     - All render with 2-color gradients
   - **Tri-Color Section:**
     - Header: "Tri-Color Combos"
     - 10 hearts: Esper, Grixis, Jund, Naya, Bant, Abzan, Jeskai, Sultai, Mardu, Temur
     - All render with 3-color gradients
   - **Special Section:**
     - Header: "Special"
     - 1 heart: Rainbow (default)
     - Renders with yellow-red-blue gradient

3. **Test Selection**
   - Tap "Gruul" heart (red/green guild)
   - Immediately observe:
     - Large preview updates to show Gruul heart
     - Preview label changes to "Gruul"
     - Gruul swatch shows thick blue border (selected)
     - Rainbow swatch loses selection border
   - Scroll to different section
   - Tap "Jund" (black/red/green tri-color)
   - Preview updates to Jund
   - Label changes to "Jund"
   - Jund swatch shows selected border
   - Gruul loses selection border

4. **Test Save**
   - Ensure a heart different from Rainbow is selected (e.g., Jund)
   - Tap "Save" button at bottom
   - Success snackbar appears: "Jund heart style saved!"
   - Screen closes automatically
   - Credits screen now shows **Jund heart** (3-color gradient)
   - Verify gradient renders correctly with 3 colors

5. **Test Persistence**
   - Reopen Heart Customization screen
   - Jund is pre-selected (has selection border)
   - Large preview shows Jund
   - Force quit app completely
   - Relaunch app
   - Credits screen still shows Jund heart
   - Reopen customization
   - Jund still selected

6. **Test Cancel Without Saving**
   - Currently saved: Jund
   - Open Heart Customization screen
   - Tap "Boros" (red/white guild)
   - Preview changes to Boros
   - Tap "Cancel" button (top-left X)
   - Confirmation dialog appears:
     - Title: "Discard Changes?"
     - Message: "You have unsaved changes. Are you sure you want to discard them?"
     - Buttons: "Continue Editing", "Discard"
   - Tap "Continue Editing"
   - Dialog closes, still on customization screen
   - Boros still selected in preview
   - Tap "Cancel" button again
   - Dialog appears again
   - Tap "Discard"
   - Screen closes
   - Credits screen shows **Jund heart** (not Boros)
   - Change was discarded

7. **Test Cancel Without Changes**
   - Open Heart Customization screen
   - Don't tap any hearts (Jund already selected)
   - Tap "Cancel" button
   - NO confirmation dialog appears
   - Screen closes immediately

8. **Test Access Control**
   - Use account that owns Play or Thank You tier (not Collector)
   - In Credits screen, heart icon should not be tappable, or show upgrade prompt
   - Attempt to navigate to customization (if you can trigger route manually)
   - Access denied dialog should appear:
     - Title: "Collector Tier Required"
     - Message: Explains it's Collector-only
   - Screen closes after tapping OK

### 3.4 What to Look For in Console Logs

**Successful Initialization:**
```
IAP service initialized successfully
Loaded cached purchases - Thank You: false, Play: false, Collector: false
Restore purchases initiated
```

**Successful Purchase:**
```
Delivering purchase: com.loosetie.frenchvanilla.play
```

**Successful Restore:**
```
Restore purchases initiated
Delivering purchase: com.loosetie.frenchvanilla.play
```

**Expected Errors (Handled Gracefully):**
```
IAP not available on this device
  → Shown in simulator/emulator, displays user-friendly error

Products not found: [com.loosetie.frenchvanilla.thank_you]
  → Platform not configured, shows error in UI

Purchase error: [details]
  → User canceled or network issue, shows snackbar
```

**Unexpected Errors (Need Investigation):**
```
PlatformException
  → Indicates code issue or platform misconfiguration

Null check operator used on null value
  → Bug in code, needs fixing

FormatException
  → Data parsing issue, investigate
```

### 3.5 How to Verify SharedPreferences Data

**Why Check SharedPreferences?**
- Confirms purchase state saved locally
- Verifies customization persists
- Helps debug offline mode

**Android: Using ADB**

1. **Connect Device**
   ```bash
   # Verify device connected
   adb devices
   ```

2. **Read SharedPreferences File**
   ```bash
   adb shell run-as com.loosetie.frenchvanilla cat /data/data/com.loosetie.frenchvanilla/shared_prefs/FlutterSharedPreferences.xml
   ```

3. **Expected Output** (after purchasing Play tier and customizing heart):
   ```xml
   <?xml version='1.0' encoding='utf-8' standalone='yes' ?>
   <map>
       <boolean name="flutter.purchased_play" value="true" />
       <string name="flutter.collector_heart_style">jund</string>
   </map>
   ```

4. **Verify Keys:**
   - `flutter.purchased_thank_you` - Boolean, true if Thank You tier owned
   - `flutter.purchased_play` - Boolean, true if Play tier owned
   - `flutter.purchased_collector` - Boolean, true if Collector tier owned
   - `flutter.collector_heart_style` - String, heart style ID (e.g., "jund", "rainbow")

**iOS: Using Xcode Debugger**

1. **Run App in Debug Mode**
   - Xcode → Run (⌘R)
   - Wait for app to launch

2. **Pause Execution**
   - Tap a heart in customization screen (to trigger save)
   - Set breakpoint in `HeartCustomizationScreen._saveStyle()`
   - Or use LLDB console

3. **Inspect UserDefaults**
   ```lldb
   po UserDefaults.standard.dictionaryRepresentation()
   ```

4. **Look for Keys:**
   - `purchased_play`
   - `collector_heart_style`

**Alternative: Add Debug Logging**

Add to your code temporarily:
```dart
// In _loadSavedStyle() method
final prefs = await SharedPreferences.getInstance();
debugPrint('All SharedPreferences keys: ${prefs.getKeys()}');
debugPrint('Thank You: ${prefs.getBool('purchased_thank_you')}');
debugPrint('Play: ${prefs.getBool('purchased_play')}');
debugPrint('Collector: ${prefs.getBool('purchased_collector')}');
debugPrint('Heart style: ${prefs.getString('collector_heart_style')}');
```

Watch console for output on app launch.

---

## Section 4: Troubleshooting

### Problem: IAP Not Available

**Symptoms:**
- Error message: "In-app purchases are not available on this device"
- Purchase menu shows error icon

**Causes & Solutions:**

1. **Testing on Simulator/Emulator**
   - **Cause:** IAP has limited support on virtual devices
   - **Solution:** Use real physical device

2. **Restricted Device**
   - **Cause:** Parental controls or device restrictions enabled
   - **Solution:** Settings → Screen Time → Content & Privacy Restrictions → iTunes & App Store Purchases → Set to Allow

3. **Network Issues**
   - **Cause:** No internet connection, app store servers unreachable
   - **Solution:** Verify internet connection, try again later

4. **Country/Region Issues**
   - **Cause:** App Store/Play Store not available in current region
   - **Solution:** Verify device region settings match developer account

### Problem: Products Don't Load

**Symptoms:**
- Product list empty
- Prices show as $0.00 or don't load
- Error message: "Unable to load products"

**Causes & Solutions:**

1. **Product IDs Don't Match**
   - **Cause:** Typo in code or platform configuration
   - **Solution:**
     - Verify IDs in code: `IAPService.dart`
     - Verify IDs in App Store Connect / Play Console
     - Must match EXACTLY: `com.loosetie.frenchvanilla.thank_you`

2. **Products Not Configured**
   - **Cause:** Products don't exist in App Store Connect / Play Console
   - **Solution:** Create all 3 products following Section 1.2 / 2.1

3. **Products Not Active (Android)**
   - **Cause:** Product status is "Inactive"
   - **Solution:** Play Console → In-app products → Set status to Active

4. **Bundle/App ID Mismatch**
   - **Cause:** App installed with different bundle ID than configured products
   - **Solution:**
     - Verify bundle ID in Xcode/Android Studio matches products
     - iOS: `LooseTie.Frenchvanilla`
     - Android: `com.loosetie.frenchvanilla`

5. **IAP Capability Missing (iOS)**
   - **Cause:** In-App Purchase capability not enabled
   - **Solution:**
     - Xcode → Target → Signing & Capabilities
     - Click "+ Capability"
     - Add "In-App Purchase"

6. **Network Issues**
   - **Cause:** Can't reach app store servers
   - **Solution:** Check internet connection, wait and retry

7. **Agreements Not Signed (iOS)**
   - **Cause:** Paid Applications Agreement not accepted
   - **Solution:** App Store Connect → Agreements, Tax, and Banking → Accept agreements

### Problem: Purchase Doesn't Complete

**Symptoms:**
- Payment UI appears but purchase never finishes
- Loading indicator spins indefinitely
- No success or error message

**Causes & Solutions:**

1. **Pending Completions Not Handled**
   - **Cause:** Previous purchases stuck in pending state
   - **Solution:**
     - Code should call `completePurchase()` - already implemented
     - Check console for errors during purchase update
     - **iOS:** No action needed, app handles automatically
     - **Android:** Check Play Console → Order Management for stuck orders

2. **Receipt Validation Failing**
   - **Cause:** App trying to verify with wrong server
   - **Solution:**
     - Current implementation trusts platform (no server validation)
     - If you added server validation, check server logs

3. **Network Interruption**
   - **Cause:** Lost connection during purchase
   - **Solution:**
     - Restore purchases to complete transaction
     - Platform will retry automatically

4. **Sandbox Account Issues (iOS)**
   - **Cause:** Sandbox account locked or expired
   - **Solution:** Create new sandbox account

### Problem: Restore Doesn't Work

**Symptoms:**
- Tap "Restore Purchases" but nothing happens
- Purchases don't appear after restore
- Error message during restore

**Causes & Solutions:**

1. **No Purchases to Restore**
   - **Cause:** Account never made purchases
   - **Solution:** This is expected, make a test purchase first

2. **Wrong Account**
   - **Cause:** Signed in with different account than used for purchase
   - **Solution:** Sign in with correct test account

3. **Cross-Platform Restore**
   - **Cause:** Purchased on iOS, trying to restore on Android (or vice versa)
   - **Solution:**
     - Apple and Google purchases don't sync across platforms
     - This is expected behavior
     - User must purchase on each platform separately

4. **Network Issues**
   - **Cause:** Can't reach app store to query purchases
   - **Solution:** Verify internet connection

5. **Platform Delays**
   - **Cause:** Purchase still processing on platform side
   - **Solution:** Wait 5-10 minutes, try restore again

### Problem: Customization Not Persisting

**Symptoms:**
- Select heart style and save
- Heart reverts to Rainbow after restart

**Causes & Solutions:**

1. **SharedPreferences Not Saving**
   - **Cause:** Permission issue or storage full
   - **Solution:**
     - Check console for errors during save
     - Verify device has storage space
     - Test on different device

2. **Loading Wrong Key**
   - **Cause:** Bug in code reading different key
   - **Solution:**
     - Check `_loadSavedStyle()` method
     - Verify key name: `collector_heart_style`

3. **Save Not Called**
   - **Cause:** User tapped Cancel instead of Save
   - **Solution:** User must tap "Save" button, not just close screen

4. **Collector Tier Lost**
   - **Cause:** Reinstalled app, purchases not restored
   - **Solution:**
     - Restore purchases first
     - Then customization access returns
     - Note: Customization preference is local only, doesn't restore automatically

### Problem: Wrong Heart Displaying

**Symptoms:**
- Own Play tier but see Red heart
- Own Collector but customization doesn't show
- Heart doesn't match owned tier

**Causes & Solutions:**

1. **Cache Out of Sync**
   - **Cause:** Local cache doesn't match platform state
   - **Solution:**
     - Tap "Restore Purchases"
     - Force quit and relaunch app

2. **Multiple Tiers Owned**
   - **Cause:** Testing purchased multiple tiers
   - **Solution:**
     - Code shows highest tier only
     - This is expected behavior
     - Collector > Play > Thank You

3. **Customization Not Loaded**
   - **Cause:** Credits screen didn't load preference yet
   - **Solution:**
     - Check console for errors in `_loadData()`
     - Verify SharedPreferences key exists

4. **Gradient Not Rendering**
   - **Cause:** Platform issue with ShaderMask
   - **Solution:**
     - Works on most devices
     - Fallback to solid color if needed (code modification)

### Problem: "Already Own This Item" Error

**Symptoms:**
- Trying to purchase shows error
- Can't buy different tier after owning one

**Causes & Solutions:**

1. **Non-Consumable Purchase**
   - **Cause:** Product is non-consumable, can only buy once
   - **Solution:**
     - This is expected for tier system
     - User owns tier forever
     - To test again, use different sandbox/test account

2. **Want to Upgrade Tier**
   - **Cause:** User owns Thank You, wants to buy Play
   - **Solution:**
     - **Current Implementation:** Separate purchases, user can own multiple
     - Each tier is independent purchase
     - Highest tier displays in UI

3. **Testing Multiple Purchases**
   - **Cause:** Need to test all tiers on same device
   - **Solution:**
     - Use multiple sandbox accounts
     - OR implement consumable test products for development

### Problem: Console Errors

**Error:** `PlatformException(store_kit_error, ...)`
- **Cause:** iOS StoreKit issue
- **Solution:** Check error code, may be network, canceled, or product issue

**Error:** `Billing unavailable`
- **Cause:** Google Play Billing not available
- **Solution:** Ensure Play Store installed, signed in, products configured

**Error:** `Null check operator used on null value`
- **Cause:** Code bug, unexpected null value
- **Solution:** Check stack trace, fix null safety issue

**Error:** `Purchase error: ProductNotFound`
- **Cause:** Product ID doesn't exist on platform
- **Solution:** Create products in App Store Connect / Play Console

### General Debugging Tips

1. **Always Check Console Logs**
   - Use `flutter run` or Xcode/Android Studio console
   - Look for debug prints from `IAPService`
   - Note any error messages

2. **Use Verbose Logging**
   - Add extra debug prints to track flow:
     ```dart
     debugPrint('🛒 About to purchase: $productId');
     debugPrint('✅ Purchase completed: $productId');
     debugPrint('💾 Saved to cache: $key = $value');
     ```

3. **Test on Multiple Devices**
   - Some issues are device-specific
   - Test on both iOS and Android
   - Test on different OS versions

4. **Use Fresh Test Accounts**
   - Create dedicated test accounts for each test scenario
   - Don't reuse accounts with complex purchase history

5. **Check Platform Dashboards**
   - App Store Connect → Sales and Trends → Sandbox Purchases
   - Play Console → Order Management → Test orders
   - Verify purchases appear on backend

6. **Document Test Results**
   - Keep notes on what works and what doesn't
   - Track device models, OS versions, account details
   - Share findings with team

7. **Isolate Issues**
   - Test one feature at a time
   - Simplify test cases when debugging
   - Remove variables to find root cause

---

## Summary

You now have:
1. **Platform setup instructions** for iOS (Section 1) and Android (Section 2)
2. **Step-by-step test procedures** for all features (Section 3)
3. **Troubleshooting guide** for common issues (Section 4)

**Next Steps:**
1. Complete platform configuration (Sections 1.2 and 2.1)
2. Create test accounts (Sections 1.1 and 2.3)
3. Follow test procedures (Section 3)
4. Use **iap_testing_checklist.md** to verify everything works
5. Reference this guide when issues arise

**Remember:**
- Always test on **real devices**
- Never use **personal accounts** for testing
- **Product IDs must match exactly** on all platforms
- Purchases are **permanent** for non-consumables
- **Restore** is required by both app stores

Good luck with testing! 🚀
