import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpException;

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tiny valid SVG (a 10x10 red square).
final validSvgBytes = utf8.encode(
  '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10" '
  'viewBox="0 0 10 10"><rect width="10" height="10" fill="#ff0000"/></svg>',
);

/// A second valid SVG (a 10x10 blue square), to tell two images apart.
final otherSvgBytes = utf8.encode(
  '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10" '
  'viewBox="0 0 10 10"><rect width="10" height="10" fill="#0000ff"/></svg>',
);

/// Bytes that download fine but are not an SVG document.
final invalidSvgBytes = utf8.encode('<<< definitely not an svg >>>');

/// One recorded call to [BaseCacheManager.getSingleFile] or
/// [BaseCacheManager.downloadFile].
class FetchCall {
  FetchCall(this.url, this.key, this.headers);

  final String url;
  final String? key;
  final Map<String, String>? headers;

  @override
  String toString() => 'FetchCall($url, key: $key, headers: $headers)';
}

/// In-memory [BaseCacheManager] that never touches the network, the file
/// system or any platform channel.
///
/// * [responses] maps a request URL to the bytes it serves. URLs without an
///   entry fail with an [HttpException], like a 404 from the real manager.
/// * [errors] maps a request URL to an error to throw instead.
/// * Successful fetches are kept in a memory cache under their cache key, so
///   [getFileFromMemory] behaves like the real manager's memory cache.
/// * When [gate] is set, fetches wait for it before answering, which keeps
///   the widget in its loading state for as long as a test needs.
class FakeCacheManager extends Fake implements BaseCacheManager {
  FakeCacheManager({
    Map<String, List<int>>? responses,
    Map<String, Object>? errors,
  })  : responses = responses ?? {},
        errors = errors ?? {};

  final Map<String, List<int>> responses;
  final Map<String, Object> errors;
  Completer<void>? gate;

  final List<FetchCall> getSingleFileCalls = [];
  final List<FetchCall> downloadFileCalls = [];
  final List<String> getFileFromMemoryCalls = [];
  final List<String> removedKeys = [];
  int emptyCacheCalls = 0;

  final MemoryFileSystem _fs = MemoryFileSystem();
  final Map<String, FileInfo> _memoryCache = {};
  int _fileCounter = 0;

  /// Keys currently held in the memory cache.
  Iterable<String> get cachedKeys => _memoryCache.keys;

  /// Puts [bytes] in the memory cache under [key], as a previous load would.
  void seedMemoryCache(String key, List<int> bytes) {
    _memoryCache[key] = _fileInfo(key, bytes);
  }

  @override
  Future<FileInfo?> getFileFromMemory(String key) async {
    getFileFromMemoryCalls.add(key);
    return _memoryCache[key];
  }

  @override
  Future<File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) async {
    getSingleFileCalls.add(FetchCall(url, key, headers));
    return (await _fetch(url, key ?? url)).file;
  }

  @override
  Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) {
    downloadFileCalls.add(FetchCall(url, key, authHeaders));
    return _fetch(url, key ?? url);
  }

  @override
  Future<void> removeFile(String key) async {
    removedKeys.add(key);
    _memoryCache.remove(key);
  }

  @override
  Future<void> emptyCache() async {
    emptyCacheCalls++;
    _memoryCache.clear();
  }

  Future<FileInfo> _fetch(String url, String key) async {
    if (gate != null) await gate!.future;

    final error = errors[url];
    if (error != null) throw error;

    final bytes = responses[url];
    if (bytes == null) throw HttpException('404 for $url', uri: Uri.parse(url));

    return _memoryCache[key] = _fileInfo(url, bytes);
  }

  FileInfo _fileInfo(String url, List<int> bytes) {
    final file = _fs.file('/cache/${_fileCounter++}.svg')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
    return FileInfo(file, FileSource.Online, DateTime(2100), url);
  }
}
