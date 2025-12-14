import 'dart:convert';

import 'package:pickquet/data_service.dart';
import 'package:pickquet/model.dart';

class CacheService {
  static String surveyKey = "survey";
  static String firstEntryKey = "is-first-entry";
  static String currentSurvey = "current-survey";

  final DataService service;

  CacheService({required this.service});

  Future<bool> surveyName(String name) async{
    return await service.addItem(currentSurvey, "$name-${DateTime.now().toString()}");
  }

  Future<void> getSurveyList() async {
    final result  = await service.readAll();


    
  }

  Future<bool> cacheSurvey(List<Map<String, dynamic>> data) async {
    final String surveyName = await service.readItem(currentSurvey);
    final String stringValue = json.encode(data);
    return await service.addItem("$surveyKey-$surveyName", stringValue);
  }

  Future<List<MeasurementModel>> getSurvey() async {
    final String surveyName = await service.readItem(currentSurvey);

    final String stringValue = await service.readItem("$surveyKey-$surveyName");
    if (stringValue.isNotEmpty) {
      final List<dynamic> convertValue = json.decode(stringValue);

      return convertValue
          .map((item) => MeasurementModel.fromJson(item))
          .toList();
    } else {
      return [];
    }
  }

  Future<void> clearSurvey() async {
    await service.deleteItem(currentSurvey);
  }
}
