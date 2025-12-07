import 'package:flutter/material.dart';
import 'package:pickquet/model.dart';

class PiquetJournalScreen extends StatelessWidget {
  const PiquetJournalScreen({
    super.key,
    required this.measurementList,
  });

  final List<MeasurementModel> measurementList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          const Text("from to tape compass clino left right  up down"),
          Expanded(
            child: ListView.separated(
                itemBuilder: (context, index) {
                  final item = measurementList[index];
                  return Row(
                    children: [
                      Text(item.from),
                      SizedBox(
                        width: 10,
                      ),
                      Text(item.to),
                      SizedBox(
                        width: 10,
                      ),
                      Text(item.distance.toString()),
                      SizedBox(
                        width: 10,
                      ),
                      Text(item.compass.toString()),
                      SizedBox(
                        width: 10,
                      ),
                      Text(item.angle.toString()),
                    ],
                  );
                },
                separatorBuilder: (context, index) => SizedBox(
                      height: 20,
                    ),
                itemCount: measurementList.length),
          ),
        ],
      ),
    );
  }
}
