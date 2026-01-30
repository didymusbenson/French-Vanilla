import 'package:flutter/material.dart';
import '../services/judge_docs_service.dart';
import '../models/ipg_infraction.dart';
import 'ipg_infraction_detail_screen.dart';

/// Screen showing all infractions in an IPG section.
class IpgSectionDetailScreen extends StatefulWidget {
  final dynamic sectionNumber; // Can be int (1-4) or String ("A"-"B")
  final String sectionTitle;

  const IpgSectionDetailScreen({
    super.key,
    required this.sectionNumber,
    required this.sectionTitle,
  });

  @override
  State<IpgSectionDetailScreen> createState() => _IpgSectionDetailScreenState();
}

class _IpgSectionDetailScreenState extends State<IpgSectionDetailScreen> {
  final _judgeDocsService = JudgeDocsService();
  List<IpgInfraction>? _infractions;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInfractions();
  }

  Future<void> _loadInfractions() async {
    try {
      final section = await _judgeDocsService.loadIpgSection(widget.sectionNumber);
      setState(() {
        _infractions = section.infractions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load infractions: $e';
        _isLoading = false;
      });
    }
  }

  Color _getPenaltyColor(String? penalty) {
    if (penalty == null) return Colors.grey;

    switch (penalty.toLowerCase()) {
      case 'no penalty':
        return Colors.green;
      case 'warning':
        return Colors.yellow.shade700;
      case 'game loss':
        return Colors.orange;
      case 'match loss':
        return Colors.red;
      case 'disqualification':
        return Colors.red.shade900;
      default:
        return Colors.grey;
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
                  _loadInfractions();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_infractions == null || _infractions!.isEmpty) {
      return const Center(child: Text('No infractions found for this section.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _infractions!.length,
      itemBuilder: (context, index) {
        final infraction = _infractions![index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            title: Text(
              '${infraction.number} ${infraction.cleanTitle}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: infraction.penalty != null
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getPenaltyColor(infraction.penalty),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          infraction.penalty!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IpgInfractionDetailScreen(
                    infraction: infraction,
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
