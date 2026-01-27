#!/usr/bin/env python3
"""
Analyze ALL rule sections for potential false positives
when matching 3-digit.digit patterns.
"""

import json
import re
from pathlib import Path

def analyze_section(section_num):
    # Load section data
    section_path = Path(__file__).parent.parent / 'assets' / 'rulesdocs' / f'section_{section_num}.json'

    if not section_path.exists():
        return None

    with open(section_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Pattern to match 3-digit.digit (like 601.2 or 702.90)
    pattern = re.compile(r'\b(\d{3})\.(\d+)([a-z])?\b')

    # Track all matches and their contexts
    matches = []

    # Parse the content field which contains all rules
    content = data.get('content', '')

    # Find all rules in this section
    rule_pattern = re.compile(r'^(\d{3})\.\s', re.MULTILINE)

    # Split content by rule boundaries
    lines = content.split('\n')
    current_rule = None
    current_content = []

    for line in lines:
        rule_match = re.match(r'^(\d{3})\.\s', line)
        if rule_match:
            # Process previous rule if exists
            if current_rule and current_content:
                process_rule(current_rule, '\n'.join(current_content), pattern, matches)

            current_rule = rule_match.group(1)
            current_content = [line]
        elif current_rule:
            current_content.append(line)

    # Process last rule
    if current_rule and current_content:
        process_rule(current_rule, '\n'.join(current_content), pattern, matches)

    return matches

def analyze_all_sections():
    print("=" * 70)
    print("ANALYZING ALL RULE SECTIONS FOR FALSE POSITIVES")
    print("=" * 70)

    all_matches = []
    section_results = {}

    for section_num in range(1, 10):  # Sections 1-9
        matches = analyze_section(section_num)
        if matches is None:
            print(f"\nSection {section_num}: File not found, skipping")
            continue

        section_results[section_num] = matches
        all_matches.extend(matches)
        print(f"\nSection {section_num}: {len(matches)} patterns found")

    print(f"\n{'=' * 70}")
    print(f"TOTAL: {len(all_matches)} 3-digit.digit patterns across all sections")
    print(f"{'=' * 70}")


    # Now analyze all matches across all sections
    # Group by pattern
    pattern_groups = {}
    for match in all_matches:
        pattern_str = match['pattern']
        if pattern_str not in pattern_groups:
            pattern_groups[pattern_str] = []
        pattern_groups[pattern_str].append(match)

    # Check for potential false positives
    false_positives = []
    valid_references = []

    for pattern_str, occurrences in sorted(pattern_groups.items()):
        # Extract the major section number (first digit)
        major_section = int(pattern_str[0])

        # MTG comprehensive rules only go from sections 1-9
        # Any reference outside this range is invalid
        if major_section < 1 or major_section > 9:
            false_positives.append((pattern_str, occurrences))
        else:
            valid_references.append((pattern_str, occurrences))

    # Report findings
    print("\n" + "=" * 70)
    print("CROSS-SECTION ANALYSIS RESULTS")
    print("=" * 70)

    if false_positives:
        print(f"\n⚠️  POTENTIAL FALSE POSITIVES FOUND: {len(false_positives)}")
        print("-" * 70)
        for pattern_str, occurrences in false_positives:
            print(f"\nPattern: {pattern_str}")
            print(f"Occurrences: {len(occurrences)}")
            # Show which sections they appear in
            sections = set(occ['rule'][:1] for occ in occurrences)
            print(f"Appears in sections: {sorted(sections)}")
            for occ in occurrences[:3]:  # Show first 3 examples
                print(f"  Rule {occ['rule']}: ...{occ['context']}...")
            if len(occurrences) > 3:
                print(f"  ... and {len(occurrences) - 3} more")
    else:
        print("\n✅ No false positives found in ANY section!")

    print(f"\n\n✓ VALID RULE REFERENCES: {len(valid_references)} unique patterns")
    print("-" * 70)

    # Show most common valid references
    valid_references.sort(key=lambda x: len(x[1]), reverse=True)
    print("\nTop 30 most referenced rules:")
    for pattern_str, occurrences in valid_references[:30]:
        sections = set(occ['rule'][:1] for occ in occurrences)
        print(f"  {pattern_str}: {len(occurrences)} times (in sections {sorted(sections)})")

    # Check for patterns that look like they might be edge cases
    print("\n\nEDGE CASES TO REVIEW:")
    print("-" * 70)
    edge_cases = []

    for pattern_str, occurrences in valid_references:
        # Look for suspicious contexts
        for occ in occurrences:
            context = occ['context'].lower()
            # Check if it appears in mathematical or non-rule contexts
            if any(word in context for word in ['power', 'toughness', 'loyalty', 'defense', 'mana value']):
                edge_cases.append(occ)
                break

    if edge_cases:
        print(f"Found {len(edge_cases)} potential edge cases (numbers in game mechanic contexts):")
        for case in edge_cases[:15]:
            print(f"  Rule {case['rule']}: ...{case['context']}...")
    else:
        print("No obvious edge cases detected.")

    # Breakdown by section
    print("\n\nBREAKDOWN BY SECTION:")
    print("-" * 70)
    for section_num in range(1, 10):
        if section_num in section_results:
            matches = section_results[section_num]
            unique_patterns = len(set(m['pattern'] for m in matches))
            print(f"Section {section_num}: {len(matches)} total matches, {unique_patterns} unique patterns")

def process_rule(rule_num, content, pattern, matches):
    """Process a single rule and extract pattern matches."""
    for match in pattern.finditer(content):
        matched_text = match.group(0)
        start = max(0, match.start() - 40)
        end = min(len(content), match.end() + 40)
        context = content[start:end].replace('\n', ' ')

        matches.append({
            'rule': rule_num,
            'pattern': matched_text,
            'context': context
        })

if __name__ == '__main__':
    analyze_all_sections()
