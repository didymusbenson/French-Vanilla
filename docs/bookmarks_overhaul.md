# Bookmarks Overhaul - Feature Specification

**Status**: 🟡 Implementation Phase - Core design finalized, implementation in progress
**Complexity**: Medium (6/10) - Data model changes simplified, manual reordering deferred
**Created**: 2026-02-09
**Last Updated**: 2026-02-09

---

## User Stories & Prioritization

### MVP (Phase 1) - Lists Foundation
**Priority: P0 - Implementing Now**

### 2. Bookmark Lists/Groups ✅
**As an EDH player**, I want to group my rules into lists so that when I play a complicated deck I have the relevant rules all in one place.

### 3. Multi-List Membership ✅
**As a general user**, I want to be able to have the same rule bookmarked in multiple lists/groups so I don't have to go digging through screens to find the one I want.

### Future Phases - Deferred

### 1. Manual Bookmark Reordering 🔄
**As a general user**, I want the ability to re-order my bookmarks so that I can have instant access to the most important rules to me.
- **Status**: Deferred - Using automatic alphabetical ordering instead for MVP
- **Reason**: Simplifies implementation, consistent user experience across all views

### 4. Decklist Import 📋
**As an EDH player**, I want the ability to import an entire decklist to my bookmarks so that I don't have to manually search up individual card rulings.
- **Status**: Deferred to Phase 2

### 5. Keyword Import from Decklist 🔑
**As a new/learning player**, I want deck imports to optionally bookmark relevant keywords in addition to card rulings so that I don't have to look up those rules later.
- **Status**: Deferred to Phase 2

---

## Technical Architecture

### Current State
```dart
// FavoritesService stores flat lists per type
SharedPreferences keys:
- 'bookmarks_rule'
- 'bookmarks_glossary'
- 'bookmarks_mtr'
- 'bookmarks_ipg'
- 'bookmarks_card'

Data structure: List<Map<String, dynamic>>
[
  {
    "id": "rule_123",
    "summary": "Rule text...",
    "timestamp": "..."
  }
]
```

### New State (MVP)
```dart
// BookmarkedItem - existing model with new field
class BookmarkedItem {
  final String identifier;
  final String content;
  final BookmarkType type;
  final DateTime timestamp;
  final List<String> listIds; // NEW: IDs of lists this bookmark belongs to

  // Order field: timestamp.millisecondsSinceEpoch.toDouble()
  // Used for automatic ordering, not manual reordering
}

// BookmarkList - new model
class BookmarkList {
  final String id;           // Unique identifier (UUID)
  final String name;         // List name (user-provided)
  final String? description; // Optional short description
  final DateTime createdAt;  // Creation timestamp
}

// Storage structure:
// SharedPreferences keys:
// - 'bookmarked_items' -> List<BookmarkedItem> (existing, add listIds field)
// - 'bookmark_lists'   -> List<BookmarkList> (new)
```

### Ordering Strategy
**Automatic alphabetical ordering** (no manual reordering in MVP):
- **Primary sort**: Type priority
  1. CR Rules (BookmarkType.rule)
  2. CR Glossary (BookmarkType.glossary)
  3. Card Rulings (BookmarkType.card)
  4. MTR (BookmarkType.mtr)
  5. IPG (BookmarkType.ipg)
- **Secondary sort**: Alphabetical within type
  - Rules: Sort by rule number (100.1, 100.2, 100.2a, etc.)
  - Glossary/Cards: Sort alphabetically by name
  - MTR/IPG: Sort by section number
- **"All" view**: Always shows this automatic ordering
- **Individual list views**: Same automatic ordering (consistent UX)

---

## Design Decisions (Finalized)

### 1. Bookmark Reordering ✅
**Decision**: Deferred manual reordering - using automatic alphabetical ordering in MVP
- **Ordering logic**: Type priority (Rules → Glossary → Cards → MTR → IPG), then alphabetical within type
- **Storage**: Use timestamp-based order value (`timestamp.millisecondsSinceEpoch.toDouble()`)
- **Rationale**: Simplifies implementation, provides consistent predictable UX, can add manual reordering in future phase

### 2. Lists/Groups System ✅
**Q2.1 - Default/Ungrouped**: "All" view serves as the unsorted list
- Bookmarks can exist with zero list memberships (empty `listIds` array)
- Visible in "All" view, can be organized into lists later

**Q2.2 - Nesting**: Flat structure only (no nested lists)

**Q2.3 - List Metadata**:
- Required: `id` (String/UUID), `name` (String), `createdAt` (DateTime)
- Optional: `description` (String?, short description)
- List display order: Alphabetically by name, with "All" pinned at top

