
import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../book/book_list_item.dart';

const String kPdfPlaceholderAsset = 'lib/assets/pdf-placeholder.webp';
const String kEpubPlaceholderAsset = 'lib/assets/epub-placeholder.webp';

class BookList extends StatelessWidget {
  final List<Book> books;
  final String searchQuery;
  final void Function(Book) onBookClick;
  final void Function(Book, [String?]) onBookLongPress;

  const BookList({
    super.key,
    required this.books,
    required this.searchQuery,
    required this.onBookClick,
    required this.onBookLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredBooks = books.where((book) {
      final query = searchQuery.toLowerCase();
      return book.title.toLowerCase().contains(query);
    }).toList();

    if (filteredBooks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
          child: Text(
            'No books found',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.secondary,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: filteredBooks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final book = filteredBooks[index];
        return BookListItem(
          book: book,
          colorScheme: colorScheme,
          onBookClick: onBookClick,
          onBookLongPress: onBookLongPress,
        );
      },
    );
  }
}
