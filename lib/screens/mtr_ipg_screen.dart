import 'package:flutter/material.dart';
import '../services/judge_docs_service.dart';
import 'mtr_sections_screen.dart';
import 'ipg_sections_screen.dart';

/// Entry screen for MTR/IPG judge documents.
/// Presents two options: Magic Tournament Rules or Infraction Procedure Guide.
class MtrIpgScreen extends StatefulWidget {
  const MtrIpgScreen({super.key});

  @override
  State<MtrIpgScreen> createState() => _MtrIpgScreenState();
}

class _MtrIpgScreenState extends State<MtrIpgScreen> {
  final _judgeDocsService = JudgeDocsService();
  String? _mtrDate;
  String? _ipgDate;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final mtrIndex = await _judgeDocsService.loadMtrIndex();
      final ipgIndex = await _judgeDocsService.loadIpgIndex();

      setState(() {
        _mtrDate = mtrIndex.effectiveDate;
        _ipgDate = ipgIndex.effectiveDate;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // MTR Card
          _DocumentCard(
            title: 'Magic Tournament Rules',
            subtitle: 'MTR',
            effectiveDate: _mtrDate,
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

          // IPG Card
          _DocumentCard(
            title: 'Infraction Procedure Guide',
            subtitle: 'IPG',
            effectiveDate: _ipgDate,
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
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? effectiveDate;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DocumentCard({
    required this.title,
    required this.subtitle,
    this.effectiveDate,
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
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (effectiveDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Effective $effectiveDate',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
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
