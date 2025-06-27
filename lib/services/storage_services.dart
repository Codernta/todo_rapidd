import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo_model.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _todosKey = 'todos';
  static const String _userKey = 'current_user';

  static Future<List<TodoModel>> getTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson = prefs.getString(_todosKey);
    if (todosJson == null) return [];

    final List<dynamic> todosList = json.decode(todosJson);
    return todosList.map((json) => TodoModel.fromJson(json)).toList();
  }

  static Future<void> saveTodos(List<TodoModel> todos) async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson = json.encode(todos.map((todo) => todo.toJson()).toList());
    await prefs.setString(_todosKey, todosJson);
  }

  static Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;

    return UserModel.fromJson(json.decode(userJson));
  }

  static Future<void> saveCurrentUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    await prefs.setString(_userKey, userJson);
  }
}