// services/child_auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import '../models/child_model.dart';

class ChildAuthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<ChildModel?> signInChild({
    required String username,
    required String password,
  }) async {
    try {
      // 1. Coba login dengan Firebase Auth
      final String childEmail = "$username@child.spirit.com";

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: childEmail.trim(),
        password: password,
      );

      final String childUid = userCredential.user!.uid;

      // 2. Cari data anak di Firestore berdasarkan UID - FIXED
      final child = await _findChildByUid(childUid);

      if (child == null) {
        // Jika tidak ditemukan di Firestore, logout dari auth
        await _auth.signOut();
        throw Exception('Data anak tidak ditemukan di database');
      }

      return child;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getChildAuthError(e.code));
    } catch (e) {
      throw Exception('Gagal login: ${e.toString()}');
    }
  }

  // Method baru untuk mencari child by UID tanpa menggunakan FieldPath.documentId()
  Future<ChildModel?> _findChildByUid(String childUid) async {
    try {
      // Query semua documents di collection group 'children'
      final querySnapshot = await _db
          .collectionGroup('children')
          .get();

      // Cari manual document dengan ID yang sesuai
      for (final doc in querySnapshot.docs) {
        if (doc.id == childUid) {
          return ChildModel.fromJson(doc.id, doc.data());
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error finding child by UID: $e');
      return null;
    }
  }

  String _getChildAuthError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Username tidak ditemukan';
      case 'wrong-password':
        return 'Password salah';
      case 'invalid-email':
        return 'Format username tidak valid';
      case 'user-disabled':
        return 'Akun anak dinonaktifkan';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan login. Coba lagi nanti';
      default:
        return 'Terjadi kesalahan saat login';
    }
  }

  // Method untuk mengecek apakah username sudah digunakan - SIMPLIFIED
  Future<bool> isUsernameTaken(String username) async {
    try {
      final String childEmail = "${username}@child.spirit.com";

      // Cek di Firestore berdasarkan username
      final querySnapshot = await _db
          .collectionGroup('children')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return true;
      }

      // Cek di Firebase Auth dengan try-catch
      try {
        await _auth.signInWithEmailAndPassword(
          email: childEmail,
          password: 'dummy_password_123',
        );
        // Jika berhasil sign in, berarti email terdaftar
        await _auth.signOut();
        return true;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password') {
          return true; // Email terdaftar
        } else if (e.code == 'user-not-found') {
          return false; // Email tidak terdaftar
        }
        return false; // Untuk error lain, anggap available
      }
    } catch (e) {
      debugPrint('Error checking username: $e');
      return false;
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      // Cek di Firestore dulu
      final firestoreCheck = await _db
          .collectionGroup('children')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (firestoreCheck.docs.isNotEmpty) {
        return false;
      }

      // Cek di Auth dengan create user (lalu delete jika berhasil)
      final String childEmail = "${username}@child.spirit.com";

      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: childEmail,
          password: 'TempPassword123!',
        );

        // Jika berhasil dibuat, hapus user tersebut
        await credential.user?.delete();
        return true;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          return false;
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error in isUsernameAvailable: $e');
      return true;
    }
  }

  // Method untuk delete akun anak - FIXED
  Future<void> deleteChildAccount(String childId) async {
    try {
      // Cari child document terlebih dahulu
      final child = await _findChildByUid(childId);
      if (child == null) {
        throw Exception('Data anak tidak ditemukan');
      }

      // Hapus dari Firestore
      final usersSnapshot = await _db.collection('users').get();
      for (final userDoc in usersSnapshot.docs) {
        final parentId = userDoc.id;
        try {
          await _db
              .collection('users')
              .doc(parentId)
              .collection('children')
              .doc(childId)
              .delete();
        } catch (e) {
          // Continue jika document tidak ditemukan
          continue;
        }
      }

      debugPrint('Child account marked for deletion: $childId');

    } catch (e) {
      throw Exception('Gagal menghapus akun anak: ${e.toString()}');
    }
  }

  // Method untuk mendapatkan child by ID - FIXED
  Future<ChildModel?> getChildById(String childId) async {
    try {
      return await _findChildByUid(childId);
    } catch (e) {
      debugPrint('Error getting child by ID: $e');
      return null;
    }
  }
}