**Q2.4 - Navigation**: Bookmarks screen shows:
- "All" at top (special view, not a real list)
- Scrollable list of user's lists below
- Tap to enter a list and see its bookmarks

**Q2.5 - List Management**:
- **Create**: + icon in app bar on bookmarks home screen
- **Edit/Delete**: Multiple interaction methods:
  - Long-press menu on list
  - Swipe actions (delete with 3-option confirmation)
  - Menu in app bar when viewing list
  - Edit mode (batch operations)
- **Delete confirmation dialog**:
  - "Delete list and remove bookmarks" (removes bookmarks entirely)
  - "Delete list but keep bookmarks" (removes list membership, bookmarks stay in "All")
  - "Cancel"

**Q2.6 - Add to List Flow**:
- When bookmarking: Snackbar with CTA "Add to list" → bottom sheet with list picker
- In bookmark preview: "Edit lists" button → bottom sheet for managing list memberships

**Q2.7 - Migration**: Seamless, backwards-compatible
- Existing bookmarks get empty `listIds: []` array
- All existing bookmarks visible in "All" view
- No user prompt or data loss

### 3. Multi-List Membership ✅
**Q3.1 - Storage Structure**: Option A (store list IDs with each bookmark)
- `BookmarkedItem` has `listIds: List<String>` field
- Easy to display "which lists?" on bookmark card
- Query "bookmarks in list X" by filtering all bookmarks where `listIds.contains(listId)`
- Rationale: Current architecture loads all bookmarks into memory, so filtering is fast

**Q3.2 - Delete Behavior from List View**: Remove from list only
- When user deletes a bookmark while viewing a specific list, it removes bookmark from that list only
- Bookmark stays in other lists and remains visible in "All" view
- To delete entirely, user must delete from "All" view or from last remaining list

**Q3.3 - Add to Another List**: "Edit lists" button in bookmark preview bottom sheet
- Shows checkboxes for all available lists
- User can add/remove from multiple lists at once

**Q3.4 - Display List Membership**: Yes, in "All" view only
- Decorator/banner under bookmark card showing all list names it belongs to
- Only shown when bookmark belongs to 1+ lists (not shown if listIds is empty)

**Q3.5 - Multi-List Indicator in List View**: No indicator
- When viewing bookmarks inside a specific list, don't show multi-list decorator
- Cleaner UI, user already knows they're in a specific list context
- Decorator only appears in "All" view

### 4. Type-Specific vs Unified Lists ✅
**Decision**: Unified lists (any bookmark type in any list)
- Users can mix rules, glossary terms, card rulings, MTR, and IPG in same list
- Enables use cases like "Ur-Dragon deck" list with rules + card rulings + relevant glossary terms

---

## Deferred Features (Phase 2+)

### 4. Decklist Import (Story #4) - ALL DEFERRED

All questions Q4.1-Q4.9 deferred to Phase 2:
- Decklist format support
- Import UI/UX flow
- Error handling
- List creation from deck name
- Duplicate handling

### 5. Keyword Import (Story #5) - ALL DEFERRED

All questions Q5.1-Q5.7 deferred to Phase 2:
- Keyword extraction logic
- Import options UI
- Glossary vs rules linking

---

## Data Migration Strategy ✅

### Current Data Format
```dart
// Single SharedPreferences key: 'bookmarked_items'
// Stores: List<BookmarkedItem>
class BookmarkedItem {
  final String identifier;
  final String content;
  final BookmarkType type;
  final DateTime timestamp;
  // No listIds field yet
}
```

### New Data Format (Migration Target)
```dart
// Two SharedPreferences keys:
// 1. 'bookmarked_items' -> List<BookmarkedItem> (updated model)
// 2. 'bookmark_lists' -> List<BookmarkList> (new)

class BookmarkedItem {
  final String identifier;
  final String content;
  final BookmarkType type;
  final DateTime timestamp;
  final List<String> listIds; // NEW FIELD - defaults to []
}

class BookmarkList {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
}
```

### Migration Plan ✅
**QM.1 - Existing Bookmarks**: Leave ungrouped
- Add `listIds: []` field with empty array as default
- All existing bookmarks remain visible in "All" view
- No data loss, fully backwards-compatible

**QM.2 - Migration Timing**: Automatic and transparent
- Migration happens automatically when `FavoritesService.getBookmarks()` is called
- If bookmark JSON lacks `listIds` field, default to empty array during deserialization
- No user prompt needed (seamless upgrade)

