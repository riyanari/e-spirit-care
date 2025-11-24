import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../models/user_model.dart';

class UserServices {
  final CollectionReference _userReference = FirebaseFirestore.instance
      .collection('users');

  Future<void> setUser(UserModel user) async {
    try {
      await _userReference.doc(user.id).set({
        'username': user.username,
        'name': user.name,
        'umur': user.umur,
        'jenisKelamin': user.jenisKelamin,          // 👈 NEW
        'statusPerkawinan': user.statusPerkawinan,  // 👈 NEW
        'pendidikan': user.pendidikan,              // 👈 NEW
        'alamat': user.alamat,                      // 👈 NEW
        'hubunganAnak': user.hubunganAnak,          // 👈 NEW
        'pekerjaan': user.pekerjaan,
        'hp': user.hp,
        'email': user.email,
        'role': user.role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }


  // // TAMBAHKAN METHOD UPDATE USER
  // Future<UserModel> updateUser({
  //   required String userId,
  //   required String username,
  // }) async {
  //   try {
  //     await _userReference.doc(userId).update({
  //       'username': username,
  //       'updatedAt': FieldValue.serverTimestamp(),
  //     });
  //
  //     // Get updated user data
  //     DocumentSnapshot snapshot = await _userReference.doc(userId).get();
  //     Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
  //
  //     return UserModel(
  //       id: snapshot.id,
  //       username: data['username'],
  //       name: data['name'],
  //       umur: data['umur'],
  //       pekerjaan: data['pekerjaan'],
  //       hp: data['hp'],
  //       email: data['email'],
  //       role: data['role'],
  //     );
  //   } catch (e) {
  //     throw Exception('Gagal mengupdate profile: $e');
  //   }
  // }

  Future<UserModel> getUserById(String id) async {
    try {
      debugPrint('[UserServices] 🔍 Getting user data for ID: $id');

      final snapshot = await _userReference.doc(id).get();

      if (!snapshot.exists) {
        debugPrint('[UserServices] ❌ User document does not exist for ID: $id');
        throw Exception('User tidak ditemukan di database');
      }

      final data = snapshot.data() as Map<String, dynamic>;
      debugPrint('[UserServices] 📄 User document data: $data');

      UserModel user = UserModel(
        id: id,
        username: (data['username'] ?? 'unknown') as String,
        name: (data['name'] ?? 'User') as String,
        umur: (data['umur'] ?? '') as String,
        jenisKelamin: (data['jenisKelamin'] ?? '') as String,          // 👈 NEW
        statusPerkawinan: (data['statusPerkawinan'] ?? '') as String,  // 👈 NEW
        pendidikan: (data['pendidikan'] ?? '') as String,              // 👈 NEW
        alamat: (data['alamat'] ?? '') as String,                      // 👈 NEW
        hubunganAnak: (data['hubunganAnak'] ?? '') as String,          // 👈 NEW
        pekerjaan: (data['pekerjaan'] ?? '') as String,
        hp: (data['hp'] ?? '') as String,
        email: (data['email'] ?? '') as String,
        role: (data['role'] ?? 'user') as String,
        createdAt: data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : null,
        updatedAt: data['updatedAt'] is Timestamp
            ? (data['updatedAt'] as Timestamp).toDate()
            : null,
      );

      return user;
    } catch (e) {
      debugPrint('''
❌ [UserServices] ERROR getting user by ID: $id
├── Error: $e
├── Error Type: ${e.runtimeType}
''');
      rethrow;
    }
  }


  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final snapshot = await _userReference
          .where('role', isEqualTo: role)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return UserModel(
          id: doc.id,
          username: data['username'] ?? '',
          name: data['name'] ?? '',
          umur: data['umur'] ?? '',
          jenisKelamin: data['jenisKelamin'] ?? '',          // 👈 NEW
          statusPerkawinan: data['statusPerkawinan'] ?? '',  // 👈 NEW
          pendidikan: data['pendidikan'] ?? '',              // 👈 NEW
          alamat: data['alamat'] ?? '',                      // 👈 NEW
          hubunganAnak: data['hubunganAnak'] ?? '',          // 👈 NEW
          pekerjaan: data['pekerjaan'] ?? '',
          hp: data['hp'] ?? '',
          email: data['email'] ?? '',
          role: data['role'] ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
        );
      }).toList();
    } catch (e) {
      debugPrint('[UserServices] getUsersByRole error: $e');
      rethrow;
    }
  }


}
