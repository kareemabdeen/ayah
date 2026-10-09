/// Data-layer exceptions. Repositories catch these and convert them to
/// [Failure]s so nothing above the data layer ever sees them.
final class NetworkException implements Exception {
  const NetworkException([this.message = '']);
  final String message;
  @override
  String toString() => 'NetworkException: $message';
}

final class CacheMissException implements Exception {
  const CacheMissException([this.message = '']);
  final String message;
  @override
  String toString() => 'CacheMissException: $message';
}

final class DataFormatException implements Exception {
  const DataFormatException([this.message = '']);
  final String message;
  @override
  String toString() => 'DataFormatException: $message';
}
