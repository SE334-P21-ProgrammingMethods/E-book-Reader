import 'package:flutter/material.dart';

class SearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final String? initialValue;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? fillColor;
  final Widget? prefixIcon;

  const SearchBar({
    Key? key,
    required this.hintText,
    required this.onChanged,
    this.initialValue,
    this.padding,
    this.borderColor,
    this.fillColor,
    this.prefixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: TextField(
        controller: initialValue != null
            ? TextEditingController(text: initialValue)
            : null,
        decoration: InputDecoration(
          prefixIcon: prefixIcon ?? const Icon(Icons.search),
          hintText: hintText,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6), 
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: borderColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: borderColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: fillColor ??
              theme.inputDecorationTheme.fillColor ??
              theme.colorScheme.surface,
        ),
        style: TextStyle(color: theme.colorScheme.onSurface),
        onChanged: onChanged,
      ),
    );
  }
}
