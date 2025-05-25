import 'package:flutter/foundation.dart';

class AuthService with ChangeNotifier {
  String? _currentUserId;
  
  // Simulated login - replace with real auth logic
  Future<void> login(String email, String password) async {
    _currentUserId = 'user_${email.hashCode}'; // Replace with real auth token
    notifyListeners();
  }

  void logout() {
    _currentUserId = null;
    notifyListeners();
  }

  String? get currentUserId => _currentUserId;
  bool get isLoggedIn => _currentUserId != null;
}