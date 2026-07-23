import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shoto/core/theme/app_colors.dart';

class ShotoLogo extends StatelessWidget {
  final double size;

  const ShotoLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size.w * 0.2),
        boxShadow: [BoxShadow(blurRadius: 24, offset: const Offset(0, 5))],
      ),
      child: Center(
        child: FaIcon(
          FontAwesomeIcons.mobileScreen,
          color: Colors.white,
          size: size.w * 0.52,
        ),
      ),
    );
  }
}
