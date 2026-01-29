import 'package:flutter/material.dart';
import '../services/judge_docs_service.dart';
import '../models/mtr_rule.dart';
import 'mtr_rule_detail_screen.dart';

/// Screen showing all rules in an MTR section.
class MtrSectionDetailScreen extends StatefulWidget {
  final int sectionNumber;
  final String sectionTitle;

  const MtrSectionDetailScreen({
    super.key,
    required this.sectionNumber,
    required this.sectionTitle,
  });

  @override
  State<MtrSectionDetailScreen> createState() => _MtrSectionDetailScreenState();
}

class _MtrSectionDetailScreenState extends State<MtrSectionDetailScreen> {
  final _judgeDocsService = JudgeDocsService();
  List<MtrRule>? _rules;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    try {
      final section = await _judgeDocsService.loadMtrSection(widget.sectionNumber);
      setState(() {
        _rules = section.rules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load rules: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sectionTitle),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadRules();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_rules == null || _rules!.isEmpty) {
      return const Center(child: Text('No rules found for this section.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _rules!.length,
      itemBuilder: (context, index) {
        final rule = _rules![index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            title: Text(
              '${rule.number} ${rule.title}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MtrRuleDetailScreen(
                    rule: rule,
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
