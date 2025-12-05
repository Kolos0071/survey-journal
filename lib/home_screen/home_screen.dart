import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:pickquet/cache.dart';
import 'package:pickquet/home_screen/model.dart';
import 'package:pickquet/model.dart';

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
        label: "К",
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
        type: TextInputType.number),
    FormViewModel(
        label: "Право",
        controller: TextEditingController(),
        type: TextInputType.number),
    FormViewModel(
        label: "Верх",
        controller: TextEditingController(),
        type: TextInputType.number),
    FormViewModel(
        label: "Низ",
        controller: TextEditingController(),
        type: TextInputType.number),
  ];

  final _formKey = GlobalKey<FormState>();
  final CacheService cacheService = GetIt.I<CacheService>();
  void clearForm() {
    _formKey.currentState!.reset();
  }
  void saveMeasurement() async {
    if (_formKey.currentState!.validate()) {
      final List<String> formValueList =
          formViemModel.map((item) => item.controller.text).toList();
      final MeasurementModel measurement = MeasurementModel(
          from: formValueList[0],
          to: formValueList[1],
          distance: num.parse(formValueList[2]),
          compass: num.parse(formValueList[3].replaceAll(",", ".")),
          angle: num.parse(formValueList[4].replaceAll(",", ".")),
          left: num.parse(formValueList[5].isNotEmpty?formValueList[5].replaceAll(",", "."):"0"),
          right: num.parse(formValueList[6].isNotEmpty?formValueList[6].replaceAll(",", "."):"0"),
          top: num.parse(formValueList[7].isNotEmpty?formValueList[7].replaceAll(",", "."):"0"),
          bottom: num.parse(formValueList[8].isNotEmpty?formValueList[8].replaceAll(",", "."):"0"));

          widget.measurementList!.add(measurement);


    List<Map<String, dynamic>> jsonList =  widget.measurementList!.map((item) => item.toJson()).toList();

      if (await cacheService.cacheSurvey(jsonList)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Измерение сохранено")));
          clearForm();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Произошла ошибка")));
      }

            print(await cacheService.getSurvey());

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: ElevatedButton(onPressed: (){
          context.push("/piquets",extra: widget.measurementList);
        }, child: Text("Пикетажный журнал")),
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
                          TextFormField(
                            validator: (value) {
                              if (item.isRequired &&
                                  (value == null || value.isEmpty)) {
                                return 'Обязательное поле';
                              }

                              if (item.type == TextInputType.number) {
                                RegExp nonDigitRegex = RegExp(r"[^0-9.,]");
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
