import 'package:flutter/material.dart';
import 'package:oma/app/di/app_scope.dart';
import 'package:oma/app/router/app_router.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(OmaApp(prefs: prefs));
}

class OmaApp extends StatelessWidget {
  const OmaApp({required this.prefs, super.key});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      prefs: prefs,
      child: MaterialApp.router(
        
        debugShowCheckedModeBanner: false,
        theme: buildOmaTheme(),
        themeMode: ThemeMode.light,
        routerConfig: buildRouter(),
      ),
    );
  }
}
