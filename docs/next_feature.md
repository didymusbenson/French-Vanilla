# Next Feature: Development Log

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


