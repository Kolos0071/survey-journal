import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class DataService {
  FlutterSecureStorage secureStorage = const FlutterSecureStorage();


  Future<bool> addItem(String key, String value) async {
    
    try {
      if (await secureStorage.read(key: key) == null) {
        await secureStorage.write(key: key, value: value);
        return true;
      } else if (await secureStorage.read(key: key) != value) {
        await secureStorage.write(key: key, value: value);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<String> readItem(String key) async {
    String value = '';
    try {

      if (await secureStorage.read(key: key) != null) {

        value = await secureStorage.read(key: key) as String;

        return value;
      } else {
        return value;
      }
    } catch (e) {
        print(e);

      return value;
    }
  }

  Future<void> deleteItem(String key) async {
    await secureStorage.delete(key: key);
  }


}