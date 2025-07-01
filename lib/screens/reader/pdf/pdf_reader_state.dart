import 'package:equatable/equatable.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfReaderState extends Equatable {
  final int currentPage;
  final int totalPages;
  final bool isBookmarked;
  final bool isSearching;
  final String searchText;
  final PdfScrollDirection scrollDirection;

  const PdfReaderState({
    this.currentPage = 1,
    this.totalPages = 1,
    this.isBookmarked = false,
    this.isSearching = false,
    this.searchText = '',
    this.scrollDirection = PdfScrollDirection.vertical,
  });

  PdfReaderState copyWith({
    int? currentPage,
    int? totalPages,
    bool? isBookmarked,
    bool? isSearching,
    String? searchText,
    PdfScrollDirection? scrollDirection,
  }) {
    return PdfReaderState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isSearching: isSearching ?? this.isSearching,
      searchText: searchText ?? this.searchText,
      scrollDirection: scrollDirection ?? this.scrollDirection,
    );
  }

  @override
  List<Object?> get props => [
        currentPage,
        totalPages,
        isBookmarked,
        isSearching,
        searchText,
        scrollDirection
      ];
}
