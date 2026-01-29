# Implementation Plan: MTR/IPG (Judge Rules)

**Status**: Planning Phase
**Last Updated**: 2026-01-29

---

## Executive Summary

This document outlines the plan to implement Magic Tournament Rules (MTR) and Infraction Procedure Guide (IPG) into the French Vanilla app. These documents have different structures than the Comprehensive Rules and require a tailored approach while maintaining consistency with existing app patterns.

---

## Document Structure Analysis

### MTR (Magic Tournament Rules)
- **Sections**: 8 major sections (1-8)
- **Structure**: Section → Rule (e.g., "1. Tournament Fundamentals" → "1.1 Tournament Types")
- **Content Type**: Procedural, narrative text explaining tournament procedures
- **Depth**: 2 levels (Section.Rule), no lettered subrules
- **Effective Date**: November 10, 2025
- **File Size**: 149KB text, 55 pages

**Example Hierarchy:**
```
1. Tournament Fundamentals
  ├─ 1.1 Tournament Types
  ├─ 1.2 Publishing Tournament Information
  ├─ 1.3 Tournament Roles
  └─ ... (through 1.12)

2. Tournament Mechanics
  ├─ 2.1 Match Structure
  ├─ 2.2 Play/Draw Rule
  └─ ... (through 2.13)
```

### IPG (Infraction Procedure Guide)
- **Sections**: 4 major sections (1-4)
- **Structure**: Section → Infraction (e.g., "2. Game Play Errors" → "2.1 Game Play Error — Missed Trigger")
- **Content Type**: Structured with subsections: Definition, Examples, Philosophy, Additional Remedy, Upgrade
- **Depth**: 2 levels (Section.Infraction), but rich internal structure
- **Penalty Levels**: Each infraction has a penalty (No Penalty, Warning, Game Loss, Match Loss, Disqualification)
- **Effective Date**: September 23, 2024
- **File Size**: 83KB text, 31 pages

**Example Hierarchy:**
```
2. Game Play Errors
  ├─ 2.1 Game Play Error — Missed Trigger [No Penalty]
  │   ├─ Definition
  │   ├─ Examples
  │   ├─ Philosophy
  │   └─ Additional Remedy
  ├─ 2.2 Game Play Error — Looking at Extra Cards [Warning]
  │   ├─ Definition
  │   ├─ Examples
  │   └─ Philosophy
  └─ ... (through 2.6)
```

### Comprehensive Rules (For Comparison)
- **Sections**: 9 major sections
- **Structure**: Section → Rule → Subrule Group → Lettered Subrules (e.g., "100. General" → "100.1" → "100.1a, 100.1b")
- **Depth**: 3-4 levels deep

---

## Existing Architecture (What We're Building On)

### Navigation Pattern
```
Bottom Nav Bar (5 tabs)
├─ Rules (Comprehensive)
├─ Rulings (Card Rulings)
├─ MTR/IPG ← WE ARE HERE
├─ Bookmarks
└─ Credits
```

### Comprehensive Rules Flow (Reference)
```
SectionsScreen
  → SectionDetailScreen (shows all major rules in a section)
    → RuleDetailScreen (shows all subrule groups for that rule)
```

### Key Patterns to Reuse
- **Data Models**: `Rule`, `SubruleGroup`, `SectionData`
- **UI Components**: Card-based layout with headers + bookmark buttons
- **Mixins**: `RuleLinkMixin` (clickable rule references), `FormattedContentMixin` (example callouts)
- **Services**: `RulesDataService` pattern (singleton, caching, JSON loading)
- **Features**: Bookmarking, search, context menus (copy/share), deep linking

---

## Acceptance Criteria

### Must Have (MVP)
1. **MTR/IPG Tab Implementation**
   - Bottom nav MTR/IPG tab opens a sheet/screen with two options:
     - "Magic Tournament Rules (MTR)"
     - "Infraction Procedure Guide (IPG)"
   - Each option navigates to its respective document browser

2. **MTR Browser**
   - Display 8 sections with icons/titles
   - Tap section → view all rules in that section (e.g., 1.1, 1.2, ..., 1.12)
   - Tap rule → view full rule content with formatted text

