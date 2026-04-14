import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/study_mode.dart';

/// Cubit quản lý chế độ học hiện tại: Luyện thi hoặc Trải nghiệm.
class StudyModeCubit extends Cubit<StudyMode> {
  StudyModeCubit({StudyModeRepository? repository})
    : _repository = repository ?? StudyModeRepository.instance,
      super(StudyMode.examPrep);

  final StudyModeRepository _repository;

  Future<void> load() async {
    final mode = await _repository.getMode();
    emit(mode);
  }

  Future<void> setMode(StudyMode mode) async {
    await _repository.setMode(mode);
    emit(mode);
  }

  /// Convenience getters for UI conditional logic.
  bool get isExamPrep => state == StudyMode.examPrep;
  bool get isCasual => state == StudyMode.casual;
  bool get showTimer => isExamPrep;
  bool get showHints => isCasual;
}
