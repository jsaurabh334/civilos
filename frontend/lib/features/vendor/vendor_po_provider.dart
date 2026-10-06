import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';

class VendorPO {
  final int id;
  final String itemName;
  final double quantity;
  final String unit;
  final double totalCost;
  final String status;
  final String orderDate;
  
  VendorPO({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.totalCost,
    required this.status,
    required this.orderDate,
  });

  factory VendorPO.fromJson(Map<String, dynamic> json) {
    return VendorPO(
      id: json['id'],
      itemName: json['item_name'] ?? 'Unknown Item',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'unit',
      totalCost: (json['total_cost'] ?? 0).toDouble(),
      status: json['status'] ?? 'Issued',
      orderDate: json['order_date'] ?? '',
    );
  }
}

class VendorPONotifier extends AsyncNotifier<List<VendorPO>> {
  @override
  Future<List<VendorPO>> build() async {
    return _fetchPOs();
  }

  Future<List<VendorPO>> _fetchPOs() async {
    final client = ref.read(apiClientProvider);
    final response = await client.get('/vendor/purchase-orders');
    
    if (response != null) {
      final List<dynamic> data = response;
      return data.map((e) => VendorPO.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> fetchPOs() async {
    state = const AsyncValue.loading();
    try {
      final pos = await _fetchPOs();
      state = AsyncValue.data(pos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(int poId, String newStatus) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.put('/vendor/purchase-orders/$poId/status', {'status': newStatus});
      await fetchPOs(); // Refresh
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitInvoice(int poId, double amount, String notes) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.post('/vendor/purchase-orders/$poId/invoice', {
        'amount': amount,
        'notes': notes,
      });
      await fetchPOs(); // Refresh
    } catch (e) {
      rethrow;
    }
  }
}

final vendorPOsProvider = AsyncNotifierProvider<VendorPONotifier, List<VendorPO>>(() {
  return VendorPONotifier();
});
