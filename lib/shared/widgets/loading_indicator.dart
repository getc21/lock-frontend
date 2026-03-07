import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/riverpod/theme_notifier.dart';
import '../utils/theme_utils.dart';

class LoadingIndicator extends ConsumerWidget {
  final String? message;
  final double size;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 50.0,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.watch(themeProvider.notifier);
    final currentTheme = themeNotifier.currentTheme;
    
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ThemeUtils.isDarkMode(themeState.themeMode, brightness);
    
    final displayColor = color ?? currentTheme.primaryColor;
    final textColor = ThemeUtils.getSecondaryTextColor(isDarkMode);

    return Semantics(
      label: message ?? 'Cargando',
      liveRegion: true,
      child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SpinKitWave(
          color: displayColor,
          size: size,
        ),
        if (message != null) ...[
          const SizedBox(height: 24),
          Text(
            message!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ],
    ), // close Semantics
    );
  }
}

