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
    measurementList = await cacheService.getSurvey();
    setState(() {});
  }

  Future<String> _nameSurvey(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (dialogContext) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text("Введите название измерения"),
          content: TextField(
            controller: controller,
          ),
          actions: [
            ElevatedButton(
                onPressed: () {
                  if (controller.text.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text("Введите название")));
                  } else {
                    Navigator.of(dialogContext).pop(controller.text);
                  }
                },
                child: const Text("Подтвердить")),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop("");
                },
                child: const Text("Отмена")),
          ],
        );
      },
    );
  }

  Future<bool?> _confirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Начать новое измерение?"),
          content:
              const Text("Может привести к потери данных предыдущих измерений"),
          actions: [
            ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                child: const Text("Подтвердить")),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text("Отмена")),
          ],
        );
      },
    );
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
                  if (measurementList.isNotEmpty) {
                    final bool? confirmed = await _confirmationDialog(context);
                    if (confirmed != null && confirmed) {
                      await cacheService.clearSurvey();
                      setState(() {
                        measurementList.clear();
                      });
                      context.push("/home");
                    }
                  } else {
                    final String surveyName = await _nameSurvey(context);
                    print(surveyName);
                    if (surveyName.isNotEmpty) context.push("/home");
                  }
                },
                child: const Text("Начать новое измерение")),
            if (measurementList.isNotEmpty)
              ElevatedButton(
                  onPressed: () {
                    context.push("/home", extra: measurementList);
                  },
                  child: Text("Продолжиь измерение")),
          ],
        ),
      ),
    );
  }
}
