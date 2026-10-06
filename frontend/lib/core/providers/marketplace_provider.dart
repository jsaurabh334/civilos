import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class MarketplaceState {
  final bool isLoading;
  final List<dynamic> listings;
  final List<dynamic> partners;

  const MarketplaceState({
    this.isLoading = false,
    this.listings = const [],
    this.partners = const [],
  });

  MarketplaceState copyWith({
    bool? isLoading,
    List<dynamic>? listings,
    List<dynamic>? partners,
  }) {
    return MarketplaceState(
      isLoading: isLoading ?? this.isLoading,
      listings: listings ?? this.listings,
      partners: partners ?? this.partners,
    );
  }
}

class MarketplaceNotifier extends Notifier<MarketplaceState> {
  @override
  MarketplaceState build() => const MarketplaceState();

  Future<void> fetchMarketplaceListings({String? category}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final path = category != null && category.isNotEmpty ? '/marketplace?category=$category' : '/marketplace';
      final response = await ref.read(apiClientProvider).get(path);
      state = state.copyWith(
        isLoading: false,
        listings: response is List ? response : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> createMarketplaceListing(
    String category,
    String title,
    String description,
    double qty,
    double price,
    String unit,
    String contact,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/marketplace', {
        'category': category,
        'title': title,
        'description': description,
        'quantity': qty,
        'price': price,
        'unit': unit,
        'contact_info': contact,
      });
      await fetchMarketplaceListings();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateMarketplaceListing(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).put('/marketplace/$id', data);
      await fetchMarketplaceListings();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteMarketplaceListing(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).delete('/marketplace/$id');
      await fetchMarketplaceListings();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> fetchB2BPartners({String? type}) async {
    state = state.copyWith(isLoading: true);
    try {
      final path = type != null && type.isNotEmpty ? '/marketplace/partners?type=$type' : '/marketplace/partners';
      final response = await ref.read(apiClientProvider).get(path);
      state = state.copyWith(
        isLoading: false,
        partners: response is List ? response : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> createB2BPartner(
    String name,
    String type,
    String services,
    String location,
    String contact,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/marketplace/partners', {
        'name': name,
        'type': type,
        'services': services,
        'location': location,
        'contact_info': contact,
      });
      await fetchB2BPartners();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateB2BPartner(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).put('/marketplace/partners/$id', data);
      await fetchB2BPartners();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteB2BPartner(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).delete('/marketplace/partners/$id');
      await fetchB2BPartners();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final marketplaceProvider = NotifierProvider<MarketplaceNotifier, MarketplaceState>(() => MarketplaceNotifier());
