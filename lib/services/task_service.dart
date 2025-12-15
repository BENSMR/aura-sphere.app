import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

/// Task data model
class Task {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime dueDate;
  final bool completed;
  final DateTime? completedAt;
  final String? priority; // 'low', 'medium', 'high'
  final List<String>? tags;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.dueDate,
    this.completed = false,
    this.completedAt,
    this.priority,
    this.tags,
    required this.createdAt,
  });

  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'title': title,
    'description': description,
    'dueDate': Timestamp.fromDate(dueDate),
    'completed': completed,
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'priority': priority,
    'tags': tags,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  /// Create from Firestore JSON
  factory Task.fromJson(Map<String, dynamic> json, String id) {
    return Task(
      id: id,
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      dueDate: (json['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completed: json['completed'] ?? false,
      completedAt: (json['completedAt'] as Timestamp?)?.toDate(),
      priority: json['priority'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Copy with modifications
  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool? completed,
    DateTime? completedAt,
    String? priority,
    List<String>? tags,
  }) {
    return Task(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      createdAt: createdAt,
    );
  }
}

/// Service for managing tasks
class TaskService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a new task
  Future<String> addTask({
    required String title,
    String? description,
    required DateTime dueDate,
    String? priority,
    List<String>? tags,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    try {
      final task = Task(
        id: '',
        userId: userId,
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
        tags: tags,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('tasks').add(task.toJson());
      logger.info('Task added: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      logger.error('Error adding task: $e');
      rethrow;
    }
  }

  /// Get all tasks for user
  Future<List<Task>> getUserTasks({bool? completed}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    try {
      var query = _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .orderBy('dueDate');

      if (completed != null) {
        query = query.where('completed', isEqualTo: completed);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => Task.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      logger.error('Error fetching tasks: $e');
      rethrow;
    }
  }

  /// Update task
  Future<void> updateTask(String taskId, Task task) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update(task.toJson());
      logger.info('Task updated: $taskId');
    } catch (e) {
      logger.error('Error updating task: $e');
      rethrow;
    }
  }

  /// Mark task as completed
  Future<void> completeTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'completed': true,
        'completedAt': Timestamp.now(),
      });
      logger.info('Task completed: $taskId');
    } catch (e) {
      logger.error('Error completing task: $e');
      rethrow;
    }
  }

  /// Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
      logger.info('Task deleted: $taskId');
    } catch (e) {
      logger.error('Error deleting task: $e');
      rethrow;
    }
  }

  /// Stream user's tasks
  Stream<List<Task>> streamUserTasks({bool? completed}) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    var query = _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .orderBy('dueDate');

    if (completed != null) {
      query = query.where('completed', isEqualTo: completed);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Task.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get overdue tasks
  Future<List<Task>> getOverdueTasks() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .where('completed', isEqualTo: false)
          .where('dueDate', isLessThan: Timestamp.now())
          .get();

      return snapshot.docs
          .map((doc) => Task.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      logger.error('Error fetching overdue tasks: $e');
      rethrow;
    }
  }

  /// Get tasks by priority
  Future<List<Task>> getTasksByPriority(String priority) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: userId)
          .where('priority', isEqualTo: priority)
          .orderBy('dueDate')
          .get();

      return snapshot.docs
          .map((doc) => Task.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      logger.error('Error fetching tasks by priority: $e');
      rethrow;
    }
  }

  /// Get completion statistics
  Future<Map<String, dynamic>> getCompletionStats() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    try {
      final allTasks = await getUserTasks();
      final completedTasks = await getUserTasks(completed: true);

      return {
        'total': allTasks.length,
        'completed': completedTasks.length,
        'pending': allTasks.length - completedTasks.length,
        'completionRate': allTasks.isEmpty
            ? 0
            : (completedTasks.length / allTasks.length * 100).toStringAsFixed(1),
      };
    } catch (e) {
      logger.error('Error getting completion stats: $e');
      rethrow;
    }
  }
}
