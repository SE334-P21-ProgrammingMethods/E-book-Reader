import 'package:equatable/equatable.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../models/book.dart';

class PdfReaderState extends Equatable {
  final int currentPage;
  final int totalPages;
  final bool isBookmarked;
  final bool isSearching;
  final String searchText;
  final PdfScrollDirection scrollDirection;
  final Book book;
  final int? initialPage;
  final int? openBookmarkPage;

  const PdfReaderState({
    this.currentPage = 1,
    this.totalPages = 1,
    this.isBookmarked = false,
    this.isSearching = false,
    this.searchText = '',
    this.scrollDirection = PdfScrollDirection.vertical,
    required this.book,
    this.initialPage,
    this.openBookmarkPage,
  });

  PdfReaderState copyWith({
    int? currentPage,
    int? totalPages,
    bool? isBookmarked,
    bool? isSearching,
    String? searchText,
    PdfScrollDirection? scrollDirection,
    Book? book,
    int? initialPage,
    int? openBookmarkPage,
  }) {
    return PdfReaderState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isSearching: isSearching ?? this.isSearching,
      searchText: searchText ?? this.searchText,
      scrollDirection: scrollDirection ?? this.scrollDirection,
      book: book ?? this.book,
      initialPage: initialPage ?? this.initialPage,
      openBookmarkPage: openBookmarkPage ?? this.openBookmarkPage,
    );
  }

  @override
  List<Object?> get props => [
    currentPage,
    totalPages,
    isBookmarked,
    isSearching,
    searchText,
    scrollDirection,
    book,
    initialPage,
    openBookmarkPage,
  ];
}
