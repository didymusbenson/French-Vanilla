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


