import 'package:flutter/material.dart';
import 'screens/site_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
