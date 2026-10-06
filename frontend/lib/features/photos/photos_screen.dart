import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../shared/widgets/civil_scaffold.dart';
import '../../shared/widgets/photo_gallery.dart';
import '../../core/theme.dart';
import '../../core/providers/document_provider.dart';

class PhotosScreen extends ConsumerWidget {
  final bool isEmbedded;
  const PhotosScreen({super.key, this.isEmbedded = false});

  Future<void> _uploadPhoto(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading photo...')));
      }
      
      final success = await ref.read(documentProvider.notifier).uploadDocument(file, 'Photos');
      
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo uploaded successfully')));
        } else {
          final error = ref.read(documentProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $error')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentProvider);
    final allDocs = state.documents;
    final photos = allDocs.where((doc) => doc['category'] == 'Photos' || doc['file_type'] == '.png' || doc['file_type'] == '.jpg' || doc['file_type'] == '.jpeg').toList();

    final bodyContent = state.isLoading && photos.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : photos.isEmpty
            ? const Center(
                child: Text('No photos uploaded yet.', style: TextStyle(color: CivilTheme.textSecondary)),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 250,
                  mainAxisExtent: 250,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  final fileUrl = photo['file_url'] ?? '';
                  final fullUrl = 'http://localhost:8080$fileUrl';

                  return GestureDetector(
                    onTap: () => showPhotoGallery(context, initialIndex: index),
                    child: Container(
                    decoration: BoxDecoration(
                      color: CivilTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CivilTheme.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          fullUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image, size: 48, color: CivilTheme.textSecondary),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.black.withValues(alpha: 0.6),
                            child: Text(
                              photo['name'] ?? 'Photo',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                            onPressed: () => ref.read(documentProvider.notifier).deleteDocument(photo['id']),
                          ),
                        ),
                      ],
                    ),
                  ),
                  );
                },
              );

    if (isEmbedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _uploadPhoto(context, ref),
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Upload Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CivilTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: bodyContent),
        ],
      );
    }

    return CivilScaffold(
      title: 'Site Photos',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _uploadPhoto(context, ref),
          icon: const Icon(Icons.add_a_photo),
          label: const Text('Upload Photo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: CivilTheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
      ],
      body: bodyContent,
    );
  }
}
