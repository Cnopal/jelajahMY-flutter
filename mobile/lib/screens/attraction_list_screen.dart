import 'package:flutter/material.dart';

import '../models/attraction.dart';
import '../models/attraction_category.dart';
import '../models/tourism_state.dart';
import '../services/attraction_service.dart';
import '../services/lookup_service.dart';
import 'attraction_detail_screen.dart';

class AttractionListScreen extends StatefulWidget {
  const AttractionListScreen({super.key});

  @override
  State<AttractionListScreen> createState() => _AttractionListScreenState();
}

class _AttractionListScreenState extends State<AttractionListScreen> {
  final AttractionService _attractionService = const AttractionService();

  final LookupService _lookupService = const LookupService();

  final TextEditingController _searchController = TextEditingController();

  late Future<List<Attraction>> _attractionsFuture;
  late Future<List<TourismState>> _statesFuture;

  late Future<List<AttractionCategory>> _categoriesFuture;

  String? _selectedStateCode;
  String? _selectedCategoryName;

  @override
  void initState() {
    super.initState();

    _statesFuture = _lookupService.getStates();
    _categoriesFuture = _lookupService.getCategories();

    _loadAttractions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadAttractions() {
    _attractionsFuture = _attractionService.getAttractions(
      search: _searchController.text,
      state: _selectedStateCode,
      category: _selectedCategoryName,
    );
  }

  void _applySearch() {
    FocusScope.of(context).unfocus();

    setState(() {
      _loadAttractions();
    });
  }

  void _changeState(String? stateCode) {
    setState(() {
      _selectedStateCode = stateCode;
      _loadAttractions();
    });
  }

  void _changeCategory(String? categoryName) {
    setState(() {
      _selectedCategoryName = categoryName;
      _loadAttractions();
    });
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _selectedStateCode = null;
      _selectedCategoryName = null;
      _loadAttractions();
    });
  }

  Future<void> _refreshAttractions() async {
    setState(() {
      _loadAttractions();
    });

    await _attractionsFuture;
  }

  void _retry() {
    setState(() {
      _loadAttractions();
    });
  }

  bool get _hasActiveFilters {
    return _searchController.text.trim().isNotEmpty ||
        _selectedStateCode != null ||
        _selectedCategoryName != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attractions'), centerTitle: true),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(child: _buildAttractionResults()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _applySearch(),
              decoration: InputDecoration(
                hintText: 'Search attractions',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Search',
                  onPressed: _applySearch,
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FutureBuilder<List<TourismState>>(
                    future: _statesFuture,
                    builder: (context, snapshot) {
                      return _FilterDropdown(
                        hint: 'All states',
                        value: _selectedStateCode,
                        isLoading:
                            snapshot.connectionState == ConnectionState.waiting,
                        items: (snapshot.data ?? const <TourismState>[])
                            .map(
                              (state) => DropdownMenuItem<String>(
                                value: state.code,
                                child: Text(
                                  state.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: snapshot.hasError ? null : _changeState,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FutureBuilder<List<AttractionCategory>>(
                    future: _categoriesFuture,
                    builder: (context, snapshot) {
                      return _FilterDropdown(
                        hint: 'All categories',
                        value: _selectedCategoryName,
                        isLoading:
                            snapshot.connectionState == ConnectionState.waiting,
                        items: (snapshot.data ?? const <AttractionCategory>[])
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category.name,
                                child: Text(
                                  category.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: snapshot.hasError ? null : _changeCategory,
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear filters'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttractionResults() {
    return FutureBuilder<List<Attraction>>(
      future: _attractionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _ErrorView(
            message: snapshot.error.toString(),
            onRetry: _retry,
          );
        }

        final attractions = snapshot.data ?? const <Attraction>[];

        if (attractions.isEmpty) {
          return _EmptyResultView(
            onClearFilters: _hasActiveFilters ? _clearFilters : null,
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshAttractions,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: attractions.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Text(
                  '${attractions.length} attraction'
                  '${attractions.length == 1 ? '' : 's'} found',
                  style: Theme.of(context).textTheme.labelLarge,
                );
              }

              final attraction = attractions[index - 1];

              return _AttractionCard(attraction: attraction);
            },
          ),
        );
      },
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isLoading,
  });

  final String hint;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(hint),
                isExpanded: true,
                items: items,
                onChanged: onChanged,
              ),
            ),
    );
  }
}

class _AttractionCard extends StatelessWidget {
  const _AttractionCard({required this.attraction});

  final Attraction attraction;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) {
                return AttractionDetailScreen(attractionId: attraction.id);
              },
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.landscape_outlined, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attraction.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(attraction.stateName),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.category_outlined, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            attraction.categoryName,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      attraction.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyResultView extends StatelessWidget {
  const _EmptyResultView({required this.onClearFilters});

  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 72),
            const SizedBox(height: 16),
            Text(
              'No Attractions Found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try another search keyword or filter.',
              textAlign: TextAlign.center,
            ),
            if (onClearFilters != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'Unable to load attractions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
