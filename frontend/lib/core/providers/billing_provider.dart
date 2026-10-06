import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class BillingState {
  final bool isLoading;
  final List<dynamic> invoices;

  const BillingState({this.isLoading = false, this.invoices = const []});

  BillingState copyWith({bool? isLoading, List<dynamic>? invoices}) {
    return BillingState(
      isLoading: isLoading ?? this.isLoading,
      invoices: invoices ?? this.invoices,
    );
  }
}

class BillingNotifier extends Notifier<BillingState> {
  @override
  BillingState build() => const BillingState();

  Future<void> fetchInvoices({String? status, String? dateRange}) async {
    state = state.copyWith(isLoading: true);
    try {
      final params = <String, String>{};
      if (status != null && status != 'All') params['status'] = status;
      if (dateRange != null && dateRange != 'All') params['date_range'] = dateRange;
      final response = await ref.read(apiClientProvider).get('/invoices', params: params);
      state = state.copyWith(
        isLoading: false,
        invoices: response is List ? response : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> createInvoice(
    int projectId,
    String invoiceNumber,
    String clientName,
    String issueDate,
    String dueDate,
    double totalAmount,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/invoices', {
        'project_id': projectId,
        'invoice_number': invoiceNumber,
        'client_name': clientName,
        'issue_date': issueDate,
        'due_date': dueDate,
        'total_amount': totalAmount,
      });
      await fetchInvoices();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateInvoice(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).put('/invoices/$id', data);
      await fetchInvoices();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> recordPayment(
    int invoiceId,
    double amount,
    String paymentDate,
    String paymentMethod,
    String referenceNo,
    String notes,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/invoices/$invoiceId/payments', {
        'amount': amount,
        'payment_date': paymentDate,
        'payment_method': paymentMethod,
        'reference_no': referenceNo,
        'notes': notes,
      });
      await fetchInvoices();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final billingProvider = NotifierProvider<BillingNotifier, BillingState>(() => BillingNotifier());
