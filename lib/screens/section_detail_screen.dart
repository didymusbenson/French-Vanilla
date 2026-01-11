import 'package:flutter/material.dart';
import '../services/rules_data_service.dart';
import '../models/rule.dart';
import 'rule_detail_screen.dart';

class SectionDetailScreen extends StatefulWidget {
  final int sectionNumber;
  final String sectionTitle;

  const SectionDetailScreen({
    super.key,
    required this.sectionNumber,
    required this.sectionTitle,
  });

  @override
  State<SectionDetailScreen> createState() => _SectionDetailScreenState();
}

class _SectionDetailScreenState extends State<SectionDetailScreen> {
  final _dataService = RulesDataService();
  List<Rule>? _rules;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    try {
      final rules = await _dataService.getRulesForSection(widget.sectionNumber);
      setState(() {
        _rules = rules;
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
        title: Text('${widget.sectionNumber}. ${widget.sectionTitle}'),
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
              '${rule.number}. ${rule.title}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              '${rule.subruleGroups.length} subrule group${rule.subruleGroups.length == 1 ? '' : 's'}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 14,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RuleDetailScreen(
                    rule: rule,
                    sectionNumber: widget.sectionNumber,
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
