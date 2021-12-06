import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:todo_list_provider/app/core/navigator/todo_list_navigator.dart';
import 'package:todo_list_provider/app/services/user/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth;
  final UserService _userService;

  AuthProvider({
    required FirebaseAuth firebaseAuth,
    required UserService userService,
  })  : _firebaseAuth = firebaseAuth,
        _userService = userService;

  Future<void> logout() => _userService.logout();
  User? get user => _firebaseAuth.currentUser;

  void loadListener() {
    // ! Verifica qualquer alteração no usuario
    _firebaseAuth.userChanges().listen((_) => notifyListeners());
    // ! Verifica se o usuario esta logado ou deslogado
    _firebaseAuth.authStateChanges().listen((user) async {
      if (user != null) {
        // await Future.delayed(const Duration(seconds: 2));
        TodoListNavigator.to.pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        // await Future.delayed(const Duration(seconds: 2));
        TodoListNavigator.to
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    });
  }
}
