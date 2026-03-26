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

    result = {}
    if mtr_match:
        result['mtr'] = mtr_match.group(1)
    if ipg_match:
        result['ipg'] = ipg_match.group(1)

    if not result:
        print("Could not find any PDF links on WPN page.")
        print("Searching for any WPN PDF links...")
        all_pdfs = re.findall(r'(https://media\.wizards\.com/[^"\']*\.pdf)', html)
        if all_pdfs:
            print(f"Found {len(all_pdfs)} PDF links:")
            for pdf in all_pdfs[:10]:  # Show first 10
                print(f"  {pdf}")
        return None

    if not mtr_match:
        print("  Warning: MTR PDF not found on WPN page")
    if not ipg_match:
        print("  Warning: IPG PDF not found on WPN page")

    return result


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
    if 'mtr' in pdf_links:
        print(f"  MTR: {pdf_links['mtr']}")
    if 'ipg' in pdf_links:
        print(f"  IPG: {pdf_links['ipg']}")
    print()

    # Step 3: Download PDFs to temporary location to check dates
    temp_dir = data_dir / 'temp'
    temp_dir.mkdir(exist_ok=True)

    mtr_date = None
    ipg_date = None

    if 'mtr' in pdf_links:
        temp_mtr = temp_dir / 'MTR_temp.pdf'
        if not download_pdf(pdf_links['mtr'], temp_mtr):
            return 1
        mtr_date = extract_effective_date_from_pdf(temp_mtr)
        if not mtr_date:
            print("Could not extract effective date from MTR PDF.")
            return 1

    if 'ipg' in pdf_links:
        temp_ipg = temp_dir / 'IPG_temp.pdf'
        if not download_pdf(pdf_links['ipg'], temp_ipg):
            return 1
        ipg_date = extract_effective_date_from_pdf(temp_ipg)
        if not ipg_date:
            print("Could not extract effective date from IPG PDF.")
            return 1

    print()
    print("Checking effective dates...")

    # Use existing dates for documents not found on WPN page
    existing_mtr_date = existing_versions.get('mtr', {}).get('effective_date')
    existing_ipg_date = existing_versions.get('ipg', {}).get('effective_date')

    # Fall back to existing dates for documents not on WPN page
    if mtr_date is None:
        mtr_date = existing_mtr_date
    if ipg_date is None:
        ipg_date = existing_ipg_date

    print(f"\nAvailable versions:")
    if mtr_date:
        print(f"  MTR: {mtr_date}")
    if ipg_date:
        print(f"  IPG: {ipg_date}")
    print()

    # Step 5: Compare versions
    mtr_is_new = 'mtr' in pdf_links and existing_mtr_date != mtr_date
    ipg_is_new = 'ipg' in pdf_links and existing_ipg_date != ipg_date

    if not mtr_is_new and not ipg_is_new:
        print("✓ Judge documents are already up to date!")
        if mtr_date:
            print(f"  MTR: {mtr_date}")
        if ipg_date:
            print(f"  IPG: {ipg_date}")
        print("\n  No download needed. Running parsers...")

        # Clean up temp files
        if 'mtr' in pdf_links:
            temp_mtr.unlink(missing_ok=True)
        if 'ipg' in pdf_links:
            temp_ipg.unlink(missing_ok=True)
        if temp_dir.exists():
            temp_dir.rmdir()
    else:
        # Step 6: Move new files to permanent location
        print("Updates available:")
        if mtr_is_new:
            print(f"  MTR: {existing_mtr_date or 'none'} → {mtr_date}")
            temp_mtr.replace(mtr_pdf_path)
        elif 'mtr' in pdf_links:
            print(f"  MTR: {mtr_date} (no change)")
            temp_mtr.unlink(missing_ok=True)

        if ipg_is_new:
            print(f"  IPG: {existing_ipg_date or 'none'} → {ipg_date}")
            temp_ipg.replace(ipg_pdf_path)
        elif 'ipg' in pdf_links:
            print(f"  IPG: {ipg_date} (no change)")
            temp_ipg.unlink(missing_ok=True)

        print()

        # Clean up temp directory
        if temp_dir.exists():
            try:
                temp_dir.rmdir()
            except OSError:
                pass

        # Step 7: Extract text from PDFs
        if mtr_is_new:
            if not extract_text_from_pdf(mtr_pdf_path, mtr_txt_path):
                return 1

        if ipg_is_new:
            if not extract_text_from_pdf(ipg_pdf_path, ipg_txt_path):
                return 1

    # Step 8: Save version info - preserve existing entries for docs not found
    new_versions = {}
    if mtr_date:
        new_versions['mtr'] = {
            'effective_date': mtr_date,
            'pdf_url': pdf_links.get('mtr', existing_versions.get('mtr', {}).get('pdf_url', '')),
            'pdf_file': mtr_pdf_path.name,
            'txt_file': mtr_txt_path.name
        }
    if ipg_date:
        new_versions['ipg'] = {
            'effective_date': ipg_date,
            'pdf_url': pdf_links.get('ipg', existing_versions.get('ipg', {}).get('pdf_url', '')),
            'pdf_file': ipg_pdf_path.name,
            'txt_file': ipg_txt_path.name
        }

    save_version_info(version_file, new_versions)

    print()
    print("=" * 80)
    print("✓ Download and extraction complete!")
    if mtr_date:
        print(f"  MTR: {mtr_date}")
    if ipg_date:
        print(f"  IPG: {ipg_date}")
    print("=" * 80)
    print()

    # Step 9: Run parsing scripts
    print("Running parsing scripts...")
    print()

    # Parse MTR
    if mtr_date:
        print("Parsing MTR...")
        parse_mtr_script = script_dir / 'parse_mtr.py'
        result = subprocess.run(
            ['python3', str(parse_mtr_script)],
            capture_output=True,
            text=True
        )

        if result.returncode != 0:
            print(f"ERROR: MTR parsing failed:")
            print(result.stderr)
            return 1

        print(result.stdout)

    # Parse IPG
    if ipg_date:
        print("Parsing IPG...")
        parse_ipg_script = script_dir / 'parse_ipg.py'
        result = subprocess.run(
            ['python3', str(parse_ipg_script)],
            capture_output=True,
            text=True
        )

        if result.returncode != 0:
            print(f"ERROR: IPG parsing failed:")
            print(result.stderr)
            return 1

        print(result.stdout)

    # Final success message
    print()
    print("=" * 80)
    print("✓ JUDGE DOCUMENTS UPDATE COMPLETE!")
    print("=" * 80)
    print()
    print(f"Processed documents:")
    if mtr_date:
        print(f"  MTR: {mtr_date}")
        print(f"    → PDF:  {mtr_pdf_path}")
        print(f"    → Text: {mtr_txt_path}")
        print(f"    → JSON: assets/judgedocs/mtr_*.json")
        print()
    if ipg_date:
        print(f"  IPG: {ipg_date}")
        print(f"    → PDF:  {ipg_pdf_path}")
        print(f"    → Text: {ipg_txt_path}")
        print(f"    → JSON: assets/judgedocs/ipg_*.json")
        print()
    print("=" * 80)
    print()

    return 0


if __name__ == '__main__':
    exit(main())
