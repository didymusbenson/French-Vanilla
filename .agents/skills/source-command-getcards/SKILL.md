---
name: "source-command-getcards"
description: "Refresh MTGJSON card and ruling data, publish it into the Flutter app bundle, and rebuild the rulings OTA archive and manifest. Use for card-data or ruling refresh requests."
---

# source-command-getcards

Fetch, process, and publish the latest MTGJSON AtomicCards data.

**What this does:**
1. Checks MTGJSON API for the latest AtomicCards.json version
2. Compares to local version (if it exists)
3. Downloads and processes only if there's a new version
4. Extracts relevant card properties (already deduplicated by MTGJSON)
5. Filters out Alchemy cards (Arena-only cards starting with "A-")
6. Generates two staging files:
   - `all_cards_deduplicated.json` - All unique cards
   - `cards_with_rulings_deduplicated.json` - Cards with rulings only
7. Publishes all card data to `assets/carddata/all_cards.json`
8. Rebuilds `archives/rulings.zip` and `assets/content_manifest.json`

## Run

Run `python3 scripts/process_cards.py` from the repository root. The script will:
   - Check for existing data and version
   - Fetch metadata from MTGJSON API
   - Download compressed file (~25 MB) if needed
   - Decompress and process data
   - Extract card properties (no deduplication needed)
   - Save staging JSON files to `scripts/data/`
   - Publish the full dataset to the app bundle even when the download is already current
   - Rebuild the rulings OTA archive and manifest

**Notes:**
- All data files are in `scripts/data/` and are gitignored
- The AtomicCards.json source file is ~143 MB uncompressed
- AtomicCards is already deduplicated by card name (faster processing!)
- Only downloads if the remote version is newer than local
- Processing takes ~30 seconds after download

**Output files contain:**
- name, manaCost, type, text
- subtypes, keywords, legalities
- rulings (when present)

## Verify and release

Verify that the command succeeds, inspect `git status` and relevant diffs, and
run the project-required Flutter validation. Do not commit or push unless the
user explicitly requests it. When authorized, stage only
`assets/carddata/all_cards.json`, `assets/content_manifest.json`, and
`archives/rulings.zip`, plus workflow script or skill changes requested by the
user. Review staged files for secrets before committing.

The rulings archive is the largest OTA download. The manifest version changes
only when the packaged bytes change.
