import 'package:equatable/equatable.dart';

import '../../../models/book.dart';

class EpubReaderState extends Equatable {
  final int currentPage;
  final int totalPages;
  final bool isBookmarked;
  final bool isSearching;
  final String searchText;
  final Book book;
  final String? initialCfi;
  final String? openBookmarkCfi;

  const EpubReaderState({
    this.currentPage = 1,
    this.totalPages = 1,
    this.isBookmarked = false,
    this.isSearching = false,
    this.searchText = '',
    required this.book,
    this.initialCfi,
    this.openBookmarkCfi,
  });

  EpubReaderState copyWith({
    int? currentPage,
    int? totalPages,
    bool? isBookmarked,
    bool? isSearching,
    String? searchText,
    Book? book,
    String? initialCfi,
    String? openBookmarkCfi,
  }) {
    return EpubReaderState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isSearching: isSearching ?? this.isSearching,
      searchText: searchText ?? this.searchText,
      book: book ?? this.book,
      initialCfi: initialCfi ?? this.initialCfi,
      openBookmarkCfi: openBookmarkCfi ?? this.openBookmarkCfi,
    );
  }

  @override
  List<Object?> get props => [
    currentPage,
    totalPages,
    isBookmarked,
    isSearching,
    searchText,
    book,
    initialCfi,
    openBookmarkCfi,
  ];
}
