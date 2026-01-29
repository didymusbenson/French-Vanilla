# Next Steps: IAP Platform Configuration & Testing

> **Implementation Status**: ✅ Code 100% complete. Platform configuration required.
>
> **For completed features and development history**, see `docs/development_log.md`

---

## What Still Needs Done

### 1. Platform Configuration ⏳ REQUIRED

IAP code is complete but **will not work** until products are configured in both app stores.

#### App Store Connect (iOS)

Create 3 non-consumable IAP products with these **exact** IDs:

```
com.loosetie.frenchvanilla.thank_you
com.loosetie.frenchvanilla.play
com.loosetie.frenchvanilla.collector
```

**Configuration:**
- Product Type: Non-consumable
- Prices: $1.99 USD, $5.49 USD, $26.99 USD
- Descriptions: See `docs/iap_testing_guide.md` for copy/paste descriptions
- Status: Submit with app for review

**Bundle ID**: `LooseTie.Frenchvanilla`

#### Google Play Console (Android)

Create 3 one-time purchase products with same **exact** IDs:

```
com.loosetie.frenchvanilla.thank_you
com.loosetie.frenchvanilla.play
com.loosetie.frenchvanilla.collector
```

**Configuration:**
- Product Type: One-time purchase (managed product)
- Prices: $1.99 USD, $5.49 USD, $26.99 USD
- Descriptions: See `docs/iap_testing_guide.md`
- Status: Activate products

**Package Name**: `com.loosetie.frenchvanilla`

---

### 2. Testing ⏳ REQUIRED

Test on **physical devices only** (simulators have limited IAP support).

#### iOS Testing Setup

1. Create sandbox test account in App Store Connect
2. Sign out of personal Apple ID on test device
3. Sign in with sandbox account when prompted during purchase
4. Test all 3 tiers + restore purchases

#### Android Testing Setup

1. Add email as license tester in Google Play Console
2. Opt into internal testing track
3. Install app from Play Store (not side-load)
4. Test all 3 tiers + restore purchases

#### Test Checklist

See `docs/iap_testing_checklist.md` for complete verification checklist covering:
- [ ] All 3 purchase tiers work correctly
- [ ] Hearts display correctly based on tier
- [ ] Restore purchases works
- [ ] Heart customization works (Collector tier)
- [ ] Error handling (network issues, cancellation, etc.)
- [ ] All 7 user journeys documented in spec

---

### 3. App Store Submission ⏳ REQUIRED

#### iOS Submission

1. Submit app with IAP products for review
2. In review notes, mention IAP functionality
3. Provide test account credentials for reviewers
4. Wait for approval

#### Android Submission

1. Upload APK/AAB to Play Console
2. Submit for review
3. IAP products are automatically reviewed with app

---

## Pre-Release Technical Debt

Before submission, clean up:

### High Priority
- [x] ~~Remove debug print statements in `rule_detail_screen.dart`~~ **DONE**

### Medium Priority
- [ ] Review bookmark snackbar aggregation UX (optional)
  - Implementation: `lib/mixins/aggregating_snackbar_mixin.dart`
  - Consider if rapid bookmark behavior needs refinement

---

## Known Limitations

1. **Server-side receipt verification not implemented**
   - Current implementation trusts platform verification
   - Production apps should ideally verify with backend server
   - See `lib/services/iap_service.dart:250` for TODO comment

2. **No analytics tracking**
   - Purchase events not logged
   - Consider adding Firebase Analytics for conversion tracking

3. **Platform configuration required**
   - App shows "Products not available" until configured in stores

---

## Quick Reference Documentation

- **[IAP Quick Start](iap_quick_start.md)** - 5-minute overview of what was built
- **[IAP Testing Guide](iap_testing_guide.md)** - Detailed platform setup instructions with product descriptions
- **[IAP Testing Checklist](iap_testing_checklist.md)** - QA verification checklist
- **[IAP Implementation Summary](iap_implementation_summary.md)** - Complete technical details

---

## Product IDs Reference

Critical: These IDs are hardcoded in `lib/services/iap_service.dart` and must match exactly:

```dart
static const String thankYouId = 'com.loosetie.frenchvanilla.thank_you';
static const String playId = 'com.loosetie.frenchvanilla.play';
static const String collectorId = 'com.loosetie.frenchvanilla.collector';
```

**Pricing:**
- Thank You: $1.99 USD
- Play: $5.49 USD
- Collector: $26.99 USD

**Features:**
- Thank You: Red heart badge
- Play: Blue heart badge + all Thank You features
- Collector: Rainbow heart badge + 26 customizable styles + all Play features

---

## Tooling Improvements

### Data Update Commands
- [ ] Create `getcards` wrapper script (matching `getjudgerules` pattern)
  - Should call `python3 scripts/process_cards.py`
  - Provides consistent interface with other data update commands
- [ ] Create `getrules` wrapper script (matching `getjudgerules` pattern)
  - Should call `python3 scripts/update_rules.py "<url>"`
  - Provides consistent interface with other data update commands

**Current status:**
- ✅ `getjudgerules` - Complete with wrapper script + Claude command
- ⏳ `getcards` - Python script exists, needs wrapper
- ⏳ `getrules` - Python script exists, needs wrapper

---

**Last Updated**: 2026-01-28
