import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/offline_sync_service.dart';

class SyncStatusBar extends StatefulWidget {
  const SyncStatusBar({super.key});

  @override
  State<SyncStatusBar> createState() => _SyncStatusBarState();
}

class _SyncStatusBarState extends State<SyncStatusBar> {
  bool _isOnline = true;
  int _pendingCount = 0;
  StreamSubscription? _syncSub;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _syncSub = OfflineSyncService().onSyncComplete.listen((_) => _checkStatus());
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final svc = OfflineSyncService();
    final online = await svc.checkConnectivity();
    final pending = await svc.queueLength;
    if (mounted) {
      setState(() {
      _isOnline = online;
      _pendingCount = pending;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline && _pendingCount == 0) return const SizedBox.shrink();

    final message = !_isOnline
        ? 'You are offline — changes will sync when connected'
        : '$_pendingCount changes pending sync';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: !_isOnline ? Colors.orange.shade900 : Colors.blue.shade900,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            !_isOnline ? Icons.cloud_off : Icons.sync,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          if (!_isOnline) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
          ],
          if (!_isOnline && _pendingCount > 0) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => OfflineSyncService().processQueue(),
              child: const Text('SYNC', style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ],
        ],
      ),
    );
  }
}
