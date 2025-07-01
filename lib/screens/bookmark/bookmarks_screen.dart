import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/book.dart';
import '../../models/bookmark.dart';
import '../library/library_cubit.dart';
import '../reader/epub/epub_reader_screen.dart';
import '../reader/pdf/pdf_reader_screen.dart';
import '../../widgets/bookmark/bookmark_card.dart';
import '../../widgets/components/search_bar.dart' as components;
import 'bookmark_cubit.dart';
import 'bookmark_state.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  static Widget newInstance() => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => BookmarkCubit(),
      ),
      BlocProvider(
        create: (context) => LibraryCubit(
          firestore: FirebaseFirestore.instance,
          storage: FirebaseStorage.instance,
          auth: FirebaseAuth.instance,
        ),
      ),
    ],
    child: const BookmarksScreen(),
  );

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load all bookmarks from Firestore for all books
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<BookmarkCubit>().loadAllBookmarksFromFirestore();
    }
  }

  void _navigateToReader(Bookmark bookmark) async {
    // Try to get the latest bookmark from cache
    final localBookmarks = await Bookmark.loadBookmarks();
    final local = localBookmarks.firstWhere(
      (b) => b.bookmarkId == bookmark.bookmarkId,
      orElse: () => bookmark,
    );
    Bookmark usedBookmark = local;
    // If not found in cache, try Firestore
    if (local.bookmarkId != bookmark.bookmarkId) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final remoteList = await Bookmark.loadBookmarksFromFirestore(
            bookmark.bookId, user.uid);
        final remote = remoteList.firstWhere(
          (b) => b.bookmarkId == bookmark.bookmarkId,
          orElse: () => bookmark,
        );
        if (remote.bookmarkId == bookmark.bookmarkId) {
          usedBookmark = remote;
        }
      }
    }
    // Fetch the Book from Firestore
    final firestore = FirebaseFirestore.instance;
    final bookDoc =
        await firestore.collection('books').doc(usedBookmark.bookId).get();
    if (!bookDoc.exists) return;
    final book = Book.fromFirestore(bookDoc.data()!, bookDoc.id);
    context.read<LibraryCubit>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Preparing book...',
                style: TextStyle(color: theme.colorScheme.onSurface)),
            ],
          ),
        );
      },
    );
    try {} finally {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
    final pageNum = int.tryParse(usedBookmark.location);
    if (pageNum != null) {
      // PDF: open reader, then open bookmark bottom sheet and navigate
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              PDFReaderScreen.newInstance(
                book: book,
                openBookmarkPage: pageNum,
                skipResumeDialog: true,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        ),
      );
    } else {
      String? cfi;
      if (kDebugMode) {
        print('DEBUG: Bookmark location string: ${usedBookmark.location}');
      }
      try {
        final decoded = jsonDecode(usedBookmark.location);
        cfi = decoded['startCfi'] as String?;
      } catch (e) {
        cfi = null;
      }
      if (kDebugMode) {
        print('DEBUG: Extracted cfi for navigation: $cfi');
      }
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              EPUBReaderScreen.newInstance(
            book: book,
            skipResumeDialog: true,
            openBookmarkCfi: cfi,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BlocBuilder<BookmarkCubit, BookmarkState>(
      builder: (context, state) {
        // Group bookmarks by bookId, not just by most recent
        final filteredBookmarks = state.bookmarks.where((bookmark) {
          final q = _searchQuery.toLowerCase();
          return bookmark.bookTitle.toLowerCase().contains(q) ||
              bookmark.location.toLowerCase().contains(q);
        }).toList();

        // Group bookmarks by bookId, then by bookTitle for display
        final Map<String, List<Bookmark>> bookmarksByBook = {};
        for (final bookmark in filteredBookmarks) {
          bookmarksByBook.putIfAbsent(bookmark.bookId, () => []).add(bookmark);
        }
        // Sort bookmarks for each book by location (as int if possible)
        for (final list in bookmarksByBook.values) {
          list.sort((a, b) {
            final aInt = int.tryParse(a.location);
            final bInt = int.tryParse(b.location);
            if (aInt != null && bInt != null) {
              return aInt.compareTo(bInt);
            }
            return a.location.compareTo(b.location);
          });
        }

        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bookmarks',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    components.SearchBar(
                      hintText: 'Search bookmarks...',
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      borderColor: colorScheme.secondary,
                      fillColor: theme.inputDecorationTheme.fillColor ??
                          colorScheme.surface,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: filteredBookmarks.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isNotEmpty
                                ? 'No bookmarks found'
                                : 'No bookmarks yet.',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.secondary),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          itemCount: bookmarksByBook.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, idx) {
                            final bookId = bookmarksByBook.keys.elementAt(idx);
                            final bookmarks = bookmarksByBook[bookId]!;
                            final bookTitle = bookmarks.first.bookTitle;
                            final dotIdx = bookTitle.lastIndexOf('.');
                            final displayTitle = dotIdx > 0
                                ? bookTitle.substring(0, dotIdx)
                                : bookTitle;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.menu_book, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$displayTitle (${bookmarks.length})',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                        softWrap: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...bookmarks.map((bookmark) => BookmarkCard(
                                      bookmark: bookmark,
                                      compact: true,
                                      onTap: () => _navigateToReader(bookmark),
                                      onDelete: () => context
                                          .read<BookmarkCubit>()
                                          .deleteBookmark(bookmark),
                                    )),
                              ],
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
