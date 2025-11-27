import 'firestore_service.dart';
import '../data/models/project_model.dart';
import '../core/constants/config.dart';

class ProjectService {
  final FirestoreService _firestore = FirestoreService();

  Future<List<Project>> getProjects(String userId) async {
    final snapshot = await _firestore.getCollection(Config.firestoreProjectsCollection);
    return snapshot.docs.map((doc) => Project.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<void> createProject(Project project) async {
    await _firestore.setDocument(
      Config.firestoreProjectsCollection,
      project.id,
      project.toJson(),
    );
  }
}
