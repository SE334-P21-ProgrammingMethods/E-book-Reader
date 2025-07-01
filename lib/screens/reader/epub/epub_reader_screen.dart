import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ebook_reader/screens/reader/epub/epub_reader_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/book.dart';
import '../../../models/bookmark.dart';
import '../../../widgets/bookmark/bookmark_card.dart';
import '../../bookmark/bookmark_cubit.dart';
import '../../bookmark/bookmark_state.dart';
import '../../library/library_cubit.dart';
import '../../theme/theme_cubit.dart';

class EPUBReaderScreen extends StatefulWidget {
  final Book book;
  final Future<void> Function(String bookId, String lastReadPage)? onSaveLastProgress;
  final String? initialCfi;
  final bool skipResumeDialog;
  final String? openBookmarkCfi;

  const EPUBReaderScreen({
    Key? key,
    required this.book,
    this.onSaveLastProgress,
    this.initialCfi,
    this.skipResumeDialog = false,
    this.openBookmarkCfi,
  }) : super(key: key);

  static Widget newInstance({
    required Book book,
    Future<void> Function(String bookId, String lastReadPage)? onSaveLastProgress,
    String? initialCfi,
    bool skipResumeDialog = false,
    String? openBookmarkCfi,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => EpubReaderCubit(
            book,
            onSaveLastProgress,
            initialCfi,
            skipResumeDialog,
            openBookmarkCfi,
          ),
        ),
        BlocProvider(
          create: (context) => BookmarkCubit(),
        ),
      ],
      child: EPUBReaderScreen(
        book: book,
        onSaveLastProgress: onSaveLastProgress,
        initialCfi: initialCfi,
        skipResumeDialog: skipResumeDialog,
        openBookmarkCfi: openBookmarkCfi,
      ),
    );
  }

  @override
  State<EPUBReaderScreen> createState() => _EPUBReaderScreenState();
}

class _EPUBReaderScreenState extends State<EPUBReaderScreen> {
  EpubController? _epubController;
  File? _localFile;
  bool _loading = true;
  String? _error;
  bool _disposed = false;
  final EpubFlow _currentFlow = EpubFlow.paginated;
  List<EpubChapter> _chapters = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  double _progress = 0.0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<EpubSearchResult> _searchResults = [];
  bool _searching = false;
  String _searchError = '';
  String? _lastHighlightedCfi;
  bool _showFontSizeSlider = false;
  double _fontSize = 16.0;
  String? _selectedCfi;
  EpubDisplaySettings? _epubDisplaySettings;
  EpubTheme _epubTheme = EpubTheme.light();
  String? _pendingInitialCfi;
  bool _hasJumpedToInitialCfi = false;

  EpubReaderCubit get cubit => context.read<EpubReaderCubit>();

