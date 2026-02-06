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

## Verification Steps for Wrapper Scripts

Quick tests to verify the new `getcards` and `getrules` wrapper scripts work correctly:

- [ ] Run `./getcards` from project root - should execute without errors
- [ ] Verify it calls `scripts/process_cards.py` and checks MTGJSON for updates
- [ ] Run `./getrules` without parameters - should show usage error message
- [ ] Run `./getrules "<url>"` with a valid rules URL - should execute update_rules.py
- [ ] Verify all three commands (`./getjudgerules`, `./getcards`, `./getrules`) follow the same pattern

---

**Last Updated**: 2026-02-05
