import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _firestore;
  TaskRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _userTasksRef(String uid) => _firestore.collection('users').doc(uid).collection('tasks');

  Stream<List<TaskModel>> streamTasks(String uid) {
    return _userTasksRef(uid)
        .orderBy('dueAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => TaskModel.fromFirestore(d)).toList());
  }

  Future<void> createTask(String uid, Map<String, dynamic> taskMap) async {
    await _userTasksRef(uid).doc(taskMap['id'] ?? _userTasksRef(uid).doc().id).set(taskMap);
  }

  Future<void> updateTask(String uid, String taskId, Map<String, dynamic> patch) async {
    await _userTasksRef(uid).doc(taskId).update(patch);
  }

  Future<void> deleteTask(String uid, String taskId) async {
    await _userTasksRef(uid).doc(taskId).delete();
  }
}