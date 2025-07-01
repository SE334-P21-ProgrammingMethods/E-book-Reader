import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/bookmark.dart';
import 'bookmark_state.dart';

class BookmarkCubit extends Cubit<BookmarkState> {
  BookmarkCubit() : super(BookmarkState.initial());

  Future<void> loadBookmarks(String bookId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    emit(state.copyWith(isLoading: true));
    final bookmarks = await Bookmark.syncBookmarks(bookId, user.uid);
    emit(state.copyWith(bookmarks: bookmarks, isLoading: false));
  }

  Future<void> addBookmark(Bookmark bookmark) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Load all bookmarks (local cache)
    final all = await Bookmark.loadBookmarks();
    // Check for duplicate (same bookId and location)
    final isDuplicate = all.any(
        (b) => b.bookId == bookmark.bookId && b.location == bookmark.location);
    if (isDuplicate) {
      // Optionally, you could show a message or emit a state for duplicate
      return;
    }
    await Bookmark.saveBookmarkToFirestore(bookmark, user.uid);
    all.add(bookmark);
    await Bookmark.saveBookmarks(all);
    emit(state.copyWith(bookmarks: all));
  }

  Future<void> deleteBookmark(Bookmark bookmark) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await Bookmark.deleteBookmarkFromFirestore(bookmark, user.uid);
    final all = await Bookmark.loadBookmarks();
    all.removeWhere((b) => b.bookmarkId == bookmark.bookmarkId);
    await Bookmark.saveBookmarks(all);
    emit(state.copyWith(bookmarks: all));
  }

  Future<void> loadAllBookmarksFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    emit(state.copyWith(isLoading: true));
    // 1. Try to load from local cache first
    final localBookmarks = await Bookmark.loadBookmarks();
    if (localBookmarks.isNotEmpty) {
      emit(state.copyWith(bookmarks: localBookmarks, isLoading: false));
    }
    // 2. Then load from Firestore
    final firestore = FirebaseFirestore.instance;
    final booksSnapshot = await firestore
        .collection('books')
        .where('userId', isEqualTo: user.uid)
        .get();
    List<Bookmark> allBookmarks = [];
    for (final bookDoc in booksSnapshot.docs) {
      final bookId = bookDoc.id;
      final bookmarksSnapshot = await firestore
          .collection('books')
          .doc(bookId)
          .collection('bookmarks')
          .get();
      final bookmarks = bookmarksSnapshot.docs
          .map((doc) => Bookmark.fromFirestore(doc.data(), doc.id))
          .toList();
      allBookmarks.addAll(bookmarks);
    }
    // Update local cache and emit latest from Firestore
    await Bookmark.saveBookmarks(allBookmarks);
    emit(state.copyWith(bookmarks: allBookmarks, isLoading: false));
  }
}
