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

  Future<void> saveDiagnosisForChild({
    required String parentId,
    required ChildModel child,
    required String diagnosis,     // misal: "Distres Spiritual (D.0128)"
    required String note,          // catatan klinis perawat
    String? nurseId,
    String? nurseName,
  }) async {
    try {
      // path: users/{parentId}/children/{childId}/diagnoses/{autoId}
      final docRef = _db
          .collection('users')
          .doc(parentId)
          .collection('children')
          .doc(child.id)
          .collection('diagnoses')
          .doc();

      await docRef.set({
        'childId': child.id,
        'childName': child.name,
        'parentId': parentId,

        'diagnosis': diagnosis,
        'note': note,

        // Simpan juga ringkasan skor & kategori HIFZ
        'totalScore': child.totalSkor,
        'overallCategory': child.kategori, // atau overallCategory dari halaman video

        'hifzAnNafsScore': child.hifzAnNafsScore,
        'hifzAdDiinScore': child.hifzAdDiinScore,
        'hifzAlAqlScore': child.hifzAlAqlScore,
        'hifzAnNaslScore': child.hifzAnNaslScore,
        'hifzAlMalScore': child.hifzAlMalScore,

        'hifzAnNafsCategory': child.hifzAnNafsCategory,
        'hifzAdDiinCategory': child.hifzAdDiinCategory,
        'hifzAlAqlCategory': child.hifzAlAqlCategory,
        'hifzAnNaslCategory': child.hifzAnNaslCategory,
        'hifzAlMalCategory': child.hifzAlMalCategory,

        // Info perawat yang mengisi
        'nurseId': nurseId,
        'nurseName': nurseName,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
        '✅ Diagnosis "$diagnosis" disimpan untuk anak ${child.name} (${child.id})',
      );
    } catch (e) {
      debugPrint('❌ Error saveDiagnosisForChild: $e');
      throw Exception('Gagal menyimpan diagnosa anak');
    }
  }

  Future<void> saveHifzDiagnosisForChild({
    required String parentId,
    required ChildModel child,
    required String aspectKey,     // contoh: 'adDiin', 'anNafs', ...
    required String aspectName,    // contoh: 'Hifz Ad-Diin'
    required String diagnosis,     // contoh: 'Distres Spiritual (D.0128)'
    required String note,          // catatan klinis perawat
    required int score,            // skor aspek tsb
    required String category,      // kategori aspek tsb
    String? nurseId,
    String? nurseName,
  }) async {
    try {
      final ref = _db
          .collection('users')
          .doc(parentId)
          .collection('children')
          .doc(child.id)
          .collection('hifz_diagnoses')
          .doc(aspectKey); // 1 dokumen per aspek

      await ref.set({
        'childId': child.id,
        'childName': child.name,
        'parentId': parentId,

        'aspectKey': aspectKey,
        'aspectName': aspectName,

        'diagnosis': diagnosis,
        'note': note,

        'score': score,
        'category': category,

        'nurseId': nurseId,
        'nurseName': nurseName,

        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // supaya bisa update berkali-kali

      debugPrint(
        '✅ HIFZ diagnosis [$aspectKey] disimpan untuk anak ${child.name}',
      );
    } catch (e) {
      debugPrint('❌ Error saveHifzDiagnosisForChild: $e');
      throw Exception('Gagal menyimpan diagnosa HIFZ');
    }
  }

  Future<Map<String, Map<String, dynamic>>> getHifzDiagnosesForChild({
    required String parentId,
    required String childId,
  }) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('hifz_diagnoses')
          .get();

      final result = <String, Map<String, dynamic>>{};
      for (final d in snap.docs) {
        result[d.id] = d.data();
      }
      return result;
    } catch (e) {
      debugPrint('❌ Error getHifzDiagnosesForChild: $e');
      rethrow;
    }
  }
}