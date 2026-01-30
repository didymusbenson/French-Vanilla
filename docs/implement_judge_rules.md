# MTR/IPG Implementation Status

**Status**: ✅ COMPLETE (v2.0 - Enhanced)
**Last Updated**: 2026-01-29

---

## Current Implementation

### ✅ Completed Features

**Data & Parsing:**
- ✅ MTR: 10 sections + 6 appendices (A-F) = 87 rules total
- ✅ IPG: 4 sections + 2 appendices (A-B) = 28 infractions + 2 appendices
- ✅ pdfplumber-based parsing (clean, maintainable)
- ✅ Page number stripping
- ✅ PDF line break normalization
- ✅ Direct navigation to appendices (no intermediate lists)

**UI & Formatting:**
- ✅ Card-based UI matching Comprehensive Rules style
- ✅ FormattedContentMixin for all content (MTR rules, IPG sections)
- ✅ Example callouts with styled borders
- ✅ Proper typography (bodyMedium, 15px, 1.6 line height)
- ✅ Long-press context menus
- ✅ Bookmark icons in card headers

**Cross-Document Navigation:**
- ✅ MTR ↔ MTR: "section 2.2" links
- ✅ IPG → MTR: "MTR section 4.3" links
- ✅ MTR/IPG → CR: "rule 704" links
- ✅ RuleLinkMixin handles all cross-references

**Bookmarking:**
- ✅ Bookmark entire MTR rules (no subrule granularity)
- ✅ Bookmark entire IPG infractions (no subsection granularity)
- ✅ Integrated with existing bookmark system

---

## TODO: Refine the MTR/IPG Implementation

**Potential Future Enhancements:**
- [ ] Search integration (add MTR/IPG to global search)
- [ ] Deep linking support (`frenchvanilla://mtr/2.3`)
- [ ] MTR/IPG glossaries (if they exist in PDFs)
- [ ] Section icons (replace numbered circles)
- [ ] History tracking (recently viewed)
- [ ] Penalty calculator tool (IPG-specific)

**Nice-to-Have:**
- [ ] REL-specific filtering (Regular/Competitive/Professional)
- [ ] Side-by-side comparison view
- [ ] Offline update check notifications

---

## Architecture Summary

**Files:**
- Models: `lib/models/mtr_rule.dart`, `lib/models/ipg_infraction.dart`
- Service: `lib/services/judge_docs_service.dart`
- Screens: 7 screens (entry, sections lists, detail screens)
- Parsers: `scripts/parse_mtr.py`, `scripts/parse_ipg.py` (pdfplumber-based)
- Data: `assets/judgedocs/*.json` (22 files: 2 indexes + 20 sections/appendices)

**Mixins Used:**
- `RuleLinkMixin` - Cross-document navigation
- `FormattedContentMixin` - Styled content rendering

**Patterns:**
- Singleton service with caching
- Card-based UI consistent with CR
- Async/await for all data loading
- SharedPreferences for bookmarks

---

**Last Validation**: 2026-01-29
- Build: ✅ Successful
- Analyze: ✅ No errors
- Cross-references: ✅ Working
- Formatting: ✅ Consistent with CR
