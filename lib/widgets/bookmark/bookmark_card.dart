import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

import '../../models/bookmark.dart';

class BookmarkCard extends StatelessWidget {
  final Bookmark bookmark;
  final bool compact;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const BookmarkCard({
    Key? key,
    required this.bookmark,
    this.compact = false,
    this.onDelete,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    String displayText;
    // Try PDF bookmark (page number)
    final pageNum = int.tryParse(bookmark.location);
    if (pageNum != null) {
      displayText = 'Page ${bookmark.location}';
    } else {
      // Try EPUB bookmark (JSON)
      EpubLocation? location;
      try {
        location = EpubLocation.fromJson(jsonDecode(bookmark.location));
      } catch (e) {
        location = null;
      }
      if (location != null) {
        displayText =
            'Progress: ${(location.progress * 100).toStringAsFixed(2)}%';
      } else {
        displayText = 'Invalid bookmark';
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          onTap: onTap ??
              () async {
                // Default navigation logic if onTap is not provided
                // You may want to fetch the Book model here if needed
                // For now, just try to open the reader with the bookmark info
                // (You can enhance this to fetch the Book from Firestore/local if needed)
                final bookId = bookmark.bookId;
                final bookTitle = bookmark.bookTitle;
                final location = bookmark.location;
                // Try PDF first
                final pageNum = int.tryParse(location);
                if (pageNum != null) {
                  // PDF
                  Navigator.pushNamed(context, '/pdf_reader', arguments: {
                    'bookId': bookId,
                    'bookTitle': bookTitle,
                    'initialPage': pageNum,
                  });
                } else {
                  // EPUB
                  String? cfi;
                  try {
                    final decoded = jsonDecode(location);
                    cfi = decoded['startCfi'] as String?;
                  } catch (e) {
                    cfi = null;
                  }
                  Navigator.pushNamed(context, '/epub_reader', arguments: {
                    'bookId': bookId,
                    'bookTitle': bookTitle,
                    'initialCfi': cfi,
                  });
                }
              },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!compact)
                  Container(
                    width: 40,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    child: const Icon(Icons.menu_book, size: 32),
                  ),
                if (!compact) const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!compact)
                        Text(bookmark.bookTitle,
                            style: textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                )),
                      Text(
                        displayText,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: colorScheme.error,
                    size: 20,
                  ),
                  onPressed: onDelete,
                  tooltip:
                      MaterialLocalizations.of(context).deleteButtonTooltip,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
