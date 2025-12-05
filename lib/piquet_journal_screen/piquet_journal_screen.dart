import 'package:flutter/material.dart';
import 'package:pickquet/model.dart';

class PiquetJournalScreen extends StatelessWidget {
  const PiquetJournalScreen({super.key, required this.measurementList, });

  final List<MeasurementModel> measurementList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView.separated(itemBuilder:(context, index) {
        final item = measurementList[index];
        return Text(item.from);
      }, separatorBuilder:(context, index) => SizedBox(height: 20,), itemCount: measurementList.length),
    );
  }
}