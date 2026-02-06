#!/usr/bin/env python3
"""
Smart update script for MTGJSON card data.

This script:
1. Checks MTGJSON API for the latest AtomicCards.json version
2. Compares it to the existing local version
3. Only downloads if there's a new version available
4. Extracts relevant card properties (already deduplicated by MTGJSON)
5. Generates two output files ready for app use
"""

import json
import subprocess
import sys
from pathlib import Path


def get_local_version(version_file_path):
    """Get the version/date of locally stored AllPrintings data."""
    if not version_file_path.exists():
        return None

    try:
        with open(version_file_path, 'r') as f:
            data = json.load(f)
            return data.get('version')
    except (json.JSONDecodeError, IOError):
        return None


def fetch_mtgjson_metadata():
    """Fetch metadata from MTGJSON API to check latest version."""
    print("Checking MTGJSON API for latest version...")

    result = subprocess.run(
        ['curl', '-s', 'https://mtgjson.com/api/v5/Meta.json'],
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        print(f"Error fetching metadata: {result.stderr}")
        return None

    try:
        meta = json.loads(result.stdout)
        return meta.get('data', {}).get('date')
    except json.JSONDecodeError:
        print("Could not parse metadata JSON")
        return None


def download_and_decompress(data_dir):
    """Download the compressed AtomicCards file and decompress it."""
    compressed_file = data_dir / 'AtomicCards.json.xz'
    output_file = data_dir / 'AtomicCards.json'

    print("\nDownloading AtomicCards.json.xz (~25 MB)...")
    print("This will take a moment...")

    result = subprocess.run(
        ['curl', '-o', str(compressed_file), 'https://mtgjson.com/api/v5/AtomicCards.json.xz'],
        capture_output=False
    )

    if result.returncode != 0:
        print("Download failed!")
        return False

    print("\n✓ Download complete")
    print("Decompressing...")

    result = subprocess.run(
        ['unxz', str(compressed_file)],
        capture_output=True
    )

    if result.returncode != 0:
        print(f"Decompression failed: {result.stderr}")
        return False

    if not output_file.exists():
        print("Decompressed file not found!")
        return False

    print(f"✓ Decompressed to {output_file.name}")
    return True


def extract_card_subset(card):
    """
    Extract only the specified properties from a card object.

    Properties extracted:
    - name, manaCost, type, text
    - subtypes, keywords, legalities
    - rulings (when present)
    """
    subset = {
        'name': card.get('name'),
        'manaCost': card.get('manaCost'),
        'type': card.get('type'),
        'text': card.get('text'),
        'subtypes': card.get('subtypes', []),
        'keywords': card.get('keywords', []),
        'legalities': card.get('legalities', {}),
    }

    # Include rulings if present
    rulings = card.get('rulings')
    if rulings:
        subset['rulings'] = rulings

    return subset


def process_atomiccards(json_file_path):
    """
    Process AtomicCards.json and extract card data.

    AtomicCards is already deduplicated by MTGJSON, so we just need to
    extract the properties we care about and filter Alchemy cards.

    Returns:
        Tuple of (all_cards, cards_with_rulings)
    """
    print(f"\nLoading {json_file_path.name}...")
    print("This may take a moment...")

    with open(json_file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"File loaded. Found {len(data.get('data', {})):,} unique cards.")

    all_cards = []
    skipped_alchemy = 0

    # AtomicCards structure: {"data": {"CardName": [cardObj], ...}}
    cards_dict = data.get('data', {})

    for card_name, card_variations in cards_dict.items():
        # Skip Alchemy cards (Arena-only, names start with "A-")
        if card_name.startswith('A-'):
            skipped_alchemy += 1
            continue

        # Take the first variation (usually only one in AtomicCards)
        card = card_variations[0] if card_variations else None
        if not card:
            continue

        # Extract the subset of properties
        card_subset = extract_card_subset(card)
        all_cards.append(card_subset)

        # Progress indicator
        if len(all_cards) % 5000 == 0:
            print(f"  Processed {len(all_cards):,} cards...")

    print(f"\n✓ Extraction complete! Processed {len(all_cards):,} unique cards")
    if skipped_alchemy > 0:
        print(f"  Skipped {skipped_alchemy:,} Alchemy cards")

    # Sort by name for easier browsing
    all_cards.sort(key=lambda c: c['name'])

    # Split into all cards and cards with rulings
    cards_with_rulings = [card for card in all_cards if 'rulings' in card and card['rulings']]

    print(f"✓ Found {len(cards_with_rulings):,} cards with rulings")

    return all_cards, cards_with_rulings


def save_json_file(data, output_path, description):
    """Save data to JSON file with pretty formatting."""
    print(f"\nSaving {description}...")

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    # Get file size
    size_mb = output_path.stat().st_size / (1024 * 1024)
    print(f"✓ Saved: {output_path.name}")
    print(f"  File size: {size_mb:.1f} MB")
    print(f"  Card count: {len(data):,}")


def save_version_info(version_file_path, version):
    """Save version information for future checks."""
    with open(version_file_path, 'w') as f:
        json.dump({'version': version}, f, indent=2)


def main():
    """Main entry point."""
    script_dir = Path(__file__).parent
    data_dir = script_dir / 'data'

    # Ensure data directory exists
    data_dir.mkdir(exist_ok=True)

    version_file = data_dir / 'version.json'
    atomiccards_file = data_dir / 'AtomicCards.json'

    print("=" * 80)
    print("MTGJSON Card Data Update Script (AtomicCards)")
    print("=" * 80)
    print()

    # Step 1: Check local version
    local_version = get_local_version(version_file)
    if local_version:
        print(f"Local version: {local_version}")
    else:
        print("No local data found")

    # Step 2: Check remote version
    remote_version = fetch_mtgjson_metadata()
    if not remote_version:
        print("Could not fetch remote version. Check network connection.")
        return 1

    print(f"Remote version: {remote_version}")
    print()

    # Step 3: Compare versions
    if local_version and local_version == remote_version and atomiccards_file.exists():
        print("✓ Card data is already up to date!")
        print(f"  Both versions are from {local_version}")
        print("  No download needed.")
        return 0

    # Step 4: Download and decompress if needed
    if local_version:
        print(f"→ Update available: {local_version} → {remote_version}")
    else:
        print(f"→ Downloading initial version: {remote_version}")
    print()

    if not download_and_decompress(data_dir):
        return 1

    # Step 5: Process the file
    all_cards, cards_with_rulings = process_atomiccards(atomiccards_file)

    # Step 6: Save output files
    all_cards_output = data_dir / 'all_cards_deduplicated.json'
    rulings_output = data_dir / 'cards_with_rulings_deduplicated.json'

    save_json_file(all_cards, all_cards_output, "all deduplicated cards")
    save_json_file(cards_with_rulings, rulings_output, "cards with rulings")

    # Step 7: Save version info
    save_version_info(version_file, remote_version)

    print("\n" + "=" * 80)
    print("✓ Update complete!")
    print(f"  Data updated from {local_version or 'none'} to {remote_version}")
    print(f"  Total unique cards: {len(all_cards):,}")
    print(f"  Cards with rulings: {len(cards_with_rulings):,}")
    print("=" * 80)

    return 0


if __name__ == '__main__':
    exit(main())
