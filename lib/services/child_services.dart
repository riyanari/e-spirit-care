// services/child_services.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import '../models/child_model.dart';

class ChildServices {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addChild(ChildModel child) async {
    try {
      // 1. Buat akun authentication di Firebase Auth
      final String childEmail = "${child.username}@child.spirit.com";

      debugPrint('🔄 Membuat akun auth untuk: $childEmail');

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: childEmail.trim(),
        password: child.password,
      );

      final String childUid = userCredential.user!.uid;
      debugPrint('✅ Akun auth berhasil dibuat dengan UID: $childUid');

      // 2. Simpan data anak ke Firestore dengan ID dari Firebase Auth
      final ref = _db
          .collection('users')
          .doc(child.parentId)
          .collection('children')
          .doc(childUid);

      // Update child model dengan ID yang baru dari Firebase Auth
      final updatedChild = child.copyWith(id: childUid);

      await ref.set(updatedChild.toJson());

      debugPrint('✅ Data anak berhasil disimpan ke Firestore: ${child.name}');

    } on FirebaseAuthException catch (e) {
      String errorMessage = _getAuthError(e.code);
      debugPrint('❌ Error auth: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('❌ Error umum: $e');
      throw Exception('Gagal membuat akun anak: ${e.toString()}');
    }
  }

  String _getAuthError(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'Username sudah digunakan oleh anak lain';
      case 'invalid-email':
        return 'Format username tidak valid';
      case 'weak-password':
        return 'Password terlalu lemah, minimal 6 karakter';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah';
      default:
        return 'Terjadi kesalahan: $errorCode';
    }
  }

  Future<List<ChildModel>> getChildren(String parentId) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(parentId)
          .collection('children')
          .orderBy('createdAt', descending: false)
          .get();

      debugPrint('📥 Memuat ${snap.docs.length} anak untuk parent: $parentId');

      return snap.docs
          .map((d) => ChildModel.fromJson(d.id, d.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getChildren: $e');
      throw Exception('Gagal memuat data anak');
    }
  }

  /// Membuat id baru secara otomatis untuk setiap anak
  String newChildId(String parentId) {
    return _db
        .collection('users')
        .doc(parentId)
        .collection('children')
        .doc()
        .id;
  }
}