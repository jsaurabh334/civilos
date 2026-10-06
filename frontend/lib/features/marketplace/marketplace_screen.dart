import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import '../../core/providers/marketplace_provider.dart';
import '../../core/theme.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _searchController = TextEditingController();
  String _selectedTab = '';
  List<String> _tabs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(marketplaceProvider.notifier).fetchMarketplaceListings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mp = ref.watch(marketplaceProvider);
    final isMarketplaceEnabled =
        ref.watch(authProvider.notifier).isFeatureEnabled('marketplace');

    if (!isMarketplaceEnabled) {
      return const Scaffold(
        backgroundColor: CivilTheme.background,
        body: Center(
          child: Text('Marketplace Module Disabled',
              style: TextStyle(color: CivilTheme.textSecondary, fontSize: 18)),
        ),
      );
    }

    final List<dynamic> sourceListings = mp.listings;

    if (_tabs.isEmpty && sourceListings.isNotEmpty) {
      final cats = sourceListings.map((l) {
        final cat = (l['Category'] ?? l['category'] ?? 'Other').toString().toUpperCase();
        return cat;
      }).toSet().toList();
      if (cats.isEmpty) cats.addAll(['MATERIALS', 'EQUIPMENT', 'SERVICES']);
      _tabs = cats;
      if (_selectedTab.isEmpty) _selectedTab = _tabs.first;
    }

    final List<dynamic> displayListings = _selectedTab.isEmpty ? sourceListings : sourceListings.where((item) {
      final cat = (item['Category'] ?? item['category'] ?? '').toString().toUpperCase();
      return cat == _selectedTab;
    }).toList();

    return Scaffold(
      backgroundColor: CivilTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF222B38), Color(0xFF161F2E)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isMobile ? 600 : 1000),
                  child: Column(
                    children: [
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(Icons.menu,
                                        color: CivilTheme.textSecondary,
                                        size: 24),
                                  ),
                                  const Spacer(),
                                  const Text('MARKETPLACE',
                                      style: TextStyle(
                                          color: CivilTheme.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2)),
                                  const Spacer(),
                                  const Icon(Icons.notifications_none,
                                      color: CivilTheme.textSecondary,
                                      size: 20),
                                  const SizedBox(width: 12),
                                  const CircleAvatar(
                                      radius: 14,
                                      backgroundImage: NetworkImage(
                                          'https://ui-avatars.com/api/?name=User+11')),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: _tabs
                                    .map((tab) => _buildTab(tab, isMobile))
                                    .toList(),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      decoration: BoxDecoration(
                                        color:
                                            CivilTheme.surface.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: CivilTheme.border),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.search,
                                              color: CivilTheme.textSecondary,
                                              size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextField(
                                              controller: _searchController,
                                              style: const TextStyle(
                                                  color: CivilTheme.textPrimary,
                                                  fontSize: 14),
                                              decoration: const InputDecoration(
                                                hintText:
                                                    'Search Materials, Vendors, Location...',
                                                hintStyle: TextStyle(
                                                    color: CivilTheme
                                                        .textSecondary),
                                                border: InputBorder.none,
                                                isDense: true,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    height: 48,
                                    width: 48,
                                    decoration: BoxDecoration(
                                        color:
                                            CivilTheme.surface.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: CivilTheme.border)),
                                    child: const Icon(Icons.tune,
                                        color: CivilTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: isMobile
                            ? ListView.separated(
                                padding: const EdgeInsets.all(20),
                                itemCount: displayListings.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) =>
                                    _buildListingCard(displayListings[index]),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(20),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 450,
                                  mainAxisSpacing: 20,
                                  crossAxisSpacing: 20,
                                  childAspectRatio: 1.6,
                                ),
                                itemCount: displayListings.length,
                                itemBuilder: (context, index) =>
                                    _buildListingCard(displayListings[index]),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(String title, bool isMobile) {
    final isSelected = _selectedTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = title),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Colors.lightBlueAccent
                    : CivilTheme.textSecondary,
                fontSize: isMobile ? 12 : 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              color: isSelected ? Colors.lightBlueAccent : Colors.transparent,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    return Container(
      decoration: BoxDecoration(
        color: CivilTheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.lightBlueAccent.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.lightBlueAccent.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: -5)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: CivilTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CivilTheme.border),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: CivilTheme.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing['title'] ?? '',
                        style: const TextStyle(
                            color: CivilTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text('by ${listing['tenant']?['name'] ?? 'Vendor'}',
                          style: const TextStyle(
                              color: CivilTheme.textSecondary, fontSize: 11)),
                      const SizedBox(height: 6),
                      Text(listing['description'] ?? '',
                          style: const TextStyle(
                              color: CivilTheme.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('STOCK: ',
                              style: TextStyle(
                                  color: CivilTheme.textSecondary,
                                  fontSize: 10)),
                          Text('${listing['stock'] ?? 'N/A'}',
                              style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                          const Text(' | ',
                              style: TextStyle(
                                  color: CivilTheme.border, fontSize: 10)),
                          const Text('LOCATION: ',
                              style: TextStyle(
                                  color: CivilTheme.textSecondary,
                                  fontSize: 10)),
                          Expanded(
                              child: Text('${listing['location'] ?? 'N/A'}',
                                  style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '\$${((listing['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)} ',
                            style: const TextStyle(
                                color: CivilTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          Text('/ ${listing['unit']}',
                              style: const TextStyle(
                                  color: CivilTheme.textSecondary,
                                  fontSize: 12)),
                          const Spacer(),
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${listing['rating']} (${listing['reviews']} Reviews)',
                            style: const TextStyle(
                                color: CivilTheme.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: CivilTheme.border, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white,
                      child: Text((listing['tenant']?['name'] ?? 'V')[0],
                          style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('VENDOR:',
                            style: TextStyle(
                                color: CivilTheme.textSecondary, fontSize: 9)),
                        Text(listing['tenant']?['name'] ?? 'Vendor',
                            style: const TextStyle(
                                color: CivilTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.lightBlueAccent),
                  ),
                  child: const Text('Add to Cart',
                      style: TextStyle(
                          color: Colors.lightBlueAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
