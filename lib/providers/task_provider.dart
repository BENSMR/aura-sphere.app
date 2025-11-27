import 'package:flutter/material.dart';
import '../services/firebase/task_service.dart';
import '../data/models/task_model.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _service;
  List<TaskModel> tasks = [];
  bool loading = false;

  TaskProvider({TaskService? service}) : _service = service ?? TaskService() {
    _init();
  }

  void _init() {
    try {
      _service.streamMyTasks().listen((list) {
        tasks = list;
        notifyListeners();
      });
    } catch (e) {
      // not authenticated yet
    }
  }

  Future<void> markDone(String id) async {
    await _service.markAsDone(id);
  }

  Future<void> delete(String id) async {
    await _service.deleteTask(id);
  }

  Stream<List<TaskModel>> watchTasks(String userId) {
    return _service.watchTasks(userId);
  }

  Stream<List<TaskModel>> watch() {
    return _service.streamMyTasks();
  }
}