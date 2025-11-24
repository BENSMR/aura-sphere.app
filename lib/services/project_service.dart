import 'firestore_service.dart';
import '../models/project_model.dart';
import '../config/constants.dart';

class ProjectService {
  final FirestoreService _firestore = FirestoreService();

  Future<List<Project>> getProjects(String userId) async {
    final snapshot = await _firestore.getCollection(Constants.firestoreProjectsCollection);
    return snapshot.docs.map((doc) => Project.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<void> createProject(Project project) async {
    await _firestore.setDocument(
      Constants.firestoreProjectsCollection,
      project.id,
      project.toJson(),
    );
  }
}
