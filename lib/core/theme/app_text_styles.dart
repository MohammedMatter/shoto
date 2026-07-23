import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shoto/core/theme/app_colors.dart';

abstract class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _base =>
      GoogleFonts.manrope(color: AppColors.textPrimary);

  static TextStyle get displayLarge =>
      _base.copyWith(fontSize: 32.sp, fontWeight: FontWeight.w800, height: 1.2);

  static TextStyle get headlineLarge =>
      _base.copyWith(fontSize: 26.sp, fontWeight: FontWeight.w700, height: 1.25);

  static TextStyle get headlineMedium =>
      _base.copyWith(fontSize: 22.sp, fontWeight: FontWeight.w700, height: 1.25);

  static TextStyle get titleLarge =>
      _base.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w600);

  static TextStyle get bodyLarge =>
      _base.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w500);

  static TextStyle get bodyMedium => _base.copyWith(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle get bodySmall => _base.copyWith(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle get button =>
      _base.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w700);

  static TextStyle get caption => _base.copyWith(
    fontSize: 11.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textDisabled,
    height: 1.4,
  );
}
