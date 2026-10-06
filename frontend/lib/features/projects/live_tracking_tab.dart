import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import 'dart:async';

class LiveTrackingTab extends ConsumerStatefulWidget {
  final Map<String, dynamic> project;
  const LiveTrackingTab({super.key, required this.project});

  @override
  ConsumerState<LiveTrackingTab> createState() => _LiveTrackingTabState();
}

class _LiveTrackingTabState extends ConsumerState<LiveTrackingTab> {
  List<dynamic> _supervisors = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchLocations());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocations() async {
    try {
      final response = await ref.read(apiClientProvider).get('/location/supervisors');
      if (mounted) {
        setState(() {
          _supervisors = response ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Failed to fetch supervisor locations: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_supervisors.isEmpty) {
      return Center(
        child: Text(
          'No supervisors assigned to this project',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _supervisors.length,
      itemBuilder: (context, index) {
        final sup = _supervisors[index];
        final distanceKm = sup['distance_from_site_km'] as double;
        final isNear = distanceKm < 1.0;

        return Card(
          color: const Color(0xFF161B26),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isNear ? CivilTheme.secondary.withValues(alpha: 0.2) : CivilTheme.warning.withValues(alpha: 0.2),
              child: Icon(
                isNear ? Icons.check_circle : Icons.navigation,
                color: isNear ? CivilTheme.secondary : CivilTheme.warning,
              ),
            ),
            title: Text(sup['name'], style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              '${distanceKm.toStringAsFixed(2)} km from site • Last updated: ${sup['last_location_update']}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
