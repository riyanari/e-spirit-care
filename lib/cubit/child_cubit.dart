// cubit/child_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/child_model.dart';
import '../services/child_services.dart';

part 'child_state.dart';

class ChildCubit extends Cubit<ChildState> {
  ChildCubit() : super(ChildInitial());

  final ChildServices _services = ChildServices();

  Future<void> loadChildren(String parentId) async {
    try {
      emit(ChildLoading());
      final children = await _services.getChildren(parentId);
      emit(ChildLoaded(children));
    } catch (e) {
      emit(ChildFailed(e.toString()));
    }
  }

  Future<void> addChild({
    required String parentId,
    required String name,
    required String username,
    required String password,
    required String umur,
    required String jenisKelamin,   // 👈 NEW
    required String pendidikan,
    // 20 pertanyaan
    required String doaSederhana,
    required String rutinMurottal,
    required String dikenalkanShalat,
    required String ceritaIslami,
    required String doaPerlindungan,
    required String pahamSakitUjian,
    required String hafalSuratPendek,
    required String tahuRukunIman,
    required String tahuRukunIslam,
    required String sopanSantun,
    required String jujurDalamBerkata,
    required String menghormatiOrtu,
    required String berbagiDenganSaudara,
    required String menjagaKebersihan,
    required String disiplinWaktu,
    required String menghafalDoaHarian,
    required String mengucapSalam,
    required String membacaBismillah,
    required String bersyukur,
    required String sabarMenghadapiMasalah,
    required List<String> harapan,
  }) async {
    try {
      emit(ChildLoading());

      // Buat ID sementara untuk perhitungan skor
      final tempId = _services.newChildId(parentId);

      // Buat child model sementara untuk menghitung skor
      final tempChild = ChildModel(
        id: tempId,
        parentId: parentId,
        name: name,
        username: username,
        password: password,
        umur: umur,
        jenisKelamin: jenisKelamin,   // 👈 NEW
        pendidikan: pendidikan,
        // 20 pertanyaan
        doaSederhana: doaSederhana,
        rutinMurottal: rutinMurottal,
        dikenalkanShalat: dikenalkanShalat,
        ceritaIslami: ceritaIslami,
        doaPerlindungan: doaPerlindungan,
        pahamSakitUjian: pahamSakitUjian,
        hafalSuratPendek: hafalSuratPendek,
        tahuRukunIman: tahuRukunIman,
        tahuRukunIslam: tahuRukunIslam,
        sopanSantun: sopanSantun,
        jujurDalamBerkata: jujurDalamBerkata,
        menghormatiOrtu: menghormatiOrtu,
        berbagiDenganSaudara: berbagiDenganSaudara,
        menjagaKebersihan: menjagaKebersihan,
        disiplinWaktu: disiplinWaktu,
        menghafalDoaHarian: menghafalDoaHarian,
        mengucapSalam: mengucapSalam,
        membacaBismillah: membacaBismillah,
        bersyukur: bersyukur,
        sabarMenghadapiMasalah: sabarMenghadapiMasalah,
        harapan: harapan,
        totalSkor: 0,
        kategori: '',
      );

      // Hitung total skor dari 20 pertanyaan
      final totalSkor = tempChild.calculateScore();
      final kategori = tempChild.determineCategory(totalSkor);

      // Buat child model final
      final child = ChildModel(
        id: tempId, // ID sementara, akan diganti oleh ChildServices
        parentId: parentId,
        name: name,
        username: username,
        password: password,
        umur: umur,
        jenisKelamin: jenisKelamin,   // 👈 NEW
        pendidikan: pendidikan,
        // 20 pertanyaan
        doaSederhana: doaSederhana,
        rutinMurottal: rutinMurottal,
        dikenalkanShalat: dikenalkanShalat,
        ceritaIslami: ceritaIslami,
        doaPerlindungan: doaPerlindungan,
        pahamSakitUjian: pahamSakitUjian,
        hafalSuratPendek: hafalSuratPendek,
        tahuRukunIman: tahuRukunIman,
        tahuRukunIslam: tahuRukunIslam,
        sopanSantun: sopanSantun,
        jujurDalamBerkata: jujurDalamBerkata,
        menghormatiOrtu: menghormatiOrtu,
        berbagiDenganSaudara: berbagiDenganSaudara,
        menjagaKebersihan: menjagaKebersihan,
        disiplinWaktu: disiplinWaktu,
        menghafalDoaHarian: menghafalDoaHarian,
        mengucapSalam: mengucapSalam,
        membacaBismillah: membacaBismillah,
        bersyukur: bersyukur,
        sabarMenghadapiMasalah: sabarMenghadapiMasalah,
        harapan: harapan,
        totalSkor: totalSkor,
        kategori: kategori,
      );

      // Panggil service untuk menyimpan child (termasuk membuat akun auth)
      await _services.addChild(child);

      // Load ulang data children
      final children = await _services.getChildren(parentId);
      emit(ChildLoaded(children));

    } catch (e) {
      emit(ChildFailed(e.toString()));
    }
  }
}