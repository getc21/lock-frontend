import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/constants/app_sizes.dart';
import '../providers/riverpod/theme_notifier.dart';
import '../utils/theme_utils.dart';

/// Loading profesional con esqueleto de tabla
class ProfessionalLoading extends ConsumerWidget {
  final String? message;
  final int rowCount;
  final int columnCount;

  const ProfessionalLoading({
    super.key,
    this.message,
    this.rowCount = 8,
    this.columnCount = 5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.watch(themeProvider.notifier);
    final currentTheme = themeNotifier.currentTheme;
    
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ThemeUtils.isDarkMode(themeState.themeMode, brightness);
    
    final bgColor = isDarkMode ? Colors.grey[900] : Colors.white;
    
    return Column(
      children: [
        // Header con icono y mensaje
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.spacing24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinKitRing(
                  color: currentTheme.primaryColor,
                  size: 30,
                  lineWidth: 2,
                ),
                const SizedBox(width: AppSizes.spacing16),
                Text(
                  message!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ThemeUtils.getSecondaryTextColor(isDarkMode),
                  ),
                ),
              ],
            ),
          ),
        
        // Skeleton Loader - Tabla
        Expanded(
          child: Card(
            color: bgColor,
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.spacing16),
              child: ListView.builder(
                itemCount: rowCount,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.spacing12),
                    child: Row(
                      children: List.generate(columnCount, (colIndex) {
                        final isLastColumn = colIndex == columnCount - 1;
                        final width = isLastColumn 
                            ? 60.0 
                            : (colIndex == 0 ? 150.0 : 100.0);
                        
                        return Expanded(
                          flex: isLastColumn ? 0 : 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.spacing8,
                            ),
                            child: _ShimmerSkeleton(
                              width: isLastColumn ? width : null,
                              height: 20,
                              isDark: isDarkMode,
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget de esqueleto con efecto shimmer
class _ShimmerSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final bool isDark;

  const _ShimmerSkeleton({
    this.width,
    required this.height,
    required this.isDark,
  });

  @override
  State<_ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<_ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark 
        ? Colors.grey[800]!
        : Colors.grey[300]!;
    final highlightColor = widget.isDark
        ? Colors.grey[700]!
        : Colors.grey[200]!;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animationController.value - 0.3).clamp(0.0, 1.0),
                _animationController.value.clamp(0.0, 1.0),
                (_animationController.value + 0.3).clamp(0.0, 1.0),
              ],
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Versión simple y compacta para loading rápido
class SimpleLoadingOverlay extends ConsumerWidget {
  final String? message;

  const SimpleLoadingOverlay({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.watch(themeProvider.notifier);
    final currentTheme = themeNotifier.currentTheme;
    
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ThemeUtils.isDarkMode(themeState.themeMode, brightness);

    return Container(
      color: Colors.black.withValues(alpha: 0.1),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSizes.spacing32),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpinKitCircle(
                color: currentTheme.primaryColor,
                size: 50,
              ),
              if (message != null) ...[
                const SizedBox(height: AppSizes.spacing20),
                Text(
                  message!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ThemeUtils.getSecondaryTextColor(isDarkMode),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
