import 'package:flutter/material.dart';
import '../services/judge_docs_service.dart';
import '../models/ipg_infraction.dart';
import 'ipg_section_detail_screen.dart';
import 'ipg_infraction_detail_screen.dart';

/// Screen showing all IPG sections (1-4).
class IpgSectionsScreen extends StatefulWidget {
  const IpgSectionsScreen({super.key});

  @override
  State<IpgSectionsScreen> createState() => _IpgSectionsScreenState();
}

class _IpgSectionsScreenState extends State<IpgSectionsScreen> {
  final _judgeDocsService = JudgeDocsService();
  List<IpgSectionInfo>? _sections;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    try {
      final index = await _judgeDocsService.loadIpgIndex();
      setState(() {
        _sections = index.sections;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infraction Procedure Guide'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sections == null || _sections!.isEmpty
              ? const Center(child: Text('No sections found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _sections!.length,
                  itemBuilder: (context, index) {
                    final section = _sections![index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        title: Text(
                          section.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: section.sectionNumber == 1
                            ? null // Section 1 has no infractions, just general info
                            : Text(
                                section.isAppendix
                                    ? 'Appendix'
                                    : section.infractionCount == 1
                                        ? '1 infraction'
                                        : '${section.infractionCount} infractions',
                              ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          // For appendices (or any section with 1 infraction), navigate directly to content
                          if (section.isAppendix || section.infractionCount == 1) {
                            // Load the section to get the single infraction
                            final sectionData = await _judgeDocsService.loadIpgSection(section.sectionNumber);
                            if (sectionData.infractions.isNotEmpty && context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => IpgInfractionDetailScreen(
                                    infraction: sectionData.infractions.first,
                                  ),
                                ),
                              );
                            }
                          } else {
                            // Navigate to infractions list for multi-infraction sections
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IpgSectionDetailScreen(
                                  sectionNumber: section.sectionNumber,
                                  sectionTitle: section.title,
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
