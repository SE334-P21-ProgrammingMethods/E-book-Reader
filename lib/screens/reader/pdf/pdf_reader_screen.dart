import 'dart:async';
import 'dart:io';

import 'package:ebook_reader/screens/reader/pdf/pdf_reader_cubit.dart';
import 'package:ebook_reader/screens/reader/pdf/pdf_reader_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../models/book.dart';
import '../../../models/bookmark.dart';
import '../../../widgets/bookmark/bookmark_card.dart';
import '../../../widgets/components/dialog_utils.dart';
import '../../bookmark/bookmark_cubit.dart';
import '../../bookmark/bookmark_state.dart';
import '../../theme/theme_cubit.dart';

const String kPdfPlaceholderAsset = 'lib/assets/pdf-placeholder.webp';

class PDFReaderScreen extends StatefulWidget {
  final Book book;
  final Future<void> Function(String bookId, String lastReadPage)? onSaveLastPage;
  final int? initialPage;
  final int? openBookmarkPage;
  final bool skipResumeDialog;
  const PDFReaderScreen({
    Key? key,
    required this.book,
    this.onSaveLastPage,
    this.initialPage,
    this.openBookmarkPage,
    this.skipResumeDialog = false})
      : super(key: key);

  static Widget newInstance({
    required Book book,
    Future<void> Function(String bookId, String lastReadPage)? onSaveLastPage,
    int? initialPage,
    int? openBookmarkPage,
    bool skipResumeDialog = false,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PdfReaderCubit(
            book,
            onSaveLastPage,
            initialPage,
            openBookmarkPage,
            skipResumeDialog,
          ),
        ),
        BlocProvider(
          create: (context) => BookmarkCubit(),
        ),
      ],
      child: PDFReaderScreen(
        book: book,
        onSaveLastPage: onSaveLastPage,
        initialPage: initialPage,
        openBookmarkPage: openBookmarkPage,
        skipResumeDialog: skipResumeDialog,
      ),
    );
  }

  @override
  State<PDFReaderScreen> createState() => _PDFReaderScreen();
}

