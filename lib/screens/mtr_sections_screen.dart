import 'package:flutter/material.dart';
import '../services/judge_docs_service.dart';
import '../models/mtr_rule.dart';
import 'mtr_section_detail_screen.dart';

/// Screen showing all MTR sections (1-8).
class MtrSectionsScreen extends StatefulWidget {
  const MtrSectionsScreen({super.key});

  @override
  State<MtrSectionsScreen> createState() => _MtrSectionsScreenState();
}

class _MtrSectionsScreenState extends State<MtrSectionsScreen> {
  final _judgeDocsService = JudgeDocsService();
  List<MtrSectionInfo>? _sections;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    try {
      final index = await _judgeDocsService.loadMtrIndex();
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
        title: const Text('Magic Tournament Rules'),
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
                        leading: CircleAvatar(
                          child: Text('${section.sectionNumber}'),
                        ),
                        title: Text(
                          section.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text('${section.ruleCount} rules'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MtrSectionDetailScreen(
                                sectionNumber: section.sectionNumber,
                                sectionTitle: section.title,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
