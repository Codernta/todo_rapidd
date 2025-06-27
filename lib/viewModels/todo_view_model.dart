import 'package:flutter/material.dart';
import 'package:mt_rapidd_todo/services/socket_services.dart';
import 'package:uuid/uuid.dart';
import '../models/todo_model.dart';
import '../models/user_model.dart';

import '../services/storage_services.dart';

class TodoViewModel extends ChangeNotifier {
  List<TodoModel> _todos = [];
  UserModel? _currentUser;
  bool _isLoading = false;
  String _searchQuery = '';
  Priority? _filterPriority;
  bool? _filterCompleted;

  List<TodoModel> get todos {
    List<TodoModel> filteredTodos = _todos;

    if (_searchQuery.isNotEmpty) {
      filteredTodos = filteredTodos.where((todo) =>
      todo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          todo.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    if (_filterPriority != null) {
      filteredTodos = filteredTodos.where((todo) => todo.priority == _filterPriority).toList();
    }

    if (_filterCompleted != null) {
      filteredTodos = filteredTodos.where((todo) => todo.isCompleted == _filterCompleted).toList();
    }

    return filteredTodos;
  }

  List<TodoModel> get myTodos => todos.where((todo) => todo.ownerId == _currentUser?.id).toList();
  List<TodoModel> get sharedTodos => todos.where((todo) =>
  todo.sharedWith.contains(_currentUser?.id) && todo.ownerId != _currentUser?.id).toList();

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  final Uuid _uuid = const Uuid();

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await StorageService.getCurrentUser();
      if (_currentUser == null) {
        _currentUser = UserModel(
          id: _uuid.v4(),
          name: 'User ${DateTime.now().millisecondsSinceEpoch}',
          email: 'user${DateTime.now().millisecondsSinceEpoch}@example.com',
        );
        await StorageService.saveCurrentUser(_currentUser!);
      }

      _todos = await StorageService.getTodos();
    } catch (e) {
      print('Error initializing: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setupSocketListeners(SocketService socketService) {
    socketService.onTodoUpdate((data) {
      final updatedTodo = TodoModel.fromJson(data);
      final index = _todos.indexWhere((todo) => todo.id == updatedTodo.id);

      if (index != -1) {
        _todos[index] = updatedTodo;
        notifyListeners();
        _saveTodos();
      }
    });
  }

  Future<void> addTodo({
    required String title,
    required String description,
    Priority priority = Priority.medium,
  }) async {
    if (_currentUser == null) return;

    final todo = TodoModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      ownerId: _currentUser!.id,
      priority: priority,
    );

    _todos.insert(0, todo);
    notifyListeners();
    await _saveTodos();
  }

  Future<void> updateTodo(TodoModel updatedTodo, [SocketService? socketService]) async {
    final index = _todos.indexWhere((todo) => todo.id == updatedTodo.id);
    if (index == -1) return;

    final newTodo = updatedTodo.copyWith(updatedAt: DateTime.now());
    _todos[index] = newTodo;
    notifyListeners();
    await _saveTodos();

    if (socketService != null && socketService.isConnected) {
      socketService.emitTodoUpdate(newTodo.toJson());
    }
  }

  Future<void> toggleTodoCompletion(String todoId, [SocketService? socketService]) async {
    final index = _todos.indexWhere((todo) => todo.id == todoId);
    if (index == -1) return;

    final todo = _todos[index];
    final updatedTodo = todo.copyWith(
      isCompleted: !todo.isCompleted,
      updatedAt: DateTime.now(),
    );

    await updateTodo(updatedTodo, socketService);
  }

  Future<void> deleteTodo(String todoId) async {
    _todos.removeWhere((todo) => todo.id == todoId);
    notifyListeners();
    await _saveTodos();
  }

  Future<void> shareTodo(String todoId, String email) async {
    final index = _todos.indexWhere((todo) => todo.id == todoId);
    if (index == -1) return;

    final todo = _todos[index];
    if (!todo.sharedWith.contains(email)) {
      final updatedTodo = todo.copyWith(
        sharedWith: [...todo.sharedWith, email],
        updatedAt: DateTime.now(),
      );
      _todos[index] = updatedTodo;
      notifyListeners();
      await _saveTodos();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterPriority(Priority? priority) {
    _filterPriority = priority;
    notifyListeners();
  }

  void setFilterCompleted(bool? completed) {
    _filterCompleted = completed;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterPriority = null;
    _filterCompleted = null;
    notifyListeners();
  }

  Future<void> _saveTodos() async {
    await StorageService.saveTodos(_todos);
  }
}