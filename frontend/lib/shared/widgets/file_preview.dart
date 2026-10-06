import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';

class FilePreview extends StatefulWidget {
  final String title;
  final String fileUrl;
  final String fileType;
  final int? fileSize;

  const FilePreview({
    super.key,
    required this.title,
    required this.fileUrl,
    required this.fileType,
    this.fileSize,
  });

  @override
  State<FilePreview> createState() => _FilePreviewState();
}

class _FilePreviewState extends State<FilePreview> {
  bool _isImage = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkType();
  }

  void _checkType() {
    final ext = widget.fileType.toLowerCase();
    _isImage = ext.contains('png') || ext.contains('jpg') || ext.contains('jpeg');
    setState(() => _isLoading = false);
  }

  Future<void> _openInBrowser() async {
    final baseUrl = 'http://localhost:8080';
    final uri = Uri.parse('$baseUrl${widget.fileUrl}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open in browser',
            onPressed: _openInBrowser,
          ),
          if (_isImage)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share',
              onPressed: _openInBrowser,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isImage
              ? _buildImageView()
              : _buildFallbackView(),
    );
  }

  Widget _buildImageView() {
    final baseUrl = 'http://localhost:8080';
    final fullUrl = '$baseUrl${widget.fileUrl}';

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.network(
          fullUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: CivilTheme.primary,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Failed to load image', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _openInBrowser,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open in Browser'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackView() {
    final sizeMb = widget.fileSize != null
        ? '${(widget.fileSize! / (1024 * 1024)).toStringAsFixed(2)} MB'
        : 'Unknown size';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 24),
            Text(
              widget.title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.fileType.toUpperCase()} · $sizeMb',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in Browser / External App'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showFilePreview(BuildContext context, {
  required String title,
  required String fileUrl,
  required String fileType,
  int? fileSize,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => FilePreview(
        title: title,
        fileUrl: fileUrl,
        fileType: fileType,
        fileSize: fileSize,
      ),
    ),
  );
}
