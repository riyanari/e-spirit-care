import 'package:e_spirit_care/services/user_services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';


class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _getUserFriendlyError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // 👇 TANGANI ERROR EMAIL BELUM TERVERIFIKASI SECARA KHUSUS
    if (errorString.contains('email_not_verified')) {
      final parts = error.toString().split(':');
      if (parts.length >= 3) {
        final userId = parts[1];
        final userEmail = parts[2];
        return 'EMAIL_NOT_VERIFIED:$userId:$userEmail';
      }
      return 'Email belum terverifikasi. Silakan cek email Anda untuk verifikasi.';
    }

    if (errorString.contains('user-not-found') ||
        errorString.contains('invalid-credential')) {
      return 'Email tidak ditemukan. Periksa kembali email atau password Anda.';
    } else if (errorString.contains('wrong-password')) {
      return 'Password yang dimasukkan salah. Silakan coba lagi.';
    } else if (errorString.contains('network-request-failed')) {
      return 'Koneksi internet terputus. Periksa koneksi Anda.';
    } else if (errorString.contains('too-many-requests')) {
      return 'Terlalu banyak percobaan login. Tunggu beberapa saat lagi.';
    } else if (errorString.contains('email-already-in-use')) {
      return 'Email sudah digunakan. Silakan pilih email lain.';
    } else if (errorString.contains('weak-password')) {
      return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
    } else if (errorString.contains('invalid-email')) {
      return 'Format email tidak valid.';
    } else if (errorString.contains('user-disabled')) {
      return 'Akun ini telah dinonaktifkan.';
    } else {
      return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }

  Future<UserModel> signIn({
    required String username,
    required String password,
  }) async {

    final isAdmin = username.toLowerCase() == 'admin';

    try {
      String email = "$username@spirit.com";
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // ✅ TAMBAHKAN TRY-CATCH UNTUK GET USER DATA
      try {
        UserModel user = await UserServices().getUserById(userCredential.user!.uid);

        return user;
      } catch (e) {

        // ✅ FALLBACK: Buat user model minimal dari Firebase Auth data
        UserModel fallbackUser = UserModel(
          id: userCredential.user!.uid,
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
          email: userCredential.user!.email ?? email,
          role: isAdmin ? 'admin' : 'ortu',
        );
        return fallbackUser;
      }

    } catch (e) {
      throw Exception(_getUserFriendlyError(e));
    }
  }

  Future<UserModel> signUp({
    required String username,
    required String name,
    required String password,
    required String umur,
    required String pekerjaan,
    required String hp,
    required String email,
    required String role,
    required String jenisKelamin,        // 👈 NEW
    required String statusPerkawinan,    // 👈 NEW
    required String pendidikan,          // 👈 NEW
    required String alamat,              // 👈 NEW
    required String hubunganAnak,        // 👈 NEW
  }) async {
    try {
      String emailSign = "$username@spirit.com";

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: emailSign.trim(),
        password: password,
      );

      await userCredential.user!.sendEmailVerification();

      UserModel user = UserModel(
        id: userCredential.user!.uid,
        username: username,
        name: name,
        umur: umur,
        jenisKelamin: jenisKelamin,
        statusPerkawinan: statusPerkawinan,
        pendidikan: pendidikan,
        alamat: alamat,
        hubunganAnak: hubunganAnak,
        pekerjaan: pekerjaan,
        hp: hp,
        email: email,
        role: role,
      );

      await UserServices().setUser(user);

      return user;
    } catch (e) {
      rethrow;
    }
  }


  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw Exception(_getUserFriendlyError(e));
    }
  }

  // METHOD UNTUK UPDATE EMAIL
  Future<void> updateEmail(String newEmail) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.verifyBeforeUpdateEmail(newEmail.trim());
      } else {
        throw Exception('Tidak ada user yang login');
      }
    } catch (e) {
      throw Exception(_getUserFriendlyError(e));
    }
  }


  // // TAMBAHKAN METHOD UPDATE PROFILE
  // Future<UserModel> updateProfile({
  //   required String userId,
  //   required String username,
  // }) async {
  //   try {
  //     UserModel updatedUser = await UserServices().updateUser(
  //       userId: userId,
  //       username: username,
  //     );
  //
  //     return updatedUser;
  //   } catch (e) {
  //     throw Exception(_getUserFriendlyError(e));
  //   }
  // }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // GET CURRENT USER DARI FIREBASE AUTH
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
