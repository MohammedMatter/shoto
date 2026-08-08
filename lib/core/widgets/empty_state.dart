import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/widgets/shoto_mark.dart';

/// An empty screen, entered rather than simply appearing.
///
/// This is one of the very few places generous motion belongs. Everywhere
/// else in Shoto the rule is "as short as possible" — but an empty state is
/// rare, it is a moment where the user is being told something rather than
/// operating something, and it is the one screen with nothing else on it to
/// carry the eye. A quiet rise and fade gives it a beginning.
///
/// Still transform + opacity only, and still under 300ms.
///
/// The line that used to sit here claimed it was "gone entirely under reduced
/// motion". It was not — there was no check of any kind, and the rise and the
/// fade both played regardless. That is now handled below, and handled
/// differently from what the old claim promised: reduced motion means **fewer
/// and gentler** animations, not none. Removing the movement is the point;
/// removing the fade as well would make the screen teleport in, which is a
/// harsher change than the one being avoided.
class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.sheet,
  )..forward();

  late final Animation<double> _in = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.standard,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final IconData icon = widget.icon;
    final String title = widget.title;
    final String message = widget.message;
    final Widget? action = widget.action;

    final Widget body = _body(context, icon, title, message, action);

    // The fade survives in both branches; only the travel is conditional.
    return FadeTransition(
      opacity: _in,
      child: AppMotion.reduced(context)
          ? body
          : SlideTransition(
              // Eight logical pixels, not forty. The point is that it
              // arrived, not that it travelled.
              position: Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(_in),
              child: body,
            ),
    );
  }

  Widget _body(
    BuildContext context,
    IconData icon,
    String title,
    String message,
    Widget? action,
  ) {
    return ListenableBuilder(
      listenable: sl<ThemeController>(),
      builder: (context, child) => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The icon each caller already passes is now what the mark is
              // holding rather than a glyph in a circle, so all fourteen
              // empty states gained the same character without any of them
              // having to say anything new.
              ShotoMark(
                icon: icon,
                open: AppMotion.reduced(context) ? null : _in,
              ),
              SizedBox(height: 20.h),
              Text(
                title,
                style: context.text.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                message,
                style: context.text.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[SizedBox(height: 20.h), action],
            ],
          ),
        ),
      ),
    );
  }
}
