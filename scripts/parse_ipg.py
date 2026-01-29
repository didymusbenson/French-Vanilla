#!/usr/bin/env python3
"""
Parse Infraction Procedure Guide (IPG) text file into structured JSON.

This script:
1. Cleans extracted PDF text (removes page dividers, fixes broken words)
2. Parses IPG structure (sections and infractions with subsections)
3. Outputs JSON files to assets/judgedocs/

IPG has structured content:
- Definition
- Examples
- Philosophy
- Additional Remedy (optional)
- Upgrade (optional)
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

    # Extract effective date (e.g., "Effective September 23, 2024")
    date_match = re.search(r'Effective\s+([A-Z][a-z]+\s+\d{1,2},\s+\d{4})', text)
    if date_match:
        metadata['effective_date'] = date_match.group(1)

    return metadata


def extract_penalty_from_title(title):
    """
    Extract penalty level from infraction title.

    Example: "Game Play Error — Missed Trigger  No Penalty"
    Returns: "No Penalty"
    """
    # Look for penalty keywords at end of title
    penalties = [
        'No Penalty',
        'Warning',
        'Game Loss',
        'Match Loss',
        'Disqualification'
    ]

    for penalty in penalties:
        if penalty in title:
            return penalty

    return None


def parse_table_of_contents(text):
    """
    Parse the table of contents to identify section boundaries.

    Returns dict mapping section numbers to their titles.
    """
    sections = {}

    # Look for main sections in TOC
    # Pattern: "2. Game Play Errors"
    toc_pattern = r'^(\d+)\.\s+([A-Za-z\s]+)\.{2,}'

    for match in re.finditer(toc_pattern, text, re.MULTILINE):
        section_num = int(match.group(1))
        section_title = match.group(2).strip()

        # Only include main sections (1-4)
        if 1 <= section_num <= 4:
            sections[section_num] = section_title

    return sections


def parse_infraction(infraction_text, infraction_num, infraction_title):
    """
    Parse a single infraction into structured subsections.

    Subsections:
    - Definition (required)
    - Examples (optional)
    - Philosophy (optional)
    - Additional Remedy (optional)
    - Upgrade (optional)
    """
    result = {
        'number': infraction_num,
        'title': infraction_title,
        'penalty': extract_penalty_from_title(infraction_title),
        'definition': None,
        'examples': [],
        'philosophy': None,
        'additional_remedy': None,
        'upgrade': None
    }

    # Find subsection headers (they're typically in Title Case or ALL CAPS)
    # Pattern: line starting with subsection name

    # Split text by subsection headers
    subsections = {}
    current_section = 'definition'  # Default to definition at start
    current_content = []

    lines = infraction_text.split('\n')

    for line in lines:
        line_stripped = line.strip()

        # Check if this is a subsection header
        if re.match(r'^Definition\s*$', line_stripped, re.IGNORECASE):
            # Save previous section
            if current_content:
                subsections[current_section] = '\n'.join(current_content).strip()
            current_section = 'definition'
            current_content = []
        elif re.match(r'^Examples?\s*$', line_stripped, re.IGNORECASE):
            if current_content:
                subsections[current_section] = '\n'.join(current_content).strip()
            current_section = 'examples'
            current_content = []
        elif re.match(r'^Philosophy\s*$', line_stripped, re.IGNORECASE):
            if current_content:
                subsections[current_section] = '\n'.join(current_content).strip()
            current_section = 'philosophy'
            current_content = []
        elif re.match(r'^Additional Remedy\s*$', line_stripped, re.IGNORECASE):
            if current_content:
                subsections[current_section] = '\n'.join(current_content).strip()
            current_section = 'additional_remedy'
            current_content = []
        elif re.match(r'^Upgrade\s*$', line_stripped, re.IGNORECASE):
            if current_content:
                subsections[current_section] = '\n'.join(current_content).strip()
            current_section = 'upgrade'
            current_content = []
        else:
            # Regular content line
            if line_stripped:
                current_content.append(line_stripped)

    # Save last section
    if current_content:
        subsections[current_section] = '\n'.join(current_content).strip()

    # Populate result
    result['definition'] = subsections.get('definition', '')

    # Parse examples (format: "A. Example text", "B. Example text", etc.)
    examples_text = subsections.get('examples', '')
    if examples_text:
        # Split by letter pattern (A., B., C., etc.)
        example_pattern = r'([A-Z])\.\s+(.+?)(?=\n[A-Z]\.\s+|\Z)'
        examples = []
        for match in re.finditer(example_pattern, examples_text, re.DOTALL):
            letter = match.group(1)
            example_text = match.group(2).strip()
            examples.append(f"{letter}. {example_text}")

        result['examples'] = examples

    result['philosophy'] = subsections.get('philosophy')
    result['additional_remedy'] = subsections.get('additional_remedy')
    result['upgrade'] = subsections.get('upgrade')

    return result


def parse_infractions_in_section(section_text, section_num):
    """
    Parse individual infractions within a section.

    Infractions are numbered like 2.1, 2.2, etc.
    Returns list of infraction dicts with structured content.
    """
    infractions = []

    # Pattern: infraction number (e.g., "2.1"), spaces, title with penalty (rest of line)
    # Example: "2.1.      Game Play Error — Missed Trigger  No Penalty"
    # IMPORTANT: Exclude TOC entries which have dots (e.g., "2.1. Game Play Error — Missed Trigger .....7")
    infraction_pattern = rf'^{section_num}\.(\d+)\.\s+([^\n]+)'

    # Find all infraction starts (excluding TOC entries)
    infraction_starts = []
    for match in re.finditer(infraction_pattern, section_text, re.MULTILINE):
        title = match.group(2).strip()

        # Skip TOC entries (they have multiple dots like "......" followed by page number)
        if re.search(r'\.{3,}', title):
            continue

        # Get end position (after the newline following the title)
        title_end = match.end()

        infraction_starts.append({
            'pos': match.start(),
            'title_end': title_end,
            'number': f"{section_num}.{match.group(1)}",
            'title': title
        })

    # Extract content between infraction starts
    for i, infraction_start in enumerate(infraction_starts):
        # Get content from after the title line to next infraction (or end of section)
        content_start = infraction_start['title_end']
        if i + 1 < len(infraction_starts):
            content_end = infraction_starts[i + 1]['pos']
        else:
            content_end = len(section_text)

        content = section_text[content_start:content_end].strip()

        # Parse infraction structure
        parsed = parse_infraction(
            content,
            infraction_start['number'],
            infraction_start['title']
        )

        infractions.append(parsed)

    return infractions


def split_into_sections(text, section_titles):
    """
    Split the cleaned text into individual sections.

    Returns dict mapping section numbers to their full text content.
    """
    sections = {}

    # Find each section header in the text
    # IMPORTANT: Skip TOC entries which have dots
    section_starts = []

    for section_num, section_title in section_titles.items():
        # Look for section header pattern
        # Pattern: "N. Section Title" or "N.  Section Title"
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

    ipg_txt_path = data_dir / 'IPG.txt'

    print("=" * 80)
    print("IPG Parser")
    print("=" * 80)
    print()

    # Check if input file exists
    if not ipg_txt_path.exists():
        print(f"ERROR: IPG.txt not found at {ipg_txt_path}")
        print("Run update_judge_docs.py first to download the file.")
        return 1

    # Ensure output directory exists
    output_dir.mkdir(parents=True, exist_ok=True)

    # Read raw text
    print(f"Reading {ipg_txt_path}...")
    with open(ipg_txt_path, 'r', encoding='utf-8') as f:
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

    # Parse infractions in each section
    print("\nParsing infractions...")
    parsed_sections = []

    for section_num in sorted(sections.keys()):
        section_data = sections[section_num]
        section_title = section_data['title']
        section_text = section_data['text']

        infractions = parse_infractions_in_section(section_text, section_num)

        print(f"  Section {section_num}: {section_title}")
        print(f"    → {len(infractions)} infractions")

        parsed_sections.append({
            'section_number': section_num,
            'title': f"{section_num}. {section_title}",
            'section_key': f"ipg_section_{section_num}",
            'metadata': metadata,
            'infractions': infractions
        })

    # Write output files
    print("\nWriting JSON files...")

    # Write index file
    index_data = {
        'title': 'Infraction Procedure Guide',
        'document_type': 'ipg',
        'metadata': metadata,
        'sections': [
            {
                'section_number': s['section_number'],
                'title': s['title'],
                'section_key': s['section_key'],
                'infraction_count': len(s['infractions'])
            }
            for s in parsed_sections
        ]
    }

    index_path = output_dir / 'ipg_index.json'
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
    print("✓ IPG parsing complete!")
    print(f"  Output: {output_dir}")
    print(f"  Files: ipg_index.json + {len(parsed_sections)} section files")
    print("=" * 80)
    print()

    return 0


if __name__ == '__main__':
    exit(main())
