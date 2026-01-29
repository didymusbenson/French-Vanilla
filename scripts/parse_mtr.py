#!/usr/bin/env python3
"""
Parse Magic Tournament Rules (MTR) text file into structured JSON.

This script:
1. Cleans extracted PDF text (removes page dividers, fixes broken words)
2. Parses MTR structure (sections and rules)
3. Outputs JSON files to assets/judgedocs/
"""

import json
import os
import re
from pathlib import Path


def clean_text(text):
    """
    Clean extracted PDF text.

    Removes:
    - Page dividers (==== PAGE X of Y ====)
    - Fixes broken words across lines (F\nRAMEWORK -> FRAMEWORK)
    - Normalizes whitespace
    """
    # Remove page dividers and page numbers
    # Pattern: ====...====\nPAGE X of Y\n====...====\n\nN\n
    text = re.sub(
        r'={70,}\s*\nPAGE \d+ of \d+\s*\n={70,}\s*\n+\d+\s*\n+',
        '\n\n',
        text
    )

    # Fix broken words across lines (capital letters split)
    # Example: F\nRAMEWORK -> FRAMEWORK
    text = re.sub(r'([A-Z])\n([A-Z]+)', r'\1\2', text)

    # Normalize multiple blank lines to double newline
    text = re.sub(r'\n{3,}', '\n\n', text)

    # Clean up extra spaces
    text = re.sub(r' {2,}', ' ', text)

    return text.strip()


def extract_metadata(text):
    """Extract metadata from the document header."""
    metadata = {}

    # Extract effective date (e.g., "Effective November 10, 2025")
    date_match = re.search(r'Effective\s+([A-Z][a-z]+\s+\d{1,2},\s+\d{4})', text)
    if date_match:
        metadata['effective_date'] = date_match.group(1)

    return metadata


def parse_table_of_contents(text):
    """
    Parse the table of contents to identify section boundaries.

    Returns dict mapping section numbers to their titles.
    """
    sections = {}

    # Look for lines like "1.  Tournament Fundamentals .....5"
    # Section headers are numbered 1-8 and appear in the TOC
    toc_pattern = r'^(\d+)\.\s+([A-Za-z\s/\-]+?)\.{2,}'

    for match in re.finditer(toc_pattern, text, re.MULTILINE):
        section_num = int(match.group(1))
        section_title = match.group(2).strip()

        # Only include main sections (1-8), not subsections
        if section_num <= 8:
            sections[section_num] = section_title

    return sections


def parse_rules_in_section(section_text, section_num):
    """
    Parse individual rules within a section.

    Rules are numbered like 1.1, 1.2, etc.
    Returns list of rule dicts with number, title, and content.
    """
    rules = []

    # Pattern: rule number (e.g., "1.1"), optional spaces, title on same or next line
    # Content continues until next rule or end of section

    # Split into rule chunks using rule number pattern
    # Pattern: start of line, section.rule (e.g., "1.1"), space, title (rest of line)
    # IMPORTANT: Exclude TOC entries which have dots (e.g., "1.1 Tournament Types .....5")
    # Title should be just the text on the same line, not include following paragraphs
    rule_pattern = rf'^{section_num}\.(\d+)\s+([^\n]+)'

    # Find all rule starts (excluding TOC entries)
    rule_starts = []
    for match in re.finditer(rule_pattern, section_text, re.MULTILINE):
        title = match.group(2).strip()

        # Skip TOC entries (they have multiple dots like "......" followed by page number)
        if re.search(r'\.{3,}', title):
            continue

        # Get end position (after the newline following the title)
        title_end = match.end()

        rule_starts.append({
            'pos': match.start(),
            'title_end': title_end,
            'number': f"{section_num}.{match.group(1)}",
            'title': title
        })

    # Extract content between rule starts
    for i, rule_start in enumerate(rule_starts):
        # Get content from after the title line to next rule (or end of section)
        content_start = rule_start['title_end']
        if i + 1 < len(rule_starts):
            content_end = rule_starts[i + 1]['pos']
        else:
            content_end = len(section_text)

        content = section_text[content_start:content_end].strip()

        rules.append({
            'number': rule_start['number'],
            'title': rule_start['title'],
            'content': content
        })

    return rules


