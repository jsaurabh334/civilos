import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/empty_state_view.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final vendorRatingsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, vendorId) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get('/marketplace/vendors/$vendorId/ratings');
  if (data == null) return {'ratings': [], 'avg': 0.0, 'total': 0};
  return data;
});

// ─── Widget: Vendor Rating Card (embeddable) ──────────────────────────────────

class VendorRatingCard extends ConsumerWidget {
  final String vendorId;
  final String vendorName;
  const VendorRatingCard({super.key, required this.vendorId, required this.vendorName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingsAsync = ref.watch(vendorRatingsProvider(vendorId));
    return ratingsAsync.when(
      loading: () => const SkeletonList(count: 2, itemHeight: 60),
      error: (_, __) => const SizedBox(),
      data: (data) {
        final avg = (data['avg'] as num?)?.toDouble() ?? 0.0;
        final total = (data['total'] as num?)?.toInt() ?? 0;
        final ratings = (data['ratings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _buildStars(avg),
              const SizedBox(width: 8),
              Text('${avg.toStringAsFixed(1)} / 5',
                  style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 8),
              Text('($total reviews)', style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            ...ratings.take(3).map((r) => _buildReview(r)),
          ],
        );
      },
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && i < rating;
        return Icon(
          filled ? Icons.star : (half ? Icons.star_half : Icons.star_border),
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  Widget _buildReview(Map<String, dynamic> r) {
    final reviewer = r['reviewer_name']?.toString() ?? 'Anonymous';
    final rating = (r['rating'] as num?)?.toInt() ?? 0;
    final comment = r['comment']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CivilTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CivilTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 14, backgroundColor: CivilTheme.primary.withValues(alpha: 0.2),
                  child: Text(reviewer[0].toUpperCase(), style: const TextStyle(color: CivilTheme.primary, fontSize: 12))),
              const SizedBox(width: 8),
              Expanded(child: Text(reviewer, style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
              Row(children: List.generate(5, (i) => Icon(
                i < rating ? Icons.star : Icons.star_border,
                color: Colors.amber, size: 12,
              ))),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(comment, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

// ─── Leave a Review Dialog ────────────────────────────────────────────────────

void showLeaveReviewDialog(BuildContext context, WidgetRef ref, String vendorId, String vendorName) {
  int rating = 0;
  final commentCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        backgroundColor: CivilTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Leave a Review', style: TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold)),
            Text(vendorName, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Rating', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setD(() => rating = star),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: star <= rating ? Colors.amber : CivilTheme.textSecondary,
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            const Text('Comment (Optional)', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              style: const TextStyle(color: CivilTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Share your experience with this vendor…',
                hintStyle: const TextStyle(color: CivilTheme.textSecondary),
                filled: true,
                fillColor: CivilTheme.background,
                contentPadding: const EdgeInsets.all(12),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CivilTheme.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CivilTheme.primary)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: CivilTheme.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              if (rating == 0) return;
              try {
                await ref.read(apiClientProvider).post(
                  '/marketplace/vendors/$vendorId/ratings',
                  {'rating': rating, 'comment': commentCtrl.text.trim()},
                );
                ref.invalidate(vendorRatingsProvider(vendorId));
              } catch (_) {}
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review submitted! Thank you.'), backgroundColor: Colors.greenAccent),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: CivilTheme.primary),
            child: const Text('Submit Review', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}
