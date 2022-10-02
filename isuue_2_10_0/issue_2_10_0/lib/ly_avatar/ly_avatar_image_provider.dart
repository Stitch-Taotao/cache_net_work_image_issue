import 'dart:async';
// import 'dart:ui' as ui show Codec;
import 'dart:ui' as ui show Codec, ImmutableBuffer;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image/src/image_provider/_image_loader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'ly_avatar_manager.dart';
import 'ly_image_stream_completer.dart';

typedef DecoderBufferCallback = Future<ui.Codec> Function(ui.ImmutableBuffer buffer,
    {int? cacheWidth, int? cacheHeight, bool allowUpscaling});

class LYAvatarImageProvider extends CachedNetworkImageProvider {
  const LYAvatarImageProvider(
    String url, {
    int? maxHeight,
    int? maxWidth,
    double scale = 1.0,
    void Function()? errorListener,
    Map<String, String>? headers,
    TheCacheManager? cacheManager,
    String? cacheKey,
  })  : _cacheManager = cacheManager,
        super(
          url,
          maxHeight: maxHeight,
          maxWidth: maxWidth,
          scale: scale,
          errorListener: errorListener,
          headers: headers,
          cacheManager: cacheManager,
          cacheKey: cacheKey,
        );

  final TheCacheManager? _cacheManager;
  @override
  TheCacheManager? get cacheManager => _cacheManager;
  @override
  void resolveStreamForKey(ImageConfiguration configuration, ImageStream stream, CachedNetworkImageProvider key,
      ImageErrorListener handleError) {
    // This is an unusual edge case where someone has told us that they found
    // the image we want before getting to this method. We should avoid calling
    // load again, but still update the image cache with LRU information.
    if (stream.completer != null) {
      final ImageStreamCompleter? completer = PaintingBinding.instance?.imageCache?.putIfAbsent(
        key,
        () => stream.completer!,
        onError: handleError,
      );
      if (completer != null) {
        if (completer is LyImageStreamCompleter) {
          /// every time I must want try refresh myself
          completer.tryRefresh();
        }
      }
      assert(identical(completer, stream.completer));
      return;
    }
    bool isInital = false;
    final ImageStreamCompleter? completer = PaintingBinding.instance?.imageCache?.putIfAbsent(
      key,
      () {
        isInital = true;
        return load(key, PaintingBinding.instance!.instantiateImageCodec);
      },
      onError: handleError,
    );
    if (completer != null) {
      stream.setCompleter(completer);
      if (completer is LyImageStreamCompleter && !isInital) {
        /// every time I must want try refresh myself
        completer.tryRefresh();
      }
    }
  }

  @override
  LyImageStreamCompleter load(CachedNetworkImageProvider key, DecoderCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();

    /// wrap a streamController ,so I can add a new Codec
    final wrapStreamController = wrapStream(key, chunkEvents, decode);
    return LyImageStreamCompleter(
      codecController: wrapStreamController,
      retryFn: () {
        /// if (has newFile) we load again.
        loadAndhandleData(wrapStreamController, key, chunkEvents, decode);
      },
      hasNewFile: () async {
        return cacheManager!.hasNewFile(key.url, key: key.cacheKey);
      },
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      informationCollector: () sync* {
        yield DiagnosticsProperty<ImageProvider>(
          'Image provider: $this \n Image key: $key',
          this,
          style: DiagnosticsTreeStyle.errorProperty,
        );
      },
    );
  }

  StreamController<ui.Codec> wrapStream(
    CachedNetworkImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderCallback decode,
  ) {
    StreamController<ui.Codec> controller = StreamController<ui.Codec>();

    /// first init  LyImageStreamCompleter , must load data
    loadAndhandleData(controller, key, chunkEvents, decode);
    return controller;
  }

  void loadAndhandleData(
    StreamController<ui.Codec> controller,
    CachedNetworkImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderCallback decode,
  ) {
    final stream = _loadAsync(key, chunkEvents, decode);
    stream.listen((event) {
      controller.add(event);
    }, onError: (error, stackTrace) {
      print('''
      JMT - Image Raw Data Error （may be happen when file was deleted）: --- 
        key : key,
        error : $error,
        stackTrace:$stackTrace
      ''');
      throw error;
    });
  }

  Stream<ui.Codec> _loadAsync(
    CachedNetworkImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderCallback decode,
  ) {
    assert(key == this);
    return ImageLoader().loadAsync(
      url,
      cacheKey,
      chunkEvents,
      decode,
      cacheManager ?? DefaultCacheManager(),
      maxHeight,
      maxWidth,
      headers,
      errorListener,
      imageRenderMethodForWeb,
      () {
        PaintingBinding.instance?.imageCache?.evict(key);
      },
    );
  }
}
