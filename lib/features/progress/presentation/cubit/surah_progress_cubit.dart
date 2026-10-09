import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/surah_progress.dart';
import '../../domain/usecases/get_surah_progress_use_case.dart';

final class SurahProgressState extends Equatable {
  const SurahProgressState({this.detail});

  final SurahProgressDetail? detail;

  bool get isLoading => detail == null;

  @override
  List<Object?> get props => [detail];
}

final class SurahProgressCubit extends Cubit<SurahProgressState> {
  SurahProgressCubit({required GetSurahProgressUseCase getSurahProgress})
      : _get = getSurahProgress,
        super(const SurahProgressState());

  final GetSurahProgressUseCase _get;
  int? _surahId;

  Future<void> load(int surahId) async {
    _surahId = surahId;
    final detail = await _get.detail(surahId);
    if (!isClosed) emit(SurahProgressState(detail: detail));
  }

  Future<void> refresh() async {
    final id = _surahId;
    if (id != null) await load(id);
  }
}
