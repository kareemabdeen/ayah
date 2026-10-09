import '../../../memorization/domain/entities/memorization_session.dart';
import '../../../quran/domain/entities/verse_key.dart';
import '../../domain/entities/daily_progress.dart';
import '../../domain/entities/verse_progress.dart';

/// JSON mappers kept out of the domain entities so the domain stays pure.
abstract final class VerseProgressMapper {
  static Map<String, dynamic> toJson(VerseProgress p) => {
        'key': p.key.id,
        'status': p.status.name,
        'stage': p.stage,
        'repetitionCount': p.repetitionCount,
        'lapses': p.lapses,
        'confidence': p.confidence,
        'difficulty': p.difficulty,
        'memorizedAt': p.memorizedAt.toIso8601String(),
        'lastReviewedAt': p.lastReviewedAt.toIso8601String(),
        'nextReviewAt': p.nextReviewAt.toIso8601String(),
      };

  static VerseProgress fromJson(Map<String, dynamic> j) => VerseProgress(
        key: VerseKey.parse(j['key'] as String),
        status: VerseStatus.values.where((s) => s.name == j['status']).firstOrNull ?? VerseStatus.learning,
        stage: j['stage'] as int? ?? 0,
        repetitionCount: j['repetitionCount'] as int? ?? 0,
        lapses: j['lapses'] as int? ?? 0,
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0,
        difficulty: (j['difficulty'] as num?)?.toDouble() ?? 0.3,
        memorizedAt: DateTime.parse(j['memorizedAt'] as String),
        lastReviewedAt: DateTime.parse(j['lastReviewedAt'] as String),
        nextReviewAt: DateTime.parse(j['nextReviewAt'] as String),
      );
}

abstract final class DailyProgressMapper {
  static Map<String, dynamic> toJson(DailyProgress d) => {
        'dayKey': d.dayKey,
        'newVersesMemorized': d.newVersesMemorized,
        'reviewsCompleted': d.reviewsCompleted,
      };

  static DailyProgress fromJson(Map<String, dynamic> j) => DailyProgress(
        dayKey: j['dayKey'] as String,
        newVersesMemorized: [for (final v in (j['newVersesMemorized'] as List? ?? const [])) v as String],
        reviewsCompleted: j['reviewsCompleted'] as int? ?? 0,
      );
}

abstract final class SessionRecordMapper {
  static Map<String, dynamic> toJson(MemorizationSessionRecord r) => {
        'id': r.id,
        'startedAt': r.startedAt.toIso8601String(),
        'endedAt': r.endedAt.toIso8601String(),
        'verseIds': r.verseIds,
        'type': r.type,
      };
}
