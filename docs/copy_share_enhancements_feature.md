# Copy/Share Enhancements Feature

## Overview
Enhance the long-press context menu on subrule cards to allow copying/sharing specific lettered subrules (e.g., 101.1a) instead of only the entire subrule (101.1).

**Complexity Rating:** 3/10 (LOW)
**Estimated Implementation Time:** ~5-6 hours

## Current Implementation

### Current Behavior
- Long-press on any subrule card (e.g., 101.1) → shows context menu
- Context menu offers:
  - Add/Remove Bookmark
  - Copy Rule (copies entire 101.1 including all lettered parts)
  - Share Rule (shares entire 101.1 including all lettered parts)
- `GestureDetector` wraps entire subrule card in `rule_detail_screen.dart:252`
- Calls `_showContextMenu(group.number, group.content)` which passes full content

### Current Code Location
- **File:** `lib/screens/rule_detail_screen.dart`
- **Methods:**
  - `_showContextMenu(String ruleNumber, String content)` - line 104
  - `_copyRuleContent(String ruleNumber, String content)` - line 73
  - `_shareRuleContent(String ruleNumber, String content)` - line 88

## Proposed Changes

### New User Flow

#### Step 1: Initial Long-Press Menu (Simplified)
```
┌─────────────────────────┐
│ 📌 Add Bookmark         │
│ 📋 Copy...              │  ← Opens copy options sheet
│ 📤 Share...             │  ← Opens share options sheet
└─────────────────────────┘
```

#### Step 2a: Copy Options Sheet (Scrollable)
```
┌─────────────────────────┐
│ Copy Rule 704.5         │
├─────────────────────────┤
│ 📋 Copy entire rule     │  ← Recommended/default
│ ─────────────────────   │
│   Copy rule 704.5a      │  ↓
│   Copy rule 704.5b      │  Scrollable
│   Copy rule 704.5c      │  list
│   ...                   │  ↑
│   Copy rule 704.5x      │
└─────────────────────────┘
```

#### Step 2b: Share Options Sheet (Scrollable)
```
┌─────────────────────────┐
│ Share Rule 704.5        │
├─────────────────────────┤
│ 📤 Share entire rule    │  ← Recommended/default
│ ─────────────────────   │
│   Share rule 704.5a     │  ↓
│   Share rule 704.5b     │  Scrollable
│   Share rule 704.5c     │  list
│   ...                   │  ↑
│   Share rule 704.5x     │
└─────────────────────────┘
```

## Data Analysis

### Rules with Many Lettered Subrules
Analysis of comprehensive rules found **71 rules** with more than 5 lettered subrules:

| Rule Number | Lettered Subrules | Notes |
|-------------|-------------------|-------|
| 704.5 | 24 (a-x) | Worst case |
| 111.10 | 19 | Token types |
| 107.3 | 17 | |
| 800.4 | 15 | |
| 601.2 | 14 | Casting spells |
| 702.22 | 13 | Keyword ability |

**Conclusion:** Scrollable bottom sheet is essential, not optional.

## Implementation Details

### High-Level Architecture

```dart
// Step 1: Update initial context menu
_showContextMenu(String ruleNumber, String content) {
  showModalBottomSheet(
    // Bookmark option (unchanged)
    // Copy... → calls _showCopyOptions()
    // Share... → calls _showShareOptions()
  );
}

// Step 2: New copy options sheet
_showCopyOptions(String ruleNumber, String content) {
  final options = _parseSubruleOptions(content);
  showModalBottomSheet(
    // Scrollable list of copy options
    // Each option calls _copySpecificSubrule(number, text)
  );
}

// Step 3: New share options sheet
_showShareOptions(String ruleNumber, String content) {
  final options = _parseSubruleOptions(content);
  showModalBottomSheet(
    // Scrollable list of share options
    // Each option calls _shareSpecificSubrule(number, text)
  );
}

// Shared parsing logic
List<SubruleOption> _parseSubruleOptions(String content) {
  // Leverage existing FormattedContentMixin parsing
  // Return list of {ruleNumber, text} for each option
  // Include "entire rule" as first option
}
```

### Data Structure for Options

```dart
class SubruleOption {
  final String ruleNumber;  // e.g., "704.5a" or "704.5" for entire
  final String displayText; // e.g., "Copy rule 704.5a"
  final String content;     // The actual text to copy/share
  final bool isEntireRule;  // true for "entire rule" option
}
```

### Parsing Strategy

Leverage existing `FormattedContentMixin` infrastructure:

```dart
List<SubruleOption> _parseSubruleOptions(String content) {
  final options = <SubruleOption>[];

  // Add "entire rule" as first option
  options.add(SubruleOption(
    ruleNumber: group.number,
    displayText: 'Copy entire rule',
    content: content,
    isEntireRule: true,
  ));

  // Parse content into blocks (already done in FormattedContentMixin)
  // Match pattern: ^\d{3}\.\d+[a-z]\s
  final subsectionPattern = RegExp(r'^(\d{3}\.\d+)([a-z])\s');

  // For each lettered subrule found:
  //   - Extract rule number (e.g., "704.5a")
  //   - Extract text from that line until next lettered subrule or end
  //   - Include associated examples
  //   - Create SubruleOption

  return options;
}
```

