import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/child_model.dart';
import '../models/user_model.dart';
import '../services/auth_services.dart';
import '../services/child_auth_service.dart';
import '../services/user_services.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  final AuthServices _authServices = AuthServices();
  final ChildAuthService _childAuthService = ChildAuthService();

  // Di AuthCubit, update signIn method
  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    try {
      emit(AuthLoading());

      debugPrint('🔐 Attempting login for username: $username');

      // Coba login sebagai user (orang tua) terlebih dahulu
      try {
        final UserModel user = await _authServices.signIn(
          username: username,
          password: password,
        );
        debugPrint('✅ Login sebagai ORANG TUA berhasil: ${user.name}');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        emit(AuthSuccess(user));
        return;
      } catch (e) {
        debugPrint('❌ Login sebagai orang tua gagal: $e');
      }

      // Jika gagal sebagai user, coba sebagai child
      try {
        debugPrint('🔄 Mencoba login sebagai ANAK...');
        final ChildModel? child = await _childAuthService.signInChild(
          username: username,
          password: password,
        );

        if (child != null) {
          debugPrint('✅ Login sebagai ANAK berhasil: ${child.name}');

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);

          emit(ChildAuthSuccess(child: child));
        } else {
          debugPrint('❌ Login sebagai anak gagal: data tidak ditemukan');
          emit(const AuthFailed('Username atau password salah'));
        }
      } catch (e) {
        debugPrint('❌ Login sebagai anak error: $e');
        emit(AuthFailed(e.toString()));
      }
    } catch (e) {
      debugPrint('❌ General signIn error: $e');
      emit(AuthFailed('Terjadi kesalahan: ${e.toString()}'));
    }
  }

  Future<void> signUp({
    required String name,
    required String username,
    required String password,
    required String umur,
    required String pekerjaan,
    required String hp,
    required String email,
    required String role,
    required String jenisKelamin,       // 👈 NEW
    required String statusPerkawinan,   // 👈 NEW
    required String pendidikan,         // 👈 NEW
    required String alamat,             // 👈 NEW
    required String hubunganAnak,       // 👈 NEW
  }) async {
    try {
      emit(AuthLoading());
      final user = await _authServices.signUp(
        username: username,
        password: password,
        name: name,
        role: role,
        umur: umur,
        pekerjaan: pekerjaan,
        hp: hp,
        email: email,
        jenisKelamin: jenisKelamin,
        statusPerkawinan: statusPerkawinan,
        pendidikan: pendidikan,
        alamat: alamat,
        hubunganAnak: hubunganAnak,
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthFailed(e.toString()));
    }
  }


  // METHOD UNTUK LUPA PASSWORD
  void resetPassword(String email) async {
    try {
      emit(AuthLoading());
      await AuthServices().resetPassword(email);
      emit(AuthPasswordResetSent());
    } catch (e) {
      emit(AuthFailed(e.toString()));
    }
  }

  // TAMBAHKAN METHOD UPDATE PROFILE
  // void updateProfile({required String userId, required String username}) async {
  //   try {
  //     emit(AuthLoading());
  //
  //     UserModel updatedUser = await AuthServices().updateProfile(
  //       userId: userId,
  //       username: username,
  //     );
  //
  //     emit(AuthSuccess(updatedUser));
  //   } catch (e) {
  //     emit(AuthFailed(e.toString()));
  //   }
  // }

  void signOut() async {
    try {
      emit(AuthLoading());
      await AuthServices().signOut();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('isLoggedIn'); // ✅ clear secara eksplisit

      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailed(e.toString()));
    }
  }

  Future<void> getCurrentUser(String id) async {
    try {
      debugPrint('[AuthCubit] 🔍 getCurrentUser called for ID: $id');
      emit(AuthLoading()); // ✅ Emit loading state

      UserModel user = await UserServices().getUserById(id);

      debugPrint('''
🎉 [AuthCubit] GET CURRENT USER SUCCESS
├── ID: ${user.id}
├── Username: ${user.username}
├── Name: ${user.name}
└── Role: ${user.role}
''');

      emit(AuthSuccess(user)); // ✅ PASTIKAN INI DIEMIT!
      debugPrint('[AuthCubit] 📤 Emitted AuthSuccess from getCurrentUser');

    } catch (e) {
      debugPrint('''
[AuthCubit] ❌ getCurrentUser failed
├── Error: $e
├── Error Type: ${e.runtimeType}
''');

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        debugPrint('[AuthCubit] 🔄 Using fallback user data');

        final email = firebaseUser.email ?? '';
        final username = email.isNotEmpty
            ? email.split('@').first
            : 'User';

        final isAdmin = username.toLowerCase() == 'admin';

        final minimalUser = UserModel(
          id: firebaseUser.uid,
          username: username,
          name: isAdmin ? 'Admin' : 'Orang Tua',
          umur: '',
          jenisKelamin: '',        // 👈 NEW
          statusPerkawinan: '',    // 👈 NEW
          pendidikan: '',          // 👈 NEW
          alamat: '',              // 👈 NEW
          hubunganAnak: '',        // 👈 NEW
          pekerjaan: '',
          hp: '',
          email: email,
          role: isAdmin ? 'admin' : 'ortu',
        );


        emit(AuthSuccess(minimalUser));
        debugPrint('[AuthCubit] 📤 Emitted AuthSuccess with fallback data (role: ${minimalUser.role})');
      } else {
        debugPrint('[AuthCubit] ❌ No Firebase user available');
        emit(AuthFailed(e.toString()));
      }

    }
  }
}
