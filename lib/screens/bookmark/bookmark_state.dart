import '../../models/bookmark.dart';

class BookmarkState {
  final List<Bookmark> bookmarks;
  final bool isLoading;

  BookmarkState({required this.bookmarks, required this.isLoading});

  factory BookmarkState.initial() =>
      BookmarkState(bookmarks: [], isLoading: false);

  BookmarkState copyWith({List<Bookmark>? bookmarks, bool? isLoading}) {
    return BookmarkState(
      bookmarks: bookmarks ?? this.bookmarks,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
