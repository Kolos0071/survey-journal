import 'dart:convert';

import 'package:pickquet/data_service.dart';
import 'package:pickquet/model.dart';

class CacheService {
  static String surveyKey = "survey";
  static String firstEntryKey = "is-first-entry";

  final DataService service;

  CacheService({required this.service});

  Future<bool> cacheSurvey(List<Map<String, dynamic>> data) async {
    final String stringValue = json.encode(data);
    return await service.addItem(surveyKey, stringValue);
  }

  Future<List<MeasurementModel>> getSurvey() async {
    final String stringValue = await service.readItem(surveyKey);
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
    await service.deleteItem(surveyKey);
  }
}