3. **IPG Browser**
   - Display 4 sections with icons/titles
   - Tap section → view all infractions in that section (e.g., 2.1, 2.2, ..., 2.6)
   - Tap infraction → view structured content (Definition, Examples, Philosophy, etc.)
   - Display penalty level prominently (Warning, Game Loss, etc.)

4. **Data Parsing**
   - Python script to parse MTR.txt into structured JSON
   - Python script to parse IPG.txt into structured JSON
   - JSON files stored in `assets/judgedocs/`
   - Parsing identifies sections, rules/infractions, and content

5. **Cross-References**
   - Clickable links within MTR/IPG content
   - Links to Comprehensive Rules (e.g., "rule 103.4")
   - Links between MTR and IPG (e.g., "IPG 2.1", "MTR 4.3")

6. **Search Integration**
   - Add MTR/IPG content to global search
   - Search results show document badge (MTR vs IPG vs CR)
   - Preview bottom sheets work for MTR/IPG results

7. **Bookmarking**
   - Bookmark MTR rules (stored as `BookmarkType.mtr`)
   - Bookmark IPG infractions (stored as `BookmarkType.ipg`)
   - Bookmarks screen shows MTR/IPG bookmarks

### Should Have (Post-MVP)
- Glossaries for MTR/IPG (both have small glossaries at the end)
- Appendices (IPG has penalty quick reference appendix)
- Offline-first (all data embedded, no network calls)
- Export MTR/IPG excerpts (copy/share)
- History tracking (recently viewed MTR/IPG rules)

### Nice to Have (Future)
- Side-by-side comparison view (MTR vs IPG)
- Penalty calculator/lookup tool
- Quick reference cards for judges
- REL-specific filtering (Regular vs Competitive vs Professional)
- Infraction severity visualization

---

## Technical Implementation Plan

### Phase 1: Data Parsing & Storage
**Scripts to Create:**
1. `scripts/parse_mtr.py` - Parse MTR.txt into JSON
2. `scripts/parse_ipg.py` - Parse IPG.txt into JSON
3. Update `scripts/update_judge_docs.py` to auto-run parsing

**JSON Structure (Proposed):**

**MTR JSON** (`assets/judgedocs/mtr_index.json`, `assets/judgedocs/mtr_section_1.json`, etc.):
```json
{
  "title": "1. Tournament Fundamentals",
  "section_key": "mtr_section_1",
  "metadata": {
    "effective_date": "November 10, 2025",
    "section_number": 1
  },
  "rules": [
    {
      "number": "1.1",
      "title": "Tournament Types",
      "content": "Full text content here..."
    },
    {
      "number": "1.2",
      "title": "Publishing Tournament Information",
      "content": "Full text content here..."
    }
  ]
}
```

**IPG JSON** (`assets/judgedocs/ipg_index.json`, `assets/judgedocs/ipg_section_2.json`, etc.):
```json
{
  "title": "2. Game Play Errors",
  "section_key": "ipg_section_2",
  "metadata": {
    "effective_date": "September 23, 2024",
    "section_number": 2
  },
  "infractions": [
    {
      "number": "2.1",
      "title": "Game Play Error — Missed Trigger",
      "penalty": "No Penalty",
      "definition": "A triggered ability triggers, but...",
      "examples": ["A. Knight of Infamy...", "B. A player forgets..."],
      "philosophy": "Triggered abilities are common...",
      "additional_remedy": "If the triggered ability is...",
      "upgrade": "If the triggered ability is usually..."
    }
  ]
}
```