def split_into_sections(text, section_titles):
    """
    Split the cleaned text into individual sections.

    Returns dict mapping section numbers to their full text content.
    """
    sections = {}

    # Find each section header in the text
    # Section headers appear as "N.  Section Title" (e.g., "1.  Tournament Fundamentals")
    # IMPORTANT: Skip TOC entries which have dots
    section_starts = []

    for section_num, section_title in section_titles.items():
        # Look for section header pattern
        # Allow for some variation in spacing and formatting
        pattern = rf'^{section_num}\.\s+{re.escape(section_title)}(.*)$'

        for match in re.finditer(pattern, text, re.MULTILINE | re.IGNORECASE):
            rest_of_line = match.group(1)

            # Skip if this is a TOC entry (has dots)
            if re.search(r'\.{3,}', rest_of_line):
                continue

            section_starts.append({
                'num': section_num,
                'title': section_title,
                'pos': match.start()
            })
            break  # Only take the first non-TOC match

    # Sort by position
    section_starts.sort(key=lambda x: x['pos'])

    # Extract text for each section
    for i, section_start in enumerate(section_starts):
        start_pos = section_start['pos']

        # End is either the start of the next section or end of document
        if i + 1 < len(section_starts):
            end_pos = section_starts[i + 1]['pos']
        else:
            end_pos = len(text)

        section_text = text[start_pos:end_pos].strip()
        sections[section_start['num']] = {
            'title': section_start['title'],
            'text': section_text
        }

    return sections


def main():
    """Main entry point."""
    script_dir = Path(__file__).parent
    data_dir = script_dir / 'data' / 'judge_docs'
    output_dir = script_dir.parent / 'assets' / 'judgedocs'

    mtr_txt_path = data_dir / 'MTR.txt'

    print("=" * 80)
    print("MTR Parser")
    print("=" * 80)
    print()

    # Check if input file exists
    if not mtr_txt_path.exists():
        print(f"ERROR: MTR.txt not found at {mtr_txt_path}")
        print("Run update_judge_docs.py first to download the file.")
        return 1

    # Ensure output directory exists
    output_dir.mkdir(parents=True, exist_ok=True)

    # Read raw text
    print(f"Reading {mtr_txt_path}...")
    with open(mtr_txt_path, 'r', encoding='utf-8') as f:
        raw_text = f.read()

    print(f"  Raw size: {len(raw_text)} characters")

    # Clean text
    print("Cleaning text...")
    cleaned_text = clean_text(raw_text)
    print(f"  Cleaned size: {len(cleaned_text)} characters")

    # Extract metadata
    print("Extracting metadata...")
    metadata = extract_metadata(cleaned_text)
    print(f"  Effective date: {metadata.get('effective_date', 'Unknown')}")

    # Parse table of contents to identify sections
    print("Parsing table of contents...")
    section_titles = parse_table_of_contents(cleaned_text)
    print(f"  Found {len(section_titles)} sections:")
    for num, title in sorted(section_titles.items()):
        print(f"    {num}. {title}")

    # Split into sections
    print("\nSplitting into sections...")
    sections = split_into_sections(cleaned_text, section_titles)
    print(f"  Extracted {len(sections)} section texts")

    # Parse rules in each section
    print("\nParsing rules...")
    parsed_sections = []

    for section_num in sorted(sections.keys()):
        section_data = sections[section_num]
        section_title = section_data['title']
        section_text = section_data['text']

        rules = parse_rules_in_section(section_text, section_num)

        print(f"  Section {section_num}: {section_title}")
        print(f"    → {len(rules)} rules")

        parsed_sections.append({
            'section_number': section_num,
            'title': f"{section_num}. {section_title}",
            'section_key': f"mtr_section_{section_num}",
            'metadata': metadata,
            'rules': rules
        })

    # Write output files
    print("\nWriting JSON files...")

    # Write index file
    index_data = {
        'title': 'Magic Tournament Rules',
        'document_type': 'mtr',
        'metadata': metadata,
        'sections': [
            {
                'section_number': s['section_number'],
                'title': s['title'],
                'section_key': s['section_key'],
                'rule_count': len(s['rules'])
            }
            for s in parsed_sections
        ]
    }

    index_path = output_dir / 'mtr_index.json'
    with open(index_path, 'w', encoding='utf-8') as f:
        json.dump(index_data, f, indent=2, ensure_ascii=False)
    print(f"  ✓ {index_path}")

    # Write individual section files
    for section_data in parsed_sections:
        section_key = section_data['section_key']
        section_path = output_dir / f"{section_key}.json"

        with open(section_path, 'w', encoding='utf-8') as f:
            json.dump(section_data, f, indent=2, ensure_ascii=False)

        print(f"  ✓ {section_path}")

    print()
    print("=" * 80)
    print("✓ MTR parsing complete!")
    print(f"  Output: {output_dir}")
    print(f"  Files: mtr_index.json + {len(parsed_sections)} section files")
    print("=" * 80)
    print()

    return 0


if __name__ == '__main__':
    exit(main())
