// lib/utils/responsive_utils.dart
import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Breakpoints
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1200;

  // Device type detection
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  static bool isDesktopOrTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= mobileBreakpoint;
  }

  // Grid configuration
  static int getGridCrossAxisCount(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4; // Desktop
  }

  static double getGridChildAspectRatio(BuildContext context) {
    if (isMobile(context)) return 0.8;
    return 0.85; // Desktop/Tablet
  }

  static double getGridSpacing(BuildContext context) {
    if (isMobile(context)) return 12;
    return 16; // Desktop/Tablet
  }

  // Padding
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    }
    return EdgeInsets.symmetric(
      horizontal: MediaQuery.of(context).size.width * 0.1,
      vertical: 24,
    );
  }

  static EdgeInsets getContentPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    }
    return const EdgeInsets.all(24);
  }

  // Max content width for desktop
  static double getMaxContentWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    return 1200; // Max width for desktop content
  }

  // Search bar configuration
  static double getSearchBarMaxWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    return 600; // Max width for search bar on desktop
  }

  // Detail screen configuration
  static bool shouldUseWideLayout(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  static double getDetailImageHeight(BuildContext context) {
    if (isMobile(context)) return 300;
    return 400; // Desktop/Tablet
  }

  // Gallery history layout
  static int getHistoryGridCount(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 4;
    return 5; // Desktop
  }

  // Navigation
  static bool shouldUseRail(BuildContext context) {
    return isDesktop(context);
  }

  static bool shouldUseBottomNav(BuildContext context) {
    return !shouldUseRail(context);
  }
}