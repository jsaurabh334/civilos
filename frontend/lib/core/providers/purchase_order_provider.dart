import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class PurchaseOrderState {
  final bool isLoading;
  final List<dynamic> purchaseOrders;

  const PurchaseOrderState({this.isLoading = false, this.purchaseOrders = const []});

  PurchaseOrderState copyWith({bool? isLoading, List<dynamic>? purchaseOrders}) {
    return PurchaseOrderState(
      isLoading: isLoading ?? this.isLoading,
      purchaseOrders: purchaseOrders ?? this.purchaseOrders,
    );
  }
}

class PurchaseOrderNotifier extends Notifier<PurchaseOrderState> {
  @override
  PurchaseOrderState build() => const PurchaseOrderState();

  Future<void> fetchPurchaseOrders() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(apiClientProvider).get('/purchase-orders');
      state = state.copyWith(
        isLoading: false,
        purchaseOrders: response is List ? response : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> createPurchaseOrder(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/purchase-orders', data);
      await fetchPurchaseOrders();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updatePurchaseOrderStatus(int id, String status) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).put('/purchase-orders/$id/status', {'status': status});
      await fetchPurchaseOrders();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> deletePurchaseOrder(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).delete('/purchase-orders/$id');
      await fetchPurchaseOrders();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final purchaseOrderProvider = NotifierProvider<PurchaseOrderNotifier, PurchaseOrderState>(() => PurchaseOrderNotifier());
