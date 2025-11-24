import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  
  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;

  void setUser(User? firebaseUser) {
    if (firebaseUser != null) {
      _user = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
      );
    } else {
      _user = null;
    }
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
