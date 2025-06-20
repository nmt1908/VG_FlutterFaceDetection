import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

Future<void> saveUserSession(User user) async {
  final prefs = await SharedPreferences.getInstance();
  final userJson = jsonEncode(user.toJson());
  await prefs.setString('active_user', userJson);
}

Future<User?> getUserSession() async {
  final prefs = await SharedPreferences.getInstance();
  final userJson = prefs.getString('active_user');
  if (userJson == null) return null;
  final data = jsonDecode(userJson);
  return User.fromJson(data);
}

Future<void> clearUserSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('active_user');
}
