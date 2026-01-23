# French Vanilla

A Flutter application for browsing and searching the Magic: The Gathering Comprehensive Rules.

## Features

**Rules Browser**
- Display official MTG Comprehensive Rules organized by section
- Navigate through rules and subrules with formatted content
- Highlight and scroll to specific subrules

**Search**
- Full-text search across all rules and glossary terms
- Search history with result counts
- Preview results in bottom sheets

**Glossary**
- Complete glossary of MTG terms and definitions
- Jump to glossary entries from anywhere in the app
- Highlight and scroll to specific terms

**Bookmarks**
- Save favorite rules and glossary terms
- Swipe to delete or bulk edit mode
- Quick access from bottom navigation

**In-App Purchases**
- Three supporter tiers (Thank You, Play, Collector)
- Unlockable heart badges
- Heart customization for Collector tier (25 Magic color combinations)

## Technical Details

- **Platform**: iOS and Android (Flutter)
- **Data Source**: Parsed from official WotC Comprehensive Rules
- **Storage**: Local JSON files + SharedPreferences for user data
- **IAP**: Non-consumable purchases via in_app_purchase package

## Data Updates

Rules data is stored in `docs/rulesdocs/` as JSON files. To update:

```bash
python3 scripts/parse_rules.py
```

This parses `docs/rulesdocs/comprehensive_rules.md` into structured JSON.

---

## Support the Project

If you find French Vanilla useful, consider supporting development on [Ko-fi](https://ko-fi.com/theonlydidymus). Your support helps keep the app ad-free and enables continued development of new features.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/theonlydidymus)
