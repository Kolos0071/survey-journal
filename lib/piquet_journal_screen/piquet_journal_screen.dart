import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pickquet/model.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<File> get _localFile async {
    Directory? directory;
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        directory = Directory('/storage/emulated/0/Download');
      } catch (e) {
        directory = await getDownloadsDirectory();
      }
    }
    try {
      return File('${directory!.path}/piquet_journal.txt');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _writeToFile(List<String> rows) async {
    try {
      final file = await _localFile;
      final content = rows.join('\n');
      await file.writeAsString(content, mode: FileMode.writeOnly);
    } catch (e) {
      print('Error writing file: $e');
      rethrow;
    }
  }

  Future<void> createFile(BuildContext context) async {
    try {
      List<String> fileString = [];

      for (final item in measurementList) {
        fileString.add(
            "${item.from} ${item.to} ${item.distance} ${item.compass} "
            "${item.angle} ${item.left.toString().replaceAll(",", " ")} ${item.right.toString().replaceAll(",", " ")} ${item.top.toString().replaceAll(",", " ")} ${item.bottom.toString().replaceAll(",", " ")}");
      }

      await _writeToFile(fileString);

      final file = await _localFile;
      if (await file.exists()) {
        String fileContent = await file.readAsString();
        print('File saved to: ${file.path}');
        print('File size: ${fileContent.length} characters');

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Файл сохранен: ${file.path}')));
      }
    } catch (e) {
      print('Error creating file: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Пикетажный журнал"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => createFile(context),
        child: const Icon(Icons.save),
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
