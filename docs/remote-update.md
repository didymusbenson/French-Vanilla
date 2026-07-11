# Over-the-Air Content Updates

French Vanilla ships all of its reference data bundled in the app, but can also
pull **newer data between app releases**. Users open **Credits → Content Updates
→ Check for Updates**, see which data sets have changed, pick what to download,
and get a progress bar while it installs.

This document describes the architecture, the file layout, and the publish
workflow. It is the reference for maintaining or extending the feature.

> Modeled on the "tripling season" token-database update feature in the
> `doubling-season` repo, generalized here to cover four content categories.

---

## Content categories

The system treats each data set as one user-facing **category**, even when it is
backed by many files. Detection and versioning are per-category (not per-file),
which is why the UI can show a short, clean list.

| Category  | Label (in app)            | Backing files                       | Asset dir            | Loaded by          |
|-----------|---------------------------|-------------------------------------|----------------------|--------------------|
| `rules`   | Comprehensive Rules       | `index`, `section_1..9`, `glossary`, `credits` (12 JSON) | `assets/rulesdocs`  | `RulesDataService` |
| `mtr`     | Tournament Rules (MTR)    | `mtr_*.json` (17 files)             | `assets/judgedocs`   | `JudgeDocsService` |
| `ipg`     | Penalty Guide (IPG)       | `ipg_*.json` (7 files)              | `assets/judgedocs`   | `JudgeDocsService` |
| `rulings` | Card Rulings              | `all_cards.json` (~40 MB)           | `assets/carddata`    | `CardDataService`  |

MTR and IPG share the `judgedocs` asset directory but are separate categories
with independent versions and separate override directories; their distinct
filename prefixes (`mtr_` / `ipg_`) prevent collisions.

---

## How it works

### Versioning

A single manifest, `assets/content_manifest.json`, describes every category:

```json
{
  "generated": "2026-06-13",
  "categories": {
    "rules": {
      "label": "Comprehensive Rules",
      "version": 1,
      "archive": "rules.zip",
      "sha256": "c9c00d8e…",
      "size": 249510,
      "updated": "April 17, 2026",
      "files": ["credits.json", "glossary.json", "index.json", "section_1.json", …]
    },
    "mtr":     { … },
    "ipg":     { … },
    "rulings": { … }
  }
}
```

- `version` is a **monotonically increasing integer**, bumped only when the
  packaged bytes of a category actually change (see *Deterministic archives*).
- `updated` is a human-readable effective date, pulled from the data's own
  metadata (`metadata.effective_date` in `credits.json` / `mtr_index.json` /
  `ipg_index.json`); `rulings` has no source date, so it uses the build date.
- The same file is **both** bundled in the app (the shipped snapshot) **and**
  served remotely. The resolver reads the bundled copy for the "what version do
  I have built in" baseline; the update service fetches the remote copy to see
  what's published.

An update is available for a category when
`remote.version > activeVersion`, where the **active version** is the higher of
the bundled version and any valid downloaded override.

### Loading precedence (`ContentResolver`)

Every data service loads JSON through `ContentResolver.instance.loadString(category, fileName)`:

1. If a **valid override** exists for the category (a downloaded copy whose
   version is strictly greater than the bundled version) → read from
   `<app-documents>/content/<category>/<fileName>`.
2. Otherwise → read the bundled `rootBundle` asset.

The resolver is **self-healing**: if an override's marker is missing, corrupt,
or its version is ≤ bundled (i.e. a later app build caught up), the override
directory is deleted and the bundled asset is used. Resolution is memoized per
category for the app session; `invalidate(category)` clears the memo after a
download or revert.

### Download → verify → install (`ContentUpdateService`)

`downloadCategory(cat, onProgress, cancelToken)`:

1. **Download** the category's archive with `dio.download(...)`, reporting
   `[0.0, 1.0]` progress via `onReceiveProgress`. (dio was chosen over plain
   `http` specifically for first-class progress + cancellation — important for
   the ~7 MB rulings download.)
2. **Verify** the downloaded bytes' SHA256 against the manifest. Mismatch →
   throw, install aborted.
3. **Stage** — unzip into `<...>/content/<category>__staging`, writing the
   `.manifest.json` marker **last** so a present marker guarantees a complete
   file set.
4. **Swap** — delete the live override dir and `rename` staging into place
   (atomic-ish), then invalidate the resolver memo.

A failure or user-cancel at any step leaves the previous override (or bundled
data) untouched — there is never a half-applied update.

After a successful install the screen drops the relevant in-memory cache
(`RulesDataService.reset()` / `JudgeDocsService.clearCache()` /
`CardDataService.reset()`) and calls `DataPreloader().reload()`, so changes
apply as the user browses — no app restart required.

### UI flow (`ContentUpdatesScreen`)

`Credits → Content Updates → "Check for Updates"` opens the screen, which:

1. Auto-runs `checkForUpdates()` and lists every category with its status
   (Up to date ✓ / update available + download size).
2. Pre-selects available updates with checkboxes (user can deselect, e.g. to
   skip the 40 MB rulings on cellular).
