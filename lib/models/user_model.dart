import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String username;
  final String name;
  final String umur;
  final String jenisKelamin;        // 👈 NEW
  final String statusPerkawinan;    // 👈 NEW
  final String pendidikan;          // 👈 NEW
  final String alamat;              // 👈 NEW
  final String hubunganAnak;        // 👈 NEW
  final String pekerjaan;
  final String hp;
  final String email;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.umur,
    required this.jenisKelamin,      // 👈 NEW
    required this.statusPerkawinan,  // 👈 NEW
    required this.pendidikan,        // 👈 NEW
    required this.alamat,            // 👈 NEW
    required this.hubunganAnak,      // 👈 NEW
    required this.pekerjaan,
    required this.hp,
    required this.email,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  // Optional: update copyWith kalau mau dipakai
  UserModel copyWith({
    String? name,
    String? jenisKelamin,
    String? statusPerkawinan,
    String? pendidikan,
    String? alamat,
    String? hubunganAnak,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id,
      username: username,
      name: name ?? this.name,
      umur: umur,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      statusPerkawinan: statusPerkawinan ?? this.statusPerkawinan,
      pendidikan: pendidikan ?? this.pendidikan,
      alamat: alamat ?? this.alamat,
      hubunganAnak: hubunganAnak ?? this.hubunganAnak,
      pekerjaan: pekerjaan,
      hp: hp,
      email: email,
      role: role,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    username,
    name,
    umur,
    jenisKelamin,
    statusPerkawinan,
    pendidikan,
    alamat,
    hubunganAnak,
    pekerjaan,
    hp,
    email,
    role,
    createdAt,
    updatedAt,
  ];
}
