part of 'theme_cubit.dart';

class ThemeState extends Equatable {
  final ThemeMode themeMode;
  final double fontSize;

  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.fontSize = 0.0,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    double? fontSize,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  @override
  List<Object?> get props => [themeMode, fontSize];
}
