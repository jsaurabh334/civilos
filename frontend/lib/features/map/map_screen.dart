import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  List<Map<String, dynamic>> _markers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMarkers();
  }

  Future<void> _fetchMarkers() async {
    setState(() => _isLoading = true);
    try {
      final response = await ref.read(apiClientProvider).get('/map/projects');
      if (response is Map && response['markers'] is List) {
        setState(() => _markers = List<Map<String, dynamic>>.from(response['markers']));
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CivilTheme.background,
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: _markers.isNotEmpty
                        ? LatLng(
                            (_markers.map((m) => (m['lat'] as num).toDouble()).reduce((a, b) => a + b) /
                                _markers.length),
                            (_markers.map((m) => (m['lng'] as num).toDouble()).reduce((a, b) => a + b) /
                                _markers.length),
                          )
                        : const LatLng(20.5937, 78.9629),
                    initialZoom: 5.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.civilos.app',
                    ),
                    MarkerLayer(
                      markers: _markers.map((m) {
                        final lat = (m['lat'] as num).toDouble();
                        final lng = (m['lng'] as num).toDouble();
                        final status = m['status']?.toString() ?? 'Active';
                        final name = m['name']?.toString() ?? 'Project';
                        final budget = (m['budget'] as num?) ?? 0;

                        Color pinColor;
                        switch (status) {
                          case 'Active':
                          case 'In Progress':
                            pinColor = Colors.green;
                            break;
                          case 'Completed':
                            pinColor = Colors.blue;
                            break;
                          case 'On Hold':
                            pinColor = Colors.orange;
                            break;
                          default:
                            pinColor = Colors.grey;
                        }

                        return Marker(
                          point: LatLng(lat, lng),
                          width: 200,
                          height: 80,
                          child: GestureDetector(
                            onTap: () => _showProjectPopup(context, name, status, budget),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(name,
                                      style: const TextStyle(color: Colors.white, fontSize: 10),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(height: 2),
                                Icon(Icons.location_on, color: pinColor, size: 32),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Project Map',
                          style: TextStyle(
                              color: CivilTheme.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: CivilTheme.primary),
                        onPressed: _fetchMarkers,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildLegend(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _legendItem(Colors.green, 'Active'),
        const SizedBox(width: 12),
        _legendItem(Colors.blue, 'Completed'),
        const SizedBox(width: 12),
        _legendItem(Colors.orange, 'On Hold'),
        const SizedBox(width: 12),
        _legendItem(Colors.grey, 'Other'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: color, size: 10),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 11)),
      ],
    );
  }

  void _showProjectPopup(BuildContext context, String name, String status, num budget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CivilTheme.surface,
        title: Text(name, style: const TextStyle(color: CivilTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $status', style: const TextStyle(color: CivilTheme.textSecondary)),
            const SizedBox(height: 4),
            Text('Budget: ₹${(budget / 10000000).toStringAsFixed(2)} Cr',
                style: const TextStyle(color: CivilTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: CivilTheme.primary)),
          ),
        ],
      ),
    );
  }
}
