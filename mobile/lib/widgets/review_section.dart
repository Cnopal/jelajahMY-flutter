import 'package:flutter/material.dart';

import '../models/review.dart';
import '../services/review_service.dart';

class ReviewSection extends StatefulWidget {
  const ReviewSection({required this.attractionId, super.key});

  final int attractionId;

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  final _reviewService = ReviewService();
  late Future<_ReviewData> _reviewFuture;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    _reviewFuture = _fetchReviewData();
  }

  Future<_ReviewData> _fetchReviewData() async {
    final results = await Future.wait<dynamic>([
      _reviewService.getReviews(widget.attractionId),
      _reviewService.getRatingSummary(widget.attractionId),
      _reviewService.getCurrentUserReview(widget.attractionId),
    ]);

    return _ReviewData(
      reviews: results[0] as List<Review>,
      summary: results[1] as RatingSummary,
      currentUserReview: results[2] as Review?,
    );
  }

  Future<void> _refresh() async {
    setState(_loadReviews);
    await _reviewFuture;
  }

  Future<void> _openReviewForm(Review? review) async {
    final draft = await showDialog<_ReviewDraft>(
      context: context,
      builder: (context) => _ReviewDialog(review: review),
    );

    if (draft == null || _isMutating) return;
    setState(() => _isMutating = true);

    try {
      if (review == null) {
        await _reviewService.createReview(
          attractionId: widget.attractionId,
          rating: draft.rating,
          comment: draft.comment,
        );
      } else {
        await _reviewService.updateReview(
          attractionId: widget.attractionId,
          reviewId: review.id,
          rating: draft.rating,
          comment: draft.comment,
        );
      }

      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            review == null
                ? 'Review submitted successfully.'
                : 'Review updated successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _deleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text(
          'Your rating and comment will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || _isMutating) return;
    setState(() => _isMutating = true);

    try {
      await _reviewService.deleteReview(
        attractionId: widget.attractionId,
        reviewId: review.id,
      );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ReviewData>(
      future: _reviewFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ReviewLoadingView();
        }

        if (snapshot.hasError) {
          return _ReviewErrorView(
            message: snapshot.error.toString(),
            onRetry: () => setState(_loadReviews),
          );
        }

        final data = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RatingSummaryCard(summary: data.summary),
            const SizedBox(height: 12),
            if (data.currentUserReview == null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isMutating ? null : () => _openReviewForm(null),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('Write a Review'),
                ),
              )
            else
              _CurrentUserReviewCard(
                review: data.currentUserReview!,
                isBusy: _isMutating,
                onEdit: () => _openReviewForm(data.currentUserReview),
                onDelete: () => _deleteReview(data.currentUserReview!),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Visitor Reviews',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isMutating ? null : _refresh,
                  tooltip: 'Refresh reviews',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (data.reviews.isEmpty)
              const _EmptyReviewsView()
            else
              for (final review in data.reviews) ...[
                _ReviewCard(review: review),
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars({
    required this.rating,
    this.size = 20,
    this.color,
    super.key,
  });

  final double rating;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Colors.amber.shade700;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final position = index + 1;
        final icon = rating >= position
            ? Icons.star
            : rating >= position - 0.5
            ? Icons.star_half
            : Icons.star_border;
        return Icon(icon, size: size, color: starColor);
      }),
    );
  }
}

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard({required this.summary});

  final RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Text(
              summary.averageRating.toStringAsFixed(1),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingStars(rating: summary.averageRating, size: 24),
                  const SizedBox(height: 5),
                  Text(
                    '${summary.totalReviews} review'
                    '${summary.totalReviews == 1 ? '' : 's'}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentUserReviewCard extends StatelessWidget {
  const _CurrentUserReviewCard({
    required this.review,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  final Review review;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Your Review',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: isBusy ? null : onEdit,
                  tooltip: 'Edit review',
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: isBusy ? null : onDelete,
                  tooltip: 'Delete review',
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            RatingStars(rating: review.rating.toDouble()),
            if (review.comment != null) ...[
              const SizedBox(height: 8),
              Text(review.comment!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final profileUrl = review.reviewerProfileImageUrl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              child: profileUrl == null
                  ? Text(review.reviewerName.characters.first.toUpperCase())
                  : ClipOval(
                      child: Image.network(
                        profileUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.person),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.reviewerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RatingStars(rating: review.rating.toDouble(), size: 17),
                      const Spacer(),
                      Text(
                        '${review.wasUpdated ? 'Updated' : 'Reviewed'} '
                        '${_formatDate(review.wasUpdated ? review.updatedAt : review.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (review.comment != null) ...[
                    const SizedBox(height: 10),
                    Text(review.comment!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({this.review});

  final Review? review;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _commentController;
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.review?.rating ?? 0;
    _commentController = TextEditingController(text: widget.review?.comment);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a rating from 1 to 5 stars.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(
      context,
    ).pop(_ReviewDraft(rating: _rating, comment: _commentController.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.review == null ? 'Write a Review' : 'Edit Review'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return IconButton(
                    onPressed: () => setState(() => _rating = value),
                    tooltip: '$value star${value == 1 ? '' : 's'}',
                    icon: Icon(
                      value <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber.shade700,
                      size: 32,
                    ),
                  );
                }),
              ),
              Text(_rating == 0 ? 'Select a rating' : '$_rating out of 5'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentController,
                minLines: 3,
                maxLines: 6,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value?.length ?? 0) > 2000) {
                    return 'Comment cannot exceed 2000 characters.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class _ReviewLoadingView extends StatelessWidget {
  const _ReviewLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ReviewErrorView extends StatelessWidget {
  const _ReviewErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.rate_review_outlined, size: 44),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReviewsView extends StatelessWidget {
  const _EmptyReviewsView();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(Icons.star_outline, size: 48),
            SizedBox(height: 8),
            Text('No reviews yet. Be the first to share your experience.'),
          ],
        ),
      ),
    );
  }
}

class _ReviewData {
  const _ReviewData({
    required this.reviews,
    required this.summary,
    required this.currentUserReview,
  });

  final List<Review> reviews;
  final RatingSummary summary;
  final Review? currentUserReview;
}

class _ReviewDraft {
  const _ReviewDraft({required this.rating, required this.comment});

  final int rating;
  final String comment;
}
