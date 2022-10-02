import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class LYAvatarCacheManger {
  static LYAvatarCacheManger single = LYAvatarCacheManger._();

  LYAvatarCacheManger._();

  TheCacheManager cacheManager = TheCacheManager.single;

  static Future<void> removeCacheAndFile(String key) async {
    return single.cacheManager.removeFile(key);
  }
}

class TheCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'avatarCachedImageData';
  TheCacheManager._(Config config) : super(config);
  static TheCacheManager single = TheCacheManager._(Config(key, maxNrOfCacheObjects: 10));
  @override
  Stream<FileResponse> getFileStream(String url,
      {String? key, Map<String, String>? headers, bool withProgress = false}) {
    key ??= url;
    final streamController = StreamController<FileResponse>();
    _pushFileToStream(streamController, url, key, headers, withProgress);
    return streamController.stream;
  }

  Future<void> _pushFileToStream(StreamController streamController, String url, String? key,
      Map<String, String>? headers, bool withProgress) async {
    key ??= url;
    FileInfo? cacheFile;
    try {
      cacheFile = await getFileFromCache(key);
      if (cacheFile != null) {
        streamController.add(cacheFile);
        withProgress = false;
      }
    } catch (e) {
      cacheLogger.log('CacheManager: Failed to load cached file for $url with error:\n$e', CacheManagerLogLevel.debug);
    }

    /// no check max age , as I want always get a new file !
    try {
      await for (var response in webHelper.downloadFile(url, key: key, authHeaders: headers)) {
        if (response is DownloadProgress && withProgress) {
          streamController.add(response);
        }
        if (response is FileInfo) {
          streamController.add(response);
        }
      }
    } catch (e) {
      cacheLogger.log('CacheManager: Failed to download file from $url with error:\n$e', CacheManagerLogLevel.debug);
      if (cacheFile == null && streamController.hasListener) {
        streamController.addError(e);
      }
    }
    unawaited(streamController.close());
  }

  requestHasNewResource(String url) {
    webHelper.downloadFile(url);
  }

  static const statusCodesNewFile = [HttpStatus.ok, HttpStatus.accepted];
  static const statusCodesFileNotChanged = [HttpStatus.notModified];

  /// check file has updated? if uodated we will call [_pushFileToStream] then download a new one ;
  Future<bool> hasNewFile(String url, {String? key, Map<String, String>? authHeaders}) async {
    key ??= url;
    var cacheObject = await store.retrieveCacheData(key);
    final headers = <String, String>{};
    final etag = cacheObject?.eTag;

    if (etag != null) {
      headers[HttpHeaders.ifNoneMatchHeader] = etag;
    } else {
      return true;
    }
    final response = await HttpFileService().get(url, headers: headers);
    final hasNewFile = statusCodesNewFile.contains(response.statusCode);
    final keepOldFile = statusCodesFileNotChanged.contains(response.statusCode);
    if (!hasNewFile && keepOldFile) {
      return false;
    }
    return true;
  }
}