### Text Extraction Logic

For a specific lettered subrule (e.g., 704.5b):
1. Find line matching `704.5b `
2. Capture all text until:
   - Next lettered subrule (704.5c), OR
   - Next first-level subrule (704.6), OR
   - End of content
3. Include any `Example:` blocks that appear in that range
4. Format as: `Rule 704.5b\n\n[extracted text]`

### Edge Cases to Handle

| Case | Solution |
|------|----------|
| Subrule with no lettered parts | Show only "Copy/Share entire rule" |
| Intro text before first lettered subrule | Could add "Copy rule 101.1 (intro)" as option, or skip for MVP |
| Examples between lettered subrules | Include with preceding lettered subrule |
| Multiple consecutive examples | All belong to preceding lettered subrule |
| Very long lettered subrule list (24 items) | Scrollable sheet handles this |

## UI/UX Specifications

### Bottom Sheet Styling
- Use existing `showModalBottomSheet` pattern from current implementation
- Set `isScrollControlled: true` for scrollable sheets
- Constrain height to 70-80% of screen for usability
- Use `SingleChildScrollView` for option lists

### Visual Hierarchy
- **First option** ("Copy/Share entire rule") should be visually distinct:
  - Slightly larger text or different color
  - Separator line below it
- Remaining options in scrollable list
- Icons: 📋 for copy actions, 📤 for share actions

### Interaction Patterns
- Tapping any option should:
  1. Close the options sheet
  2. Perform the action (copy or share)
  3. Show appropriate feedback (snackbar for copy, share dialog for share)
- User can dismiss sheet by tapping outside or swiping down

## Code Changes Required

### Files to Modify

1. **`lib/screens/rule_detail_screen.dart`**
   - Update `_showContextMenu()` - change "Copy Rule" → "Copy..." and "Share Rule" → "Share..."
   - Add `_showCopyOptions(String ruleNumber, String content)`
   - Add `_showShareOptions(String ruleNumber, String content)`
   - Add `_parseSubruleOptions(String content)` helper
   - Add `_copySpecificSubrule(String ruleNumber, String content)`
   - Add `_shareSpecificSubrule(String ruleNumber, String content)`

### New Helper Class (Optional)

Could extract to a separate utility if the parsing logic becomes complex:

```dart
// lib/utils/subrule_extractor.dart
class SubruleExtractor {
  static List<SubruleOption> extractOptions(String content, String baseRuleNumber);
  static String extractSubruleText(String content, String targetRuleNumber);
}
```

## Testing Checklist

### Manual Test Cases
- [ ] Rule with no lettered subrules (e.g., 100.1) → only shows "entire rule"
- [ ] Rule with 2-3 lettered subrules → shows all options
- [ ] Rule with 24 lettered subrules (704.5) → scrollable list works
- [ ] Copy entire rule → copies full content
- [ ] Copy specific subrule (704.5a) → copies only that subsection
- [ ] Copy subrule with example → example is included
- [ ] Share entire rule → share dialog appears with full content
- [ ] Share specific subrule → share dialog appears with subsection
- [ ] Tapping option closes sheet and performs action
- [ ] Dismissing sheet (swipe/tap outside) works correctly

### Edge Cases to Test
- [ ] First lettered subrule (includes intro text or not?)
- [ ] Last lettered subrule (handles end of content)
- [ ] Multiple consecutive examples
- [ ] Lettered subrule with no content (just points to another rule)

## Benefits

### User Experience
- ✅ More granular control over what to copy/share
- ✅ Reduces need to manually edit copied text
- ✅ Useful for judges/players referencing specific subsections
- ✅ Handles edge cases gracefully (even 24-item lists)

### Technical
- ✅ Leverages existing `FormattedContentMixin` parsing
- ✅ Consistent pattern between Copy and Share
- ✅ Extensible (could add "copy with/without examples" later)
- ✅ Low complexity, minimal risk

## Future Enhancements (Out of Scope for Initial Implementation)

1. **Intro text handling:** Add "Copy rule 101.1 (intro)" for content before first lettered subrule
2. **Copy formatting options:** Plain text vs. Markdown vs. HTML
3. **Bulk copy:** Select multiple lettered subrules to copy together
4. **Example-only copy:** Copy just the example text without the rule
5. **Copy with references:** Automatically include linked rules

## Implementation Estimate

### Task Breakdown
1. Update initial context menu UI (30 min)
2. Implement parsing logic for lettered subrules (2 hrs)
3. Build copy options sheet UI (1 hr)
4. Build share options sheet UI (30 min)
5. Text extraction for specific subrules (1.5 hrs)
6. Edge case handling (1 hr)
7. Testing and refinement (1 hr)

**Total: ~5-6 hours**

## Notes for Implementation

- Start with the simplest case: rules with clear lettered subrules
- Test with rule 704.5 (24 letters) early to ensure scrolling works
- Can defer intro text handling to v2 if needed
- Consider adding haptic feedback when copying (already exists for long-press)
- Maintain consistency with existing snackbar patterns for "copied" confirmation

---

**Status:** Design Complete, Ready for Implementation
**Priority:** Medium (nice-to-have enhancement, not critical)
**Dependencies:** None (uses existing infrastructure)
