import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../screens/theme/theme_cubit.dart';

class FontSizeSettings extends StatelessWidget {
  const FontSizeSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Small',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            Text(
              'Medium',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            Text(
              'Large',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
        Slider(
          value: themeState.fontSize,
          min: 0,
          max: 2,
          divisions: 2,
          label: _getFontSizeLabel(themeState.fontSize),
          onChanged: (double value) {
            context.read<ThemeCubit>().setFontSize(value);
          },
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Theme.of(context).colorScheme.secondary,
        ),
      ],
    );
  }

  String _getFontSizeLabel(double size) {
    switch (size) {
      case 0:
        return 'Small (1x)';
      case 1:
        return 'Medium (1.5x)';
      case 2:
        return 'Large (2x)';
      default:
        return 'Medium (1.5x)';
    }
  }
}
