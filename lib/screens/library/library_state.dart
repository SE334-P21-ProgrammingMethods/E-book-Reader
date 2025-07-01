part of 'library_cubit.dart';

class LibraryState extends Equatable {
  final List<Book> books;
  final bool isLoading;
  final String? error;

  const LibraryState({
    this.books = const [],
    this.isLoading = false,
    this.error,
  });

  LibraryState copyWith({
    List<Book>? books,
    bool? isLoading,
    String? error,
  }) {
    return LibraryState(
      books: books ?? this.books,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [books, isLoading, error];
}
