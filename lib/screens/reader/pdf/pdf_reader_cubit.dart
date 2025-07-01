import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/book.dart';
import 'pdf_reader_state.dart';

class PdfReaderCubit extends Cubit<PdfReaderState> {
  PdfReaderCubit(
    Book book,
    Future<void> Function(String bookId, String lastReadPage)? onSaveLastPage,
    int? initialPage,
    int? openBookmarkPage,
    bool skipResumeDialog,
  ) : super(PdfReaderState(
    book: book,
    initialPage: initialPage,
    openBookmarkPage: openBookmarkPage,
  ));

  void setCurrentPage(int page) => emit(state.copyWith(currentPage: page));
  void setTotalPages(int pages) => emit(state.copyWith(totalPages: pages));
  void setBookmarked(bool bookmarked) =>
      emit(state.copyWith(isBookmarked: bookmarked));
  void setSearching(bool searching) =>
      emit(state.copyWith(isSearching: searching));
  void setSearchText(String text) => emit(state.copyWith(searchText: text));
  void setScrollDirection(scrollDirection) =>
      emit(state.copyWith(scrollDirection: scrollDirection));


}
