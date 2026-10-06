import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class InventoryState {
  final bool isLoading;
  final List<dynamic> items;

  const InventoryState({this.isLoading = false, this.items = const []});

  InventoryState copyWith({bool? isLoading, List<dynamic>? items}) {
    return InventoryState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
    );
  }
}

class InventoryNotifier extends Notifier<InventoryState> {
  @override
  InventoryState build() => const InventoryState();

  Future<void> fetchInventory() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(apiClientProvider).get('/inventory');
      state = state.copyWith(
        isLoading: false,
        items: response is List ? response : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> createInventoryItem(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/inventory', data);
      await fetchInventory();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateInventoryItem(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).put('/inventory/$id', data);
      await fetchInventory();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteInventoryItem(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).delete('/inventory/$id');
      await fetchInventory();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> recordInventoryTransaction(
    int itemId,
    String type,
    double quantity,
    String reference,
    String notes,
    String date, {
    String? ewayBillNumber,
    String? ewayBillDocument,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/inventory/transactions', {
        'inventory_item_id': itemId,
        'type': type,
        'quantity': quantity,
        'reference': reference,
        'notes': notes,
        'transaction_date': date,
        if (ewayBillNumber != null && ewayBillNumber.isNotEmpty) 'eway_bill_number': ewayBillNumber,
        if (ewayBillDocument != null && ewayBillDocument.isNotEmpty) 'eway_bill_document': ewayBillDocument,
      });
      await fetchInventory();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final inventoryProvider = NotifierProvider<InventoryNotifier, InventoryState>(() => InventoryNotifier());
