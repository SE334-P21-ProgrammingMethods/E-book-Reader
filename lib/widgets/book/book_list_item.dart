import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../library/book_list.dart';

class BookListItem extends StatelessWidget {
  final Book book;
  final ColorScheme colorScheme;
  final void Function(Book) onBookClick;
  final void Function(Book, [String?]) onBookLongPress;

  const BookListItem({
    super.key,
    required this.book,
    required this.colorScheme,
    required this.onBookClick,
    required this.onBookLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onBookClick(book),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.secondary),
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surface,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                book.format.toUpperCase() == 'PDF'
                    ? kPdfPlaceholderAsset
                    : kEpubPlaceholderAsset,
                width: 40,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: colorScheme.surface,
                  width: 40,
                  height: 56,
                  child: const Icon(Icons.broken_image,
                      color: Colors.grey, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (() {
                      final dotIdx = book.title.lastIndexOf('.');
                      if (dotIdx > 0) {
                        return book.title.substring(0, dotIdx);
                      }
                      return book.title;
                    })(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.description,
                          size: 14, color: colorScheme.secondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          (() {
                            int? fileSize;
                            if (book.link.isNotEmpty &&
                                !book.link.startsWith('http')) {
                              final file = File(book.link);
                              if (file.existsSync()) {
                                fileSize = file.lengthSync();
                              }
                            }
                            String sizeStr = 'Unknown size';
                            if (fileSize != null) {
                              if (fileSize < 1024) {
                                sizeStr = '$fileSize B';
                              } else if (fileSize < 1024 * 1024) {
                                sizeStr =
                                    '${(fileSize / 1024).toStringAsFixed(1)} KB';
                              } else {
                                sizeStr =
                                    '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
                              }
                            }
                            return '${book.format} • $sizeStr';
                          })(),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colorScheme.secondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              padding: const EdgeInsets.all(4),
              onSelected: (value) => onBookLongPress(book, value),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Rename')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

