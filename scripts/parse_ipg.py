#!/usr/bin/env python3
"""
Parse Infraction Procedure Guide (IPG) PDF into structured JSON.

This script uses pdfplumber for clean text extraction with proper
paragraph and list formatting.

IPG has structured content:
- Definition
- Examples
- Philosophy
- Additional Remedy (optional)
- Upgrade (optional)

Outputs JSON files to assets/judgedocs/
"""

import json
import re
from pathlib import Path
import pdfplumber


def extract_text_from_pdf(pdf_path):
    """
    Extract text from PDF using pdfplumber.

    Returns clean text with proper paragraph breaks and list formatting.
    """
    text_parts = []

    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            # Extract text with layout preservation
            page_text = page.extract_text(layout=True, x_tolerance=3, y_tolerance=3)
            if page_text:
                text_parts.append(page_text)

    # Join pages with double newline
    full_text = '\n\n'.join(text_parts)

    # Clean up common PDF artifacts
    # Remove excessive whitespace while preserving paragraph structure
    full_text = re.sub(r' +', ' ', full_text)  # Multiple spaces to single
    full_text = re.sub(r'\n{4,}', '\n\n', full_text)  # Excessive newlines to double

    return full_text.strip()


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

    Returns dict mapping section identifiers to their titles.
    For numbered sections: integer keys (1-4)
    For appendices: string keys ("A"-"B")
    """
    sections = {}

    # Look for main sections in TOC
    # Pattern: "       2. Game Play Errors ....."
    # Allow for leading whitespace
    toc_pattern = r'^\s*(\d+)\.\s+([A-Za-z\s]+)\s*\.{2,}'

    for match in re.finditer(toc_pattern, text, re.MULTILINE):
        section_num = int(match.group(1))
        section_title = match.group(2).strip()

        # Only include main sections (1-4)
        if 1 <= section_num <= 4:
            sections[section_num] = section_title

    # Look for appendices like "       Appendix A — Penalty Quick Reference  ....."
    # Allow for leading whitespace
    appendix_pattern = r'^\s*Appendix\s+([A-B])\s*[—–-]\s*([^.]+?)\s*\.{2,}'

    for match in re.finditer(appendix_pattern, text, re.MULTILINE):
        appendix_letter = match.group(1)
        appendix_title = match.group(2).strip()
        sections[appendix_letter] = appendix_title

    return sections


def clean_infraction_content(content):
    """
    Clean up PDF line break artifacts in infraction content.

    Preserves paragraph breaks (double newlines) but removes
    mid-sentence line breaks that are PDF layout artifacts.
    Also strips page numbers.
    """
    # First, normalize paragraph breaks
    # Replace any sequence of whitespace with newlines to double newline
    content = re.sub(r'\n\s*\n', '\n\n', content)

    # Split into paragraphs
    paragraphs = content.split('\n\n')

    cleaned_paragraphs = []
    for para in paragraphs:
        # Within each paragraph, replace single newlines with spaces
        # This joins lines that were broken for PDF layout
        para = re.sub(r'\n', ' ', para)
        # Clean up multiple spaces
        para = re.sub(r' +', ' ', para)
        para = para.strip()

        # Skip if this is just a page number (1-3 digits)
        if para and not re.match(r'^\d{1,3}$', para):
            cleaned_paragraphs.append(para)

    # Join paragraphs with double newline
    return '\n\n'.join(cleaned_paragraphs)


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

    # Populate result - clean up line breaks in each subsection
    definition = subsections.get('definition', '')
    result['definition'] = clean_infraction_content(definition) if definition else None

    # Parse examples (format: "A. Example text", "B. Example text", etc.)
    examples_text = subsections.get('examples', '')
    if examples_text:
        # Split by letter pattern (A., B., C., etc.)
        example_pattern = r'([A-Z])\.\s+(.+?)(?=\n[A-Z]\.\s+|\Z)'
        examples = []
        for match in re.finditer(example_pattern, examples_text, re.DOTALL):
            letter = match.group(1)
            example_text = match.group(2).strip()
            # Clean up line breaks in example text
            example_text = clean_infraction_content(example_text)
            examples.append(f"{letter}. {example_text}")

        result['examples'] = examples

    philosophy = subsections.get('philosophy')
    result['philosophy'] = clean_infraction_content(philosophy) if philosophy else None

    additional_remedy = subsections.get('additional_remedy')
    result['additional_remedy'] = clean_infraction_content(additional_remedy) if additional_remedy else None

    upgrade = subsections.get('upgrade')
    result['upgrade'] = clean_infraction_content(upgrade) if upgrade else None

    return result


def parse_general_philosophy_entries(section_text, section_num):
    """
    Parse Section 1 (General Philosophy) entries.

    These are NOT infractions - just informational entries with plain text.
    Pattern can be either:
      - "       1.1." with title on next line
      - "       1.2.  TITLE" with title on same line
    Returns list of simple entry dicts (no subsections like Definition/Examples).
    """
    entries = []

    # Pattern: entry number (e.g., "       1.1.") with period, optionally followed by title
    # Handles both: "1.1." (title on next line) and "1.2.  TITLE" (title on same line)
    # Allow for leading whitespace
    entry_pattern = rf'^\s*{section_num}\.(\d+)\.\s*(.*)$'

    # Find all entry starts
    entry_starts = []
    for match in re.finditer(entry_pattern, section_text, re.MULTILINE):
        title_on_same_line = match.group(2).strip()

        # Check if this is a TOC entry (has multiple dots)
        if title_on_same_line and re.search(r'\.{3,}', title_on_same_line):
            continue

        title = None
        title_line_end = match.end()

        if title_on_same_line:
            # Title is on the same line as the number
            title = title_on_same_line
        else:
            # Title is on the next non-empty line
            lines_after = section_text[match.end():].split('\n')
            for line in lines_after:
                stripped = line.strip()
                if stripped:
                    title = stripped
                    # Calculate where this title line ends
                    title_line_end = section_text.find(line, match.end()) + len(line)
                    break

        if not title:
            continue

        entry_starts.append({
            'pos': match.start(),
            'title_end': title_line_end,
            'number': f"{section_num}.{match.group(1)}",
            'title': title
        })

    # Extract content between entry starts
    for i, entry_start in enumerate(entry_starts):
        # Get content from after the title line to next entry (or end of section)
        content_start = entry_start['title_end']
        if i + 1 < len(entry_starts):
            content_end = entry_starts[i + 1]['pos']
        else:
            content_end = len(section_text)

        content = section_text[content_start:content_end].strip()

        # Clean up PDF line break artifacts
        content = clean_infraction_content(content)

        # Simple structure - just plain content, no subsections
        entries.append({
            'number': entry_start['number'],
            'title': entry_start['title'],
            'penalty': None,
            'definition': content,  # Store all content as "definition" for compatibility
            'examples': [],
            'philosophy': None,
            'additional_remedy': None,
            'upgrade': None
        })

    return entries


def parse_infractions_in_section(section_text, section_num):
    """
    Parse individual infractions within a section (Sections 2-4).

    Infractions are numbered like 2.1, 2.2, etc.
    Returns list of infraction dicts with structured content.
    """
    infractions = []

    # Pattern: infraction number (e.g., "       2.1."), spaces, title with penalty (rest of line)
    # Example: "       2.1.      Game Play Error — Missed Trigger  No Penalty"
    # IMPORTANT: Exclude TOC entries which have dots (e.g., "         2.1. Game Play Error — Missed Trigger .....7")
    # Allow for leading whitespace
    infraction_pattern = rf'^\s*{section_num}\.(\d+)\.\s+([^\n]+)'

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
    Split the cleaned text into individual sections and appendices.

    Returns dict mapping section identifiers (int or str) to their full text content.
    """
    sections = {}

    # Find each section/appendix header in the text
    # IMPORTANT: Skip TOC entries which have dots
    section_starts = []

    for section_id, section_title in section_titles.items():
        # Determine pattern based on whether it's a number or letter
        # Allow for leading whitespace
        if isinstance(section_id, int):
            # Numbered section: "N. Section Title"
            pattern = rf'^\s*{section_id}\.\s+{re.escape(section_title)}(.*)$'
        else:
            # Appendix: "Appendix A — Title" or "APPENDIX A — Title"
            pattern = rf'^\s*Appendix\s+{section_id}\s*[—–-]\s*{re.escape(section_title)}(.*)$'

        for match in re.finditer(pattern, text, re.MULTILINE | re.IGNORECASE):
            rest_of_line = match.group(1)

            # Skip if this is a TOC entry (has dots)
            if re.search(r'\.{3,}', rest_of_line):
                continue

            section_starts.append({
                'id': section_id,
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
        sections[section_start['id']] = {
            'title': section_start['title'],
            'text': section_text
        }

    return sections


def main():
    """Main entry point."""
    script_dir = Path(__file__).parent
    data_dir = script_dir / 'data' / 'judge_docs'
    output_dir = script_dir.parent / 'assets' / 'judgedocs'

    ipg_pdf_path = data_dir / 'IPG.pdf'

    print("=" * 80)
    print("IPG Parser (pdfplumber)")
    print("=" * 80)
    print()

    # Check if input file exists
    if not ipg_pdf_path.exists():
        print(f"ERROR: IPG.pdf not found at {ipg_pdf_path}")
        print("Run update_judge_docs.py first to download the file.")
        return 1

    # Ensure output directory exists
    output_dir.mkdir(parents=True, exist_ok=True)

    # Extract text from PDF
    print(f"Extracting text from {ipg_pdf_path}...")
    text = extract_text_from_pdf(ipg_pdf_path)
    print(f"  Extracted: {len(text)} characters")

    # Extract metadata
    print("Extracting metadata...")
    metadata = extract_metadata(text)
    print(f"  Effective date: {metadata.get('effective_date', 'Unknown')}")

    # Parse table of contents to identify sections
    print("Parsing table of contents...")
    section_titles = parse_table_of_contents(text)
    print(f"  Found {len(section_titles)} sections:")
    # Sort: numbers first, then letters
    sorted_items = sorted(section_titles.items(), key=lambda x: (isinstance(x[0], str), x[0]))
    for section_id, title in sorted_items:
        if isinstance(section_id, int):
            print(f"    {section_id}. {title}")
        else:
            print(f"    Appendix {section_id}: {title}")

    # Split into sections
    print("\nSplitting into sections...")
    sections = split_into_sections(text, section_titles)
    print(f"  Extracted {len(sections)} section texts")

    # Parse entries/infractions in each section
    print("\nParsing entries/infractions...")
    parsed_sections = []

    # Sort: numbers first, then letters
    sorted_keys = sorted(sections.keys(), key=lambda x: (isinstance(x, str), x))

    for section_id in sorted_keys:
        section_data = sections[section_id]
        section_title = section_data['title']
        section_text = section_data['text']

        if isinstance(section_id, int):
            # Numbered sections
            if section_id == 1:
                # Section 1 (General Philosophy) - simple entries, not infractions
                entries = parse_general_philosophy_entries(section_text, section_id)
                entry_type = "entries"
            else:
                # Sections 2-4 - actual infractions with structured content
                entries = parse_infractions_in_section(section_text, section_id)
                entry_type = "infractions"

            print(f"  Section {section_id}: {section_title}")
            print(f"    → {len(entries)} {entry_type}")

            parsed_sections.append({
                'section_number': section_id,
                'title': f"{section_id}. {section_title}",
                'section_key': f"ipg_section_{section_id}",
                'metadata': metadata,
                'infractions': entries  # Keep field name as 'infractions' for compatibility
            })
        else:
            # Appendix - just store plain content as a single "infraction"
            print(f"  Appendix {section_id}: {section_title}")
            print(f"    → appendix content")

            # Clean up PDF line break artifacts in appendix content
            cleaned_content = clean_infraction_content(section_text)

            # Store appendix as a section with one "infraction" containing all content
            parsed_sections.append({
                'section_number': section_id,  # Will be "A", "B", etc.
                'title': f"Appendix {section_id}—{section_title}",
                'section_key': f"ipg_appendix_{section_id.lower()}",
                'metadata': metadata,
                'infractions': [{
                    'number': section_id,
                    'title': section_title,
                    'penalty': None,
                    'definition': cleaned_content,
                    'examples': [],
                    'philosophy': None,
                    'additional_remedy': None,
                    'upgrade': None
                }]
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
