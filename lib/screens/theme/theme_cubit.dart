import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  static const String _themeKey = 'theme_mode';
  static const String _fontSizeKey = 'font_size';
  SharedPreferences? _prefs;

  ThemeCubit() : super(const ThemeState()) {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    if (_prefs == null) return;
    final themeMode = ThemeMode.values[_prefs!.getInt(_themeKey) ?? 0];
    final fontSize = _prefs!.getDouble(_fontSizeKey) ?? 0.0;
    emit(state.copyWith(themeMode: themeMode, fontSize: fontSize));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_prefs == null) return;
    await _prefs!.setInt(_themeKey, mode.index);
    emit(state.copyWith(themeMode: mode));
  }

  void toggleTheme() {
    final isDark = state.themeMode == ThemeMode.dark;
    setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setFontSize(double size) async {
    if (_prefs == null) return;
    await _prefs!.setDouble(_fontSizeKey, size);
    emit(state.copyWith(fontSize: size));
  }

  static const double smallScale = 1.0;
  static const double mediumScale = 1.5;
  static const double largeScale = 2.0;

  double get fontSizeScale {
    final fontSize = state.fontSize;
    if (fontSize <= 0) return smallScale;
    if (fontSize >= 2) return largeScale;
    final scale = smallScale + (fontSize / 2) * (largeScale - smallScale);
    if (scale <= 0) return 1.0;
    return scale;
  }
}
