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
    debugPrint('[ChildCubit] loadChildren untuk parentId = $parentId');
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
    required String jenisKelamin,
    required String pendidikan,
    required Map<String, String> pertanyaan,
    List<String> harapan = const [],
  }) async {
    try {
      emit(ChildLoading());

      // id bisa dikosongkan, biasanya Firestore generate sendiri
      final tempChild = ChildModel(
        id: '',
        parentId: parentId,
        name: name,
        username: username,
        password: password,
        umur: umur,
        jenisKelamin: jenisKelamin,
        pendidikan: pendidikan,
        pertanyaan: pertanyaan,
        harapan: harapan,
        totalSkor: 0,
        kategori: '',
      );

      final totalSkor = tempChild.calculateScore();
      final kategori = tempChild.determineCategory(totalSkor);

      final finalChild = tempChild.copyWith(
        totalSkor: totalSkor,
        kategori: kategori,
      );

      await _services.addChild(finalChild);

      final children = await _services.getChildren(parentId);
      emit(ChildLoaded(children));
    } catch (e) {
      emit(ChildFailed(e.toString()));
    }
  }

  Future<void> saveDiagnosis({
    required String parentId,
    required ChildModel child,
    required String diagnosis,
    required String note,
    String? nurseId,
    String? nurseName,
  }) async {
    try {
      debugPrint(
        '[ChildCubit] saveDiagnosis untuk childId=${child.id}, parentId=$parentId',
      );
      await _services.saveDiagnosisForChild(
        parentId: parentId,
        child: child,
        diagnosis: diagnosis,
        note: note,
        nurseId: nurseId,
        nurseName: nurseName,
      );
      // Tidak mengubah state list anak, hanya log
    } catch (e) {
      debugPrint('[ChildCubit] ❌ saveDiagnosis error: $e');
      emit(ChildFailed(e.toString()));
    }
  }
}