3. On **Download**, shows a confirmation dialog with the **total size**, then a
   progress bar per category (`Downloading <label> (n of m)` + percent) with a
   **Cancel** button.
4. Offers **Reset to built-in** per category whenever an override is installed.

---

## File layout

```
assets/
  content_manifest.json        # OTA manifest — BUNDLED (in pubspec) and PUBLISHED
  rulesdocs/   *.json           # bundled rules data
  judgedocs/   mtr_*.json ipg_*.json
  carddata/    all_cards.json
archives/                       # OTA download archives — PUBLISHED, NOT bundled
  rules.zip  mtr.zip  ipg.zip  rulings.zip
lib/services/
  content_resolver.dart         # load-time precedence (override vs bundled)
  content_update_service.dart   # check / download / verify / install / revert
lib/screens/
  content_updates_screen.dart   # the UI
scripts/
  build_content_manifest.py     # packages archives + writes the manifest
```

The `archives/` directory lives at the repo root and is **deliberately not in
the `pubspec.yaml` assets list** — the zips are publish-only and downloaded on
demand, so they do not bloat the app binary. They are committed to git so
`raw.githubusercontent.com` can serve them.

### On-device override layout

```
<app-documents>/content/<category>/
  <data files…>
  .manifest.json    # { version, sha256, size, updated } — written last
```

---

## Remote source

Published from the `master` branch of the public repo and served via GitHub raw
(no separate CDN — every push is the live snapshot):

```
https://raw.githubusercontent.com/didymusbenson/French-Vanilla/master/assets/content_manifest.json
https://raw.githubusercontent.com/didymusbenson/French-Vanilla/master/archives/<category>.zip
```

Defined in `RemoteContent` in `lib/services/content_update_service.dart`. To
change branch/repo, edit `_rawBase` there.

---

## Publishing an update

### Deterministic archives (why versions don't churn)

`build_content_manifest.py` builds each zip with **sorted entries and a fixed
timestamp**, so identical data always produces an identical archive → identical
SHA256 → **no version bump**. Versions only increase when the data genuinely
changes, so users are never prompted to re-download unchanged content.

### Per-category workflow

**Comprehensive Rules** — fully automatic. `scripts/parse_rules.py` (invoked by
the `/getRules` skill via `update_rules.py`) re-parses, syncs to
`assets/rulesdocs/`, then calls `build_content_manifest.py rules`. Then:

```
git add assets/rulesdocs assets/content_manifest.json archives/rules.zip
git commit -m "Update comprehensive rules to <date>"
git push
```

**MTR / IPG** — after refreshing `assets/judgedocs/*.json` (via
`scripts/parse_mtr.py` / `parse_ipg.py`), rebuild manually:

```
python3 scripts/build_content_manifest.py mtr
python3 scripts/build_content_manifest.py ipg
git add assets/judgedocs assets/content_manifest.json archives/mtr.zip archives/ipg.zip
git commit -m "Update MTR/IPG to <date>" && git push
```

**Card Rulings** — after refreshing `assets/carddata/all_cards.json`:

```
python3 scripts/build_content_manifest.py rulings
git add assets/carddata/all_cards.json assets/content_manifest.json archives/rulings.zip
git commit -m "Update card rulings to <date>" && git push
```

`build_content_manifest.py all` rebuilds every category at once.

The relevant `/getRules`, `/getJudgeRules`, and `/getCards` skill command files
document these steps inline as well.

---

## Dependencies

Added to `pubspec.yaml` for this feature:

| Package         | Purpose                                  |
|-----------------|------------------------------------------|
| `dio`           | HTTP download with progress + cancel     |
| `crypto`        | SHA256 integrity verification            |
| `path_provider` | App documents / temp directories         |
| `archive`       | Unzip category archives on device        |

---

## Design decisions

- **dio over streamed `http`** — first-class `onReceiveProgress` + cancellation,
  which the 40 MB-source rulings download needs. The extra dependency is
  marginal (it can replace `http` outright).
- **One archive per category** — a single download = one smooth progress bar and
  one integrity check per category, and makes each multi-file category's update
  atomic. The alternative (per-file downloads) gives chunky progress and
  partial-update risk.
- **Category-level versioning** — the user asked for file-level change detection
  presented as a short category list; per-category versions deliver exactly that
  with far less complexity (true per-file diffing saves almost nothing, since
  rulings is one file and rules is ~1 MB total).
- **Archives at repo root, not under `assets/`** — keeps publish-only artifacts
  out of the shipped app binary while still git-tracked for raw-serving.

---

## Notes & gotchas

- **The feature goes live only after the first publish.** Until
  `assets/content_manifest.json` + `archives/` are pushed to `master`, in-app
  "Check for Updates" will report a network error (manifest 404s).
- After the initial push, bundled and remote are both v1, so everything reads
  "up to date." The next data update + push makes that one category — and only
  that one — show as updatable for existing installs.
- The on-device override is automatically discarded when a **newer app build**
  ships bundled data at an equal-or-higher version (self-healing in the
  resolver), so OTA updates never "stick" past a real app update.

---

_Last updated: 2026-06-13_
