import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/widgets/shoto_brand_mark.dart';

/// Shoto's logo, wherever the app needs to show itself to the user.
///
/// This used to be a rounded slab in the accent colour with a Font Awesome
/// phone glyph dropped in the middle, which is a placeholder — it said "an
/// app" rather than "this app", and the glyph came from a library every other
/// Flutter project draws from. It now draws [ShotoBrandMark]: the same
/// geometry the launcher icon and the launch window are generated from, so
/// what the sign-in screen shows is recognisably the thing the user tapped on
/// the home screen.
///
/// Kept as a thin wrapper rather than replaced outright by the mark, for two
/// reasons. Its call sites size it in design pixels through [ScreenUtil] and
/// the mark deliberately does not — the mark is also asked for at exact
/// device pixel sizes by the asset generator, where a design-width scale
/// factor would be wrong. And if the logo ever grows a wordmark beside it,
/// this is where that goes without every call site learning about it.
class ShotoLogo extends StatelessWidget {
  final double size;

  const ShotoLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) => ShotoBrandMark(size: size.w);
}
