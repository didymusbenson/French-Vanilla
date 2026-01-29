#!/usr/bin/env python3
"""
Smart update script for Magic: The Gathering Judge Documents.

This script:
1. Scrapes the WPN rules-documents page to find current PDF links
2. Downloads PDFs to check effective dates
3. Compares to existing versions
4. Only fully processes if there's a new version
5. Extracts PDF text to .txt files for easier parsing
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path


def get_existing_versions(version_file_path):
    """Get the effective dates from existing judge documents."""
    if not version_file_path.exists():
        return {}

    try:
        with open(version_file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return {}


def scrape_wpn_page():
    """
    Scrape the WPN rules-documents page to find PDF links.

    Returns:
        dict: {'mtr': url, 'ipg': url} or None if failed
    """
    print("Fetching WPN rules-documents page...")

    result = subprocess.run(
        ['curl', '-s', 'https://wpn.wizards.com/en/rules-documents'],
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        print(f"Error fetching WPN page: {result.stderr}")
        return None

    html = result.stdout

    # Look for PDF links
    # MTR pattern: Magic: the Gathering Tournament Rules or MTG_MTR
    # IPG pattern: Magic Infraction Procedure Guide or MTG_IPG

    mtr_match = re.search(r'(https://media\.wizards\.com/[^"\']*MTG_MTR[^"\']*\.pdf)', html, re.IGNORECASE)
    ipg_match = re.search(r'(https://media\.wizards\.com/[^"\']*MTG_IPG[^"\']*\.pdf)', html, re.IGNORECASE)

    if not mtr_match or not ipg_match:
        print("Could not find PDF links on WPN page.")
        print("Searching for any WPN PDF links...")
        all_pdfs = re.findall(r'(https://media\.wizards\.com/[^"\']*\.pdf)', html)
        if all_pdfs:
            print(f"Found {len(all_pdfs)} PDF links:")
            for pdf in all_pdfs[:10]:  # Show first 10
                print(f"  {pdf}")
        return None

    return {
        'mtr': mtr_match.group(1),
        'ipg': ipg_match.group(1)
    }


def extract_effective_date_from_pdf(pdf_path):
    """
    Extract effective date from PDF using pypdf.

    Returns:
        str: Effective date or None
    """
    try:
        from pypdf import PdfReader

        reader = PdfReader(pdf_path)
        if len(reader.pages) == 0:
            return None

        # Get first page text
        first_page = reader.pages[0].extract_text()

        # Look for "Effective [Month Day, Year]" pattern
        # MTR format: "Effective November 10, 2025"
        # IPG format: "Effective September 23, 2024"
        match = re.search(r'Effective\s+([A-Z][a-z]+\s+\d{1,2},\s+\d{4})', first_page)

        if match:
            return match.group(1)

        # Fallback: look for just a date pattern
        match = re.search(r'([A-Z][a-z]+\s+\d{1,2},\s+\d{4})', first_page)
        if match:
            return match.group(1)

        return None

    except ImportError:
        print("ERROR: pypdf library not installed.")
        print("Install it with: pip3 install pypdf")
        return None
    except Exception as e:
        print(f"Error extracting date from PDF: {e}")
        return None


def download_pdf(url, output_path):
    """Download a PDF file."""
    print(f"Downloading {output_path.name}...")

    result = subprocess.run(
        ['curl', '-o', str(output_path), url],
        capture_output=True,
        text=True
    )

    if result.returncode != 0:
        print(f"Error downloading: {result.stderr}")
        return False

    print(f"✓ Downloaded {output_path.name}")
    return True


def extract_text_from_pdf(pdf_path, txt_path):
    """
    Extract all text from PDF to a .txt file.

    Returns:
        bool: Success status
    """
    print(f"Extracting text from {pdf_path.name}...")

    try:
        from pypdf import PdfReader

        reader = PdfReader(pdf_path)
        total_pages = len(reader.pages)

        all_text = []

        for i, page in enumerate(reader.pages):
            text = page.extract_text()
            all_text.append(f"{'='*80}\n")
            all_text.append(f"PAGE {i + 1} of {total_pages}\n")
            all_text.append(f"{'='*80}\n\n")
            all_text.append(text)
            all_text.append(f"\n\n")

        # Write to file
        with open(txt_path, 'w', encoding='utf-8') as f:
            f.write(''.join(all_text))

        # Get file size
        size_kb = txt_path.stat().st_size / 1024
        print(f"✓ Extracted {total_pages} pages to {txt_path.name}")
        print(f"  File size: {size_kb:.1f} KB")

        return True

    except ImportError:
        print("ERROR: pypdf library not installed.")
        print("Install it with: pip3 install pypdf")
        return False
    except Exception as e:
        print(f"Error extracting text: {e}")
        return False


def save_version_info(version_file_path, versions):
    """Save version information for future checks."""
    with open(version_file_path, 'w', encoding='utf-8') as f:
        json.dump(versions, f, indent=2)


def main():
    """Main entry point."""
    script_dir = Path(__file__).parent
    data_dir = script_dir / 'data' / 'judge_docs'

    # Ensure data directory exists
    data_dir.mkdir(parents=True, exist_ok=True)

    version_file = data_dir / 'version.json'
    mtr_pdf_path = data_dir / 'MTR.pdf'
    ipg_pdf_path = data_dir / 'IPG.pdf'
    mtr_txt_path = data_dir / 'MTR.txt'
    ipg_txt_path = data_dir / 'IPG.txt'

    print("=" * 80)
    print("MTG Judge Documents Update Script")
    print("=" * 80)
    print()

    # Step 1: Check existing versions
    existing_versions = get_existing_versions(version_file)

    if existing_versions:
        print("Current versions:")
        print(f"  MTR: {existing_versions.get('mtr', {}).get('effective_date', 'Unknown')}")
        print(f"  IPG: {existing_versions.get('ipg', {}).get('effective_date', 'Unknown')}")
    else:
        print("No existing judge documents found")
    print()

    # Step 2: Scrape WPN page for PDF links
    pdf_links = scrape_wpn_page()

    if not pdf_links:
        print("\nFailed to find PDF links. Exiting.")
        return 1

    print(f"\n✓ Found PDF links:")
    print(f"  MTR: {pdf_links['mtr']}")
    print(f"  IPG: {pdf_links['ipg']}")
    print()

    # Step 3: Download PDFs to temporary location to check dates
    temp_dir = data_dir / 'temp'
    temp_dir.mkdir(exist_ok=True)

    temp_mtr = temp_dir / 'MTR_temp.pdf'
    temp_ipg = temp_dir / 'IPG_temp.pdf'

    if not download_pdf(pdf_links['mtr'], temp_mtr):
        return 1

    if not download_pdf(pdf_links['ipg'], temp_ipg):
        return 1

    print()

    # Step 4: Extract effective dates from PDFs
    print("Checking effective dates...")
    mtr_date = extract_effective_date_from_pdf(temp_mtr)
    ipg_date = extract_effective_date_from_pdf(temp_ipg)

    if not mtr_date or not ipg_date:
        print("\nCould not extract effective dates from PDFs.")
        print(f"MTR date: {mtr_date}")
        print(f"IPG date: {ipg_date}")
        return 1

    print(f"\nAvailable versions:")
    print(f"  MTR: {mtr_date}")
    print(f"  IPG: {ipg_date}")
    print()

    # Step 5: Compare versions
    existing_mtr_date = existing_versions.get('mtr', {}).get('effective_date')
    existing_ipg_date = existing_versions.get('ipg', {}).get('effective_date')

    mtr_is_new = existing_mtr_date != mtr_date
    ipg_is_new = existing_ipg_date != ipg_date

    if not mtr_is_new and not ipg_is_new:
        print("✓ Judge documents are already up to date!")
        print(f"  MTR: {mtr_date}")
        print(f"    → Existing file: {mtr_pdf_path}")
        print(f"    → Text file: {mtr_txt_path}")
        print(f"  IPG: {ipg_date}")
        print(f"    → Existing file: {ipg_pdf_path}")
        print(f"    → Text file: {ipg_txt_path}")
        print("\n  No download needed.")

        # Clean up temp files
        temp_mtr.unlink()
        temp_ipg.unlink()
        temp_dir.rmdir()

        return 0

    # Step 6: Move new files to permanent location
    print("Updates available:")
    if mtr_is_new:
        print(f"  MTR: {existing_mtr_date or 'none'} → {mtr_date}")
        temp_mtr.replace(mtr_pdf_path)
    else:
        print(f"  MTR: {mtr_date} (no change)")
        temp_mtr.unlink()

    if ipg_is_new:
        print(f"  IPG: {existing_ipg_date or 'none'} → {ipg_date}")
        temp_ipg.replace(ipg_pdf_path)
    else:
        print(f"  IPG: {ipg_date} (no change)")
        temp_ipg.unlink()

    print()

    # Clean up temp directory
    if temp_dir.exists():
        temp_dir.rmdir()

    # Step 7: Extract text from PDFs
    if mtr_is_new:
        if not extract_text_from_pdf(mtr_pdf_path, mtr_txt_path):
            return 1

    if ipg_is_new:
        if not extract_text_from_pdf(ipg_pdf_path, ipg_txt_path):
            return 1

    # Step 8: Save version info
    new_versions = {
        'mtr': {
            'effective_date': mtr_date,
            'pdf_url': pdf_links['mtr'],
            'pdf_file': mtr_pdf_path.name,
            'txt_file': mtr_txt_path.name
        },
        'ipg': {
            'effective_date': ipg_date,
            'pdf_url': pdf_links['ipg'],
            'pdf_file': ipg_pdf_path.name,
            'txt_file': ipg_txt_path.name
        }
    }

    save_version_info(version_file, new_versions)

    print()
    print("=" * 80)
    print("✓ Download and extraction complete!")
    print(f"  MTR: {mtr_date}")
    print(f"  IPG: {ipg_date}")
    print("=" * 80)
    print()

    # Step 9: YELL AT THE USER
    print("\n" + "🚨" * 40)
    print("⚠️  WARNING WARNING WARNING ⚠️")
    print("🚨" * 40)
    print()
    print("HEY! YOU NEED TO UPDATE THIS COMMAND!")
    print()
    print("The PDFs have been downloaded and text has been extracted to .txt files,")
    print("but you still need to:")
    print()
    print("  1. Create parsing scripts to structure the judge documents")
    print("  2. Decide on the JSON format for MTR and IPG data")
    print("  3. Integrate parsed data into the app")
    print("  4. Update this script to automatically run the parsing scripts")
    print()
    print(f"Your files are here:")
    print(f"  MTR PDF:  {mtr_pdf_path}")
    print(f"  MTR Text: {mtr_txt_path}")
    print(f"  IPG PDF:  {ipg_pdf_path}")
    print(f"  IPG Text: {ipg_txt_path}")
    print()
    print("🚨" * 40)
    print()

    return 0


if __name__ == '__main__':
    exit(main())