### Phase 2: Data Models
**New Models:**
```dart
// lib/models/mtr_rule.dart
class MtrRule {
  final String number;        // e.g., "1.1"
  final String title;         // e.g., "Tournament Types"
  final String content;       // Full text
}

class MtrSection {
  final int sectionNumber;    // e.g., 1
  final String title;         // e.g., "Tournament Fundamentals"
  final List<MtrRule> rules;
  final SectionMetadata metadata;
}

// lib/models/ipg_infraction.dart
class IpgInfraction {
  final String number;        // e.g., "2.1"
  final String title;         // e.g., "Game Play Error — Missed Trigger"
  final String penalty;       // e.g., "Warning"
  final String definition;
  final List<String> examples;
  final String philosophy;
  final String? additionalRemedy;
  final String? upgrade;
}

class IpgSection {
  final int sectionNumber;    // e.g., 2
  final String title;         // e.g., "Game Play Errors"
  final List<IpgInfraction> infractions;
  final SectionMetadata metadata;
}

// lib/models/bookmark.dart (extend existing)
enum BookmarkType {
  rule,
  glossary,
  mtr,      // NEW
  ipg,      // NEW
}
```

### Phase 3: Data Service
**New Service:**
```dart
// lib/services/judge_docs_service.dart
class JudgeDocsService {
  static final JudgeDocsService _instance = JudgeDocsService._internal();
  factory JudgeDocsService() => _instance;

  // Caches
  Map<int, MtrSection>? _mtrSections;
  Map<int, IpgSection>? _ipgSections;

  // Methods
  Future<List<MtrSection>> getMtrSections();
  Future<MtrSection> getMtrSection(int sectionNumber);
  Future<MtrRule?> getMtrRule(String ruleNumber);  // e.g., "1.1"

  Future<List<IpgSection>> getIpgSections();
  Future<IpgSection> getIpgSection(int sectionNumber);
  Future<IpgInfraction?> getIpgInfraction(String infractionNumber);  // e.g., "2.1"

  // Search across both MTR and IPG
  Future<List<SearchResult>> searchJudgeDocs(String query);
}
```

### Phase 4: UI Screens
**New Screens:**

1. **`lib/screens/mtr_ipg_screen.dart`** (replace placeholder)
   - Shows two large buttons/cards: "Magic Tournament Rules" and "Infraction Procedure Guide"
   - Each has icon, title, effective date
   - Tapping navigates to respective browser

2. **`lib/screens/mtr_sections_screen.dart`**
   - Lists 8 MTR sections
   - Similar to existing `SectionsScreen`

3. **`lib/screens/mtr_section_detail_screen.dart`**
   - Shows all rules in a section (e.g., 1.1, 1.2, ..., 1.12)
   - Similar to existing `SectionDetailScreen`

4. **`lib/screens/mtr_rule_detail_screen.dart`**
   - Shows full content of a single rule
   - Card-based layout with bookmark button
   - Formatted text with clickable rule links

5. **`lib/screens/ipg_sections_screen.dart`**
   - Lists 4 IPG sections
   - Similar to MTR sections screen

6. **`lib/screens/ipg_section_detail_screen.dart`**
   - Shows all infractions in a section
   - Each item shows penalty badge (color-coded)

7. **`lib/screens/ipg_infraction_detail_screen.dart`**
   - Shows structured content: Definition, Examples, Philosophy, etc.
   - Penalty displayed prominently at top (color-coded chip)
   - Expandable sections for each part
   - Formatted text with clickable rule links

### Phase 5: Enhancements
**Extend Existing Mixins:**

1. **`lib/mixins/rule_link_mixin.dart`**
   - Add pattern detection for "MTR X.X" (e.g., "MTR 2.3")
   - Add pattern detection for "IPG X.X" (e.g., "IPG 2.1")
   - Add cross-document navigation (MTR ↔ IPG ↔ CR)

2. **`lib/mixins/formatted_content_mixin.dart`**
   - Add support for IPG subsection headers (Definition, Examples, Philosophy)
   - Add support for penalty level formatting

**Search Integration:**
- Add MTR/IPG to `RulesDataService.search()` or create unified search
- Add document type badges to search results
- Update `SearchScreen` to handle MTR/IPG results

**Bookmark Integration:**
- Extend `BookmarkType` enum
- Update `BookmarksScreen` to show MTR/IPG bookmarks
- Update bookmark storage format

---

## Design Decisions Needed

Below are the key decisions that need to be made before implementation begins. Each has 1-2 recommended options based on the existing architecture.

### 🔴 CRITICAL DECISIONS

#### 1. MTR/IPG Tab Entry Point
**Question**: How should users access MTR vs IPG from the bottom nav tab?

