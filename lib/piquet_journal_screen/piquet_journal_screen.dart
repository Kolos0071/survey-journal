import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pickquet/cache.dart';
import 'package:pickquet/model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// A pair value is null when that side wasn't measured at all (Therion:
/// bare "0" / carry over previous value), as opposed to an explicit [0, 0].
String lrudToken(List<num>? pair) {
  if (pair == null) return '0';
  return '[${pair[0]} ${pair[1]}]';
}

String lrudDisplay(List<num>? pair) {
  if (pair == null) return '0';
  return pair.toString();
}

class PiquetJournalScreen extends StatefulWidget {
  const PiquetJournalScreen({super.key});

  @override
  State<PiquetJournalScreen> createState() => _PiquetJournalScreenState();
}

class _PiquetJournalScreenState extends State<PiquetJournalScreen> {
  final CacheService cacheService = GetIt.I<CacheService>();
  final List<String> tableHeader = [
    "from",
    "to",
    "tape",
    "compass",
    "clino",
    "left",
    "right",
    "up",
    "down",
    "comment",
    "",
  ];

  List<MeasurementModel> measurementList = [];
  bool _loading = true;

  static const String _fileName = 'piquet_journal.txt';

  @override
  void initState() {
    super.initState();
    _loadSurvey();
  }

  Future<void> _loadSurvey() async {
    final List<MeasurementModel> list = await cacheService.getSurvey();
    if (!mounted) return;
    setState(() {
      measurementList = list;
      _loading = false;
    });
  }

  String get _fileContent {
    final List<String> rows = [];
    for (final item in measurementList) {
      final String comment =
          item.comment.isNotEmpty ? ' #${item.comment}' : '';
      rows.add("${item.from} ${item.to} ${item.distance} ${item.compass} "
          "${item.angle} ${lrudToken(item.left)} ${lrudToken(item.right)} ${lrudToken(item.top)} ${lrudToken(item.bottom)}$comment");
    }
    return rows.join('\n');
  }

  Future<void> _deleteAt(int index) async {
    final MeasurementModel target = measurementList[index];
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Удалить измерение?'),
          content: Text('${target.from} → ${target.to}'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Отмена')),
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Удалить')),
          ],
        );
      },
    );
    if (confirmed != true) return;

    // Re-read the freshest list before mutating so we never clobber a
    // concurrent change (e.g. a new measurement added from the home screen).
    final List<MeasurementModel> currentList = await cacheService.getSurvey();
    final int freshIndex = currentList.indexOf(target);
    if (freshIndex != -1) {
      currentList.removeAt(freshIndex);
    } else if (index < currentList.length) {
      currentList.removeAt(index);
    }
    await cacheService.saveSurvey(currentList);
    if (!mounted) return;
    setState(() {
      measurementList = currentList;
    });
  }

  Future<void> _editAt(int index) async {
    final MeasurementModel target = measurementList[index];
    final MeasurementModel? edited = await showDialog<MeasurementModel>(
      context: context,
      builder: (dialogContext) =>
          _EditMeasurementDialog(measurement: target),
    );
    if (edited == null) return;

    final List<MeasurementModel> currentList = await cacheService.getSurvey();
    final int freshIndex = currentList.indexOf(target);
    final int targetIndex = freshIndex != -1 ? freshIndex : index;
    if (targetIndex < currentList.length) {
      currentList[targetIndex] = edited;
    } else {
      currentList.add(edited);
    }
    await cacheService.saveSurvey(currentList);
    if (!mounted) return;
    setState(() {
      measurementList = currentList;
    });
  }

  Future<void> _saveAs(BuildContext context) async {
    try {
      final Uint8List bytes = Uint8List.fromList(utf8.encode(_fileContent));

      final String? savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить пикетажный журнал',
        fileName: _fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (!context.mounted) return;

      if (savedPath == null) {
        return;
      }

      final File file = File(savedPath);
      if (!(await file.exists())) {
        // On some platforms saveFile only returns the chosen path
        // without writing the bytes, so write it ourselves.
        await file.writeAsBytes(bytes);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Файл сохранен: $savedPath')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    }
  }

  Future<void> _share(BuildContext context) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/$_fileName');
      await tempFile.writeAsString(_fileContent);

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Пикетажный журнал',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка отправки: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Пикетажный журнал"),
      ),
      floatingActionButton: (_loading || measurementList.isEmpty)
          ? null
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'share',
                  onPressed: () => _share(context),
                  tooltip: 'Поделиться',
                  child: const Icon(Icons.share),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: 'saveAs',
                  onPressed: () => _saveAs(context),
                  tooltip: 'Сохранить как',
                  child: const Icon(Icons.save),
                ),
              ],
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : measurementList.isEmpty
              ? const Center(child: Text('Нет данных для отображения'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Table(
                        border: TableBorder.all(),
                        defaultColumnWidth: const IntrinsicColumnWidth(),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                            ),
                            children: tableHeader
                                .map((item) => TableCell(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          item,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                          for (int index = 0;
                              index < measurementList.length;
                              index++)
                            _buildRow(measurementList[index], index),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  TableRow _buildRow(MeasurementModel row, int index) {
    return TableRow(
      children: [
        TableCell(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(row.from),
        )),
        TableCell(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(row.to),
        )),
        TableCell(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(row.distance.toStringAsFixed(2)),
        )),
        TableCell(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(row.compass.toStringAsFixed(1)),
        )),
        TableCell(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(row.angle.toStringAsFixed(1)),
        )),
        TableCell(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(lrudDisplay(row.left)),
        )),
        TableCell(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(lrudDisplay(row.right)),
        )),
        TableCell(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(lrudDisplay(row.top)),
        )),
        TableCell(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(lrudDisplay(row.bottom)),
        )),
        TableCell(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(row.comment),
        )),
        TableCell(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Изменить',
                onPressed: () => _editAt(index),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                tooltip: 'Удалить',
                onPressed: () => _deleteAt(index),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditMeasurementDialog extends StatefulWidget {
  const _EditMeasurementDialog({required this.measurement});

  final MeasurementModel measurement;

  @override
  State<_EditMeasurementDialog> createState() =>
      _EditMeasurementDialogState();
}

class _EditMeasurementDialogState extends State<_EditMeasurementDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  late final TextEditingController _distanceController;
  late final TextEditingController _compassController;
  late final TextEditingController _angleController;
  late final TextEditingController _leftController;
  late final TextEditingController _leftPrevController;
  late final TextEditingController _rightController;
  late final TextEditingController _rightPrevController;
  late final TextEditingController _topController;
  late final TextEditingController _topPrevController;
  late final TextEditingController _bottomController;
  late final TextEditingController _bottomPrevController;
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    final m = widget.measurement;
    _fromController = TextEditingController(text: m.from);
    _toController = TextEditingController(text: m.to);
    _distanceController = TextEditingController(text: m.distance.toString());
    _compassController = TextEditingController(text: m.compass.toString());
    _angleController = TextEditingController(text: m.angle.toString());
    _leftController =
        TextEditingController(text: m.left != null ? '${m.left![0]}' : '');
    _leftPrevController =
        TextEditingController(text: m.left != null ? '${m.left![1]}' : '');
    _rightController =
        TextEditingController(text: m.right != null ? '${m.right![0]}' : '');
    _rightPrevController =
        TextEditingController(text: m.right != null ? '${m.right![1]}' : '');
    _topController =
        TextEditingController(text: m.top != null ? '${m.top![0]}' : '');
    _topPrevController =
        TextEditingController(text: m.top != null ? '${m.top![1]}' : '');
    _bottomController = TextEditingController(
        text: m.bottom != null ? '${m.bottom![0]}' : '');
    _bottomPrevController = TextEditingController(
        text: m.bottom != null ? '${m.bottom![1]}' : '');
    _commentController = TextEditingController(text: m.comment);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _distanceController.dispose();
    _compassController.dispose();
    _angleController.dispose();
    _leftController.dispose();
    _leftPrevController.dispose();
    _rightController.dispose();
    _rightPrevController.dispose();
    _topController.dispose();
    _topPrevController.dispose();
    _bottomController.dispose();
    _bottomPrevController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.isEmpty) return 'Обязательное поле';
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.isEmpty) return 'Обязательное поле';
    if (RegExp(r"[^-0-9.,]").hasMatch(value)) {
      return 'Должно быть цифровым';
    }
    return null;
  }

  String? _optionalNumberValidator(String? value) {
    if (value == null || value.isEmpty) return null;
    if (RegExp(r"[^-0-9.,]").hasMatch(value)) {
      return 'Должно быть цифровым';
    }
    return null;
  }

  List<num>? _pairOrNull(
      TextEditingController cur, TextEditingController prev) {
    final bool curEmpty = cur.text.isEmpty;
    final bool prevEmpty = prev.text.isEmpty;
    if (curEmpty && prevEmpty) return null;
    return <num>[
      curEmpty ? 0 : num.parse(cur.text),
      prevEmpty ? 0 : num.parse(prev.text),
    ];
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final MeasurementModel edited = MeasurementModel(
      from: _fromController.text,
      to: _toController.text,
      distance: num.parse(_distanceController.text),
      compass: num.parse(_compassController.text.replaceAll(",", ".")),
      angle: num.parse(_angleController.text.replaceAll(",", ".")),
      left: _pairOrNull(_leftController, _leftPrevController),
      right: _pairOrNull(_rightController, _rightPrevController),
      top: _pairOrNull(_topController, _topPrevController),
      bottom: _pairOrNull(_bottomController, _bottomPrevController),
      comment: _commentController.text.trim(),
    );
    Navigator.of(context).pop(edited);
  }

  Widget _field(String label, TextEditingController controller,
      {String? Function(String?)? validator, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: type ?? TextInputType.text,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _pairField(String label, TextEditingController cur,
      TextEditingController prev) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: cur,
              keyboardType: TextInputType.number,
              validator: _optionalNumberValidator,
              decoration: InputDecoration(
                labelText: label,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: prev,
              keyboardType: TextInputType.number,
              validator: _optionalNumberValidator,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Изменить измерение'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field('От', _fromController, validator: _requiredValidator),
                _field('До', _toController, validator: _requiredValidator),
                _field('Дистанция, м', _distanceController,
                    validator: _numberValidator,
                    type: TextInputType.number),
                _field('Азимут, градусы', _compassController,
                    validator: _numberValidator,
                    type: TextInputType.number),
                _field('Угол, градусы', _angleController,
                    validator: _numberValidator,
                    type: TextInputType.number),
                _pairField('Лево', _leftController, _leftPrevController),
                _pairField('Право', _rightController, _rightPrevController),
                _pairField('Верх', _topController, _topPrevController),
                _pairField('Низ', _bottomController, _bottomPrevController),
                _field('Комментарий', _commentController),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
