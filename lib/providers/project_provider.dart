import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';

class ProjectProvider with ChangeNotifier {
  final ProjectService _projectService = ProjectService();
  List<Project> _projects = [];
  bool _isLoading = false;

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;

  Future<void> loadProjects(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _projects = await _projectService.getProjects(userId);
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createProject(Project project) async {
    await _projectService.createProject(project);
    _projects.add(project);
    notifyListeners();
  }
}
