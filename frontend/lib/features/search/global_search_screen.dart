import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

class SearchState {
  final String query;
  final bool isLoading;
  final List<Map<String, dynamic>> results;
  final String? error;
  const SearchState({this.query = '', this.isLoading = false, this.results = const [], this.error});
  SearchState copyWith({String? query, bool? isLoading, List<Map<String, dynamic>>? results, String? error}) {
    return SearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      error: error,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  Future<void> search(String query) async {
    if (query.trim().length < 2) {
      state = const SearchState();
      return;
    }
    state = state.copyWith(query: query, isLoading: true, results: [], error: null);
    try {
      final data = await ref.read(apiClientProvider).get('/search?q=${Uri.encodeComponent(query)}');
      if (data == null) {
        state = state.copyWith(isLoading: false, results: []);
        return;
      }
      final results = <Map<String, dynamic>>[];
      // Handle multi-section response {projects:[], inventory:[], vendors:[], tasks:[]}
      void _addSection(String type, dynamic raw, {String? nameKey, String? subtitleKey}) {
        if (raw is List) {
          for (final item in raw) {
            results.add({
              'type': type,
              'id': item['id']?.toString() ?? '',
              'title': item[nameKey ?? 'name']?.toString() ?? item['title']?.toString() ?? 'Untitled',
              'subtitle': item[subtitleKey ?? 'description']?.toString() ?? item['status']?.toString() ?? type,
              'raw': item,
            });
          }
        }
      }
      _addSection('Project', data['projects'], nameKey: 'name', subtitleKey: 'location');
      _addSection('Inventory', data['inventory'], nameKey: 'item_name', subtitleKey: 'category');
      _addSection('Vendor', data['vendors'], nameKey: 'company_name', subtitleKey: 'category');
      _addSection('Task', data['tasks'], nameKey: 'title', subtitleKey: 'status');
      _addSection('Invoice', data['invoices'], nameKey: 'invoice_number', subtitleKey: 'status');
      _addSection('Worker', data['workers'], nameKey: 'name', subtitleKey: 'skill_category');
      // flat list fallback
      if (results.isEmpty && data['results'] is List) {
        for (final item in data['results']) {
          results.add({'type': item['type'] ?? 'Result', 'id': item['id']?.toString() ?? '', 'title': item['title'] ?? '', 'subtitle': item['subtitle'] ?? ''});
        }
      }
      state = state.copyWith(isLoading: false, results: results);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() => state = const SearchState();
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);

// ─── Screen ───────────────────────────────────────────────────────────────────

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  final _routes = {
    'Project': '/projects',
    'Inventory': '/inventory',
    'Vendor': '/vendors',
    'Task': '/work_orders',
    'Invoice': '/bills',
    'Worker': '/labor',
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final r in state.results) {
      grouped.putIfAbsent(r['type'] as String, () => []).add(r);
    }

    return Scaffold(
      backgroundColor: CivilTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar header
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              color: CivilTheme.surface,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focusNode,
                      style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search projects, inventory, vendors…',
                        hintStyle: const TextStyle(color: CivilTheme.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: CivilTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: CivilTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: CivilTheme.primary),
                        ),
                        filled: true,
                        fillColor: CivilTheme.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        prefixIcon: state.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: CivilTheme.primary)),
                              )
                            : const Icon(Icons.search, color: CivilTheme.textSecondary),
                        suffixIcon: _ctrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, color: CivilTheme.textSecondary),
                                onPressed: () {
                                  _ctrl.clear();
                                  ref.read(searchProvider.notifier).clear();
                                },
                              )
                            : null,
                      ),
                      onChanged: (q) {
                        setState(() {});
                        ref.read(searchProvider.notifier).search(q);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: CivilTheme.border),

            // Results
            Expanded(
              child: state.query.isEmpty
                  ? _buildEmptyState()
                  : state.isLoading
                      ? const Center(child: CircularProgressIndicator(color: CivilTheme.primary))
                      : state.results.isEmpty
                          ? _buildNoResults(state.query)
                          : ListView(
                              padding: const EdgeInsets.only(bottom: 24),
                              children: grouped.entries.map((entry) {
                                return _buildSection(entry.key, entry.value);
                              }).toList(),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String type, List<Map<String, dynamic>> items) {
    final (icon, color) = _typeStyle(type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(type.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Text('${items.length}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        ...items.map((item) => _buildResultTile(item, icon, color)),
      ],
    );
  }

  Widget _buildResultTile(Map<String, dynamic> item, IconData icon, Color color) {
    final route = _routes[item['type'] as String];
    return ListTile(
      onTap: route != null ? () { Navigator.pop(context); context.push(route); } : null,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: _buildHighlightedText(item['title'] as String, ref.watch(searchProvider).query),
      subtitle: item['subtitle'] != null && (item['subtitle'] as String).isNotEmpty
          ? Text(item['subtitle'] as String, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 12))
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: CivilTheme.textSecondary),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) return Text(text, style: const TextStyle(color: CivilTheme.textPrimary));
    final lc = text.toLowerCase();
    final idx = lc.indexOf(query.toLowerCase());
    if (idx < 0) return Text(text, style: const TextStyle(color: CivilTheme.textPrimary));
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 14),
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: const TextStyle(backgroundColor: Color(0x33667EEA), color: Color(0xFF667EEA), fontWeight: FontWeight.bold),
          ),
          TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final suggestions = ['Bridge', 'Cement', 'Reliance', 'Invoice', 'Plumber', 'Project'];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.search, size: 80, color: CivilTheme.border),
        const SizedBox(height: 16),
        const Text('Search across everything', style: TextStyle(color: CivilTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Projects, inventory, vendors, workers, invoices…', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: suggestions.map((s) => GestureDetector(
            onTap: () { _ctrl.text = s; ref.read(searchProvider.notifier).search(s); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: CivilTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: CivilTheme.border),
              ),
              child: Text(s, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: CivilTheme.border),
          const SizedBox(height: 16),
          Text('No results for "$query"', style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Try a different search term', style: TextStyle(color: CivilTheme.textSecondary)),
        ],
      ),
    );
  }

  (IconData, Color) _typeStyle(String type) {
    switch (type) {
      case 'Project': return (Icons.business, Colors.blueAccent);
      case 'Inventory': return (Icons.inventory_2, Colors.orangeAccent);
      case 'Vendor': return (Icons.store, Colors.purpleAccent);
      case 'Task': return (Icons.task_alt, Colors.tealAccent);
      case 'Invoice': return (Icons.receipt_long, Colors.greenAccent);
      case 'Worker': return (Icons.people, Colors.cyanAccent);
      default: return (Icons.search, CivilTheme.primary);
    }
  }
}
