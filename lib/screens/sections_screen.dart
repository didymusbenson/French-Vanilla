import 'package:flutter/material.dart';
import 'section_detail_screen.dart';

class SectionsScreen extends StatelessWidget {
  const SectionsScreen({super.key});

  static const List<Map<String, dynamic>> sections = [
    {'number': 1, 'title': 'Game Concepts', 'icon': Icons.casino},
    {'number': 2, 'title': 'Parts of a Card', 'icon': Icons.credit_card},
    {'number': 3, 'title': 'Card Types', 'icon': Icons.category},
    {'number': 4, 'title': 'Zones', 'icon': Icons.layers},
    {'number': 5, 'title': 'Turn Structure', 'icon': Icons.rotate_right},
    {'number': 6, 'title': 'Spells, Abilities, and Effects', 'icon': Icons.flash_on},
    {'number': 7, 'title': 'Additional Rules', 'icon': Icons.rule},
    {'number': 8, 'title': 'Multiplayer Rules', 'icon': Icons.groups},
    {'number': 9, 'title': 'Casual Variants', 'icon': Icons.sports_esports},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
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
              '${section['number']}. ${section['title']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SectionDetailScreen(
                    sectionNumber: section['number'] as int,
                    sectionTitle: section['title'] as String,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
