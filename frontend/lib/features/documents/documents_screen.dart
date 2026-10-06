import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/civil_scaffold.dart';
import '../../shared/widgets/file_preview.dart';
import '../../core/theme.dart';
import '../../core/providers/document_provider.dart';
import '../../core/providers/partner_provider.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {

  Future<void> _uploadDocument(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx', 'xls', 'xlsx'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      
      // Simple dialog to pick category and vendor
      if (!context.mounted) return;
      ref.read(partnerProvider.notifier).fetchPartners(type: 'Vendor');
      
      final uploadData = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          String selectedCategory = 'General';
          int? selectedVendor;
          
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: CivilTheme.surface,
                title: const Text('Upload Document', style: TextStyle(color: CivilTheme.textPrimary)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      dropdownColor: CivilTheme.surface,
                      style: const TextStyle(color: CivilTheme.textPrimary),
                      items: ['General', 'Legal', 'Financial', 'Drawings', 'Tenders']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => selectedCategory = v!),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: CivilTheme.border)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (context, ref, child) {
                        final partnerState = ref.watch(partnerProvider);
                        final vendors = partnerState.partners;
                        return DropdownButtonFormField<int?>(
                          initialValue: selectedVendor,
                          dropdownColor: CivilTheme.surface,
                          style: const TextStyle(color: CivilTheme.textPrimary),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('Do not share (Internal)')),
                            ...vendors.map((v) => DropdownMenuItem<int?>(value: v['id'] as int, child: Text(v['name'].toString()))),
                          ],
                          onChanged: (v) => setState(() => selectedVendor = v),
                          decoration: const InputDecoration(
                            labelText: 'Share with Vendor',
                            labelStyle: TextStyle(color: CivilTheme.textSecondary),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: CivilTheme.border)),
                          ),
                        );
                      }
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, {
                      'category': selectedCategory,
                      'vendorId': selectedVendor,
                    }),
                    child: const Text('Upload'),
                  ),
                ],
              );
            }
          );
        }
      );

      if (uploadData == null) return;
      final category = uploadData['category'] as String;
      final vendorId = uploadData['vendorId'] as int?;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading document...')));
      }
      
      final success = await ref.read(documentProvider.notifier).uploadDocument(file, category, vendorId: vendorId);
      
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload successful')));
        } else {
          final error = ref.read(documentProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $error')));
        }
      }
    }
  }

  void _shareDocument(BuildContext context, Map<String, dynamic> doc) {
    // We will copy the link to the clipboard to simulate sharing
    final baseUrl = 'http://localhost:8080'; // Should ideally come from env
    final fileUrl = doc['file_url'] ?? '';
    final fullUrl = '$baseUrl$fileUrl';

    Clipboard.setData(ClipboardData(text: fullUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copied to clipboard: $fullUrl'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentProvider);
    final docs = state.documents;

    return CivilScaffold(
      title: 'Documents Workspace',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _uploadDocument(context, ref),
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload Document'),
          style: ElevatedButton.styleFrom(
            backgroundColor: CivilTheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
      ],
      body: state.isLoading && docs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : docs.isEmpty
              ? const Center(
                  child: Text('No documents uploaded yet.', style: TextStyle(color: CivilTheme.textSecondary)),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 350,
                    mainAxisExtent: 180,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return _buildDocumentCard(context, ref, doc);
                  },
                ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, WidgetRef ref, Map<String, dynamic> doc) {
    final ext = (doc['file_type'] as String?)?.toLowerCase() ?? '';
    IconData icon = Icons.insert_drive_file;
    Color iconColor = CivilTheme.textSecondary;

    if (ext.contains('pdf')) {
      icon = Icons.picture_as_pdf;
      iconColor = Colors.redAccent;
    } else if (ext.contains('png') || ext.contains('jpg') || ext.contains('jpeg')) {
      icon = Icons.image;
      iconColor = Colors.blueAccent;
    } else if (ext.contains('xls')) {
      icon = Icons.table_chart;
      iconColor = Colors.greenAccent;
    }

    final createdAt = DateTime.tryParse(doc['created_at'] ?? '');
    final dateStr = createdAt != null ? DateFormat('MMM d, yyyy h:mm a').format(createdAt.toLocal()) : 'Unknown Date';
    final sizeKb = ((doc['file_size'] ?? 0) / 1024).round();

    return GestureDetector(
      onTap: () => showFilePreview(context,
        title: doc['name'] ?? 'Document',
        fileUrl: doc['file_url'] ?? '',
        fileType: doc['file_type'] ?? '',
        fileSize: doc['file_size'] as int?,
      ),
      child: Container(
      decoration: BoxDecoration(
        color: CivilTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CivilTheme.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc['name'] ?? 'Document',
                      style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CivilTheme.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        doc['category'] ?? 'General',
                        style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 10),
                      ),
                    ),
                    if (doc['shared_with_vendor_id'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.share, size: 10, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Shared (Vendor #${doc['shared_with_vendor_id']})',
                                style: const TextStyle(color: Colors.green, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: CivilTheme.textSecondary),
                color: CivilTheme.surface,
                onSelected: (value) {
                  if (value == 'delete') {
                    ref.read(documentProvider.notifier).deleteDocument(doc['id']);
                  } else if (value == 'share') {
                    _shareDocument(context, doc);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 18, color: CivilTheme.primary),
                        SizedBox(width: 8),
                        Text('Share / Copy Link', style: TextStyle(color: CivilTheme.textPrimary)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          const Divider(color: CivilTheme.border),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 11),
              ),
              Text(
                '$sizeKb KB',
                style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
