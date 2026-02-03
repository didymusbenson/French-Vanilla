# Current Development: MTR/IPG PDF Parsing Improvements

> **Status**: 🚧 In Progress - Investigating parsing edge cases
>
> **Last Updated**: 2026-02-02

---

## What We're Working On

Improving how MTR (Magic Tournament Rules) and IPG (Infraction Procedure Guide) content is parsed from PDF source material to fix formatting issues.

### Issues Being Addressed

1. **Mid-sentence line breaks** - PDF layout artifacts causing text to break mid-sentence
2. **List formatting** - Bulleted and numbered lists need proper indentation and hanging indent
3. **List-to-paragraph transitions** - Text following lists gets incorrectly joined to list items
4. **Paragraph spacing** - Adding visual separation between paragraphs in rendered content

### What's Been Completed ✅

1. **Page number filtering** - Header/footer regions filtered out before text extraction (50px top/bottom margins)
2. **Smart line joining** - Intelligently joins mid-sentence breaks while preserving paragraph boundaries
3. **List detection** - Identifies bullets (`•`, `-`, `*`, `◦`, `▪`) and numbered lists (`1.`, `2.`, etc.)
4. **UI formatting improvements**:
   - Paragraph dividers (dash separators like Comprehensive Rules)
   - List item indentation (10px left padding)
   - Hanging indent for lists (bullet in 24px column, text wraps properly)

### Current Problem 🔍

**List-to-paragraph transitions**: When content has:
```
• List item one
• List item two that ends with a period.
Regular paragraph text that follows the list...
more text on the next line...
```

The parser correctly:
- Separates the list from the paragraph ✅
- Formats list items with indentation ✅

But fails to:
- Join the prose lines AFTER the list ❌

**Example (MTR 3.4 Proxy Cards)**:
```
• The card is a foil card for which no non-foil printing exists.
Players may not create their own proxies; they may only be created by the H...
to whether the creation of a proxy is appropriate. When a judge creates a p...
```

Should be:
```
• The card is a foil card for which no non-foil printing exists.
Players may not create their own proxies; they may only be created by the Head Judge who has sole discretion as to whether the creation of a proxy is appropriate. When a judge creates a proxy...
```

### Technical Details

**Files involved**:
- `scripts/parse_mtr.py` - MTR parser with `clean_rule_content()` function
- `scripts/parse_ipg.py` - IPG parser with `clean_infraction_content()` function
- `lib/mixins/formatted_content_mixin.dart` - UI rendering with `buildFormattedContent()`

**Current parsing logic** (`clean_rule_content()` around line 125-180):
1. Detects if content has list items
2. If yes, processes line-by-line:
   - List items (start with bullet/number): Keep as-is
   - Non-list lines after complete list item (ends with `.`): Separate as new paragraph
   - Non-list lines mid-list-item: Join to current list item
3. If no lists, applies intelligent line joining based on punctuation/capitalization

**The gap**: Step 2 correctly separates prose from lists but doesn't apply intelligent joining to those separated prose lines.

### Possible Solutions

**Option A**: After list processing, detect consecutive non-list lines and apply intelligent joining to them
- Pros: Comprehensive fix
- Cons: More complex, risk of regression

**Option B**: Two-pass approach - separate lists/prose first, then join prose separately
- Pros: Cleaner separation of concerns
- Cons: Performance impact (minimal)

**Option C**: Accept current state, rely on UI wrapping
- Pros: No code changes
- Cons: Sub-optimal display

### Next Steps When Resuming

1. Review MTR 3.4 and other rules with lists followed by prose
2. Implement two-pass approach or refactor list handling
3. Test edge cases:
   - Lists at start/middle/end of content
   - Mixed bullets and numbered lists
   - Multi-paragraph content with multiple lists
4. Regenerate JSON files and verify in app
5. Check IPG for similar patterns

### Test Cases to Verify

- **MTR 3.1** (Tiebreakers) - Numbered list + prose
- **MTR 3.2** (Format Categories) - Simple bullet list
- **MTR 3.4** (Proxy Cards) - Bullets + long prose paragraph
- **IPG 2.1** (Missed Trigger) - Complex definition with inline lists

---

# IAP Platform Configuration & Testing

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
