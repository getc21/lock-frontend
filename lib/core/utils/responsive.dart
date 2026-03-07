import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';

/// Responsive utility for consistent breakpoint-based layout decisions.
///
/// Usage:
/// ```dart
/// // In a build method:
/// final r = Responsive(context);
/// final padding = r.padding;           // 24 on desktop, 16 on tablet, 12 on mobile
/// final columns = r.value(mobile: 1, tablet: 2, desktop: 4);
/// final dialogWidth = r.dialogWidth(preferred: 600); // clamped to screen
/// if (r.isMobile) { ... }
/// ```
class Responsive {
  final BuildContext context;
  late final double _width;
  late final double _height;

  Responsive(this.context) {
    final size = MediaQuery.sizeOf(context);
    _width = size.width;
    _height = size.height;
  }

  // ── Breakpoint queries ──

  /// Screen width < 768
  bool get isMobile => _width < AppSizes.mobileBreakpoint;

  /// Screen width >= 768 && < 1200
  bool get isTablet =>
      _width >= AppSizes.mobileBreakpoint &&
      _width < AppSizes.tabletBreakpoint;

  /// Screen width >= 1200
  bool get isDesktop => _width >= AppSizes.tabletBreakpoint;

  /// Screen width >= 1920
  bool get isLargeDesktop => _width >= AppSizes.desktopBreakpoint;

  /// Current screen width
  double get width => _width;

  /// Current screen height
  double get height => _height;

  // ── Responsive values ──

  /// Returns a value based on current breakpoint.
  /// [desktop] is required; [tablet] defaults to desktop; [mobile] defaults to tablet.
  T value<T>({
    required T desktop,
    T? tablet,
    T? mobile,
  }) {
    if (isMobile) return mobile ?? tablet ?? desktop;
    if (isTablet) return tablet ?? desktop;
    return desktop;
  }

  // ── Common responsive properties ──

  /// Responsive page content padding
  double get padding => value(
        desktop: AppSizes.spacing24,
        tablet: AppSizes.spacing16,
        mobile: AppSizes.spacing12,
      );

  /// Responsive content padding as EdgeInsets
  EdgeInsets get contentPadding => EdgeInsets.all(padding);

  /// Responsive spacing between sections
  double get sectionSpacing => value(
        desktop: AppSizes.spacing24,
        tablet: AppSizes.spacing16,
        mobile: AppSizes.spacing12,
      );

  // ── Dialog helpers ──

  /// Returns a dialog width clamped to 90% of screen width.
  /// [preferred] is the ideal width on large screens.
  double dialogWidth({double preferred = 600}) {
    final maxAllowed = _width * 0.9;
    return preferred.clamp(280, maxAllowed);
  }

  /// Returns a dialog max height clamped to 90% of screen height.
  /// [preferred] is the ideal height on large screens.
  double dialogMaxHeight({double preferred = 700}) {
    final maxAllowed = _height * 0.9;
    return preferred.clamp(300, maxAllowed);
  }

  /// Returns responsive EdgeInsets for dialog insetPadding.
  /// Ensures dialogs don't overflow on small screens.
  EdgeInsets get dialogInsetPadding => EdgeInsets.symmetric(
        horizontal: value(desktop: 80.0, tablet: 40.0, mobile: 16.0),
        vertical: value(desktop: 40.0, tablet: 24.0, mobile: 16.0),
      );

  // ── Table / content area helpers ──

  /// Responsive table container height based on available viewport.
  /// Returns 70% of screen height, clamped between [min] and [max].
  double tableHeight({double min = 400, double max = 800}) {
    return (_height * 0.70).clamp(min, max);
  }
}
