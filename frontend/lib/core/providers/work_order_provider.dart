import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class WorkOrderState {
  final bool isLoading;
  final List<dynamic> workOrders;

  const WorkOrderState({this.isLoading = false, this.workOrders = const []});

  WorkOrderState copyWith({bool? isLoading, List<dynamic>? workOrders}) {
    return WorkOrderState(
      isLoading: isLoading ?? this.isLoading,
      workOrders: workOrders ?? this.workOrders,
    );
  }
}

class WorkOrderNotifier extends Notifier<WorkOrderState> {
  @override
  WorkOrderState build() => const WorkOrderState();

  Future<void> fetchWorkOrders() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(apiClientProvider).get('/work-orders');
      state = state.copyWith(
        isLoading: false,
        workOrders: response is List ? response : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> createWorkOrder(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/work-orders', data);
      await fetchWorkOrders();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateWorkOrderStatus(int id, String status) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).put('/work-orders/$id/status', {'status': status});
      await fetchWorkOrders();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteWorkOrder(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).delete('/work-orders/$id');
      await fetchWorkOrders();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final workOrderProvider = NotifierProvider<WorkOrderNotifier, WorkOrderState>(() => WorkOrderNotifier());
