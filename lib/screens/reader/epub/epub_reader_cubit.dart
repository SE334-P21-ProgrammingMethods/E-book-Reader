import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/book.dart';
import 'epub_reader_state.dart';

class EpubReaderCubit extends Cubit<EpubReaderState> {
  EpubReaderCubit(
      Book book,
      Future<void> Function(String bookId, String lastReadPage)? onSaveLastPage,
      String? initialCfi,
      bool skipResumeDialog,
      String? openBookmarkCfi,
      ) : super(EpubReaderState(
    book: book,
    initialCfi: initialCfi,
    openBookmarkCfi: openBookmarkCfi,
  ));

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  void setCurrentPage(int page) => emit(state.copyWith(currentPage: page));
  void setTotalPages(int pages) => emit(state.copyWith(totalPages: pages));
  void setBookmarked(bool bookmarked) =>
      emit(state.copyWith(isBookmarked: bookmarked));
  void setSearching(bool searching) =>
      emit(state.copyWith(isSearching: searching));
  void setSearchText(String text) => emit(state.copyWith(searchText: text));
}
