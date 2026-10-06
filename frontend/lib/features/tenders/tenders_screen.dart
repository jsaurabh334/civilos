import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../../core/providers/tender_provider.dart';
import '../../core/theme.dart';
import '../../shared/widgets/civil_scaffold.dart';

class TendersScreen extends ConsumerStatefulWidget {
  const TendersScreen({super.key});

  @override
  ConsumerState<TendersScreen> createState() => _TendersScreenState();
}

class _TendersScreenState extends ConsumerState<TendersScreen> {
  final _searchController = TextEditingController();
  String _selectedTab = 'Open';
  final List<String> _tabs = ['All', 'Open', 'Closed', 'My Bids'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tenderProvider.notifier).fetchTenders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tenderProv = ref.watch(tenderProvider);
    final tenders = tenderProv.tenders;
    final List<dynamic> displayTenders = tenders;

    return CivilScaffold(
      title: 'Tenders Board',
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: CivilTheme.textSecondary),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: CivilTheme.textSecondary),
          onPressed: () {},
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: CivilTheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CivilTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: CivilTheme.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search tenders...',
                        hintStyle: TextStyle(color: CivilTheme.textSecondary),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _tabs.map((tab) => _buildTab(tab)).toList(),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: displayTenders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _buildTenderCard(displayTenders[index]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            FilePickerResult? result = await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf'],
              withReadStream: true,
            );

            if (result != null && result.files.single.readStream != null) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Uploading and Analyzing PDF...')),
              );

              final file = result.files.single;
              final length = file.size;
              
              final multipartFile = http.MultipartFile(
                'pdf',
                file.readStream!,
                length,
                filename: file.name,
              );

              await ref.read(tenderProvider.notifier).importPdf(multipartFile);
              
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI Extraction Complete! Tender Draft Created.')),
              );
            }
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: $e')),
            );
          }
        },
        backgroundColor: CivilTheme.textPrimary,
        icon: const Icon(Icons.auto_awesome, color: CivilTheme.background),
        label: const Text('AI Import PDF', style: TextStyle(color: CivilTheme.background, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTab(String title) {
    final isSelected = _selectedTab == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? CivilTheme.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? CivilTheme.textPrimary : CivilTheme.border),
        ),
        child: Text(
          title,
          style: TextStyle(
            color:
                isSelected ? CivilTheme.background : CivilTheme.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTenderCard(Map<String, dynamic> tender) {
    final status = tender['status']?.toString().toUpperCase() ?? 'DRAFT';
    final isOpen = status != 'CLOSED' && status != 'AWARDED' && status != 'LOST' && status != 'CANCELLED';
    final glowColor = isOpen ? Colors.greenAccent : Colors.redAccent;

    return GestureDetector(
      onTap: () {
        ref.read(currentTenderProvider.notifier).setTender(tender);
        context.go('/tenders/${tender['id']}', extra: tender);
      },
      child: Container(
        decoration: BoxDecoration(
        color: CivilTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glowColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: glowColor.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 5)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tender['tender_name'] ?? 'Untitled Tender',
                        style: const TextStyle(
                            color: CivilTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: glowColor),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: glowColor.withValues(alpha: 0.2), blurRadius: 8)
                        ],
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                            color: glowColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Ref: ${tender['tender_no'] ?? 'N/A'}',
                    style: const TextStyle(
                        color: CivilTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Client: ${tender['department'] ?? 'N/A'}',
                    style: const TextStyle(
                        color: CivilTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Type: ${tender['tender_type'] ?? 'N/A'}',
                    style: const TextStyle(
                        color: CivilTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Value: ',
                        style: TextStyle(
                            color: CivilTheme.textSecondary, fontSize: 13)),
                    Text(
                        '₹${tender['details']?['estimated_cost'] ?? 0}',
                        style: const TextStyle(
                            color: CivilTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: CivilTheme.border, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isOpen) ...[
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: CivilTheme.textSecondary, size: 14),
                      const SizedBox(width: 6),
                      Text('Ends in: ${tender['ends_in']}',
                          style: const TextStyle(
                              color: CivilTheme.textSecondary, fontSize: 12)),
                      const SizedBox(width: 16),
                      const Icon(Icons.people_outline,
                          color: CivilTheme.textSecondary, size: 14),
                      const SizedBox(width: 6),
                      Text('${tender['bids']} Bids',
                          style: const TextStyle(
                              color: CivilTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Text('Closed: ${tender['closed_date']}',
                          style: const TextStyle(
                              color: CivilTheme.textSecondary, fontSize: 12)),
                      const SizedBox(width: 16),
                      Text('Final: ${tender['final']}',
                          style: const TextStyle(
                              color: CivilTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
                const Text('VIEW DETAILS',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
