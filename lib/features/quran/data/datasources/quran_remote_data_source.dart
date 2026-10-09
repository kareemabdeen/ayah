import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/verse_dto.dart';

abstract interface class QuranRemoteDataSource {
  Future<List<VerseDto>> fetchSurah(int surahId);
}

/// Fetches verified Uthmani text (Tanzil) from AlQuran Cloud.
final class AlQuranCloudRemoteDataSource implements QuranRemoteDataSource {
  AlQuranCloudRemoteDataSource(this._client);

  final http.Client _client;

  @override
  Future<List<VerseDto>> fetchSurah(int surahId) async {
    final uri = Uri.parse(
      '${QuranSourceConstants.textApiBase}/surah/$surahId/${QuranSourceConstants.textEdition}',
    );
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(QuranSourceConstants.requestTimeout);
    } on TimeoutException {
      throw const NetworkException('timeout');
    } catch (e) {
      throw NetworkException(e.toString());
    }
    if (response.statusCode != 200) throw NetworkException('HTTP ${response.statusCode}');

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    final ayahs = (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>)
        ? (body['data'] as Map<String, dynamic>)['ayahs']
        : null;
    if (ayahs is! List) throw const DataFormatException('Missing ayahs');

    return [
      for (final a in ayahs) VerseDto.fromAlQuranCloud(surahId, a as Map<String, dynamic>),
    ];
  }
}