class _PDFReaderScreen extends State<PDFReaderScreen>
    with AutomaticKeepAliveClientMixin {
  static final Map<String, PdfViewerController> _controllerCache = {};
  static final Map<String, Future<String>> _futureCache = {};
  PdfReaderCubit get cubit => context.read<PdfReaderCubit>();

  PdfViewerController get _pdfController =>
      _controllerCache.putIfAbsent(widget.book.id, () => PdfViewerController());
  Future<String> get _pdfPathFuture => _futureCache.putIfAbsent(
      widget.book.id, () => _getLocalPdfPath(widget.book.link));

  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  PdfBookmarkBase? _rootBookmark;
  PdfTextSearchResult? _searchResult;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchResult?.removeListener(_onSearchResultChanged);
    super.dispose();
  }

  void _onSearchResultChanged() {
    if (mounted) setState(() {});
  }

  void _startSearch(String value) {
    final searchValue = value.trim();
    if (searchValue.isEmpty) {
      _clearSearch();
      return;
    }
    _searchResult?.removeListener(_onSearchResultChanged);
    _searchResult = _pdfController.searchText(searchValue);
    _searchResult?.addListener(_onSearchResultChanged);
    cubit.setSearchText(searchValue);
    cubit.setSearching(true);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchResult?.removeListener(_onSearchResultChanged);
    _searchResult?.clear();
    _searchResult = null;
    cubit.setSearchText('');
    cubit.setSearching(false);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadScrollDirection();
    if (!widget.skipResumeDialog) {
      _checkAndPromptResumePage();
    }

    if (widget.initialPage != null) {
      cubit.setCurrentPage(widget.initialPage!);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pdfController.jumpToPage(widget.initialPage!);
      });
    }

    if (widget.initialPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pdfController.jumpToPage(widget.initialPage!);
      });
    }
    if (widget.openBookmarkPage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        _openBookmarkSheetAndJump(widget.openBookmarkPage!);
      });
    }
  }

  Future<void> _loadScrollDirection() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('reader_scroll_direction');
    if (saved == 'horizontal') {
      cubit.setScrollDirection(PdfScrollDirection.horizontal);
    } else {
      cubit.setScrollDirection(PdfScrollDirection.vertical);
    }
  }

  Future<void> _saveScrollDirection(PdfScrollDirection direction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reader_scroll_direction',
        direction == PdfScrollDirection.horizontal ? 'horizontal' : 'vertical');
  }

  Future<void> _saveLastPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pdf_last_page_${widget.book.id}', page);
    // Also update Firestore via callback
    if (widget.onSaveLastPage != null) {
      await widget.onSaveLastPage!(widget.book.id, page.toString());
    }
  }

  Future<int> _getLastPage() async {
    final prefs = await SharedPreferences.getInstance();
    final cache = prefs.getInt('pdf_last_page_${widget.book.id}');
    if (cache != null) return cache;
    // Fallback to Firestore value from Book model
    final firestoreValue = int.tryParse(widget.book.lastReadPage);
    return firestoreValue ?? 1;
  }

  Future<void> _checkAndPromptResumePage() async {
    final lastPage = await _getLastPage();
    if (lastPage > 1) {
      if (!mounted) return;
      final shouldResume = await showCustomDialog(
        context,
        'Resume reading from page $lastPage?',
        okLabel: 'OK',
        cancelLabel: 'Start at page 1',
      );
      if (shouldResume == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pdfController.jumpToPage(lastPage);
        });
      } else {
        // Remove the old cache if user picks start at page 1
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pdf_last_page_${widget.book.id}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pdfController.jumpToPage(1);
        });
      }
    }
  }

  List<Widget> _buildBookmarkList(PdfBookmarkBase bookmark) {
    List<Widget> children = [];
    for (var i = 0; i < bookmark.count; i++) {
      final child = bookmark[i];
      if (child.count > 0) {
        children.add(
          ExpansionTile(
            title: Text(child.title),
            children: _buildBookmarkList(child),
            onExpansionChanged: (_) {},
          ),
        );
      } else {
        children.add(
          ListTile(
            title: Text(child.title),
            onTap: () {
              _pdfController.jumpToBookmark(child);
              Navigator.of(context).maybePop();
            },
          ),
        );
      }
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPdf = widget.book.format.toUpperCase() == 'PDF';
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: null,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BlocBuilder<PdfReaderCubit, PdfReaderState>(
                  builder: (context, state) => IconButton(
                    icon: Icon(state.isSearching ? Icons.close : Icons.search),
                    tooltip: 'Search',
                    onPressed: () {
                      if (state.isSearching) {
                        _clearSearch();
                      } else {
                        cubit.setSearching(true);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.zoom_out_map),
                  tooltip: 'Reset Zoom',
                  onPressed: () {
                    setState(() {
                      _pdfController.zoomLevel = 1.0;
                    });
                  },
                ),
                const SizedBox(width: 4),
                BlocBuilder<PdfReaderCubit, PdfReaderState>(
                  builder: (context, state) => IconButton(
                    icon: Icon(
                      state.isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: state.isBookmarked
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                    tooltip: 'Bookmark',
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;
                      final bookmarkCubit = context.read<BookmarkCubit>();
                      final pdfCubit = context.read<PdfReaderCubit>();
                      await bookmarkCubit.loadBookmarks(widget.book.id);

                      if (!mounted) return;

                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (context) => MultiBlocProvider(
                          providers: [
                            BlocProvider<BookmarkCubit>.value(value: bookmarkCubit),
                            BlocProvider<PdfReaderCubit>.value(value: pdfCubit),
                          ],
                          child: DraggableScrollableSheet(
                            expand: false,
                            initialChildSize: 0.3,
                            minChildSize: 0.1,
                            maxChildSize: 0.9,
                            builder: (context, scrollController) {
                              return BlocBuilder<BookmarkCubit, BookmarkState>(
                                builder: (context, state) {
                                  final cubit = context.read<BookmarkCubit>();
                                  if (!state.isLoading) {
                                    cubit.loadBookmarks(widget.book.id);
                                  }
                                  final bookmarks = state.bookmarks
                                      .where((b) => b.bookId == widget.book.id)
                                      .toList();
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Bookmarks for "${widget.book.title}"',
                                                style: Theme.of(context).textTheme.titleLarge,
                                                maxLines: 2,
                                                softWrap: true,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.add, size: 18),
                                              label: const Text('Add', softWrap: true, maxLines: 1),
                                              style: ElevatedButton.styleFrom(
                                                  minimumSize: const Size(60, 36),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8)),
                                              onPressed: () async {
                                                final currentPage = context.read<PdfReaderCubit>().state.currentPage;
                                                final newBookmark = Bookmark(
                                                  bookId: widget.book.id,
                                                  bookTitle: widget.book.title,
                                                  location: currentPage.toString(),
                                                );
                                                await cubit.addBookmark(newBookmark);
                                                await cubit.loadBookmarks(widget.book.id);
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Bookmark added on page $currentPage')),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: bookmarks.isEmpty
                                            ? const Center(child: Text('No bookmarks yet.'))
                                            : ListView.builder(
                                                controller: scrollController,
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                itemCount: bookmarks.length,
                                                itemBuilder: (context, idx) {
                                                  final bookmark = bookmarks[idx];
                                                  return BookmarkCard(
                                                    bookmark: bookmark,
                                                    compact: true,
                                                    onTap: () {
                                                      Navigator.pop(context);
                                                      final page = int.tryParse(bookmark.location) ?? 1;
                                                      _pdfController.jumpToPage(page);
                                                    },
                                                    onDelete: () async {
                                                      await cubit.deleteBookmark(bookmark);
                                                      await cubit.loadBookmarks(widget.book.id);
                                                      if (mounted) {
                                                        Navigator.pop(context);
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('Bookmark deleted')),
                                                        );
                                                      }
                                                    },
                                                  );
                                                },
                                              ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                    onLongPress: () async {
                      final currentPage = state.currentPage;
                      final newBookmark = Bookmark(
                        bookId: widget.book.id,
                        bookTitle: widget.book.title,
                        location: currentPage.toString(),
                      );
                      final cubit = context.read<BookmarkCubit>();
                      await cubit.addBookmark(newBookmark);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Bookmark added on page $currentPage')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    theme.brightness == Brightness.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: colorScheme.onSurface,
                  ),
                  onPressed: () {
                    final themeCubit = context.read<ThemeCubit>();
                    themeCubit.setThemeMode(
                      theme.brightness == Brightness.dark
                          ? ThemeMode.light
                          : ThemeMode.dark,
                    );
                  },
                  tooltip: theme.brightness == Brightness.dark
                      ? 'Theme'
                      : 'Dark Mode',
                ),
                const SizedBox(width: 4),
                BlocBuilder<PdfReaderCubit, PdfReaderState>(
                  builder: (context, state) => IconButton(
                    icon: const Icon(Icons.menu_book),
                    tooltip: 'Contents',
                    onPressed: () {
                      if (isPdf) {
                        _scaffoldKey.currentState?.openEndDrawer();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                BlocBuilder<PdfReaderCubit, PdfReaderState>(
                  builder: (context, state) => IconButton(
                    icon: Icon(
                        state.scrollDirection == PdfScrollDirection.vertical
                            ? Icons.swap_horiz
                            : Icons.swap_vert),
                    tooltip:
                        state.scrollDirection == PdfScrollDirection.vertical
                            ? 'Switch to Horizontal Scroll'
                            : 'Switch to Vertical Scroll',
                    onPressed: () {
                      final newDirection =
                          state.scrollDirection == PdfScrollDirection.vertical
                              ? PdfScrollDirection.horizontal
                              : PdfScrollDirection.vertical;
                      cubit.setScrollDirection(newDirection);
                      _saveScrollDirection(newDirection);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: BlocBuilder<PdfReaderCubit, PdfReaderState>(
        builder: (context, state) {
          final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
          return Stack(
            children: [
              // PDF Viewer
              Positioned.fill(
                child: isPdf
                    ? FutureBuilder<String>(
                        future: _pdfPathFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  kPdfPlaceholderAsset,
                                  width: 80,
                                  height: 120,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 16),
                                Text('Failed to load PDF: \\${snapshot.error}')
                              ],
                            ));
                          }
                          if (!snapshot.hasData) {
                            return Center(
                                child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  kPdfPlaceholderAsset,
                                  width: 80,
                                  height: 120,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 16),
                                const Text('No PDF file found.')
                              ],
                            ));
                          }
                          final localPath = snapshot.data!;
                          final file = File(localPath);
                          if (!file.existsSync() &&
                              !localPath.startsWith('http')) {
                            return Center(
                                child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  kPdfPlaceholderAsset,
                                  width: 80,
                                  height: 120,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 16),
                                Text('PDF file does not exist at \\$localPath')
                              ],
                            ));
                          }
                          final pdfViewer = localPath.startsWith('http')
                              ? SfPdfViewer.network(
                                  localPath,
                                  key: _pdfViewerKey,
                                  controller: _pdfController,
                                  enableTextSelection: true,
                                  canShowTextSelectionMenu: true,
                                  canShowScrollHead: true,
                                  canShowScrollStatus: true,
                                  scrollDirection: state.scrollDirection,
                                  pageLayoutMode: state.scrollDirection ==
                                          PdfScrollDirection.horizontal
                                      ? PdfPageLayoutMode.single
                                      : PdfPageLayoutMode.continuous,
                                  onDocumentLoaded:
                                      (PdfDocumentLoadedDetails details) {
                                    context
                                        .read<PdfReaderCubit>()
                                        .setTotalPages(
                                            details.document.pages.count);
                                    setState(() {
                                      _rootBookmark =
                                          details.document.bookmarks;
                                    });
                                  },
                                  onPageChanged:
                                      (PdfPageChangedDetails details) {
                                    context
                                        .read<PdfReaderCubit>()
                                        .setCurrentPage(details.newPageNumber);
                                    _saveLastPage(details.newPageNumber);
                                  },
                                  enableHyperlinkNavigation: true,
                                  enableDocumentLinkAnnotation: true,
                                  enableDoubleTapZooming: true,
                                  maxZoomLevel: 5.0,
                                )
                              : SfPdfViewer.file(
                                  file,
                                  key: _pdfViewerKey,
                                  controller: _pdfController,
                                  enableTextSelection: true,
                                  canShowTextSelectionMenu: true,
                                  canShowScrollHead: true,
                                  canShowScrollStatus: true,
                                  scrollDirection: state.scrollDirection,
                                  pageLayoutMode: state.scrollDirection ==
                                          PdfScrollDirection.horizontal
                                      ? PdfPageLayoutMode.single
                                      : PdfPageLayoutMode.continuous,
                                  onDocumentLoaded:
                                      (PdfDocumentLoadedDetails details) {
                                    context
                                        .read<PdfReaderCubit>()
                                        .setTotalPages(
                                            details.document.pages.count);
                                    setState(() {
                                      _rootBookmark =
                                          details.document.bookmarks;
                                    });
                                  },
                                  onPageChanged:
                                      (PdfPageChangedDetails details) {
                                    context
                                        .read<PdfReaderCubit>()
                                        .setCurrentPage(details.newPageNumber);
                                    _saveLastPage(details.newPageNumber);
                                  },
                                  enableHyperlinkNavigation: true,
                                  enableDocumentLinkAnnotation: true,
                                  enableDoubleTapZooming: true,
                                  maxZoomLevel: 5.0,
                                );
                          return Stack(
                            children: [
                              pdfViewer,
                              // Bottom nav bar (page indicator) - only show if keyboard is not open
                              if (state.scrollDirection ==
                                      PdfScrollDirection.horizontal &&
                                  !isKeyboardOpen)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.first_page),
                                          tooltip: 'First Page',
                                          onPressed: state.currentPage > 1
                                              ? () {
                                                  _pdfController.jumpToPage(1);
                                                }
                                              : null,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left),
                                          tooltip: 'Previous Page',
                                          onPressed: state.currentPage > 1
                                              ? () {
                                                  _pdfController.previousPage();
                                                }
                                              : null,
                                        ),
                                        Text(
                                          'Page ${state.currentPage}/${state.totalPages}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right),
                                          tooltip: 'Next Page',
                                          onPressed: state.currentPage <
                                                  state.totalPages
                                              ? () {
                                                  _pdfController.nextPage();
                                                }
                                              : null,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.last_page),
                                          tooltip: 'Last Page',
                                          onPressed: state.currentPage <
                                                  state.totalPages
                                              ? () {
                                                  _pdfController.jumpToPage(
                                                      state.totalPages);
                                                }
                                              : null,
                                        ),
                                        const Spacer(),
                                        if (state.totalPages > 0)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(right: 4),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${((state.currentPage / state.totalPages) * 100).toStringAsFixed(0)}%',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ),
              // Search bar overlay
              if (isPdf && state.isSearching)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Flexible(
                            flex: 6,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search',
                                border: const OutlineInputBorder(),
                                isDense: true,
                                suffixIcon: state.searchText.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: _clearSearch,
                                      )
                                    : null,
                              ),
                              autofocus: true,
                              onSubmitted: _startSearch,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_searchResult != null &&
                              _searchResult!.totalInstanceCount > 0)
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  tooltip: 'Previous',
                                  onPressed: () {
                                    _searchResult!.previousInstance();
                                    setState(() {});
                                  },
                                ),
                                Text(
                                  '${_searchResult!.currentInstanceIndex}/${_searchResult!.totalInstanceCount}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  tooltip: 'Next',
                                  onPressed: () {
                                    _searchResult!.nextInstance();
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                child: Text(
                  'Table of Contents',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: _rootBookmark == null
                    ? const Center(child: Text('No bookmarks'))
                    : ListView(
                        children: _buildBookmarkList(_rootBookmark!),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _getLocalPdfPath(String link) async {
    if (link.startsWith('http')) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = link.split('/').last.split('?').first;
      final localPath = '${appDir.path}/$fileName';
      final localFile = File(localPath);
      if (!await localFile.exists()) {
        final response = await http.get(Uri.parse(link));
        if (response.statusCode == 200) {
          await localFile.writeAsBytes(response.bodyBytes);
        } else {
          throw Exception('Failed to download PDF: ${response.statusCode}');
        }
      }
      return localPath;
    } else {
      return link;
    }
  }

  void _openBookmarkSheetAndJump(int page) async {
    final bookmarkCubit = context.read<BookmarkCubit>();
    final pdfCubit = context.read<PdfReaderCubit>();
    await bookmarkCubit.loadBookmarks(widget.book.id);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => BlocProvider<BookmarkCubit>.value(
        value: bookmarkCubit,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.3,
          minChildSize: 0.1,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return BlocBuilder<BookmarkCubit, BookmarkState>(
              builder: (context, state) {
                final cubit = context.read<BookmarkCubit>();
                if (!state.isLoading) {
                  cubit.loadBookmarks(widget.book.id);
                }
                final bookmarks = (state.bookmarks)
                    .where((b) => b.bookId == widget.book.id)
                    .toList();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Bookmarks for "${widget.book.title}"',
                              style: Theme.of(context).textTheme.titleLarge,
                              maxLines: 2,
                              softWrap: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add',
                                softWrap: true, maxLines: 1),
                            style: ElevatedButton.styleFrom(
                                minimumSize: const Size(60, 36),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8)),
                            onPressed: () async {
                              final currentPage = context
                                  .read<PdfReaderCubit>()
                                  .state
                                  .currentPage;
                              final newBookmark = Bookmark(
                                bookId: widget.book.id,
                                bookTitle: widget.book.title,
                                location: currentPage.toString(),
                              );
                              await cubit.addBookmark(newBookmark);
                              await cubit.loadBookmarks(widget.book.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Bookmark added on page $currentPage')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: bookmarks.isEmpty
                          ? const Center(child: Text('No bookmarks yet.'))
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              itemCount: bookmarks.length,
                              itemBuilder: (context, idx) {
                                final bookmark = bookmarks[idx];
                                return BookmarkCard(
                                  bookmark: bookmark,
                                  compact: true,
                                  onTap: () {
                                    Navigator.pop(context);
                                    final page =
                                        int.tryParse(bookmark.location) ??
                                            1;
                                    _pdfController.jumpToPage(page);
                                  },
                                  onDelete: () async {
                                    await cubit.deleteBookmark(bookmark);
                                    await cubit
                                        .loadBookmarks(widget.book.id);
                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Bookmark deleted')),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
    // After opening, jump to the given page
    await Future.delayed(const Duration(milliseconds: 200));
    _pdfController.jumpToPage(page);
  }
}

bool isInAppData(String path) {
  if (!Platform.isAndroid) return true; // Always allow on non-Android
  return path.contains('/app_flutter/') ||
      path.contains('/data/user/0/') ||
      path.contains('/data/data/');
}
