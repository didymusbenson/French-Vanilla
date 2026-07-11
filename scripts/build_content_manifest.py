#!/usr/bin/env python3
"""
Build the over-the-air content manifest + per-category archives.

French Vanilla ships its reference data (Comprehensive Rules, MTR, IPG, card
rulings) bundled in the app, but can also pull newer data between app releases.
This script packages each content category's bundled JSON into a single
deterministic .zip and writes `assets/content_manifest.json` describing every
category's current version, hash, size, and effective date.

Publishing flow (per category, after its data is refreshed in assets/):
    python3 scripts/build_content_manifest.py [rules|mtr|ipg|rulings|all]
    git add assets/content_manifest.json archives/
    git commit && git push        # live immediately via raw.githubusercontent.com

The in-app ContentUpdateService fetches the manifest, compares each category's
`version` against the locally-active version, and downloads only the archives
the user opts into. `version` is a monotonically increasing integer that is
bumped ONLY when a category's packaged bytes actually change (the archive is
built deterministically so unchanged data produces an identical hash and no
spurious version bump).

Run from the repo root.
"""

import hashlib
import io
import json
import os
import sys
import zipfile
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

REPO_ROOT = Path(__file__).resolve().parent.parent
MANIFEST_PATH = REPO_ROOT / "assets" / "content_manifest.json"
ARCHIVES_DIR = REPO_ROOT / "archives"

# Fixed timestamp for every zip entry so identical content => identical bytes
# => identical sha256. This is what keeps `version` from bumping on no-op runs.
FIXED_ZIP_DATETIME = (1980, 1, 1, 0, 0, 0)


def _rules_file(name: str) -> bool:
    return name.endswith(".json")


def _mtr_file(name: str) -> bool:
    return name.startswith("mtr_") and name.endswith(".json")


def _ipg_file(name: str) -> bool:
    return name.startswith("ipg_") and name.endswith(".json")


def _rulings_file(name: str) -> bool:
    return name == "all_cards.json"


# Each category: where its bundled files live, which files belong to it, the
# archive filename published under archives/, and where to read its human
# "effective date" (None => use today's build date).
CATEGORIES: Dict[str, dict] = {
    "rules": {
        "label": "Comprehensive Rules",
        "src": REPO_ROOT / "assets" / "rulesdocs",
        "match": _rules_file,
        "archive": "rules.zip",
        "date_file": REPO_ROOT / "assets" / "rulesdocs" / "credits.json",
    },
    "mtr": {
        "label": "Tournament Rules (MTR)",
        "src": REPO_ROOT / "assets" / "judgedocs",
        "match": _mtr_file,
        "archive": "mtr.zip",
        "date_file": REPO_ROOT / "assets" / "judgedocs" / "mtr_index.json",
    },
    "ipg": {
        "label": "Penalty Guide (IPG)",
        "src": REPO_ROOT / "assets" / "judgedocs",
        "match": _ipg_file,
        "archive": "ipg.zip",
        "date_file": REPO_ROOT / "assets" / "judgedocs" / "ipg_index.json",
    },
    "rulings": {
        "label": "Card Rulings",
        "src": REPO_ROOT / "assets" / "carddata",
        "match": _rulings_file,
        "archive": "rulings.zip",
        "date_file": None,
    },
}


def read_effective_date(date_file: Optional[Path]) -> str:
    """Pull `metadata.effective_date` from a category's index/credits file.

    Falls back to today's build date (used by `rulings`, which has no source
    effective date)."""
    if date_file and date_file.exists():
        try:
            with open(date_file, "r", encoding="utf-8") as f:
                data = json.load(f)
            date = data.get("metadata", {}).get("effective_date")
            if date:
                return date
        except (json.JSONDecodeError, IOError):
            pass
    return datetime.now().strftime("%B %d, %Y")


def collect_files(src: Path, match) -> List[Path]:
    if not src.exists():
        return []
    return sorted(p for p in src.iterdir() if p.is_file() and match(p.name))


def build_archive(files: List[Path]) -> bytes:
    """Build a deterministic zip of [files] (sorted, fixed timestamps) and
    return its raw bytes. Entry names are basenames so the in-app extractor
    writes them flat into the override directory."""
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for path in files:
            with open(path, "rb") as f:
                data = f.read()
            info = zipfile.ZipInfo(path.name, date_time=FIXED_ZIP_DATETIME)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            zf.writestr(info, data)
    return buf.getvalue()


def load_existing_manifest() -> dict:
    if MANIFEST_PATH.exists():
        try:
            with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            pass
    return {"categories": {}}


def build_category(key: str, prior: dict) -> Optional[dict]:
    cfg = CATEGORIES[key]
    files = collect_files(cfg["src"], cfg["match"])
    if not files:
        print(f"  [{key}] no source files found in {cfg['src']} — skipping")
        return None

    archive_bytes = build_archive(files)
    sha = hashlib.sha256(archive_bytes).hexdigest()
    size = len(archive_bytes)
    updated = read_effective_date(cfg["date_file"])

    prior_entry = prior.get("categories", {}).get(key, {})
    prior_sha = prior_entry.get("sha256")
    prior_version = int(prior_entry.get("version", 0))

    if prior_sha == sha and prior_version > 0:
        version = prior_version  # content unchanged — keep version
        changed = False
    else:
        version = prior_version + 1
        changed = True

    ARCHIVES_DIR.mkdir(parents=True, exist_ok=True)
    archive_path = ARCHIVES_DIR / cfg["archive"]
    with open(archive_path, "wb") as f:
        f.write(archive_bytes)

    entry = {
        "label": cfg["label"],
        "version": version,
        "archive": cfg["archive"],
        "sha256": sha,
        "size": size,
        "updated": updated,
        "files": [p.name for p in files],
    }

    flag = "BUMPED -> v{}".format(version) if changed else "unchanged (v{})".format(version)
    print(
        f"  [{key}] {len(files)} files, {size / 1024:.1f} KB zip, "
        f"updated {updated} — {flag}"
    )
    return entry


def main() -> int:
    target = sys.argv[1] if len(sys.argv) > 1 else "all"
    if target != "all" and target not in CATEGORIES:
        print(f"Unknown category '{target}'. Choices: {', '.join(CATEGORIES)}, all")
        return 1

    keys = list(CATEGORIES) if target == "all" else [target]

    print("Building content manifest + archives")
    print("=" * 60)

    prior = load_existing_manifest()
    manifest = {
        "generated": datetime.now().strftime("%Y-%m-%d"),
        "categories": dict(prior.get("categories", {})),
    }

    for key in keys:
        entry = build_category(key, prior)
        if entry is not None:
            manifest["categories"][key] = entry

    # Keep categories in a stable display order.
    ordered = {
        k: manifest["categories"][k]
        for k in CATEGORIES
        if k in manifest["categories"]
    }
    manifest["categories"] = ordered

    MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print("=" * 60)
    print(f"Wrote {MANIFEST_PATH.relative_to(REPO_ROOT)}")
    print(f"Archives in {ARCHIVES_DIR.relative_to(REPO_ROOT)}/")
    print("\nNext: git add assets/content_manifest.json archives/ && commit & push")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
