import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/surah_progress.dart';
import '../../domain/usecases/get_surah_progress_use_case.dart';

enum ProgressStatus { loading, ready }

final class ProgressState extends Equatable {
  const ProgressState({this.status = ProgressStatus.loading, this.surahs = const []});

  final ProgressStatus status;
  final List<SurahProgress> surahs;

  @override
  List<Object?> get props => [status, surahs];
}

final class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit({required GetSurahProgressUseCase getSurahProgress})
      : _get = getSurahProgress,
        super(const ProgressState());

  final GetSurahProgressUseCase _get;

  Future<void> load() async {
    final list = await _get.onPath();
    if (!isClosed) emit(ProgressState(status: ProgressStatus.ready, surahs: list));
  }
}
