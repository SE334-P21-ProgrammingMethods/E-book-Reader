import 'package:ebook_reader/screens/auth/sign-up/signup_screen.dart';
import 'package:ebook_reader/screens/library/library_screen.dart';
import 'package:ebook_reader/screens/theme/theme_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
    BlocProvider(
      create: (context) => ThemeCubit(),
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
        // Get the font size scale factor from ThemeCubit
        final fontScale = context.read<ThemeCubit>().fontSizeScale;

        // Create base theme with scaled text styles
        final baseTextTheme = GoogleFonts.lobsterTextTheme(
          Typography.englishLike2021,
        )
            .apply(
          displayColor: Colors.white,
          bodyColor: Colors.white,
        );

        final scaledTextTheme = baseTextTheme.copyWith(
          displayLarge: baseTextTheme.displayLarge?.copyWith(
              fontSize: baseTextTheme.displayLarge!.fontSize! * fontScale),
          displayMedium: baseTextTheme.displayMedium?.copyWith(
              fontSize: baseTextTheme.displayMedium!.fontSize! * fontScale),
          displaySmall: baseTextTheme.displaySmall?.copyWith(
              fontSize: baseTextTheme.displaySmall!.fontSize! * fontScale),
          headlineLarge: baseTextTheme.headlineLarge?.copyWith(
              fontSize: baseTextTheme.headlineLarge!.fontSize! * fontScale),
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(
              fontSize: baseTextTheme.headlineMedium!.fontSize! * fontScale),
          headlineSmall: baseTextTheme.headlineSmall?.copyWith(
              fontSize: baseTextTheme.headlineSmall!.fontSize! * fontScale),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
              fontSize: baseTextTheme.titleLarge!.fontSize! * fontScale),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
              fontSize: baseTextTheme.titleMedium!.fontSize! * fontScale),
          titleSmall: baseTextTheme.titleSmall?.copyWith(
              fontSize: baseTextTheme.titleSmall!.fontSize! * fontScale),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(
              fontSize: baseTextTheme.bodyLarge!.fontSize! * fontScale),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(
              fontSize: baseTextTheme.bodyMedium!.fontSize! * fontScale),
          bodySmall: baseTextTheme.bodySmall?.copyWith(
              fontSize: baseTextTheme.bodySmall!.fontSize! * fontScale),
          labelLarge: baseTextTheme.labelLarge?.copyWith(
              fontSize: baseTextTheme.labelLarge!.fontSize! * fontScale),
          labelMedium: baseTextTheme.labelMedium?.copyWith(
              fontSize: baseTextTheme.labelMedium!.fontSize! * fontScale),
          labelSmall: baseTextTheme.labelSmall?.copyWith(
              fontSize: baseTextTheme.labelSmall!.fontSize! * fontScale),
        );

        return MaterialApp(
          title: 'E-book Reader',
          theme: ThemeData(
            textTheme: scaledTextTheme,
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
          ),
          darkTheme: ThemeData(
            textTheme: scaledTextTheme,
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
            '/forgot-password': (context) => ForgetPasswordScreen.newInstance(
              toggleTheme: () => context.read<ThemeCubit>().toggleTheme(),
            ),
            '/sign-up': (context) => SignUpScreen.newInstance(
              toggleTheme: () => context.read<ThemeCubit>().toggleTheme(),
            ),
            '/sign-in': (context) => SignInScreen.newInstance(
              toggleTheme: () => context.read<ThemeCubit>().toggleTheme(),
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
              return PDFReaderScreen.newInstance(
                  book: book,
                  initialPage: args['initialPage'] as int? ?? 1);
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
              return EPUBReaderScreen.newInstance(
                book: book,
                initialCfi: args['initialCfi'] as String?,
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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get the current route name
        final currentRoute = ModalRoute.of(context)?.settings.name;

        // If we're on the sign-up screen, don't redirect
        if (currentRoute == '/sign-up') {
          return SignUpScreen.newInstance(
            toggleTheme: () => context.read<ThemeCubit>().toggleTheme(),
          );
        } else if (snapshot.hasData) {
          return const MainScreen();
        }

        // For all other cases, show sign in screen
        return SignInScreen.newInstance(
          toggleTheme: () => context.read<ThemeCubit>().toggleTheme(),
        );
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
      LibraryScreen.newInstance(),
      BookmarksScreen.newInstance(),
      SettingsScreen.newInstance(),
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
