import 'package:flutter/material.dart';
import 'sections_screen.dart';
import 'rulings_screen.dart';
import 'mtr_sections_screen.dart';
import 'ipg_sections_screen.dart';

/// Landing screen for all rules categories.
/// Presents four main categories: Comprehensive Rules, Card Rulings, MTR, and IPG.
class RulesCategoriesScreen extends StatelessWidget {
  const RulesCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Comprehensive Rules & Glossary
        _CategoryCard(
          title: 'Comprehensive Rules & Glossary',
          subtitle: 'Official Magic: The Gathering rules',
          icon: Icons.book,
          color: Colors.deepPurple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SectionsScreen(),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Individual Card Rulings
        _CategoryCard(
          title: 'Individual Card Rulings',
          subtitle: 'Official rulings for specific cards',
          icon: Icons.style,
          color: Colors.indigo,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RulingsScreen(),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Magic Tournament Rules
        _CategoryCard(
          title: 'Magic Tournament Rules',
          subtitle: 'MTR - Tournament policy and procedures',
          icon: Icons.gavel,
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MtrSectionsScreen(),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Infraction Procedure Guide
        _CategoryCard(
          title: 'Infraction Procedure Guide',
          subtitle: 'IPG - Tournament infractions and penalties',
          icon: Icons.warning_amber_rounded,
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const IpgSectionsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