**Option A (RECOMMENDED)**: Modal bottom sheet with two buttons
- Tap MTR/IPG tab → Bottom sheet slides up with two options
- Clean, mobile-first pattern
- Matches how you might do search or settings
- Less screen real estate used

**Option B**: Full screen with two large cards
- Tap MTR/IPG tab → Full screen with two large cards/buttons
- More visual weight, easier to add descriptions
- Similar to how sections are shown

**Option C**: Segmented control at top of screen
- Tap MTR/IPG tab → Screen with segmented control (MTR | IPG)
- Toggle between documents without going back
- More complex state management

**User Decision Needed**: Which option?

---

#### 2. JSON File Organization
**Question**: How should we organize the JSON files in assets?

**Option A (RECOMMENDED)**: Separate files per section
```
assets/judgedocs/
├─ mtr_index.json          (TOC + metadata)
├─ mtr_section_1.json      (Section 1 content)
├─ mtr_section_2.json      (Section 2 content)
├─ ... (through mtr_section_8.json)
├─ ipg_index.json          (TOC + metadata)
├─ ipg_section_1.json      (Section 1 content)
├─ ipg_section_2.json      (Section 2 content)
└─ ... (through ipg_section_4.json)
```
- **Pros**: Mirrors comprehensive rules pattern, lazy loading possible
- **Cons**: More files to manage

**Option B**: Single file per document
```
assets/judgedocs/
├─ mtr.json                (All MTR content)
└─ ipg.json                (All IPG content)
```
- **Pros**: Simpler file structure, both documents are small enough
- **Cons**: Must load entire document at once

**User Decision Needed**: Which option?

---

#### 3. IPG Penalty Display
**Question**: How should we visually represent penalty levels?

**Option A (RECOMMENDED)**: Color-coded chips
- Severity colors: No Penalty (gray), Warning (yellow), Game Loss (orange), Match Loss (red), DQ (dark red)
- Displayed as small chip/badge next to infraction title
- At top of detail screen as larger banner

**Option B**: Icon-based system
- Different icons for each penalty level (info, warning, error, etc.)
- Text label always shown alongside icon

**Option C**: Text only
- Just show penalty as bold text (e.g., "Warning")
- No special colors or icons

**User Decision Needed**: Which option?

---

#### 4. Cross-Document Link Format
**Question**: What patterns should we detect for MTR/IPG cross-references?

**Patterns to Detect:**
- `MTR 2.3` → Navigate to MTR rule 2.3
- `IPG 2.1` → Navigate to IPG infraction 2.1
- `rule 103.4` → Navigate to CR rule 103
- `CR 704` → Navigate to CR rule 704

**Option A (RECOMMENDED)**: Detect all, show document prefix on link
- All patterns detected automatically
- Links styled with subtle document badge (e.g., "MTR 2.3" gets small MTR icon)
- Tapping navigates to other document

**Option B**: Detect all, same link style as CR
- No visual distinction between MTR/IPG/CR links
- Just blue underlined text
- Navigation handles routing

**User Decision Needed**: Which option? Any other patterns to detect?

---

#### 5. IPG Content Structure Display
**Question**: How should we display the structured IPG content (Definition, Examples, Philosophy, etc.)?

**Option A (RECOMMENDED)**: Expandable sections
- Each subsection (Definition, Examples, Philosophy) is an expandable card
- Definition expanded by default, others collapsed
- User can expand/collapse each section

**Option B**: Single scrollable view with headers
- All content visible at once
- Headers style each section (Definition, Examples, Philosophy)
- Similar to current rule detail screen

**Option C**: Tabbed interface
- Tabs at top: Definition | Examples | Philosophy | Remedy
- Swipe between tabs
- More mobile app-like

**User Decision Needed**: Which option?

---

### 🟡 IMPORTANT DECISIONS

#### 6. MTR/IPG Glossaries
**Question**: MTR and IPG don't have large glossaries like CR. Should we include their small glossary sections?

**Context**: MTR has a small glossary, IPG has a small appendix

