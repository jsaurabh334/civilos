import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';

class GlobalVendor {
  final int id;
  final String name;
  final String email;
  final String verificationStatus;
  final String createdAt;

  GlobalVendor({
    required this.id,
    required this.name,
    required this.email,
    required this.verificationStatus,
    required this.createdAt,
  });

  factory GlobalVendor.fromJson(Map<String, dynamic> json) {
    return GlobalVendor(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? 'Unknown',
      verificationStatus: json['verification_status'] ?? 'Pending',
      createdAt: json['created_at'] ?? '',
    );
  }
}

// Riverpod 3.x: Use Notifier instead of StateNotifier
class AdminVendorsNotifier extends Notifier<AsyncValue<List<GlobalVendor>>> {
  @override
  AsyncValue<List<GlobalVendor>> build() {
    fetchVendors();
    return const AsyncValue.loading();
  }

  Future<void> fetchVendors() async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/admin/vendors');

      if (response != null && response['data'] != null) {
        final List<dynamic> data = response['data'];
        final vendors = data.map((e) => GlobalVendor.fromJson(e)).toList();
        state = AsyncValue.data(vendors);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateVendorStatus(int id, String status) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.put('/admin/vendors/$id/status', {'verification_status': status});
      fetchVendors();
    } catch (e) {
      rethrow;
    }
  }
}

final adminVendorsProvider =
    NotifierProvider<AdminVendorsNotifier, AsyncValue<List<GlobalVendor>>>(
        AdminVendorsNotifier.new);

class PlatformSetting {
  final String key;
  final String value;

  PlatformSetting({required this.key, required this.value});

  factory PlatformSetting.fromJson(Map<String, dynamic> json) {
    return PlatformSetting(
      key: json['key'] ?? '',
      value: json['value'] ?? '',
    );
  }
}

// Riverpod 3.x: Use Notifier instead of StateNotifier
class AdminSettingsNotifier extends Notifier<AsyncValue<List<PlatformSetting>>> {
  @override
  AsyncValue<List<PlatformSetting>> build() {
    fetchSettings();
    return const AsyncValue.loading();
  }

  Future<void> fetchSettings() async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/admin/settings');

      if (response != null) {
        final List<dynamic> data = response;
        final settings = data.map((e) => PlatformSetting.fromJson(e)).toList();
        state = AsyncValue.data(settings);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSetting(String key, String value) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.put('/admin/settings', {'key': key, 'value': value});
      fetchSettings();
    } catch (e) {
      rethrow;
    }
  }
}

final adminSettingsProvider =
    NotifierProvider<AdminSettingsNotifier, AsyncValue<List<PlatformSetting>>>(
        AdminSettingsNotifier.new);
