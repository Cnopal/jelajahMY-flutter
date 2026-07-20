import 'package:flutter/material.dart';

import '../services/bookmark_service.dart';

class BookmarkButton extends StatefulWidget {
  const BookmarkButton({required this.attractionId, super.key});

  final int attractionId;

  @override
  State<BookmarkButton> createState() {
    return _BookmarkButtonState();
  }
}

class _BookmarkButtonState extends State<BookmarkButton> {
  final BookmarkService _bookmarkService = BookmarkService();

  bool _isBookmarked = false;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarkStatus();
  }

  Future<void> _loadBookmarkStatus() async {
    try {
      final isBookmarked = await _bookmarkService.getBookmarkStatus(
        attractionId: widget.attractionId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isBookmarked = isBookmarked;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      if (_isBookmarked) {
        await _bookmarkService.removeBookmark(
          attractionId: widget.attractionId,
        );
      } else {
        await _bookmarkService.addBookmark(attractionId: widget.attractionId);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isBookmarked = !_isBookmarked;
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBookmarked
                ? 'Attraction added to bookmarks.'
                : 'Bookmark removed successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdating = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: null,
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (_isBookmarked) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: _isUpdating ? null : _toggleBookmark,
          icon: _isUpdating
              ? const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Icon(Icons.bookmark),
          label: Text(_isUpdating ? 'Updating...' : 'Saved to Bookmarks'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _isUpdating ? null : _toggleBookmark,
        icon: _isUpdating
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(Icons.bookmark_add_outlined),
        label: Text(_isUpdating ? 'Updating...' : 'Add to Bookmarks'),
      ),
    );
  }
}
