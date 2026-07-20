import 'package:flutter/material.dart';

import '../models/attraction.dart';
import '../models/trip.dart';
import '../services/attraction_service.dart';
import '../services/trip_service.dart';
import 'attraction_detail_screen.dart';
import 'trip_form_screen.dart';

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({required this.tripId, super.key});

  final int tripId;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final _tripService = TripService();
  late Future<Trip> _tripFuture;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  void _loadTrip() {
    _tripFuture = _tripService.getTrip(widget.tripId);
  }

  void _refresh() {
    setState(() {
      _loadTrip();
    });
  }

  Future<void> _edit(Trip trip) async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => TripFormScreen(trip: trip)));
    if (changed == true && mounted) _refresh();
  }

  Future<void> _delete(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete trip?'),
        content: Text(
          'Delete “${trip.title}” and all its itinerary items? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _tripService.deleteTrip(trip.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _addAttraction(Trip trip) async {
    final attraction = await Navigator.of(context).push<Attraction>(
      MaterialPageRoute(
        builder: (_) => _AttractionPickerScreen(
          excludedIds: trip.items.map((item) => item.attractionId).toSet(),
        ),
      ),
    );
    if (attraction == null) return;

    try {
      await _tripService.addAttraction(
        tripId: trip.id,
        attractionId: attraction.id,
      );
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${attraction.name} added to the trip.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _removeItem(Trip trip, TripItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove attraction?'),
        content: Text('Remove ${item.attractionName} from this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _tripService.removeAttraction(tripId: trip.id, itemId: item.id);
      if (mounted) _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _organize(Trip trip) async {
    final updates = await Navigator.of(context).push<List<ItineraryUpdate>>(
      MaterialPageRoute(builder: (_) => _ItineraryOrganizerScreen(trip: trip)),
    );
    if (updates == null) return;

    try {
      await _tripService.updateItinerary(tripId: trip.id, items: updates);
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Itinerary updated successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Trip>(
      future: _tripFuture,
      builder: (context, snapshot) {
        final trip = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(trip?.title ?? 'Trip Details'),
            actions: [
              if (trip != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _edit(trip);
                    if (value == 'delete') _delete(trip);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit trip')),
                    PopupMenuItem(value: 'delete', child: Text('Delete trip')),
                  ],
                ),
            ],
          ),
          body: _buildBody(snapshot),
          floatingActionButton: trip == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _addAttraction(trip),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Add Attraction'),
                ),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<Trip> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return _DetailStateView(
        message: snapshot.error.toString(),
        onRetry: () => _refresh(),
      );
    }

    final trip = snapshot.data!;
    final groups = _groupItems(trip);

    return RefreshIndicator(
      onRefresh: () async {
        _refresh();
        await _tripFuture;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.date_range_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${formatApiDate(trip.startDate)} — '
                          '${formatApiDate(trip.endDate)}',
                        ),
                      ),
                    ],
                  ),
                  if (trip.notes != null) ...[
                    const SizedBox(height: 12),
                    Text(trip.notes!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Itinerary',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (trip.items.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _organize(trip),
                  icon: const Icon(Icons.reorder),
                  label: const Text('Organize'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (trip.items.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.route_outlined, size: 52),
                    SizedBox(height: 10),
                    Text('No attractions in this trip yet.'),
                  ],
                ),
              ),
            )
          else
            for (final group in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Text(
                  group.key,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              for (final item in group.value)
                Card(
                  child: ListTile(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AttractionDetailScreen(
                          attractionId: item.attractionId,
                        ),
                      ),
                    ),
                    leading: CircleAvatar(
                      child: Text('${item.sequenceNumber}'),
                    ),
                    title: Text(item.attractionName),
                    subtitle: Text(
                      [
                        item.stateName,
                        item.categoryName,
                        if (item.visitTime != null)
                          _displayTime(item.visitTime!),
                      ].join(' • '),
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove attraction',
                      onPressed: () => _removeItem(trip, item),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                  ),
                ),
            ],
        ],
      ),
    );
  }

  Map<String, List<TripItem>> _groupItems(Trip trip) {
    final groups = <String, List<TripItem>>{};
    for (final item in trip.items) {
      final key = item.visitDate == null
          ? 'Unscheduled'
          : 'Day ${item.visitDate!.difference(DateUtils.dateOnly(trip.startDate)).inDays + 1} • ${formatApiDate(item.visitDate!)}';
      groups.putIfAbsent(key, () => <TripItem>[]).add(item);
    }
    return groups;
  }

  String _displayTime(String time) {
    return time.length >= 5 ? time.substring(0, 5) : time;
  }
}

