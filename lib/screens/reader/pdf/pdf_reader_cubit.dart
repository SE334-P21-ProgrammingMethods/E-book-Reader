import 'package:flutter_bloc/flutter_bloc.dart';
import 'pdf_reader_state.dart';

class PdfReaderCubit extends Cubit<PdfReaderState> {
  PdfReaderCubit() : super(const PdfReaderState());

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
