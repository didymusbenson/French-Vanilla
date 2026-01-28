#!/usr/bin/env python3
"""
Smart update script for MTGJSON card data.

This script:
1. Checks MTGJSON API for the latest AllPrintings.json version
2. Compares it to the existing local version
3. Only downloads if there's a new version available
4. Extracts relevant card properties and deduplicates by name
5. Generates two output files ready for app use
"""

import json
import subprocess
import sys
from pathlib import Path
from collections import defaultdict


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
    """Download the compressed AllPrintings file and decompress it."""
    compressed_file = data_dir / 'AllPrintings.json.xz'
    output_file = data_dir / 'AllPrintings.json'

    print("\nDownloading AllPrintings.json.xz (~71 MB)...")
    print("This will take a moment...")

    result = subprocess.run(
        ['curl', '-o', str(compressed_file), 'https://mtgjson.com/api/v5/AllPrintings.json.xz'],
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


def deduplicate_cards(cards):
    """
    Deduplicate cards by name, merging rulings from all printings.

    Args:
        cards: List of card objects

    Returns:
        List of deduplicated card objects
    """
    # Group cards by name
    cards_by_name = defaultdict(list)
    for card in cards:
        cards_by_name[card['name']].append(card)

    deduplicated = []

    for name, printings in cards_by_name.items():
        # Take the first printing as the base
        base_card = printings[0].copy()

        # Merge all rulings from all printings
        all_rulings = []
        for printing in printings:
            if 'rulings' in printing and printing['rulings']:
                all_rulings.extend(printing['rulings'])

        # Deduplicate rulings by (date, text) tuple
        if all_rulings:
            unique_rulings = []
            seen_rulings = set()

            for ruling in all_rulings:
                ruling_key = (ruling.get('date'), ruling.get('text'))
                if ruling_key not in seen_rulings:
                    seen_rulings.add(ruling_key)
                    unique_rulings.append(ruling)

            # Sort rulings by date
            unique_rulings.sort(key=lambda r: r.get('date', ''))

            base_card['rulings'] = unique_rulings
        elif 'rulings' in base_card:
            # No rulings found, remove the key
            del base_card['rulings']

        deduplicated.append(base_card)

    return deduplicated


def process_allprintings(json_file_path):
    """
    Process AllPrintings.json and extract deduplicated card data.

    Returns:
        Tuple of (all_cards, cards_with_rulings)
    """
    print(f"\nLoading {json_file_path.name}...")
    print("This may take a minute...")

    with open(json_file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"File loaded. Found {len(data.get('data', {}))} sets.")

    all_cards = []
    total_processed = 0

    all_sets = data.get('data', {})

    for set_code, set_data in all_sets.items():
        cards = set_data.get('cards', [])

        for card in cards:
            total_processed += 1

            # Skip Alchemy cards (Arena-only, names start with "A-")
            card_name = card.get('name', '')
            if card_name.startswith('A-'):
                continue

            # Extract the subset of properties
            card_subset = extract_card_subset(card)
            all_cards.append(card_subset)

            # Progress indicator
            if total_processed % 10000 == 0:
                print(f"  Processed {total_processed:,} cards...")

    print(f"\n✓ Extraction complete! Processed {len(all_cards):,} card printings")

    # Deduplicate
    print("\nDeduplicating cards by name...")
    deduplicated_cards = deduplicate_cards(all_cards)

    # Sort by name for easier browsing
    deduplicated_cards.sort(key=lambda c: c['name'])

    print(f"✓ Deduplicated to {len(deduplicated_cards):,} unique cards")

    # Split into all cards and cards with rulings
    cards_with_rulings = [card for card in deduplicated_cards if 'rulings' in card and card['rulings']]

    print(f"✓ Found {len(cards_with_rulings):,} cards with rulings")

    return deduplicated_cards, cards_with_rulings


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
    allprintings_file = data_dir / 'AllPrintings.json'

    print("=" * 80)
    print("MTGJSON Card Data Update Script")
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
    if local_version and local_version == remote_version and allprintings_file.exists():
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
    all_cards, cards_with_rulings = process_allprintings(allprintings_file)

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
