import 'package:flutter/material.dart';

import '../models/attraction.dart';
import '../services/bookmark_service.dart';
import 'attraction_detail_screen.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() {
    return _BookmarkScreenState();
  }
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  final BookmarkService _bookmarkService = BookmarkService();

  late Future<List<Attraction>> _bookmarksFuture;

  int _lastChangeVersion = 0;

  @override
  void initState() {
    super.initState();

    _lastChangeVersion = BookmarkService.changes.value;

    BookmarkService.changes.addListener(_handleBookmarkChanges);

    _loadBookmarks();
  }

  @override
  void dispose() {
    BookmarkService.changes.removeListener(_handleBookmarkChanges);

    super.dispose();
  }

  void _loadBookmarks() {
    _bookmarksFuture = _bookmarkService.getBookmarks();
  }

  void _refreshBookmarks() {
    setState(_loadBookmarks);
  }

  void _handleBookmarkChanges() {
    final newVersion = BookmarkService.changes.value;

    if (newVersion == _lastChangeVersion) {
      return;
    }

    _lastChangeVersion = newVersion;

    if (mounted) {
      _refreshBookmarks();
    }
  }

  Future<void> _removeBookmark(Attraction attraction) async {
    try {
      await _bookmarkService.removeBookmark(attractionId: attraction.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bookmark removed successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _openAttraction(Attraction attraction) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return AttractionDetailScreen(attractionId: attraction.id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        actions: [
          IconButton(
            onPressed: _refreshBookmarks,
            tooltip: 'Refresh bookmarks',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Attraction>>(
          future: _bookmarksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _BookmarkErrorView(
                message: snapshot.error.toString(),
                onRetry: _refreshBookmarks,
              );
            }

            final bookmarks = snapshot.data ?? <Attraction>[];

            if (bookmarks.isEmpty) {
              return _EmptyBookmarksView(onRefresh: _refreshBookmarks);
            }

            return RefreshIndicator(
              onRefresh: () async {
                _refreshBookmarks();
                await _bookmarksFuture;
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: bookmarks.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 12);
                },
                itemBuilder: (context, index) {
                  final attraction = bookmarks[index];

                  return _BookmarkCard(
                    attraction: attraction,
                    onTap: () {
                      _openAttraction(attraction);
                    },
                    onRemove: () {
                      _removeBookmark(attraction);
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({
    required this.attraction,
    required this.onTap,
    required this.onRemove,
  });

  final Attraction attraction;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AttractionThumbnail(imageUrl: attraction.imageUrl),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attraction.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 17),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            attraction.stateName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.category_outlined, size: 17),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            attraction.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: onRemove,
              tooltip: 'Remove bookmark',
              icon: const Icon(Icons.bookmark_remove_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttractionThumbnail extends StatelessWidget {
  const _AttractionThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final validImageUrl = imageUrl?.trim().isNotEmpty == true;

    return SizedBox(
      width: 110,
      height: 125,
      child: validImageUrl
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const _ImagePlaceholder();
              },
            )
          : const _ImagePlaceholder(),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Icon(Icons.landscape_outlined, size: 40),
    );
  }
}

class _EmptyBookmarksView extends StatelessWidget {
  const _EmptyBookmarksView({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.bookmark_border, size: 78),
            const SizedBox(height: 18),
            Text(
              'No bookmarks yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open an attraction and save it '
              'to view it here.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkErrorView extends StatelessWidget {
  const _BookmarkErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.bookmark_remove_outlined, size: 68),
            const SizedBox(height: 16),
            const Text(
              'Unable to load bookmarks',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
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
