import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/civil_scaffold.dart';
import '../../shared/widgets/file_preview.dart';
import '../../core/theme.dart';
import '../../core/providers/document_provider.dart';
import '../../core/empty_state.dart';

class DrawingsScreen extends ConsumerStatefulWidget {
  const DrawingsScreen({super.key});

  @override
  ConsumerState<DrawingsScreen> createState() => _DrawingsScreenState();
}

class _DrawingsScreenState extends ConsumerState<DrawingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(documentProvider.notifier).fetchDocuments());
  }

  @override
  Widget build(BuildContext context) {
    final documentState = ref.watch(documentProvider);
    final drawings = documentState.documents.where((doc) => doc['category'] == 'Drawings').toList();

    return CivilScaffold(
      title: 'Structural Drawings',
      body: documentState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : drawings.isEmpty
              ? EmptyState(
                  icon: Icons.architecture,
                  title: 'No Drawings Found',
                  subtitle: 'Upload architectural or structural drawings in the Documents workspace.',
                  actionLabel: 'Go to Documents',
                  onAction: () {},
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: drawings.length,
                  itemBuilder: (context, index) {
                    final doc = drawings[index];
                    final date = DateTime.tryParse(doc['created_at'] ?? '');
                    final formattedDate = date != null ? DateFormat('MMM d').format(date) : '';
                    return Card(
                      color: CivilTheme.surface,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: CivilTheme.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => showFilePreview(context,
                          title: doc['name'] ?? 'Drawing',
                          fileUrl: doc['file_url'] ?? '',
                          fileType: doc['file_type'] ?? 'pdf',
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.map, color: Colors.blueAccent),
                              ),
                              const Spacer(),
                              Text(
                                doc['name'] ?? 'Drawing',
                                style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    doc['file_type']?.toString().toUpperCase() ?? 'PDF',
                                    style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 11),
                                  ),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
