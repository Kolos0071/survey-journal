import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:piquet/app.dart';
import 'package:piquet/cache.dart';
import 'package:piquet/data_service.dart';

void main() async{
    final DataService dataService = DataService();
    final CacheService cacheService = CacheService(service: dataService);
            

    GetIt.I.registerSingleton<DataService>(dataService);
    GetIt.I.registerSingleton<CacheService>(cacheService);



  runApp(const PiquetApp());
}

