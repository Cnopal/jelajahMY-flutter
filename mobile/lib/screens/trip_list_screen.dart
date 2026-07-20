import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../services/trip_service.dart';
import 'trip_detail_screen.dart';
import 'trip_form_screen.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  final _tripService = TripService();
  late Future<List<Trip>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() {
    _tripsFuture = _tripService.getTrips();
  }

  void _refresh() => setState(_loadTrips);

  Future<void> _openCreate() async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const TripFormScreen()));
    if (changed == true && mounted) _refresh();
  }

  Future<void> _openTrip(Trip trip) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: trip.id)),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trips'),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Refresh trips',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
      ),
      body: FutureBuilder<List<Trip>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _TripStateView(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load trips',
              message: snapshot.error.toString(),
              buttonLabel: 'Try Again',
              onPressed: _refresh,
            );
          }

          final trips = snapshot.data ?? const <Trip>[];
          if (trips.isEmpty) {
            return _TripStateView(
              icon: Icons.luggage_outlined,
              title: 'No trips yet',
              message: 'Create your first Malaysian adventure.',
              buttonLabel: 'Create Trip',
              onPressed: _openCreate,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refresh();
              await _tripsFuture;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: trips.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final trip = trips[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _openTrip(trip),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            child: Text('${_days(trip)}d'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${formatApiDate(trip.startDate)} — '
                                  '${formatApiDate(trip.endDate)}',
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${trip.itemCount} itinerary item'
                                  '${trip.itemCount == 1 ? '' : 's'}',
                                  style: Theme.of(context).textTheme.bodySmall,
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
              },
            ),
          );
        },
      ),
    );
  }

  int _days(Trip trip) => trip.endDate.difference(trip.startDate).inDays + 1;
}

class _TripStateView extends StatelessWidget {
  const _TripStateView({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(icon, size: 72),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
