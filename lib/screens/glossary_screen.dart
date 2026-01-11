import 'package:flutter/material.dart';
import '../services/rules_data_service.dart';
import '../models/glossary_term.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  final _dataService = RulesDataService();
  final _searchController = TextEditingController();
  List<GlossaryTerm> _allTerms = [];
  List<GlossaryTerm> _filteredTerms = [];
  bool _isLoading = true;
  String? _error;
  final Set<int> _expandedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadGlossary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGlossary() async {
    try {
      final terms = await _dataService.getGlossaryTerms();
      setState(() {
        _allTerms = terms;
        _filteredTerms = terms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load glossary: $e';
        _isLoading = false;
      });
    }
  }

  void _filterTerms(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTerms = _allTerms;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredTerms = _allTerms.where((term) {
          return term.term.toLowerCase().contains(lowerQuery) ||
                 term.definition.toLowerCase().contains(lowerQuery);
        }).toList();
      }
      _expandedIndices.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Filter glossary terms...',
              prefixIcon: const Icon(Icons.filter_list),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterTerms('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _filterTerms,
          ),
        ),
        Expanded(
          child: _buildBody(),
        ),
      ],
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
                  _loadGlossary();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredTerms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No terms found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredTerms.length,
      itemBuilder: (context, index) {
        final term = _filteredTerms[index];
        final isExpanded = _expandedIndices.contains(index);

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                title: Text(
                  term.term,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                trailing: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedIndices.remove(index);
                    } else {
                      _expandedIndices.add(index);
                    }
                  });
                },
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      term.definition,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
