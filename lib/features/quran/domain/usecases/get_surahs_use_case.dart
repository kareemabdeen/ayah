import '../entities/surah.dart';
import '../repositories/quran_repository.dart';

final class GetSurahsUseCase {
  const GetSurahsUseCase(this._repository);
  final QuranRepository _repository;

  List<Surah> call() => _repository.getSurahs();
}
