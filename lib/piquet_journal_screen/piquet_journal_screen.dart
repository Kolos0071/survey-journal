import 'dart:convert';
import 'dart:io';

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
    final directory = await getApplicationDocumentsDirectory();

    return File('${directory.path}/piquet_journal.th');
  }

  Future<void> writeMultipleRowsToFile(List<String> rows) async {
    final file = await _localFile;
    final content = rows.join('\n'); // Join the list of strings with newlines
    await file.writeAsString(content,
        mode: FileMode.write); // Overwrites if exists
  }

  void createFile() async {
    List<String> fileString = [];

    for (final item in measurementList) {
      fileString.add(
          "${item.from} ${item.to} ${item.distance} ${item.compass} ${item.angle} ${item.left} ${item.right} ${item.top} ${item.bottom}");
      await writeMultipleRowsToFile(fileString);
    }

    final file = await _localFile;
    String fileContent = await file.readAsString();
    print(file.path);
    print("File content:\n$fileContent");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Пикетажный журнал"),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: createFile,
          child: const Icon(Icons.save),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Table(
            border: TableBorder.all(),
            children: [
              TableRow(children: [
                for (final item in tableHeader) TableCell(child: Text(item))
              ]),
              for (final row in measurementList)
                TableRow(children: [
                  TableCell(child: Text(row.from)),
                  TableCell(child: Text(row.to)),
                  TableCell(child: Text(row.distance.toString())),
                  TableCell(child: Text(row.compass.toString())),
                  TableCell(child: Text(row.angle.toString())),
                  TableCell(child: Text(row.left.toString())),
                  TableCell(child: Text(row.right.toString())),
                  TableCell(child: Text(row.top.toString())),
                  TableCell(child: Text(row.bottom.toString())),
                ])
            ],
          ),
        ));
  }
}
