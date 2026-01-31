import 'dart:math' show pi;
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
      padding: const EdgeInsets.all(8.0),
      children: [
        // Comprehensive Rules & Glossary
        _CategoryCard(
          title: 'Comprehensive Rules & Glossary',
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

        const SizedBox(height: 8),

        // Individual Card Rulings
        _CategoryCard(
          title: 'Individual Card Rulings',
          icon: Icons.style,
          iconRotation: pi,
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

        const SizedBox(height: 8),

        // Magic Tournament Rules
        _CategoryCard(
          title: 'Magic Tournament Rules',
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

        const SizedBox(height: 8),

        // Infraction Procedure Guide
        _CategoryCard(
          title: 'Infraction Procedure Guide',
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
  final IconData icon;
  final double iconRotation;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    this.iconRotation = 0,
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
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Transform.rotate(
                  angle: iconRotation,
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