  @override
  void initState() {
    super.initState();

    // Initialize theme based on current app theme mode
    final themeCubit = context.read<ThemeCubit>();
    final isDark = themeCubit.state.themeMode == ThemeMode.dark;
    _epubTheme = isDark ? EpubTheme.dark() : EpubTheme.light();

    _prepareEpub();

    _epubDisplaySettings = EpubDisplaySettings(
      flow: _currentFlow,
      snap: false,
      // spread: EpubSpread.auto,
      allowScriptedContent: true,
      useSnapAnimationAndroid: false,
      theme: _epubTheme,
    );

    if (widget.openBookmarkCfi != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        _openBookmarkSheetAndJump(widget.openBookmarkCfi!);
      });
    }
    _searchController.addListener(() async {
      setState(() {
        _searchResults.clear();
        _searchError = '';
      });
      if (_searchController.text.isEmpty && _lastHighlightedCfi != null) {
        await _epubController?.removeHighlight(cfi: _lastHighlightedCfi!);
        _lastHighlightedCfi = null;
      }
    });

    // If initialCfi is provided, jump to it after loading and override lastReadPage
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.initialCfi != null && _epubController != null) {
        _pendingInitialCfi = widget.initialCfi;
        _hasJumpedToInitialCfi = false;
        if (kDebugMode) {
          print('DEBUG: Jumping to initial CFI: ${widget.initialCfi}');
        }
        await _epubController?.display(cfi: widget.initialCfi!);
        // Override lastReadPage with this CFI
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'epub_last_cfi_${widget.book.id}', widget.initialCfi!);
        if (widget.onSaveLastProgress != null) {
          await widget.onSaveLastProgress!(widget.book.id, widget.initialCfi!);
        }
        // Extract startCfi if initialCfi is a JSON string
        String cfiString = widget.initialCfi!;
        try {
          final decoded = jsonDecode(widget.initialCfi!);
          if (decoded is Map && decoded['startCfi'] is String) {
            cfiString = decoded['startCfi'];
          }
        } catch (_) {
          // If JSON decoding fails, keep the original CFI
          if (kDebugMode) {
            print('DEBUG: Failed to decode initial CFI JSON: ${widget.initialCfi}');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // Save the CFI string to SharedPreferences and Firestore
  Future<void> _saveLastProgress(String cfi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('epub_last_cfi_${widget.book.id}', cfi);
    if (kDebugMode) {
      print('DEBUG: Saved EPUB last CFI: $cfi');
    }
    // Extract startCfi if cfi is a JSON string
    String cfiString = cfi;
    try {
      final decoded = jsonDecode(cfi);
      if (decoded is Map && decoded['startCfi'] is String) {
        cfiString = decoded['startCfi'];
      }
    } catch (_) {}
    if (widget.onSaveLastProgress != null) {
      await widget.onSaveLastProgress!(widget.book.id, cfi);
    }
  }

  Future<String?> _getLastCfi() async {
    final prefs = await SharedPreferences.getInstance();
    final cache = prefs.getString('epub_last_cfi_${widget.book.id}');
    if (cache != null && cache.isNotEmpty) return cache;
    // Fallback to Firestore value from Book model
    final firestoreValue = widget.book.lastReadPage;
    if (firestoreValue.isNotEmpty) return firestoreValue;
    return null;
  }

  Future<void> _checkAndPromptResumeProgress() async {
    final lastCfi = await _getLastCfi();
    if (lastCfi != null && lastCfi.isNotEmpty) {
      if (!mounted) return;
      if (widget.skipResumeDialog) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (kDebugMode) {
            print('DEBUG: Resuming EPUB at CFI: $lastCfi (skip dialog)');
          }
          _epubController?.display(cfi: lastCfi);
        });
        return;
      }
      final shouldResume = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Resume Reading?'),
          content: const Text('Resume reading from your last position?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Start at Beginning'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Resume'),
            ),
          ],
        ),
      );
      if (shouldResume == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (kDebugMode) {
            print('DEBUG: Resuming EPUB at CFI: $lastCfi');
          }
          _epubController?.display(cfi: lastCfi);
        });
      } else {
        // Optionally clear the saved CFI
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('epub_last_cfi_${widget.book.id}');
      }
    }
  }

  Future<void> _prepareEpub() async {
    if (_disposed) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      File file;
      if (widget.book.link.startsWith('http')) {
        // Download to local
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = widget.book.link.split('/').last.split('?').first;
        final localPath = '${appDir.path}/$fileName';
        file = File(localPath);
        if (!await file.exists()) {
          final response = await http.get(Uri.parse(widget.book.link));
          if (response.statusCode == 200) {
            await file.writeAsBytes(response.bodyBytes);
          } else {
            throw Exception(
                'Failed to download EPUB: \\${response.statusCode}');
          }
        }
      } else {
        file = File(widget.book.link);
        if (!await file.exists()) {
          throw Exception('EPUB file not found: \\${widget.book.link}');
        }
      }
      if (_disposed) return;
      setState(() {
        _localFile = file;
        _epubController = EpubController();
        _loading = false;
      });
      // Only check for last progress if not opening from a bookmark
      if (!widget.skipResumeDialog && widget.initialCfi == null) {
        await _checkAndPromptResumeProgress();
      }
    } catch (e) {
      if (_disposed) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Helper to get chapter title for a given cfi
  String? _getChapterTitleForCfi(String cfi) {
    for (final chapter in _chapters) {
      if (cfi.contains(chapter.href)) {
        return chapter.title;
      }
    }
    return null;
  }

  // Helper to highlight search word in excerpt
  Widget _highlightedExcerpt(String excerpt, String query) {
    if (query.isEmpty) return Text(excerpt);
    final matches =
        RegExp(RegExp.escape(query), caseSensitive: false).allMatches(excerpt);
    if (matches.isEmpty) return Text(excerpt);
    List<TextSpan> spans = [];
    int last = 0;
    for (final match in matches) {
      if (match.start > last) {
        spans.add(TextSpan(text: excerpt.substring(last, match.start)));
      }
      spans.add(TextSpan(
        text: excerpt.substring(match.start, match.end),
        style: const TextStyle(
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));
      last = match.end;
    }
    if (last < excerpt.length) {
      spans.add(TextSpan(text: excerpt.substring(last)));
    }
    return RichText(
        text: TextSpan(
            style: const TextStyle(color: Colors.black), children: spans));
  }

  List<ContextMenuItem> get _menuItems {
    List<ContextMenuItem> baseItems = [
      ContextMenuItem(id: 1, title: 'Copy'),
      ContextMenuItem(id: 2, title: 'Highlight'),
      ContextMenuItem(id: 3, title: 'Underline'),
    ];
    return [
      ...baseItems,
    ];
  }

  void _onContextMenuActionItemClicked(ContextMenuItem item) async {
    switch (item.id) {
      case 1: // Copy
        if (_selectedCfi != null) {
          await Clipboard.setData(ClipboardData(text: _selectedCfi!));
        }
        break;
      case 2: // Highlight
        if (_selectedCfi != null) {
          await _epubController?.addHighlight(
            cfi: _selectedCfi!,
            color: Colors.yellow,
            opacity: 0.5,
          );
        }
        break;
      case 3: // Underline
        if (_selectedCfi != null) {
          await _epubController?.addUnderline(cfi: _selectedCfi!);
        }
        break;
    }
    // Dismiss both context menu and text selection after any action
    setState(() {
      _selectedCfi = null;
    });
    ContextMenuController.removeAny();
  }

  ContextMenu get _customContextMenu => ContextMenu(
        menuItems: _menuItems,
        onContextMenuActionItemClicked: _onContextMenuActionItemClicked,
        settings: ContextMenuSettings(
          hideDefaultSystemContextMenuItems: true,
        ),
      );

  void _toggleTheme(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();
    final isDark = themeCubit.state.themeMode == ThemeMode.dark;
    final newTheme = isDark ? ThemeMode.light : ThemeMode.dark;
    themeCubit.setThemeMode(newTheme);
    setState(() {
      _epubTheme = isDark ? EpubTheme.light() : EpubTheme.dark();
      _epubDisplaySettings = EpubDisplaySettings(
        flow: _currentFlow,
        snap: false,
        spread: EpubSpread.auto,
        allowScriptedContent: true,
        useSnapAnimationAndroid: false,
        theme: _epubTheme,
      );
    });
    _epubController?.updateTheme(theme: _epubTheme);
  }

  void _openBookmarkSheetAndJump(String cfi) async {
    // Get the BookmarkCubit from the current context
    final bookmarkCubit = context.read<BookmarkCubit>();
    await bookmarkCubit.loadBookmarks(widget.book.id);
    if (!mounted) return;

    // Open the bookmark bottom sheet and jump to the given CFI
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
                  final bookBookmarks = (state.bookmarks)
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
                                  padding: const EdgeInsets.symmetric(horizontal: 8)),
                              onPressed: () async {
                                if (_epubController == null) return;
                                final location =
                                    await _epubController!.getCurrentLocation();
                                final locationJson = jsonEncode(location);
                                if (locationJson.isEmpty) return;
                                final newBookmark = Bookmark(
                                  bookId: widget.book.id,
                                  bookTitle: widget.book.title,
                                  location: locationJson,
                                );
                                await cubit.addBookmark(newBookmark);
                                await cubit.loadBookmarks(widget.book.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Bookmark added')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: bookBookmarks.isEmpty
                            ? const Center(child: Text('No bookmarks yet.'))
                            : ListView.builder(
                                controller: scrollController,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: bookBookmarks.length,
                                itemBuilder: (context, idx) {
                                  final bookmark = bookBookmarks[idx];
                                  return BookmarkCard(
                                    bookmark: bookmark,
                                    compact: true,
                                    onTap: () async {
                                      Navigator.pop(context);
                                      String? cfi;
                                      try {
                                        final decoded =
                                            jsonDecode(bookmark.location);
                                        cfi = decoded['startCfi'] as String?;
                                      } catch (e) {
                                        cfi = null;
                                      }
                                      if (cfi != null && cfi.isNotEmpty) {
                                        await _epubController?.display(
                                            cfi: cfi);
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Bookmark location is invalid or missing.')),
                                          );
                                        }
                                      }
                                    },
                                    onDelete: () async {
                                      await cubit.deleteBookmark(bookmark);
                                      await cubit.loadBookmarks(widget.book.id);
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
    // After opening, jump to the given CFI
    if (_epubController != null && cfi.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 200));
      await _epubController!.display(cfi: cfi);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          IconButton(
            icon: const Icon(Icons.format_size),
            tooltip: 'Font Size',
            onPressed: () {
              setState(() {
                _showFontSizeSlider = !_showFontSizeSlider;
              });
            },
            onLongPress: () {
              setState(() {
                _fontSize = 16.0;
              });
              _epubController?.setFontSize(fontSize: 16.0);
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            tooltip: 'Bookmark',
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              final cubit = context.read<BookmarkCubit>();
              await cubit.loadBookmarks(widget.book.id);
              cubit.state.bookmarks
                  .where((b) => b.bookId == widget.book.id)
                  .toList();
              if (!mounted) return;
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) => BlocProvider<BookmarkCubit>.value(
                  value: cubit,
                  child: Builder(
                    builder: (modalContext) {
                      return DraggableScrollableSheet(
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
                              final bookBookmarks = (state.bookmarks)
                                  .where((b) => b.bookId == widget.book.id)
                                  .toList();
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Bookmarks for "${widget.book.title}"',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
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
                                            if (_epubController == null) return;
                                            final location =
                                                await _epubController!
                                                    .getCurrentLocation();
                                            final locationJson =
                                                jsonEncode(location);
                                            if (locationJson.isEmpty) return;
                                            final newBookmark = Bookmark(
                                              bookId: widget.book.id,
                                              bookTitle: widget.book.title,
                                              location: locationJson,
                                            );
                                            await cubit.addBookmark(newBookmark);
                                            await cubit
                                                .loadBookmarks(widget.book.id);
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content:
                                                        Text('Bookmark added')),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: bookBookmarks.isEmpty
                                        ? const Center(
                                            child: Text('No bookmarks yet.'))
                                        : ListView.builder(
                                            controller: scrollController,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12),
                                            itemCount: bookBookmarks.length,
                                            itemBuilder: (context, idx) {
                                              final bookmark = bookBookmarks[idx];
                                              return BookmarkCard(
                                                bookmark: bookmark,
                                                compact: true,
                                                onTap: () async {
                                                  Navigator.pop(context);
                                                  String? cfi;
                                                  try {
                                                    final decoded = jsonDecode(
                                                        bookmark.location);
                                                    cfi = decoded['startCfi']
                                                        as String?;
                                                  } catch (e) {
                                                    cfi = null;
                                                  }
                                                  if (cfi != null &&
                                                      cfi.isNotEmpty) {
                                                    await _epubController
                                                        ?.display(cfi: cfi);
                                                  } else {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                            content: Text(
                                                                'Bookmark location is invalid or missing.')),
                                                      );
                                                    }
                                                  }
                                                },
                                                onDelete: () async {
                                                  await cubit
                                                      .deleteBookmark(bookmark);
                                                  await cubit.loadBookmarks(
                                                      widget.book.id);
                                                  if (mounted) {
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              'Bookmark deleted')),
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
                      );
                    },
                  ),
                ),
              );
            },
            onLongPress: () async {
              if (_epubController == null) return;
              final location = await _epubController!.getCurrentLocation();
              final locationJson = jsonEncode(location);
              if (locationJson.isEmpty) return;
              final newBookmark = Bookmark(
                bookId: widget.book.id,
                bookTitle: widget.book.title,
                location: locationJson,
              );
              final cubit = context.read<BookmarkCubit>();
              await cubit.addBookmark(newBookmark);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bookmark added')),
                );
              }
            },
          ),
          Builder(
            builder: (context) {
              final themeState = context.watch<ThemeCubit>().state;
              final isDark = themeState.themeMode == ThemeMode.dark;
              return IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => RotationTransition(
                    turns: animation,
                    child: child,
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    key: ValueKey<bool>(isDark),
                  ),
                ),
                tooltip: isDark ? 'Light Mode' : 'Dark Mode',
                onPressed: () => _toggleTheme(context),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Table of Contents',
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Table of Contents',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: _chapters.isEmpty
                    ? const Center(child: Text('No chapters'))
                    : ListView.builder(
                        itemCount: _chapters.length,
                        itemBuilder: (context, idx) {
                          final chapter = _chapters[idx];
                          return ListTile(
                            title: Text(chapter.title),
                            onTap: () {
                              Navigator.of(context).maybePop();
                              _epubController?.display(cfi: chapter.href);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Search',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (query) async {
                          if (query.trim().isEmpty) return;
                          setState(() {
                            _searching = true;
                            _searchResults.clear();
                            _searchError = '';
                          });
                          try {
                            final results = await _epubController!
                                .search(query: query.trim());
                            setState(() {
                              _searchResults = results;
                              _searching = false;
                              _searchError =
                                  results.isEmpty ? 'No results found.' : '';
                            });
                          } catch (e) {
                            setState(() {
                              _searching = false;
                              _searchError = 'Search failed: $e';
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          suffixIcon: _searchController.text.isNotEmpty ||
                                  _searchResults.isNotEmpty ||
                                  _searchError.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchResults.clear();
                                      _searchError = '';
                                    });
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                    if (_searching)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
              if (_searchResults.isNotEmpty)
                Expanded(
                  child: ListView.separated(
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, idx) => const Divider(),
                    itemBuilder: (context, idx) {
                      final result = _searchResults[idx];
                      final chapterTitle = _getChapterTitleForCfi(result.cfi);
                      return ListTile(
                        title: _highlightedExcerpt(
                            result.excerpt, _searchController.text),
                        subtitle: Text(chapterTitle ?? ''),
                        onTap: () async {
                          Navigator.of(context).maybePop();
                          if (_lastHighlightedCfi != null) {
                            await _epubController?.removeHighlight(
                                cfi: _lastHighlightedCfi!);
                          }
                          await _epubController?.display(cfi: result.cfi);
                          if (result.cfi.isNotEmpty) {
                            await _epubController?.addHighlight(
                              cfi: result.cfi,
                              color: Colors.yellow,
                              opacity: 0.5,
                            );
                            _lastHighlightedCfi = result.cfi;
                          }
                        },
                      );
                    },
                  ),
                ),
              if (_searchError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Text(_searchError,
                      style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          _loading
              ? const SizedBox.shrink()
              : _error != null
                  ? Center(child: Text(_error!))
                  : _localFile == null || _epubController == null
                      ? const Center(child: Text('Failed to load EPUB.'))
                      : GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            if (_showFontSizeSlider) {
                              setState(() {
                                _showFontSizeSlider = false;
                              });
                            }
                          },
                          child: Stack(
                            children: [
                              // Main content (EpubViewer with font size slider overlay)
                              Column(
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        SafeArea(
                                          child: Builder(
                                            builder: (context) {
                                              return EpubViewer(
                                                key: ValueKey(_currentFlow),
                                                epubSource: EpubSource.fromFile(
                                                    _localFile!),
                                                epubController:
                                                    _epubController!,
                                                displaySettings:
                                                    _epubDisplaySettings!,
                                                selectionContextMenu:
                                                    _customContextMenu,
                                                onChaptersLoaded: (chapters) {
                                                  setState(() {
                                                    _chapters = chapters;
                                                  });
                                                },
                                                onEpubLoaded: () async {
                                                  final chapters =
                                                      _epubController
                                                          ?.getChapters();
                                                  if (kDebugMode) {
                                                    print(chapters);
                                                  } // Inspect for cfi or other properties
                                                },
                                                onRelocated: (value) async {
                                                  final location =
                                                      await _epubController
                                                          ?.getCurrentLocation();
                                                  if (location != null &&
                                                      mounted) {
                                                    final cfi =
                                                        location.startCfi;
                                                    if (kDebugMode) {
                                                      print(
                                                          'DEBUG: onRelocated CFI: $cfi');
                                                    }
                                                    // If opening from a bookmark, ignore ALL relocations until we reach the intended CFI
                                                    if (_pendingInitialCfi !=
                                                        null) {
                                                      if (cfi ==
                                                          _pendingInitialCfi) {
                                                        _pendingInitialCfi =
                                                            null;
                                                        _hasJumpedToInitialCfi =
                                                            true;
                                                      } else {
                                                        // Ignore ALL relocation events until we reach the intended CFI
                                                        return;
                                                      }
                                                    }
                                                    // Only save progress after we've jumped to the intended CFI (or if not opening from bookmark)
                                                    if (_hasJumpedToInitialCfi ||
                                                        widget.initialCfi ==
                                                            null) {
                                                      if (cfi.isNotEmpty) {
                                                        await _saveLastProgress(
                                                            cfi);
                                                      }
                                                      setState(() {
                                                        _progress =
                                                            location.progress;
                                                      });
                                                    }
                                                  }
                                                },
                                                onTextSelected:
                                                    (epubTextSelection) {
                                                  setState(() {
                                                    _selectedCfi =
                                                        epubTextSelection
                                                            .selectionCfi;
                                                  });
                                                },
                                                onAnnotationClicked:
                                                    (cfi) async {
                                                  await _epubController
                                                      ?.removeHighlight(
                                                          cfi: cfi);
                                                  await _epubController
                                                      ?.removeUnderline(
                                                          cfi: cfi);
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                        if (_showFontSizeSlider)
                                          Positioned(
                                            top: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              child: Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.zoom_out),
                                                    tooltip: 'Zoom -',
                                                    onPressed: () {
                                                      setState(() {
                                                        _showFontSizeSlider =
                                                            true;
                                                        _fontSize =
                                                            (_fontSize - 1)
                                                                .clamp(10, 40);
                                                      });
                                                      _epubController
                                                          ?.setFontSize(
                                                              fontSize:
                                                                  _fontSize);
                                                    },
                                                  ),
                                                  Expanded(
                                                    child: Slider(
                                                      min: 10,
                                                      max: 40,
                                                      divisions: 30,
                                                      value: _fontSize,
                                                      label: _fontSize
                                                          .toStringAsFixed(0),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _showFontSizeSlider =
                                                              true;
                                                          _fontSize = value;
                                                        });
                                                        _epubController
                                                            ?.setFontSize(
                                                                fontSize:
                                                                    _fontSize);
                                                      },
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.zoom_in),
                                                    tooltip: 'Zoom +',
                                                    onPressed: () {
                                                      setState(() {
                                                        _showFontSizeSlider =
                                                            true;
                                                        _fontSize =
                                                            (_fontSize + 1)
                                                                .clamp(10, 40);
                                                      });
                                                      _epubController
                                                          ?.setFontSize(
                                                              fontSize:
                                                                  _fontSize);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // Bottom navigation bar (page navigator)
                              if (MediaQuery.of(context).viewInsets.bottom == 0)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Material(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 8.0,
                                        right: 8.0,
                                        top: 4.0,
                                        bottom: 12.0 +
                                            MediaQuery.of(context)
                                                .viewPadding
                                                .bottom,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.first_page),
                                            tooltip: 'First Page',
                                            onPressed: _epubController == null
                                                ? null
                                                : () {
                                                    _epubController!
                                                        .moveToFistPage();
                                                  },
                                          ),
                                          IconButton(
                                            icon:
                                                const Icon(Icons.chevron_left),
                                            tooltip: 'Previous Page',
                                            onPressed: _epubController == null
                                                ? null
                                                : () {
                                                    _epubController!.prev();
                                                  },
                                          ),
                                          Text(
                                              '${(_progress * 100).toStringAsFixed(2)}%'),
                                          IconButton(
                                            icon:
                                                const Icon(Icons.chevron_right),
                                            tooltip: 'Next Page',
                                            onPressed: _epubController == null
                                                ? null
                                                : () {
                                                    _epubController!.next();
                                                  },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.last_page),
                                            tooltip: 'Last Page',
                                            onPressed: _epubController == null
                                                ? null
                                                : () {
                                                    _epubController!
                                                        .moveToLastPage();
                                                  },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
