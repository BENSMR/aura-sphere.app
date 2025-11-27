import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/models/task_model.dart';

class TaskService {
  final TaskRepository _repo;
  final FirebaseAuth _auth;

  TaskService({TaskRepository? repo, FirebaseAuth? auth})
      : _repo = repo ?? TaskRepository(),
        _auth = auth ?? FirebaseAuth.instance;

  String get currentUid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Not authenticated');
    return u.uid;
  }

  Stream<List<TaskModel>> streamMyTasks() {
    return _repo.streamTasks(currentUid);
  }

  Stream<List<TaskModel>> watchTasks(String userId) {
    return _repo.streamTasks(userId);
  }

  Future<void> markAsDone(String taskId) async {
    return _repo.updateTask(currentUid, taskId, {'status': 'done', 'doneAt': FieldValue.serverTimestamp()});
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> patch) async {
    return _repo.updateTask(currentUid, taskId, patch);
  }

  Future<void> deleteTask(String taskId) async {
    return _repo.deleteTask(currentUid, taskId);
  }
}