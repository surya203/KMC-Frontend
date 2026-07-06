import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

import 'kmc_scroll_behavior.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorSchemeSeed: AppColors.primary,
    textTheme: GoogleFonts.interTextTheme(),
    scrollbarTheme: KmcScrollbarTheme.data,
  );
}