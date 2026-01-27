# French Vanilla Development Log

This document tracks completed features and historical development decisions.

---

## Recent Work (2026-01-26)

### Pre-Release Cleanup - COMPLETE ✅

Removed all debug print statements from production code in preparation for release builds.

**Files Modified:**
- `lib/screens/rule_detail_screen.dart` - Removed 14 debug print statements from `initState()` and `_scrollToSubrule()`

### Enhanced Rule Link Parsing - COMPLETE ✅

Fixed rule link parsing to capture **all** rule references, not just those with "rule" prefix.

**Problem:** References like "(see 601.2b and 601.2f–h)" in rule 702.140a were not clickable because they lacked the word "rule".

**Solution:** Enhanced pattern matching in `lib/mixins/rule_link_mixin.dart` to recognize:
1. ✅ Traditional format: "rule 704", "rule 702.9a", "rules 702.9"
2. ✅ Bare references: "601.2b" (now clickable!)
3. ✅ Range references: "601.2f–h" or "601.2f-h" (links to first rule: 601.2f)

**Analysis:** Verified no false positives across all 3,803 rule patterns in sections 1-9 using `scripts/analyze_false_positives.py`.

**Files Modified:**
- `lib/mixins/rule_link_mixin.dart` - Enhanced regex pattern to match bare 3-digit.digit patterns

**Files Created:**
- `scripts/analyze_false_positives.py` - Analyzed all sections for false positive patterns
- `scripts/test_rule_pattern.dart` - Test suite for pattern matching verification

### Glossary UI Restructure - COMPLETE ✅

Reorganized the app navigation and integrated the glossary into the Rules section.

**Changes:**
1. ✅ Updated bottom navigation from 4 to 5 tabs:
   - **Before**: Rules | Glossary | Bookmarks | Credits
   - **After**: Rules | Rulings | MTR/IPG | Bookmarks | Credits
2. ✅ Added placeholder screens for future features (Rulings, MTR/IPG)
3. ✅ Moved Glossary into Rules section as the last item (after "9. Casual Variants")
4. ✅ **Glossary now displays like a rule section** - terms shown as cards with headers (like subrules)
5. ✅ Glossary terms display with:
   - Term name as card header (like subrule numbers)
   - Definition as card content
   - Bookmark icon in header
   - Long-press context menu (bookmark, copy, share)
   - Clickable rule references in definitions

**Files Modified:**
- `lib/screens/home_screen.dart` - Updated navigation structure
- `lib/screens/sections_screen.dart` - Added Glossary to sections list, navigate to GlossaryDetailScreen
- `lib/screens/glossary_screen.dart` - Kept for legacy/bookmark support (no longer in main navigation)
- `lib/mixins/preview_bottom_sheet_mixin.dart` - Updated to use GlossaryDetailScreen

**Files Created:**
- `lib/screens/rulings_screen.dart` - Placeholder for future Rulings feature
- `lib/screens/mtr_ipg_screen.dart` - Placeholder for future MTR/IPG feature
- `lib/screens/glossary_detail_screen.dart` - New glossary view matching rule detail style

### In-App Purchase System - CODE COMPLETE ✅

**Status**: Code implementation 100% complete. Platform configuration and testing pending.

Implemented a complete 3-tier supporter system with heart badges and customization:

**Core Features:**
- ✅ `IAPService` singleton service managing all purchase operations
- ✅ Three tiers: Thank You ($1.99), Play ($5.49), Collector ($26.99)
- ✅ Heart badge system on Credits screen (red, blue, rainbow)
- ✅ Purchase menu bottom sheet with restore functionality
- ✅ Heart customization screen (26 Magic color combinations for Collector tier)
- ✅ Persistent state management (SharedPreferences + platform receipts)
- ✅ Feature gating system (higher tiers include lower tier benefits)

**Files Created:**
- `lib/services/iap_service.dart` - Core IAP service (368 lines)
- `lib/models/heart_style.dart` - 26 heart style definitions
- `lib/widgets/heart_icon.dart` - Reusable heart rendering widget
- `lib/widgets/purchase_menu.dart` - Purchase menu UI
- `lib/screens/heart_customization_screen.dart` - Customization interface
- `lib/constants/magic_colors.dart` - Magic color constants

**Files Modified:**
- `lib/main.dart` - IAP service initialization
- `lib/screens/credits_screen.dart` - Heart badges integrated
- `pubspec.yaml` - Added `in_app_purchase: ^3.2.0`

**Documentation:**
- `docs/iap_quick_start.md` - 5-minute overview
- `docs/iap_implementation_summary.md` - Complete technical checklist
- `docs/iap_testing_guide.md` - Platform setup instructions
- `docs/iap_testing_checklist.md` - QA verification checklist

**Remaining Work:**
- Platform configuration (App Store Connect & Google Play Console)
- Device testing with sandbox accounts
- App store submission

**Implementation Details**: See `docs/next_feature.md` for complete specification.

### Rules Update System - COMPLETE ✅

Created smart update scripts for MTG comprehensive rules:

- ✅ `scripts/update_rules.py` - Smart update with version checking
- ✅ `scripts/parse_rules.py` - Enhanced with date comparison
- ✅ `docs/getRules.md` - Complete update documentation

**Features:**
- Fetches only file header (2KB) to check effective date before downloading
- Compares to existing version in `credits.json`
- Only downloads and parses if new version available
- Automatic line ending conversion
- Generates 12 JSON files (index, 9 sections, glossary, credits)

