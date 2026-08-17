import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/theme/app_motion.dart';

class HomeGutter extends StatelessWidget {
  final Widget child;

  const HomeGutter({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 20.w),
    child: child,
  );
}

class HomeEnter extends StatelessWidget {
  final Animation<double> parent;
  final int index;
  final Widget child;

  const HomeEnter({
    super.key,
    required this.parent,
    required this.index,
    required this.child,
  });

  static const Duration total = Duration(milliseconds: 520);

  static const double _step = 60 / 520;
  static const double _span = 220 / 520;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;

    final Animation<double> t = parent.drive(
      CurveTween(
        curve: Interval(
          index * _step,
          index * _step + _span,
          curve: AppMotion.standard,
        ),
      ),
    );

    return FadeTransition(
      opacity: t,
      child: SlideTransition(
        position: t.drive(
          Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }
}
