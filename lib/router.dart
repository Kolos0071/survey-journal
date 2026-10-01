import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pickquet/home_screen/home_screen.dart';
import 'package:pickquet/piquet_journal_screen/piquet_journal_screen.dart';
import 'package:pickquet/start_screen/start_screen.dart';

final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const StartScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'home',
          builder: (BuildContext context, GoRouterState state) {
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: "piquets",
          builder: (context, state) {
            return const PiquetJournalScreen();
          },
        )
      ],
    ),
  ],
);
