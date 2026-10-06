import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../auth_provider.dart';

class CurrentTenderNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;
  void setTender(Map<String, dynamic>? tender) => state = tender;
}

final currentTenderProvider = NotifierProvider<CurrentTenderNotifier, Map<String, dynamic>?>(CurrentTenderNotifier.new);

class TenderState {
  final bool isLoading;
  final List<dynamic> tenders;
  final List<dynamic> bids;

  const TenderState({
    this.isLoading = false,
    this.tenders = const [],
    this.bids = const [],
  });

  TenderState copyWith({
    bool? isLoading,
    List<dynamic>? tenders,
    List<dynamic>? bids,
  }) {
    return TenderState(
      isLoading: isLoading ?? this.isLoading,
      tenders: tenders ?? this.tenders,
      bids: bids ?? this.bids,
    );
  }
}

class TenderNotifier extends Notifier<TenderState> {
  @override
  TenderState build() => const TenderState();

  Future<void> fetchTenders() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(apiClientProvider).get('/tenders');
      state = state.copyWith(
        isLoading: false,
        tenders: response is List ? response : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> createTender(
    String title,
    String description,
    String clientName,
    double budget,
    String closingDate,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/tenders', {
        'title': title,
        'description': description,
        'client_name': clientName,
        'budget': budget,
        'closing_date': closingDate,
      });
      await fetchTenders();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> importPdf(http.MultipartFile file) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).postMultipart('/tenders/import-pdf', file);
      await fetchTenders();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> fetchBids(int tenderId) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(apiClientProvider).get('/tenders/$tenderId/bids');
      state = state.copyWith(
        isLoading: false,
        bids: response is List ? response : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> submitBid(int tenderId, double amount, String proposal) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/tenders/$tenderId/bids', {
        'amount': amount,
        'proposal': proposal,
      });
      await fetchBids(tenderId);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final tenderProvider = NotifierProvider<TenderNotifier, TenderState>(() => TenderNotifier());
