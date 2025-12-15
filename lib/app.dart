import 'package:flutter/material.dart';
import 'package:piquet/router.dart';

class PiquetApp extends StatelessWidget {
  const PiquetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Пикетажный журнал',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

