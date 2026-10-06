import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/auth_provider.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  Timer? _pollingTimer;
  List<dynamic> _supervisorLocations = [];
  bool _isLoading = true;
  String _error = '';
  static const _defaultCenter = LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    _fetchLocations();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchLocations();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocations() async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/location/supervisors');

      if (mounted) {
        setState(() {
          _supervisorLocations = response ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Supervisor Tracking'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchLocations();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _supervisorLocations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty && _supervisorLocations.isEmpty) {
      return Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));
    }

    if (_supervisorLocations.isEmpty) {
      return FlutterMap(
        options: MapOptions(
          initialCenter: _defaultCenter,
          initialZoom: 5.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.frontend',
          ),
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution('OpenStreetMap contributors'),
            ],
          ),
        ],
      );
    }

    final markers = _supervisorLocations.map<Marker>((loc) {
      final lat = (loc['latitude'] ?? 0.0).toDouble();
      final lng = (loc['longitude'] ?? 0.0).toDouble();
      final name = loc['name'] ?? 'Supervisor';
      return Marker(
        point: LatLng(lat, lng),
        width: 80,
        height: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_pin_circle, color: Colors.blue, size: 36),
            Text(name, style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }).toList();

    final avgLat = markers.isNotEmpty
        ? _supervisorLocations.map((l) => (l['latitude'] ?? 0.0).toDouble()).reduce((a, b) => a + b) / markers.length
        : _defaultCenter.latitude;
    final avgLng = markers.isNotEmpty
        ? _supervisorLocations.map((l) => (l['longitude'] ?? 0.0).toDouble()).reduce((a, b) => a + b) / markers.length
        : _defaultCenter.longitude;

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(avgLat, avgLng),
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.frontend',
        ),
        MarkerLayer(markers: markers),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}
