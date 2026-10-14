// Standalone review entry point. Uses the same page and catalog as the app.
import 'package:flutter/material.dart';
import 'package:sageroute/pages/dongpo_catalog_page.dart';
import 'package:sageroute/services/database_service.dart';
import 'package:sageroute/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.initialize();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const DongpoCatalogPage(),
    ),
  );
}
