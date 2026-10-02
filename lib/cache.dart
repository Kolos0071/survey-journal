import 'dart:convert';

import 'package:pickquet/data_service.dart';
import 'package:pickquet/model.dart';

class CacheService {
  static String currentSurvey = "current-survey";

  final DataService service;

  CacheService({required this.service});

  Future<bool> surveyName(String name) async{
    return await service.addItem(currentSurvey, name);
  }

  Future<String> getSurveyName() async{
    return await service.readItem(currentSurvey);
  }

  Future<List<String>> getSurveyList() async {
    final result  = await service.readAll();
    List<String> keysList = [];

    result.forEach((key, value){
      if(key != currentSurvey) {
        keysList.add(key);
      }
    });
    return keysList;
  }
  Future<bool> cacheSurvey(List<Map<String, dynamic>> data) async {
    final String surveyName = await service.readItem(currentSurvey);
    final String stringValue = json.encode(data);
    return await service.addItem(surveyName, stringValue);
  }

  /// Persists the whole measurement list for the current survey. Always call
  /// this with the freshest list read via [getSurvey] right before mutating
  /// it, so concurrent edits (e.g. two open dialogs) never clobber
  /// each other's changes.
  Future<bool> saveSurvey(List<MeasurementModel> list) async {
    return await cacheSurvey(list.map((item) => item.toJson()).toList());
  }

  Future<List<MeasurementModel>> getSurvey() async {
    final String surveyName = await service.readItem(currentSurvey);

    final String stringValue = await service.readItem(surveyName);
    if (stringValue.isNotEmpty) {
      final List<dynamic> convertValue = json.decode(stringValue);

      return convertValue
          .map((item) => MeasurementModel.fromJson(item))
          .toList();
    } else {
      return [];
    }
  }

  Future<void> clearList() async {
    await service.clearAll();
  }

  Future<void> clearSurvey() async {
    await service.deleteItem(currentSurvey);
  }
}