**Option A (RECOMMENDED)**: Skip for MVP, add later
- Focus on main content first
- Add glossaries in post-MVP phase

**Option B**: Include in MVP
- Parse glossaries into separate screens
- Add glossary button at top of MTR/IPG browsers

**User Decision Needed**: Include in MVP or defer?

---

#### 7. Search Document Filtering
**Question**: Should users be able to filter search results by document (CR only, MTR only, IPG only)?

**Option A**: No filtering (search all)
- Search returns results from all documents
- Document badge shows which document each result is from

**Option B (RECOMMENDED)**: Add filter chips
- Search bar has filter chips: CR | MTR | IPG | Glossary
- Toggle on/off to filter results
- Saves preference

**User Decision Needed**: Which option?

---

#### 8. Bookmark Organization
**Question**: How should bookmarks screen organize MTR/IPG bookmarks?

**Option A (RECOMMENDED)**: Sections with headers
- "Comprehensive Rules"
  - [CR bookmarks]
- "Magic Tournament Rules"
  - [MTR bookmarks]
- "Infraction Procedure Guide"
  - [IPG bookmarks]
- "Glossary"
  - [Glossary bookmarks]

**Option B**: Single flat list with document badges
- All bookmarks in one list
- Each has badge showing document type

**Option C**: Tabbed interface
- Tabs: CR | MTR | IPG | Glossary
- Filter bookmarks by tab

**User Decision Needed**: Which option?

---

#### 9. Deep Linking Support
**Question**: Should we support deep links to specific MTR/IPG rules?

**Context**: Currently supports deep links to CR rules (e.g., `frenchvanilla://rule/704`)

**Option A (RECOMMENDED)**: Yes, add MTR/IPG deep links
- `frenchvanilla://mtr/2.3` → MTR rule 2.3
- `frenchvanilla://ipg/2.1` → IPG infraction 2.1
- Useful for sharing specific rules

**Option B**: No, defer to later
- Focus on in-app navigation first
- Add deep linking in future release

**User Decision Needed**: Include in MVP?

---

### 🟢 MINOR DECISIONS

#### 10. Section Icons
**Question**: What icons should represent MTR/IPG sections?

**MTR Sections:**
1. Tournament Fundamentals → ?
2. Tournament Mechanics → ?
3. Tournament Rules → ?
4. Communication → ?
5. Tournament Violations → ?
6. Constructed Tournament Rules → ?
7. Limited Tournament Rules → ?
8. Team Tournament Rules → ?

**IPG Sections:**
1. General Philosophy → ?
2. Game Play Errors → ?
3. Tournament Errors → ?
4. Unsporting Conduct → ?

**User Decision Needed**: Suggested icons or just use generic document icons?

---

#### 11. Parser Script Integration
**Question**: Should parsing scripts be auto-run by `update_judge_docs.py`?

**Option A (RECOMMENDED)**: Yes, auto-run
- Update `update_judge_docs.py` to call parsing scripts after text extraction
- Fully automated update process

**Option B**: Manual separate step
- Keep parsing separate
- User runs parsing scripts manually after update

**User Decision Needed**: Auto-run or manual?

---

#### 12. Content Formatting Special Cases
**Question**: Are there special content formats we need to handle?

**Known Special Cases:**
- IPG appendix (penalty quick reference table) - skip for MVP?
- Bulleted lists in content
- Indented paragraphs in IPG philosophy sections
- Page break markers from PDF extraction

**User Decision Needed**: Any special formatting to preserve? Or strip to plain text with paragraphs?

---

## Implementation Checklist

### Data Parsing
- [ ] Create `scripts/parse_mtr.py`
- [ ] Create `scripts/parse_ipg.py`
- [ ] Test parsing on current MTR/IPG files
- [ ] Validate JSON output structure
- [ ] Update `scripts/update_judge_docs.py` to call parsers (if auto-run chosen)
- [ ] Add parsed JSON files to `assets/judgedocs/`
- [ ] Update `pubspec.yaml` assets section

