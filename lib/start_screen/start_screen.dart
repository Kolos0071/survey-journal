import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:pickquet/cache.dart';
import 'package:pickquet/model.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  List<MeasurementModel> measurementList = [];
  final CacheService cacheService = GetIt.I<CacheService>();
  getCache() async {
    print(await cacheService.getSurvey());
    measurementList = await cacheService.getSurvey();

    setState(() {});
  }

  @override
  void initState() {
    getCache();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () async {
                  await cacheService.clearSurvey();
                  context.push("/home");
                },
                child: const Text("Начать новое измерение")),
            if (measurementList.isNotEmpty)
              ElevatedButton(
                  onPressed: () {
                    context.push("/home", extra: measurementList);

                  }, child: Text("Продолжиь измерение")),
          ],
        ),
      ),
    );
  }
}
