import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:piquet/home_screen/home_screen.dart';
import 'package:piquet/model.dart';
import 'package:piquet/piquet_journal_screen/piquet_journal_screen.dart';
import 'package:piquet/start_screen/start_screen.dart';

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
            final List<MeasurementModel>? measurementList =
                state.extra as List<MeasurementModel>?;
            return HomeScreen(
              measurementList: measurementList ?? [],
            );
          },
        ),
        GoRoute(path: "piquets",
        builder: (context, state) {
          final List<MeasurementModel>? measurementList =
                state.extra as List<MeasurementModel>?;
            return PiquetJournalScreen(
              measurementList: measurementList ?? [],
            );
        },
        )
      ],
    ),
  ],
);
