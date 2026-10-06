import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    return results.isNotEmpty && results.first != ConnectivityResult.none;
  });
});

class SyncQueueItem {
  final String id;
  final String method;
  final String path;
  final Map<String, dynamic>? body;
  final DateTime createdAt;

  SyncQueueItem({
    required this.id,
    required this.method,
    required this.path,
    this.body,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'method': method,
    'path': path,
    'body': body,
    'created_at': createdAt.toIso8601String(),
  };

  static SyncQueueItem fromJson(Map<String, dynamic> json) => SyncQueueItem(
    id: json['id'] as String,
    method: json['method'] as String,
    path: json['path'] as String,
    body: json['body'] as Map<String, dynamic>?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class OfflineSyncService {
  static const _boxName = 'offline_sync';
  static const _cacheBoxName = 'api_cache';
  static const int _maxQueueSize = 500;
  late Box _syncBox;
  late Box _cacheBox;
  final _connectivity = Connectivity();
  StreamSubscription? _connectivitySub;
  final _onSyncComplete = StreamController<bool>.broadcast();

  Stream<bool> get onSyncComplete => _onSyncComplete.stream;

  static final OfflineSyncService _instance = OfflineSyncService._();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._();

  Future<void> initialize() async {
    await Hive.openBox(_boxName);
    await Hive.openBox(_cacheBoxName);
    _syncBox = Hive.box(_boxName);
    _cacheBox = Hive.box(_cacheBoxName);

    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        processQueue();
      }
    });

    // Process any pending items on startup
    await processQueue();
  }

  bool get isOnline => _lastConnectivity != ConnectivityResult.none;
  ConnectivityResult _lastConnectivity = ConnectivityResult.wifi;

  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _lastConnectivity = results.isNotEmpty ? results.first : ConnectivityResult.none;
    return _lastConnectivity != ConnectivityResult.none;
  }

  void enqueue(String method, String path, {Map<String, dynamic>? body}) {
    final item = SyncQueueItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      method: method,
      path: path,
      body: body,
    );
    final items = _getQueue();
    items.add(item.toJson());
    if (items.length > _maxQueueSize) {
      items.removeRange(0, items.length - _maxQueueSize);
    }
    _syncBox.put('queue', jsonEncode(items));
  }

  List<Map<String, dynamic>> _getQueue() {
    final raw = _syncBox.get('queue', defaultValue: '[]') as String;
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(raw));
    } catch (_) {
      return [];
    }
  }

  Future<int> get queueLength async {
    return _getQueue().length;
  }

  Future<void> processQueue() async {
    final items = _getQueue();
    if (items.isEmpty) return;

    final client = ApiClient();
    final List<Map<String, dynamic>> failed = [];

    for (final itemJson in items) {
      final item = SyncQueueItem.fromJson(itemJson);
      try {
        switch (item.method.toUpperCase()) {
          case 'POST':
            await client.post(item.path, item.body ?? {});
            break;
          case 'PUT':
            await client.put(item.path, item.body ?? {});
            break;
          case 'DELETE':
            await client.delete(item.path);
            break;
        }
      } catch (e) {
        final failedItem = Map<String, dynamic>.from(itemJson);
        if (e is ApiException && e.statusCode == 409) {
          failedItem['conflict'] = true;
        }
        failed.add(failedItem);
      }
    }

    _syncBox.put('queue', jsonEncode(failed));
    _onSyncComplete.add(failed.isEmpty);
  }

  void cacheResponse(String key, dynamic data) {
    _cacheBox.put(key, jsonEncode({
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  dynamic getCachedResponse(String key, {Duration maxAge = const Duration(minutes: 5)}) {
    final raw = _cacheBox.get(key);
    if (raw == null) return null;
    try {
      final cached = jsonDecode(raw as String);
      final timestamp = DateTime.parse(cached['timestamp'] as String);
      if (DateTime.now().difference(timestamp) > maxAge) return null;
      return cached['data'];
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    _onSyncComplete.close();
  }
}
