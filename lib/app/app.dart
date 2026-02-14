import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'routes.dart';
import 'app_settings.dart';
import 'theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: settings.themeMode,
      builder: (context, mode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: settings.locale,
          builder: (context, locale, __) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,

              routes: AppRoutes.map,
              initialRoute: AppRoutes.splash,

              // ✅ Language + RTL
              locale: locale,
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              // ✅ Theme
              themeMode: mode,
              theme: AppTheme.light(locale),
              darkTheme: AppTheme.dark(locale),
            );
          },
        );
      },
    );
  }
}
