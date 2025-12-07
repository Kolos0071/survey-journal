import 'package:flutter/material.dart';
import 'package:pickquet/model.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Пикетажный журнал"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Table(
            border: TableBorder.all(),
            children: [
              TableRow(children: [
                for (final item in tableHeader) TableCell(child: Text(item))
              ]),
              for (final row  in measurementList)
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
        )
        // Column(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     const Text("from to tape compass clino left right  up down"),
        //     Expanded(
        //       child: ListView.separated(
        //           itemBuilder: (context, index) {
        //             final item = measurementList[index];
        //             return Text("${item.from} ${item.to} ${item.distance} ${item.compass} ${item.angle} ${item.left} ${item.right} ${item.top} ${item.bottom}");
        //           },
        //           separatorBuilder: (context, index) => SizedBox(
        //                 height: 20,
        //               ),
        //           itemCount: measurementList.length),
        //     ),
        //   ],
        // ),
        );
  }
}