class _AttractionPickerScreen extends StatefulWidget {
  const _AttractionPickerScreen({required this.excludedIds});

  final Set<int> excludedIds;

  @override
  State<_AttractionPickerScreen> createState() =>
      _AttractionPickerScreenState();
}

class _AttractionPickerScreenState extends State<_AttractionPickerScreen> {
  final _service = const AttractionService();
  final _searchController = TextEditingController();
  late Future<List<Attraction>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _service.getAttractions(search: _searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Attraction')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => setState(_load),
              decoration: InputDecoration(
                hintText: 'Search attractions',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () => setState(_load),
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Attraction>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _DetailStateView(
                    message: snapshot.error.toString(),
                    onRetry: () => setState(_load),
                  );
                }
                final attractions = (snapshot.data ?? const <Attraction>[])
                    .where((item) => !widget.excludedIds.contains(item.id))
                    .toList();
                if (attractions.isEmpty) {
                  return const Center(child: Text('No attractions available.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                  itemCount: attractions.length,
                  itemBuilder: (_, index) {
                    final attraction = attractions[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.landscape_outlined),
                        ),
                        title: Text(attraction.name),
                        subtitle: Text(
                          '${attraction.stateName} • ${attraction.categoryName}',
                        ),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => Navigator.pop(context, attraction),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ItineraryOrganizerScreen extends StatefulWidget {
  const _ItineraryOrganizerScreen({required this.trip});

  final Trip trip;

  @override
  State<_ItineraryOrganizerScreen> createState() =>
      _ItineraryOrganizerScreenState();
}

class _ItineraryOrganizerScreenState extends State<_ItineraryOrganizerScreen> {
  late final List<_ItineraryDraft> _items;
  late final List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _items = widget.trip.items
        .map((item) => _ItineraryDraft(item: item, date: item.visitDate))
        .toList();
    _dates = [];
    var date = widget.trip.startDate;
    while (!date.isAfter(widget.trip.endDate)) {
      _dates.add(date);
      date = date.add(const Duration(days: 1));
    }
  }

  void _move(int index, int offset) {
    final target = index + offset;
    if (target < 0 || target >= _items.length) return;
    setState(() {
      final item = _items.removeAt(index);
      _items.insert(target, item);
    });
  }

  void _save() {
    final sequences = <String, int>{};
    final updates = _items.map((draft) {
      final key = draft.date == null
          ? 'unscheduled'
          : formatApiDate(draft.date!);
      final sequence = (sequences[key] ?? 0) + 1;
      sequences[key] = sequence;
      return ItineraryUpdate(
        itemId: draft.item.id,
        visitDate: draft.date,
        visitTime: draft.date == null ? null : draft.item.visitTime,
        sequenceNumber: sequence,
      );
    }).toList();
    Navigator.of(context).pop(updates);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organize Itinerary'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final draft = _items[index];
          return Card(
            key: ValueKey(draft.item.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
              child: Row(
                children: [
                  const Icon(Icons.drag_handle),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.item.attractionName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<DateTime?>(
                          initialValue: draft.date,
                          decoration: const InputDecoration(
                            labelText: 'Trip day',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<DateTime?>(
                              value: null,
                              child: Text('Unscheduled'),
                            ),
                            ..._dates.map(
                              (date) => DropdownMenuItem<DateTime?>(
                                value: date,
                                child: Text(formatApiDate(date)),
                              ),
                            ),
                          ],
                          onChanged: (date) =>
                              setState(() => draft.date = date),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: index == 0 ? null : () => _move(index, -1),
                        icon: const Icon(Icons.keyboard_arrow_up),
                      ),
                      IconButton(
                        onPressed: index == _items.length - 1
                            ? null
                            : () => _move(index, 1),
                        icon: const Icon(Icons.keyboard_arrow_down),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ItineraryDraft {
  _ItineraryDraft({required this.item, required this.date});

  final TripItem item;
  DateTime? date;
}

class _DetailStateView extends StatelessWidget {
  const _DetailStateView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
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