### Data Models
- [ ] Create `lib/models/mtr_rule.dart`
- [ ] Create `lib/models/mtr_section.dart`
- [ ] Create `lib/models/ipg_infraction.dart`
- [ ] Create `lib/models/ipg_section.dart`
- [ ] Extend `BookmarkType` enum in `lib/models/bookmark.dart`
- [ ] Add JSON serialization methods

### Data Service
- [ ] Create `lib/services/judge_docs_service.dart`
- [ ] Implement MTR section loading
- [ ] Implement IPG section loading
- [ ] Implement search across MTR/IPG
- [ ] Add caching layer
- [ ] Write unit tests for service

### UI - Entry Point
- [ ] Implement new `MtrIpgScreen` (replace placeholder)
- [ ] Add navigation to MTR browser
- [ ] Add navigation to IPG browser
- [ ] Add effective date display

### UI - MTR Browser
- [ ] Create `MtrSectionsScreen` (8 sections list)
- [ ] Create `MtrSectionDetailScreen` (rules in section)
- [ ] Create `MtrRuleDetailScreen` (full rule content)
- [ ] Add bookmark buttons
- [ ] Add context menus (copy/share)

### UI - IPG Browser
- [ ] Create `IpgSectionsScreen` (4 sections list)
- [ ] Create `IpgSectionDetailScreen` (infractions in section)
- [ ] Create `IpgInfractionDetailScreen` (structured content)
- [ ] Add penalty level display
- [ ] Add bookmark buttons
- [ ] Add context menus (copy/share)

### Cross-References & Links
- [ ] Extend `RuleLinkMixin` for MTR patterns
- [ ] Extend `RuleLinkMixin` for IPG patterns
- [ ] Test cross-document navigation (MTR ↔ IPG ↔ CR)
- [ ] Add link preview on long-press

### Search Integration
- [ ] Add MTR content to search index
- [ ] Add IPG content to search index
- [ ] Add document badges to search results
- [ ] Update preview bottom sheets for MTR/IPG
- [ ] Add filter chips (if chosen)

### Bookmarks Integration
- [ ] Update bookmark storage for MTR/IPG
- [ ] Update `BookmarksScreen` to display MTR/IPG bookmarks
- [ ] Update bookmark snackbar messages
- [ ] Test bookmark persistence

### Testing & Validation
- [ ] Manual testing of all navigation paths
- [ ] Test all cross-references
- [ ] Test search with MTR/IPG content
- [ ] Test bookmarking across all document types
- [ ] Test on iOS simulator
- [ ] Test on Android emulator
- [ ] Test on physical devices
- [ ] Accessibility review (screen reader, font scaling)

### Build Validation
- [ ] Run `flutter analyze` - no errors
- [ ] Run `flutter build ios --simulator --debug --no-codesign`
- [ ] Run `flutter build apk --debug`
- [ ] Verify assets are properly bundled

---

## Open Questions & Unknowns

1. **Page break handling**: The extracted text has page markers (`====== PAGE X of Y ======`). Should we strip these or preserve for context?

2. **MTR Appendices**: MTR has appendices (Appendix A-F) with format-specific rules. Include these or focus on main sections?

3. **IPG Penalty Quick Reference**: IPG has an appendix with a penalty table. This would require special table formatting. Include in MVP?

4. **Glossary cross-references**: Both docs have small glossaries. If we include them, should glossary terms be linkable?

5. **Update frequency**: How often do these docs update? Should we add "check for updates" button?

6. **REL-specific content**: Some content applies to different Rules Enforcement Levels (Regular/Competitive/Professional). Should we filter by REL?

7. **Examples formatting**: IPG examples are lettered (A, B, C). Should these be formatted specially or just as paragraphs?

8. **Philosophy section styling**: IPG philosophy sections are descriptive. Should they be styled differently (italics, different background)?

9. **Additional Remedy formatting**: This section can be long and procedural. Keep as plain text or add special formatting?

10. **Line number preservation**: The parsed text has line numbers in `====` markers. Do we need these for debugging?