**QM.3 - Failure Handling**: Not needed
- Migration is additive-only (no data deletion)
- Empty array is safe default for missing `listIds` field
- No complex transformation that could fail
- Worst case: Missing `listIds` field → defaults to `[]` → bookmark shows in "All" only

---

## Implementation Phases

### Phase 1: Lists Foundation (MVP) 🚧 IN PROGRESS
**Goal**: Implement bookmark lists with multi-list membership

#### Data Layer
- [ ] Add `listIds: List<String>` field to `BookmarkedItem` model with migration-safe default
- [ ] Create `BookmarkList` model (id, name, description, createdAt)
- [ ] Update `FavoritesService`:
  - [ ] List CRUD operations (create, read, update, delete list)
  - [ ] Update bookmark methods to handle `listIds`
  - [ ] Query methods: getBookmarksInList(listId), getAllLists()
- [ ] Implement automatic alphabetical ordering with type priority

#### UI Layer - Navigation
- [ ] Update bookmarks screen to show "All" + list of lists landing page
- [ ] Add + icon in app bar for creating new lists
- [ ] Implement list detail view (tap list → see bookmarks in that list)

#### UI Layer - List Management
- [ ] Create list creation/edit dialog (name + optional description)
- [ ] Implement list deletion with 3-option confirmation dialog
- [ ] Add multiple interaction methods:
  - [ ] Long-press menu on list
  - [ ] Swipe-to-delete on list
  - [ ] Menu in app bar when viewing list
  - [ ] Edit mode for batch operations

#### UI Layer - Multi-List Assignment
- [ ] Add snackbar CTA "Add to list" when bookmarking (tap → bottom sheet)
- [ ] Create list selection bottom sheet (checkboxes for all lists)
- [ ] Add "Edit lists" button in bookmark preview sheet
- [ ] Show list badges/decorators on bookmarks in "All" view only (not in specific list views)
- [ ] Implement "remove from list" behavior (deleting from list view removes from that list only)

### Phase 2: Advanced Features (Future)
**Deferred** - Not in current scope

#### Manual Reordering (Story #1)
- [ ] Implement drag-and-drop reordering with fractional indexing
- [ ] Add edit mode toggle for reordering
- [ ] Update UI to show drag handles

#### Decklist Import (Story #4)
- [ ] Design and implement decklist parser (plain text format initially)
- [ ] Create import UI flow (paste → preview → select list → confirm)
- [ ] Handle errors (cards not found, no rulings, etc.)
- [ ] Consider URL import (Moxfield, Archidekt)

#### Keyword Import (Story #5)
- [ ] Extract keywords from imported card list
- [ ] Present checkbox UI for keyword selection
- [ ] Link keywords to glossary entries

---

## Current Bookmark System Components

### Files to Modify:
- `lib/services/favorites_service.dart` - Core data model and persistence
- `lib/screens/bookmarks_screen.dart` - Main bookmarks UI
- `lib/mixins/aggregating_snackbar_mixin.dart` - Bookmark feedback
- All screens with bookmark buttons (rules, glossary, cards, MTR, IPG)

### Existing BookmarkType Enum:
```dart
enum BookmarkType {
  rule,
  glossary,
  mtr,
  ipg,
  card,
}
```

**Answer**: Unified lists ✅ (any bookmark type in any list)

---

## Next Steps

### Immediate (In Progress)
1. ✅ **Design finalized** - All architecture and UX decisions made (Q3.2, Q3.5 resolved)
2. 🚧 **Implementation started** - Working on Phase 1 (Lists Foundation)
3. 🎯 **Ready to implement** - All design questions answered, no blockers

### Before Release
1. Implement all Phase 1 checklist items
2. Test migration with existing user data
3. Validate automatic ordering works correctly for all bookmark types
4. Test multi-list membership edge cases
5. Ensure list deletion confirmation works as specified

### Future Considerations (Phase 2)
1. Manual reordering with drag-and-drop
2. Decklist import feature
3. Keyword extraction and import
4. List export/backup functionality
5. List sharing between devices (if cloud sync added)

---

**Last Updated**: 2026-02-09

## Summary

**MVP Scope**: Bookmark lists with multi-list membership and automatic alphabetical ordering

**Key Design Principles**:
- Simplicity first (alphabetical ordering, flat structure)
- Migration safety (backwards compatible, no data loss)
- Unified lists (mix any bookmark types)
- Multiple interaction methods (long-press, swipe, edit mode)
- "All" view as default unsorted collection

**Deferred**: Manual reordering, decklist import, keyword import
