# IAP Quick Start Guide

## What Was Built

A complete **In-App Purchase (IAP) system** for French Vanilla with three support tiers:

- **Thank You Tier** - Base support with red heart badge
- **Play Tier** - Mid-tier with blue heart badge
- **Collector Tier** - Premium tier with rainbow heart badge + **26 customizable heart styles**

All purchases are **non-consumable** (one-time purchase, owned forever) and work offline after initial purchase.

## Features Implemented

- Purchase flow with App Store/Google Play integration
- Purchase restoration (for reinstalls or new devices)
- Local caching for offline access
- Heart badge system showing supporter status
- Full customization screen for Collector tier (26 heart styles based on Magic color combinations)
- Purchase menu with tier details and pricing
- Persistent preferences across app restarts

## What You Need to Do Next

### Critical Platform Configuration Required

The app code is complete, but **IAP will not work** until you configure products on both platforms:

1. **Apple App Store Connect**
   - Create the 3 IAP products with exact IDs (see below)
   - Submit for review (required for production)
   - Set up pricing tiers

2. **Google Play Console**
   - Create the 3 IAP products with exact IDs (see below)
   - Set up pricing
   - Publish products (no review needed for testing)

### Exact Product IDs (Must Match!)

These IDs are hardcoded in the app and **must match exactly** in both stores:

```
com.loosetie.frenchvanilla.thank_you
com.loosetie.frenchvanilla.play
com.loosetie.frenchvanilla.collector
```

**Product Type:** Non-consumable / One-time purchase

### Bundle Identifiers

- **iOS:** `LooseTie.Frenchvanilla`
- **Android:** `com.loosetie.frenchvanilla`

## Critical Gotchas

1. **IAP only works on real devices** - Simulators/emulators have limited support
2. **Products must be configured** - App will show "Products not available" until platform setup is complete
3. **Test with sandbox accounts** - Never use real Apple ID or Google account for testing
4. **iOS requires app submission** - IAP products must be submitted with app (even for sandbox testing)
5. **Restoration is mandatory** - Both platforms require a "Restore Purchases" button (already implemented)

## Testing Checklist

Before testing, you must:
- [ ] Configure all 3 products in App Store Connect
- [ ] Configure all 3 products in Google Play Console
- [ ] Create sandbox test accounts (iOS) or add license testers (Android)
- [ ] Build app to physical device
- [ ] Sign in with test account

## Documentation

This implementation includes 4 documentation files:

1. **iap_quick_start.md** (this file) - 5-minute overview
2. **iap_implementation_summary.md** - Complete technical checklist
3. **iap_testing_guide.md** - Detailed testing instructions for both platforms
4. **iap_testing_checklist.md** - Verification checklist for QA

## Next Steps

1. Read **iap_testing_guide.md** for detailed platform setup instructions
2. Configure products in both App Store Connect and Google Play Console
3. Set up test accounts
4. Follow **iap_testing_checklist.md** to verify everything works
5. Test on real iOS and Android devices
6. Submit to app stores!

## Support & Troubleshooting

If IAP isn't working:
1. Check console logs for error messages
2. Verify product IDs match exactly
3. Confirm you're using a test account (not personal account)
4. See **iap_testing_guide.md** Section 4: Troubleshooting

---

**Implementation Date:** January 2026
**Flutter Version:** 3.9.2
**in_app_purchase Plugin:** ^3.2.0
