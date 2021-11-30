import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:todo_list_provider/app/exceptions/auth_exception.dart';

import 'package:todo_list_provider/app/repositories/user/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseAuth _firebaseAuth;
  UserRepositoryImpl({
    required FirebaseAuth firebaseAuth,
  }) : _firebaseAuth = firebaseAuth;

  @override
  Future<User?> register(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e, s) {
      print(e);
      print(s);
      // ! Aviso de que já existe o e-mail cadastrado
      if (e.code == 'email-already-in-use') {
        // ! Faz a checagem de qual tipo de autenticação o e-mail esta sendo usado
        final loginTypes =
            await _firebaseAuth.fetchSignInMethodsForEmail(email);
        if (loginTypes.contains('password')) {
          throw AuthException(
              // ! E-mail cadastrado pelo modo de autenticação NORMAL
              message: 'E-mail já utilizado, por favor escolha outro e-mail');
        } else {
          // ! E-mail cadastrado pelo modo de autenticação GOOGLE
          throw AuthException(
              message:
                  'Você se cadastrou no TodoList pelo Google, por favor utilize ele para entrar');
        }
      } else {
        // ! Própria mensagem de erro do FirebaseAuth
        // ! Caso for nula, exibe a mensagem de Erro ao registrar usuário
        throw AuthException(message: e.message ?? 'Erro ao registrar usuário');
      }
    }
  }

  @override
  Future<User?> login(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      return userCredential.user;
    } on PlatformException catch (e, s) {
      print(e);
      print(s);
      throw AuthException(message: 'Erro ao realizar login');
    } on FirebaseAuthException catch (e, s) {
      print(e);
      print(s);
      if(e.code == 'wrong-password') {
        throw AuthException(message: 'Login ou senha inválidos');
      }
      throw AuthException(message: 'Erro ao realizar login');
    }
  }
}
