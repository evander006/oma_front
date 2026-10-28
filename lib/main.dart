import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/di/app_scope.dart';
import 'package:oma/app/router/app_router.dart';
import 'package:oma/theme/oma_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(OmaApp(prefs: prefs));
}

class OmaApp extends StatefulWidget {
  const OmaApp({required this.prefs, super.key});

  final SharedPreferences prefs;

  @override
  State<OmaApp> createState() => _OmaAppState();
}

class _OmaAppState extends State<OmaApp> {
  // Keep the router alive for the app's entire foreground/background session.
  // Rebuilds must not restart the four-slide introduction.
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      prefs: widget.prefs,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: buildOmaTheme(),
        themeMode: ThemeMode.light,
        routerConfig: _router,
      ),
    );
  }
}
