import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pickquet/model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PiquetJournalScreen extends StatelessWidget {
  PiquetJournalScreen({
    super.key,
    required this.measurementList,
  });

  final List<MeasurementModel> measurementList;
  final List<String> tableHeader = [
    "from",
    "to",
    "tape",
    "compass",
    "clino",
    "left",
    "right",
    "up",
    "down"
  ];

  static const String _fileName = 'piquet_journal.txt';

  String get _fileContent {
    final List<String> rows = [];
    for (final item in measurementList) {
      rows.add("${item.from} ${item.to} ${item.distance} ${item.compass} "
          "${item.angle} ${item.left.toString().replaceAll(",", " ")} ${item.right.toString().replaceAll(",", " ")} ${item.top.toString().replaceAll(",", " ")} ${item.bottom.toString().replaceAll(",", " ")}");
    }
    return rows.join('\n');
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
      floatingActionButton: measurementList.isEmpty
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
      body: measurementList.isEmpty
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
                      for (final row in measurementList)
                        TableRow(
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
                              child: Text(row.left.toString()),
                            )),
                            TableCell(
                                child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(row.right.toString()),
                            )),
                            TableCell(
                                child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(row.top.toString()),
                            )),
                            TableCell(
                                child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(row.bottom.toString()),
                            )),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