---

## Recent Work (2026-01-13)

### Bookmarks Feature - COMPLETED ✅
- ✅ Created `FavoritesService` with SharedPreferences persistence
- ✅ Created `BookmarksScreen` with edit mode, swipe-to-delete, batch operations
- ✅ Added bookmark icons to all rule subrule cards and glossary term cards
- ✅ Integrated bookmarks tab into home navigation (index 2)
- ✅ Implemented preview bottom sheets for bookmarked rules and glossary terms
- ✅ Added navigation from bookmarks to full rule/glossary views with highlighting

### UI/UX Improvements - COMPLETED ✅
- ✅ Redesigned cards with header layout (subrule number on left, bookmark icon on right)
- ✅ Removed redundant subrule numbers from card content body
- ✅ Implemented clickable inline rule references (e.g., "rule 702.9a" → navigate to rule)
- ✅ Added long-press context menus (bookmark/copy/share) to rules and glossary
- ✅ Fixed scroll positioning for rule navigation (alignment: 0.01)
- ✅ Added glossary term highlighting and scroll-to on navigation
- ✅ Fixed share functionality with iPad popover positioning

---

## Search Functionality Refinements (2026-01-11) - COMPLETED ✅

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

## Initial App Development - COMPLETED ✅

### Project Overview
**French Vanilla** is a Magic: The Gathering rules reference application targeting iOS and Android. The app serves as a quick-lookup wiki for players to search and browse the MTG comprehensive rules.

### Completed Core Features
1. ✅ **Browse Rules**: Section-based navigation of all comprehensive rules
2. ✅ **Search Functionality**: Full-text search with recent searches history
3. ✅ **Rule Detail View**: Detailed view with clickable cross-references
4. ✅ **Glossary**: Complete glossary with search and navigation
5. ✅ **Bookmarks**: Persistent favorites system across rules and glossary
6. ✅ **Offline Access**: All data embedded in app
7. ✅ **Clean UI**: Simple, readable interface with Dark mode support

### Project Configuration
- **iOS**: `LooseTie.Frenchvanilla`
- **Android**: `com.loosetie.frenchvanilla`
- **Package**: `frenchvanilla`

### Technical Stack
- **Platform**: Flutter (iOS & Android)
- **State Management**: Provider
- **Data Storage**: Local JSON files (comprehensive rules parsed into 12 JSON chunks)
- **Search**: Custom full-text search with highlighting
- **Persistence**: SharedPreferences for bookmarks and search history

---

## Rules Data Management

### Rules Parsing System - COMPLETED ✅
- ✅ Created `scripts/parse_rules.py` to parse comprehensive rules into 12 JSON files
- ✅ Splits rules into: Index, 9 sections, Glossary, Credits
- ✅ Automatic effective date detection and comparison (2026-01-26)
- ✅ Created `scripts/update_rules.py` for smart updates (checks version before downloading)
- ✅ Documentation in `docs/getRules.md`

### Update Process
- Script fetches only header (2KB) to check effective date
- Compares to existing version
- Only downloads full file if new version available
- Automatically handles line ending conversion
- Runs parser to regenerate JSON files

---

## Technical Debt & Future Considerations

### High Priority
1. **Remove Debug Logging**: Production build should remove debug print statements
   - Locations: `rule_detail_screen.dart` (`_scrollToSubrule`, `initState`, `_buildSubruleContent`)
   - Before release build

### Medium Priority
2. **Profile Widget Building**: Could optimize `_buildSubruleContent()` method
   - Potential caching of parsed text for large rules
   - May improve Rule 702/701 load times

3. **Bookmark Snackbar Aggregation** - Currently works but may need UX refinement:
   - Implementation: `lib/mixins/aggregating_snackbar_mixin.dart`
   - Shows count (e.g., "Bookmark added (3)") when triggered rapidly
   - Consider alternative visual feedback (toast, inline icon animation)
   - Test user behavior - do rapid bookmarks happen in practice?
   - Counter resets after 2 seconds; different messages reset separately
   - Alternative: Debounce and show final state only

### Low Priority
4. **Consider Virtualization Alternative**: For massive rules (702, 701)
   - Could explore `flutter_sticky_header` or custom slivers
   - Trade-off: More complex but better performance for large rules

5. **Adjust Performance Threshold**: Monitor real-world usage
   - Current: 50 subrule groups triggers loading indicator
   - May need adjustment based on user feedback

6. **Loading Animation Enhancement**:
   - Could make loading indicator more sophisticated
   - Progress bar or animated content placeholder

---

## App Store Metadata

### Current Version
- Version: (check pubspec.yaml)
- Build: (check pubspec.yaml)

### Description
(Add final App Store/Play Store description here when ready)

### Screenshots Needed
- iPhone screenshots (6.7", 6.5", 5.5")
- iPad screenshots (12.9", 12.9" 2nd gen)
- Android screenshots (phone + tablet)

---

## Known Issues

*No known critical issues as of 2026-01-26*

### Minor Issues
- Large rules (702, 701, 712) have 1-2 second load time
  - Acceptable trade-off for reliable scroll-to-subrule behavior
  - Loading indicator provides user feedback

---

## Next Steps

See `docs/next_feature.md` for upcoming features (In-App Purchase system).
