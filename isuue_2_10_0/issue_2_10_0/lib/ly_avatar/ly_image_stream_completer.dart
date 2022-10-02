import 'dart:async';
import 'dart:ui' as ui show Codec,FrameInfo;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LyImageStreamCompleter extends MultiImageStreamCompleter {
  LyImageStreamCompleter({
    required this.codecController,
    required this.retryFn,
    required this.hasNewFile,
    required double scale,
    Stream<ImageChunkEvent>? chunkEvents,
    InformationCollector? informationCollector,
  }) : super(
          codec: codecController.stream,
          scale: scale,
          chunkEvents: chunkEvents,
          informationCollector: informationCollector,
        );
  StreamController<ui.Codec> codecController;

  void Function() retryFn;
  Future<bool> Function() hasNewFile;
  int hasNewSchedule = 0;
  bool isScheduleCheck = false;
  tryRefresh() async {
    try {
      if (isScheduleCheck) return;
      isScheduleCheck = true;
      await doTry();
    } finally {
      isScheduleCheck = false;
    }
    return;
  }

  doTry() async {
    final hasNew = await hasNewFile();
    if (hasNew) {
      // print('JMT retry');
      retryFn();
    }
  }
}


