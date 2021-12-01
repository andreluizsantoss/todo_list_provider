import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
      if (e.code == 'wrong-password') {
        throw AuthException(message: 'Login ou senha inválidos');
      }
      throw AuthException(message: 'Erro ao realizar login');
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    // ! IMPORTANTE
    // ! Somente podemos resetar a senha de email (forma de cadastro e-mail)
    // ! Não podemos resetar a senha na forma de cadastro GOOGLE
    try {
      final loginMethods =
          await _firebaseAuth.fetchSignInMethodsForEmail(email);
      if (loginMethods.contains('password')) {
        await _firebaseAuth.sendPasswordResetEmail(email: email);
      } else if (loginMethods.contains('google')) {
        throw AuthException(
            message:
                'Cadastro realizado com o google, não pode ser resetado a senha');
      } else {
        throw AuthException(message: 'E-mail não cadastrado');
      }
    } on PlatformException catch (e, s) {
      print(e);
      print(s);
      throw AuthException(message: 'Erro ao resetar senha');
    }
  }

  @override
  Future<User?> googleLogin() async {
    List<String>? loginMethods;
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        // ! Verifica se o metódo de login é EMAIL ou GOOGLE
        // ! Não pode deixar que ocorra isso - Pode ocorrer problemas
        loginMethods =
            await _firebaseAuth.fetchSignInMethodsForEmail(googleUser.email);
        if (loginMethods.contains('password')) {
          throw AuthException(
              message:
                  'Você utilizou o e-mail para cadastro no TodoList, caso tenha esquecido sua senha, por favor clique no botão esqueci minha senha');
        } else {
          final googleAuth = await googleUser.authentication;
          final firebaseCredential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          var userCredencial =
              await _firebaseAuth.signInWithCredential(firebaseCredential);
          return userCredencial.user;
        }
      }
    } on FirebaseAuthException catch (e, s) {
      print(e);
      print(s);
      // ! Essa exceção é quando vc tenta fazer login com credencial diferente
      if (e.code == 'account-exists-with-different-credential') {
        throw AuthException(message: '''
            Login inválido. Você se registrou no TodoList com os seguintes provedores:
            ${loginMethods?.join(',')}
        ''');
      } else {
        throw AuthException(message: 'Erro ao realizar login');
      }
    }
  }

  @override
  Future<void> googleLogout() async {
    // ! Fazer o logout do metodo de autenticação 
    // ! Para apareça novamente a tela de escolher o e-mail do Google no celular
    await GoogleSignIn().signOut();
    _firebaseAuth.signOut();
  }
}