---

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| PDF text extraction loses formatting | High | Low | Manual review of parsed content, add special-case handling |
| Cross-references not detected correctly | High | Medium | Comprehensive regex testing, manual validation of sample links |
| MTR/IPG structure changes in future updates | Medium | Medium | Keep parsers flexible, add validation checks |
| Performance issues with search (3 documents) | Medium | Low | Efficient indexing, lazy loading, consider debouncing |
| Bookmark conflicts between document types | Low | Low | Clear `BookmarkType` separation in data model |
| Users confused by multiple document types | Medium | Medium | Clear labeling, consistent navigation patterns |

---

## Success Metrics

**MVP Success Criteria:**
- [ ] User can browse all MTR sections and rules
- [ ] User can browse all IPG sections and infractions
- [ ] Cross-references between MTR/IPG/CR work correctly
- [ ] Search finds MTR/IPG content
- [ ] Bookmarks work for MTR/IPG
- [ ] No crashes or major bugs
- [ ] Build succeeds on iOS and Android

**Post-MVP Goals:**
- User engagement with MTR/IPG (analytics)
- Search usage for judge docs vs CR
- Most bookmarked MTR/IPG rules
- User feedback on usefulness

---

## Dependencies

**Existing Code:**
- `lib/models/rule.dart` - Reference for model structure
- `lib/services/rules_data_service.dart` - Reference for service pattern
- `lib/mixins/rule_link_mixin.dart` - Extend for cross-references
- `lib/mixins/formatted_content_mixin.dart` - Extend for IPG formatting
- `lib/screens/section_detail_screen.dart` - Reference for UI patterns

**External:**
- MTR and IPG text files (already fetched by `update_judge_docs.py`)
- Flutter packages (existing, no new dependencies expected)

**Scripts:**
- `scripts/update_judge_docs.py` - Fetches latest docs
- `scripts/parse_mtr.py` - TO BE CREATED
- `scripts/parse_ipg.py` - TO BE CREATED

---

## Timeline Estimate

**Assumptions**: Solo developer, working part-time

| Phase | Tasks | Estimated Time |
|-------|-------|----------------|
| Data Parsing | Write parsing scripts, test output | 4-6 hours |
| Data Models | Create models, serialization | 2-3 hours |
| Data Service | Service layer, caching | 3-4 hours |
| UI - MTR Browser | 3 screens, navigation | 4-6 hours |
| UI - IPG Browser | 3 screens, navigation | 4-6 hours |
| Entry Point | MTR/IPG tab screen | 1-2 hours |
| Cross-References | Extend link mixin | 2-3 hours |
| Search Integration | Add to search, badges | 2-3 hours |
| Bookmarks | Extend bookmark system | 2-3 hours |
| Testing & Polish | Manual testing, fixes | 4-6 hours |
| **Total** | | **28-42 hours** |

**MVP Delivery**: 1-2 weeks (part-time) or 3-5 days (full-time)

---

## Notes

- Both MTR and IPG are significantly smaller than Comprehensive Rules (~150KB and ~80KB vs ~900KB for CR)
- Structure is simpler (2 levels vs 3-4 levels for CR)
- IPG has more structured content that needs special formatting
- Both documents cross-reference each other and CR frequently
- Judges will likely use this feature heavily, so reliability is key

---

## Next Steps

1. **User reviews this document** and answers all design decision questions
2. **Create a finalized decision log** with chosen options
3. **Write parsing scripts** and validate JSON output
4. **Prototype one complete flow** (e.g., MTR browser) to validate architecture
5. **Implement remaining features** following checklist
6. **Test thoroughly** before declaring complete

---

**Decision Log (To Be Filled By User)**

| Decision # | Question | Chosen Option | Notes |
|------------|----------|---------------|-------|
| 1 | MTR/IPG entry point | | |
| 2 | JSON file organization | | |
| 3 | IPG penalty display | | |
| 4 | Cross-document links | | |
| 5 | IPG content structure | | |
| 6 | MTR/IPG glossaries | | |
| 7 | Search filtering | | |
| 8 | Bookmark organization | | |
| 9 | Deep linking | | |
| 10 | Section icons | | |
| 11 | Parser auto-run | | |
| 12 | Content formatting | | |

---

**Last Updated**: 2026-01-29
**Author**: Claude Code
**Status**: Awaiting user input on design decisions
