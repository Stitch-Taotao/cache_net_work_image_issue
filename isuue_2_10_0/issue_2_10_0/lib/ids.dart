import 'dart:math';

import 'package:flutter/cupertino.dart';

String allIds = '''

''';
final random = Random();

String initSourceFile2() {
  // "http://dummyimage.com/200x100/894FC4/FFF.png&text=!";
  const base = "http://dummyimage.com";
  int wH = random.nextInt(2048 - 100) + 100;
  String url = base + "/${wH}x$wH";
  Color geneColro() {
    final a = random.nextInt(256 - 100) + 100;
    final r = random.nextInt(256 - 100) + 100;
    final g = random.nextInt(256 - 100) + 100;
    final b = random.nextInt(256 - 100) + 100;
    final color = Color.fromARGB(a, r, g, b);
    return color;
  }

  final bgColro = geneColro();
  final textColor = geneColro();
  final bghexString = bgColro.value.toRadixString(16);
  final texthexString = textColor.value.toRadixString(16);
  url += "/$bghexString/$texthexString";
  url += "?text=A";
  return url;
}
