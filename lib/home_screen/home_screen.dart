import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:pickquet/cache.dart';
import 'package:pickquet/home_screen/model.dart';
import 'package:pickquet/model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
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

  final TextEditingController _commentController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final CacheService cacheService = GetIt.I<CacheService>();
  void clearForm() {
    _formKey.currentState!.reset();
  }

  void saveMeasurement() async {
    if (_formKey.currentState!.validate()) {
      final List<dynamic> formValueList = formViemModel.map((item) {
        if (item.prevController != null) {
          final bool curEmpty = item.controller.text.isEmpty;
          final bool prevEmpty = item.prevController!.text.isEmpty;
          // Both sides left blank => not measured at all (Therion: bare "0"),
          // as opposed to an explicit [0, 0] reading.
          if (curEmpty && prevEmpty) {
            return null;
          }
          return <num>[
            curEmpty ? 0 : num.parse(item.controller.text),
            prevEmpty ? 0 : num.parse(item.prevController!.text),
          ];
        }
        return item.controller.text;
      }).toList();
      final MeasurementModel measurement = MeasurementModel(
          from: formValueList[0] as String,
          to: formValueList[1] as String,
          distance: num.parse(formValueList[2] as String),
          compass:
              num.parse((formValueList[3] as String).replaceAll(",", ".")),
          angle: num.parse((formValueList[4] as String).replaceAll(",", ".")),
          left: formValueList[5] as List<num>?,
          right: formValueList[6] as List<num>?,
          top: formValueList[7] as List<num>?,
          bottom: formValueList[8] as List<num>?,
          comment: _commentController.text.trim());

      // Read the freshest persisted list right before appending, so this
      // never clobbers measurements added/edited elsewhere (e.g. the journal
      // screen) since this screen was opened.
      final List<MeasurementModel> currentList =
          await cacheService.getSurvey();
      currentList.add(measurement);

      if (await cacheService.saveSurvey(currentList)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Измерение сохранено")));
        clearForm();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Произошла ошибка")));
      }
    }
  }

  Widget _buildField(FormViewModel item) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
      padding: const EdgeInsets.all(6.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(isDense: true),
                  validator: (value) {
                    if (item.isRequired &&
                        (value == null || value.isEmpty)) {
                      return 'Обязательное поле';
                    }

                    if (item.type == TextInputType.number) {
                      RegExp nonDigitRegex = RegExp(r"[^-0-9.,]");
                      if (!nonDigitRegex.hasMatch(value!)) {
                        return null;
                      } else {
                        return "Должно быть цифровым";
                      }
                    }
                    return null;
                  },
                  controller: item.controller,
                  keyboardType: item.type,
                ),
              ),
              if (item.prevController != null) const SizedBox(width: 6),
              if (item.prevController != null)
                Expanded(
                  child: TextFormField(
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(isDense: true),
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
                          return "Должно быть цифровым";
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: ElevatedButton(
            onPressed: () {
              context.push("/piquets");
            },
            child: const Text("Пикетажный журнал")),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      mainAxisExtent: 100,
                    ),
                    itemCount: formViemModel.length,
                    itemBuilder: (context, index) {
                      return _buildField(formViemModel[index]);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: TextFormField(
                    controller: _commentController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Комментарий",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            )),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ElevatedButton(
        onPressed: saveMeasurement,
        child: const Text("Записать"),
      ),
    );
  }
}
