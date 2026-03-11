import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'screens/site_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: [Locale('fr', 'FR'), Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: Locale('fr', 'FR'),
      startLocale: Locale('fr', 'FR'),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'Construction Site Manager',
      theme: ThemeData(
        // This is the theme of your application.
        colorScheme: .fromSeed(seedColor: Colors.lightBlueAccent.shade400),
        useMaterial3: true,
      ),
      home: SiteListPage(),
    );
  }
}
