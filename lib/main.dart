import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ebook_reader/screens/auth/forget-password/forget_password_cubit.dart';
import 'package:ebook_reader/screens/auth/sign-in/signin_cubit.dart';
import 'package:ebook_reader/screens/auth/sign-up/signup_cubit.dart';
import 'package:ebook_reader/screens/auth/sign-up/signup_screen.dart';
import 'package:ebook_reader/screens/bookmark/bookmark_cubit.dart';
import 'package:ebook_reader/screens/library/library_cubit.dart';
import 'package:ebook_reader/screens/library/library_screen.dart';
import 'package:ebook_reader/screens/reader/pdf/pdf_reader_cubit.dart';
import 'package:ebook_reader/screens/setting/setting_cubit.dart';
import 'package:ebook_reader/screens/theme/theme_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/book.dart';
import 'screens/bookmark/bookmarks_screen.dart';
import 'screens/reader/epub/epub_reader_screen.dart';
import 'screens/auth/forget-password/forget_password_screen.dart';
import 'screens/reader/pdf/pdf_reader_screen.dart';
import 'screens/setting/settings_screen.dart';
import 'screens/auth/sign-in/signin_screen.dart';
import 'widgets/navigation/bottom_nav.dart';

void main() async {
  // Đảm bảo Flutter được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp();
  // await FirebaseFirestore.instance.collection('test').add({'test': 'value'});

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => SettingCubit()),
        BlocProvider(create: (_) => BookmarkCubit()),
        BlocProvider(create: (_) => PdfReaderCubit()),
        BlocProvider(
          create: (_) => LibraryCubit(
            firestore: FirebaseFirestore.instance,
            storage: FirebaseStorage.instance,
            auth: FirebaseAuth.instance,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          title: 'E-book Reader',
          theme: ThemeData(
            colorScheme: const ColorScheme(
              brightness: Brightness.light,
              primary: Colors.black,
              onPrimary: Colors.white,
              secondary: Colors.black87,
              onSecondary: Colors.white,
              error: Colors.red,
              onError: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.lobsterTextTheme(
              Typography.englishLike2021,
            )
                .apply(
                  displayColor: Colors.black,
                  bodyColor: Colors.black,
                )
                .copyWith(
                  bodySmall: GoogleFonts.lobster(fontSize: 14),
                  bodyMedium: GoogleFonts.lobster(fontSize: 16),
                  bodyLarge: GoogleFonts.lobster(fontSize: 18),
                ),
          ),
          darkTheme: ThemeData(
            colorScheme: const ColorScheme(
              brightness: Brightness.dark,
              primary: Colors.white,
              onPrimary: Colors.black,
              secondary: Colors.white70,
              onSecondary: Colors.black,
              error: Colors.red,
              onError: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.lobsterTextTheme(
              Typography.englishLike2021,
            )
                .apply(
                  displayColor: Colors.white,
                  bodyColor: Colors.white,
                )
                .copyWith(
                  bodySmall: GoogleFonts.lobster(fontSize: 14),
                  bodyMedium: GoogleFonts.lobster(fontSize: 16),
                  bodyLarge: GoogleFonts.lobster(fontSize: 18),
                ),
          ),
          themeMode: themeState.themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('vi'), // Vietnamese
          ],
          home: const AuthGate(),
          routes: {
            '/forgot-password': (context) => BlocProvider(
                  create: (_) => ForgetPasswordCubit(),
                  child: ForgotPasswordScreen(
                    toggleTheme: () => context.read<ThemeCubit>().toggleTheme(),
                  ),
                ),
            '/sign-up': (context) => BlocProvider(
                  create: (_) => SignupCubit(),
                  child: SignUpScreen(
                    toggleTheme: () => context.read<ThemeCubit>().toggleTheme(),
                  ),
                ),
            '/sign-in': (context) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: context.read<SettingCubit>()),
                    BlocProvider(create: (_) => SigninCubit()),
                  ],
                  child: SignInScreen(
                    toggleTheme: () => context.read<ThemeCubit>().toggleTheme(),
                  ),
                ),
            '/main': (context) => const MainScreen(),
            '/pdf_reader': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              final book = Book(
                id: args['bookId'] as String,
                title: args['bookTitle'] as String? ?? '',
                format: 'PDF',
                link: '',
                userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                lastReadPage: (args['initialPage']?.toString() ?? '1'),
              );
              final cubit = BlocProvider.of<LibraryCubit>(context);
              return BlocProvider.value(
                value: cubit,
                child: PDFReaderScreen(
                  book: book,
                  initialPage: args['initialPage'] as int?,
                ),
              );
            },
            '/epub_reader': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              final book = Book(
                id: args['bookId'] as String,
                title: args['bookTitle'] as String? ?? '',
                format: 'EPUB',
                link: '',
                userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                lastReadPage: '',
              );
              final cubit = BlocProvider.of<LibraryCubit>(context);
              return BlocProvider.value(
                value: cubit,
                child: EPUBReaderScreen(
                  book: book,
                  initialCfi: args['initialCfi'] as String?,
                ),
              );
            },
          },
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: Future.value(FirebaseAuth.instance.currentUser),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == null) {
          return MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<SettingCubit>()),
              BlocProvider(create: (_) => SigninCubit()),
            ],
            child: SignInScreen(
              toggleTheme: () => context.read<ThemeCubit>().toggleTheme(),
            ),
          );
        } else {
          return const MainScreen();
        }
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      const LibraryScreen(),
      const BookmarksScreen(),
      const SettingsScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNav(
        activeItem: _getActiveItem(_selectedIndex),
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  String _getActiveItem(int index) {
    switch (index) {
      case 0:
        return 'home';
      case 1:
        return 'bookmarks';
      case 2:
        return 'settings';
      default:
        return 'home';
    }
  }
}
