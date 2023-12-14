import 'package:laporcepat/data_users.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  Future<void> saveData(key, DataUsers data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = json.encode(data.toJson());
    await prefs.setString(key, jsonString);
  }

  Future<DataUsers?> loadData(key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = prefs.getString(key) ?? '{}';
    Map<String, dynamic> jsonMap =
        Map<String, dynamic>.from(json.decode(jsonString));
    return DataUsers.fromJson(jsonMap);
  }

  Future<void> removeData(key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
