import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../library/book_grid.dart';

class BookGridItem extends StatelessWidget {
  final Book book;
  final ColorScheme colorScheme;
  final void Function(Book) onBookClick;
  final void Function(Book, [String?]) onBookLongPress;

  const BookGridItem({
    super.key,
    required this.book,
    required this.colorScheme,
    required this.onBookClick,
    required this.onBookLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onBookClick(book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.secondary),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      book.format.toUpperCase() == 'PDF'
                          ? kPdfPlaceholderAsset
                          : kEpubPlaceholderAsset,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                        color: colorScheme.surface,
                        width: double.infinity,
                        height: double.infinity,
                        child: const Icon(Icons.broken_image,
                            color: Colors.grey, size: 32),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    padding: const EdgeInsets.all(4),
                    onSelected: (value) => onBookLongPress(book, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'edit', child: Text('Rename')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      book.format,
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            (() {
              final dotIdx = book.title.lastIndexOf('.');
              if (dotIdx > 0) {
                return book.title.substring(0, dotIdx);
              }
              return book.title;
            })(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600, color: colorScheme.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
