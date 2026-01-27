#!/usr/bin/env python3
"""
Smart update script for Magic: The Gathering Comprehensive Rules.

This script:
1. Fetches only the header of the rules file to check the effective date
2. Compares it to the existing rules version
3. Only downloads the full file if there's a new version
4. Runs the parser to generate JSON files
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path


def get_existing_effective_date(credits_path: str) -> str:
    """Get the effective date from existing credits.json."""
    if not os.path.exists(credits_path):
        return None

    try:
        with open(credits_path, 'r', encoding='utf-8') as f:
            credits_data = json.load(f)
            return credits_data.get('metadata', {}).get('effective_date')
    except (json.JSONDecodeError, IOError):
        return None


def extract_effective_date_from_text(text: str) -> str:
    """Extract effective date from the header text."""
    # Look for pattern like "effective as of January 16, 2026."
    match = re.search(r'effective as of (.+?)\.', text)
    if match:
        return match.group(1)
    return None


def fetch_header(url: str, bytes_to_fetch: int = 2000) -> str:
    """Fetch just the first N bytes of the file using curl."""
    print(f"Fetching header from {url}...")

    # Use curl with range header to fetch only first 2000 bytes
    result = subprocess.run(
        ['curl', '-s', '-r', f'0-{bytes_to_fetch}', url],
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        print(f"Error fetching header: {result.stderr}")
        return None

    return result.stdout


def download_full_file(url: str, output_path: str) -> bool:
    """Download the full rules file."""
    print(f"Downloading full file to {output_path}...")

    result = subprocess.run(
        ['curl', '-o', output_path, url],
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        print(f"Error downloading file: {result.stderr}")
        return False

    print(f"✓ Downloaded to {output_path}")
    return True


def fix_line_endings(file_path: str) -> bool:
    """Convert CR/CRLF to LF line endings."""
    print("Converting line endings to Unix format (LF)...")

    # Read with binary mode to handle any line ending
    with open(file_path, 'rb') as f:
        content = f.read()

    # Replace CRLF and CR with LF
    content = content.replace(b'\r\n', b'\n')
    content = content.replace(b'\r', b'\n')

    # Write back
    with open(file_path, 'wb') as f:
        f.write(content)

    # Verify line count
    with open(file_path, 'r', encoding='utf-8') as f:
        line_count = len(f.readlines())

    print(f"✓ Line endings converted. Total lines: {line_count}")

    if line_count < 100:
        print(f"WARNING: Only {line_count} lines found. Expected ~9,200-9,300.")
        print("Line ending conversion may have failed.")
        return False

    return True


def run_parser(parser_path: str) -> bool:
    """Run the parse_rules.py script."""
    print("\nRunning parser...")

    result = subprocess.run(
        ['python3', parser_path],
        capture_output=False  # Show parser output directly
    )

    return result.returncode == 0


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: python3 update_rules.py <rules_url>")
        print()
        print("Example:")
        print('  python3 update_rules.py "https://media.wizards.com/2026/downloads/MagicCompRules%2020260116.txt"')
        return 1

    url = sys.argv[1]

    # Determine paths
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    rules_dir = project_root / 'docs' / 'rulesdocs'
    credits_path = rules_dir / 'credits.json'
    rules_file_path = rules_dir / 'comprehensive_rules.md'
    parser_path = script_dir / 'parse_rules.py'

    print("=" * 60)
    print("MTG Comprehensive Rules Update Script")
    print("=" * 60)
    print()

    # Step 1: Check existing version
    existing_date = get_existing_effective_date(str(credits_path))
    if existing_date:
        print(f"Current version: {existing_date}")
    else:
        print("No existing rules found")
    print()

    # Step 2: Fetch header to check new version
    header_text = fetch_header(url)
    if not header_text:
        print("Failed to fetch header. Check URL and network connection.")
        return 1

    new_date = extract_effective_date_from_text(header_text)
    if not new_date:
        print("Could not extract effective date from header.")
        print("Header preview:")
        print(header_text[:500])
        return 1

    print(f"Available version: {new_date}")
    print()

    # Step 3: Compare dates
    if existing_date and existing_date == new_date:
        print("✓ Rules are already up to date!")
        print(f"  Both versions are effective as of {existing_date}")
        print("  No download needed.")
        return 0

    # Step 4: Download full file
    if existing_date:
        print(f"→ Update available: {existing_date} → {new_date}")
    else:
        print(f"→ Downloading initial version: {new_date}")
    print()

    # Download to .txt first
    temp_txt_path = rules_dir / 'comprehensive_rules.txt'
    if not download_full_file(url, str(temp_txt_path)):
        return 1

    # Step 5: Rename and fix line endings
    print(f"Renaming to {rules_file_path.name}...")
    temp_txt_path.rename(rules_file_path)

    if not fix_line_endings(str(rules_file_path)):
        return 1

    # Step 6: Run parser
    if not run_parser(str(parser_path)):
        print("Parser failed!")
        return 1

    print()
    print("=" * 60)
    print("✓ Update complete!")
    print(f"  Rules updated from {existing_date or 'none'} to {new_date}")
    print("=" * 60)

    return 0


if __name__ == '__main__':
    exit(main())
