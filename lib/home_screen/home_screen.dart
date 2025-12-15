import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:piquet/cache.dart';
import 'package:piquet/home_screen/model.dart';
import 'package:piquet/model.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key, this.measurementList});
  List<MeasurementModel>? measurementList;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<FormViewModel> formViemModel = [
    FormViewModel(
        label: "От",
        controller: TextEditingController(),
        type: TextInputType.text,
        isRequired: true),
    FormViewModel(
        label: "До",
        controller: TextEditingController(),
        type: TextInputType.text,
        isRequired: true),
    FormViewModel(
        label: "Дистанция, м",
        controller: TextEditingController(),
        type: TextInputType.number,
        isRequired: true),
    FormViewModel(
        label: "Азимут, градусы",
        controller: TextEditingController(),
        type: TextInputType.number,
        isRequired: true),
    FormViewModel(
        label: "Угол, градусы",
        controller: TextEditingController(),
        type: TextInputType.number,
        isRequired: true),
    FormViewModel(
        label: "Лево",
        controller: TextEditingController(),
        prevController: TextEditingController(),
        type: TextInputType.number),
    FormViewModel(
        label: "Право",
        controller: TextEditingController(),
        prevController: TextEditingController(),
        type: TextInputType.number),
    FormViewModel(
        label: "Верх",
        controller: TextEditingController(),
        prevController: TextEditingController(),
        type: TextInputType.number),
    FormViewModel(
        label: "Низ",
        controller: TextEditingController(),
        prevController: TextEditingController(),
        type: TextInputType.number),
  ];

  final _formKey = GlobalKey<FormState>();
  final CacheService cacheService = GetIt.I<CacheService>();
  void clearForm() {
    _formKey.currentState!.reset();
  }

  void saveMeasurement() async {
    if (_formKey.currentState!.validate()) {
      final List<dynamic> formValueList = formViemModel.map((item) {
        if (item.prevController != null) {
          return [
            item.controller.text.isNotEmpty
                ? num.parse(item.controller.text)
                : 0,
            item.prevController!.text.isNotEmpty
                ? num.parse(item.prevController!.text)
                : 0
          ];
        }
        return item.controller.text;
      }).toList();
      final MeasurementModel measurement = MeasurementModel(
          from: formValueList[0],
          to: formValueList[1],
          distance: num.parse(formValueList[2]),
          compass: num.parse(formValueList[3].replaceAll(",", ".")),
          angle: num.parse(formValueList[4].replaceAll(",", ".")),
          left: formValueList[5].isNotEmpty ? formValueList[5] : "0",
          right: formValueList[6].isNotEmpty ? formValueList[6] : "0",
          top: formValueList[7].isNotEmpty ? formValueList[7] : "0",
          bottom: formValueList[8].isNotEmpty ? formValueList[8] : "0");

      widget.measurementList!.add(measurement);

      List<Map<String, dynamic>> jsonList =
          widget.measurementList!.map((item) => item.toJson()).toList();

      if (await cacheService.cacheSurvey(jsonList)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Измерение сохранено")));
        clearForm();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Произошла ошибка")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: ElevatedButton(
            onPressed: () {
              context.push("/piquets", extra: widget.measurementList);
            },
            child: const Text("Пикетажный журнал")),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Form(
            key: _formKey,
            child: ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(
                height: 12,
              ),
              itemCount: formViemModel.length + 1,
              itemBuilder: (context, index) {
                if (index == formViemModel.length) {
                  return const SizedBox(
                    height: 60,
                  );
                } else {
                  final item = formViemModel[index];

                  return Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(item.label),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  validator: (value) {
                                    if (item.isRequired &&
                                        (value == null || value.isEmpty)) {
                                      return 'Обязательное поле';
                                    }

                                    if (item.type == TextInputType.number) {
                                      RegExp nonDigitRegex =
                                          RegExp(r"[^0-9.,]");
                                      if (!nonDigitRegex.hasMatch(value!)) {
                                        return null;
                                      } else {
                                        return "Значение должно быть цифровым";
                                      }
                                    }
                                    return null;
                                  },
                                  controller: item.controller,
                                  keyboardType: item.type,
                                ),
                              ),
                              if (item.prevController != null)
                                const SizedBox(
                                  width: 12,
                                ),
                              if (item.prevController != null)
                                Expanded(
                                  child: TextFormField(
                                    validator: (value) {
                                      if (item.isRequired &&
                                          (value == null || value.isEmpty)) {
                                        return 'Обязательное поле';
                                      }

                                      if (item.type == TextInputType.number) {
                                        RegExp nonDigitRegex =
                                            RegExp(r"[^0-9.,]");
                                        if (!nonDigitRegex.hasMatch(value!)) {
                                          return null;
                                        } else {
                                          return "Значение должно быть цифровым";
                                        }
                                      }
                                      return null;
                                    },
                                    controller: item.prevController,
                                    keyboardType: item.type,
                                  ),
                                ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                }
              },
            )),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ElevatedButton(
        onPressed: saveMeasurement,
        child: const Text("Продолжить"),
      ),
    );
  }
}
