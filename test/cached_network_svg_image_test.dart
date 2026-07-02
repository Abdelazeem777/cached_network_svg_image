import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_svg_image/cached_network_svg_image.dart';
import 'package:file/file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('removes a stale cached file and retries download once', (
    tester,
  ) async {
    const url = 'https://example.com/image.svg?token=abc';
    const expectedCacheKey = 'https://example.com/image.svg';
    final cacheManager = _FakeCacheManager(
      memoryFileInfo: FileInfo(
        const _MissingFile('/missing.svg'),
        FileSource.Cache,
        DateTime(3000),
        url,
      ),
      downloadFileInfo: FileInfo(
        _BytesFile('/fresh.svg', _validSvgBytes),
        FileSource.Online,
        DateTime(3000),
        url,
      ),
    );

    await _pumpImage(tester, cacheManager, url: url);
    await tester.pumpAndSettle();

    expect(cacheManager.memoryKeys, <String>[expectedCacheKey]);
    expect(cacheManager.removedKeys, <String>[expectedCacheKey]);
    expect(cacheManager.downloadRequests, hasLength(1));
    expect(cacheManager.downloadRequests.single.url, url);
    expect(cacheManager.downloadRequests.single.key, expectedCacheKey);
    expect(cacheManager.downloadRequests.single.force, isTrue);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('error'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows errorWidget when download fails', (tester) async {
    final cacheManager = _FakeCacheManager(
      getSingleFileError: Exception('download failed'),
    );

    await _pumpImage(tester, cacheManager);
    await tester.pumpAndSettle();

    expect(find.text('error'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows errorWidget when SVG decoding fails', (tester) async {
    final cacheManager = _FakeCacheManager(
      memoryFileInfo: FileInfo(
        _BytesFile('/invalid.svg', utf8.encode('not an svg')),
        FileSource.Cache,
        DateTime(3000),
        _url,
      ),
    );

    await _pumpImage(tester, cacheManager);
    await tester.pumpAndSettle();

    expect(find.text('error'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _url = 'https://example.com/image.svg';

final _validSvgBytes = Uint8List.fromList(
  utf8.encode(
    '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">'
    '<rect width="10" height="10" fill="#000000"/>'
    '</svg>',
  ),
);

Future<void> _pumpImage(
  WidgetTester tester,
  BaseCacheManager cacheManager, {
  String url = _url,
  String? cacheKey,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: CachedNetworkSVGImage(
        url,
        cacheKey: cacheKey,
        cacheManager: cacheManager,
        placeholder: const Text('placeholder'),
        errorWidget: const Text('error'),
        width: 10,
        height: 10,
        fadeDuration: Duration.zero,
      ),
    ),
  );
}

class _FakeCacheManager implements BaseCacheManager {
  _FakeCacheManager({
    this.memoryFileInfo,
    this.downloadFileInfo,
    this.getSingleFileError,
  });

  final FileInfo? memoryFileInfo;
  final FileInfo? downloadFileInfo;
  final Object? getSingleFileError;

  final memoryKeys = <String>[];
  final removedKeys = <String>[];
  final downloadRequests = <_DownloadRequest>[];

  @override
  Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) async {
    downloadRequests.add(_DownloadRequest(url, key, force));

    final fileInfo = downloadFileInfo;
    if (fileInfo == null) {
      throw StateError('downloadFile was not expected');
    }

    return fileInfo;
  }

  @override
  Future<void> emptyCache() async {}

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async {
    return null;
  }

  @override
  Future<FileInfo?> getFileFromMemory(String key) async {
    memoryKeys.add(key);
    return memoryFileInfo;
  }

  @override
  Future<File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) async {
    final error = getSingleFileError;
    if (error != null) throw error;

    throw StateError('getSingleFile was not expected');
  }

  @override
  Future<File> putFile(
    String url,
    Uint8List fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) {
    throw UnsupportedError('putFile is not implemented');
  }

  @override
  Future<File> putFileStream(
    String url,
    Stream<List<int>> source, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) {
    throw UnsupportedError('putFileStream is not implemented');
  }

  @override
  Future<void> removeFile(String key) async {
    removedKeys.add(key);
  }

  @override
  Future<void> dispose() async {}

  @override
  Stream<FileInfo> getFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) {
    throw UnsupportedError('getFile is not implemented');
  }

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    throw UnsupportedError('getFileStream is not implemented');
  }
}

class _DownloadRequest {
  const _DownloadRequest(this.url, this.key, this.force);

  final String url;
  final String? key;
  final bool force;
}

class _BytesFile implements File {
  _BytesFile(this.path, List<int> bytes) : _bytes = Uint8List.fromList(bytes);

  final Uint8List _bytes;

  @override
  final String path;

  @override
  Future<Uint8List> readAsBytes() async => _bytes;

  @override
  Uint8List readAsBytesSync() => _bytes;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MissingFile implements File {
  const _MissingFile(this.path);

  @override
  final String path;

  @override
  Future<Uint8List> readAsBytes() {
    throw FileSystemException('No such file or directory', path);
  }

  @override
  Uint8List readAsBytesSync() {
    throw FileSystemException('No such file or directory', path);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
