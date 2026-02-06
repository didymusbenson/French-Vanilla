# IAP Platform Configuration & Testing

> **Implementation Status**: ✅ Code 100% complete. Platform configuration required.
>
> **For completed features and development history**, see `docs/development_log.md`

---
## Pre-Release Technical Debt

### Medium Priority
- [ ] Review bookmark snackbar aggregation UX (optional)
  - Implementation: `lib/mixins/aggregating_snackbar_mixin.dart`
  - Consider if rapid bookmark behavior needs refinement

---



## Tooling Improvements

### Data Update Commands
- [x] Create `getcards` wrapper script (matching `getjudgerules` pattern)
  - Should call `python3 scripts/process_cards.py`
  - Provides consistent interface with other data update commands
- [x] Create `getrules` wrapper script (matching `getjudgerules` pattern)
  - Should call `python3 scripts/update_rules.py "<url>"`
  - Provides consistent interface with other data update commands

**Current status:**
- ✅ `getjudgerules` - Complete with wrapper script + Claude command
- ✅ `getcards` - Complete with wrapper script + Claude command
- ✅ `getrules` - Complete with wrapper script + Claude command

---

**Last Updated**: 2026-02-05
