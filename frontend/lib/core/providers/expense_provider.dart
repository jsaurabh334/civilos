import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class ExpenseState {
  final bool isLoading;
  final List<dynamic> expenses;

  const ExpenseState({this.isLoading = false, this.expenses = const []});

  ExpenseState copyWith({bool? isLoading, List<dynamic>? expenses}) {
    return ExpenseState(
      isLoading: isLoading ?? this.isLoading,
      expenses: expenses ?? this.expenses,
    );
  }
}

class ExpenseNotifier extends Notifier<ExpenseState> {
  @override
  ExpenseState build() => const ExpenseState();

  Future<void> fetchExpenses() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(apiClientProvider).get('/expenses');
      state = state.copyWith(
        isLoading: false,
        expenses: response is List ? response : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> createExpense(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/expenses', data);
      await fetchExpenses();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateExpense(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).put('/expenses/$id', data);
      await fetchExpenses();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteExpense(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).delete('/expenses/$id');
      await fetchExpenses();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final expenseProvider = NotifierProvider<ExpenseNotifier, ExpenseState>(() => ExpenseNotifier());
