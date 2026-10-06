import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class PartnerState {
  final bool isLoading;
  final List<dynamic> partners;
  final String? error;

  const PartnerState({
    this.isLoading = false,
    this.partners = const [],
    this.error,
  });

  PartnerState copyWith({
    bool? isLoading,
    List<dynamic>? partners,
    String? error,
  }) {
    return PartnerState(
      isLoading: isLoading ?? this.isLoading,
      partners: partners ?? this.partners,
      error: error ?? this.error,
    );
  }
}

class PartnerNotifier extends Notifier<PartnerState> {
  @override
  PartnerState build() {
    return const PartnerState();
  }

  Future<void> fetchPartners({String? type}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final endpoint = type != null ? '/partners?type=$type' : '/partners';
      final response = await ref.read(apiClientProvider).get(endpoint);
      state = state.copyWith(isLoading: false, partners: response is List ? response : []);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createPartner(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(apiClientProvider).post('/partners', data);
      await fetchPartners();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final partnerProvider = NotifierProvider<PartnerNotifier, PartnerState>(PartnerNotifier.new);
