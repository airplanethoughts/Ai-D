import 'package:flutter/material.dart';

/// Shared presentation for the local demo and connected app.
ThemeData buildAppTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF246B5C)),
  scaffoldBackgroundColor: const Color(0xFFF7F9F6),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF7F9F6),
    centerTitle: false,
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
  ),
);
