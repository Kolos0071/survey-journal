import 'package:flutter/material.dart';
import 'package:pickquet/router.dart';

class PickuetApp extends StatelessWidget {
  const PickuetApp({super.key});

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

