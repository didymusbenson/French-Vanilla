import 'package:flutter/material.dart';
import 'section_detail_screen.dart';
import 'glossary_detail_screen.dart';

class SectionsScreen extends StatelessWidget {
  const SectionsScreen({super.key});

  static const List<Map<String, dynamic>> sections = [
    {'number': 1, 'title': 'Game Concepts', 'icon': Icons.casino},
    {'number': 2, 'title': 'Parts of a Card', 'icon': Icons.auto_awesome_mosaic},
    {'number': 3, 'title': 'Card Types', 'icon': Icons.category},
    {'number': 4, 'title': 'Zones', 'icon': Icons.layers},
    {'number': 5, 'title': 'Turn Structure', 'icon': Icons.rotate_right},
    {'number': 6, 'title': 'Spells, Abilities, and Effects', 'icon': Icons.flash_on},
    {'number': 7, 'title': 'Additional Rules', 'icon': Icons.rule},
    {'number': 8, 'title': 'Multiplayer Rules', 'icon': Icons.groups},
    {'number': 9, 'title': 'Casual Variants', 'icon': Icons.castle},
    {'number': null, 'title': 'Glossary', 'icon': Icons.book}, // Glossary - no number
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprehensive Rules'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(section['icon'] as IconData),
              ),
              title: Text(
                section['number'] != null
                    ? '${section['number']}. ${section['title']}'
                    : section['title'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to Glossary or Section Detail
                if (section['number'] == null) {
                  // Glossary
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GlossaryDetailScreen(),
                    ),
                  );
                } else {
                  // Regular section
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SectionDetailScreen(
                        sectionNumber: section['number'] as int,
                        sectionTitle: section['title'] as String,
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
