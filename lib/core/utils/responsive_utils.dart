import 'package:flutter/widgets.dart';
import '../constants/app_dimensions.dart';

enum ScreenSize { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  ScreenSize get screenSize {
    final w = screenWidth;
    if (w >= AppDimensions.breakpointDesktop) return ScreenSize.desktop;
    if (w >= AppDimensions.breakpointTablet) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }

  bool get isMobile => screenSize == ScreenSize.mobile;
  bool get isTablet => screenSize == ScreenSize.tablet;
  bool get isDesktop => screenSize == ScreenSize.desktop;
}
