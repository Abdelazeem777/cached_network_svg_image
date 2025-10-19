library cached_network_svg_image;

import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Since File from dart:io can't be used in web, we need to use XFile from
/// cross_file package to support both, mobile and web.
class SvgXFileLoader extends SvgLoader<Uint8List> {
  const SvgXFileLoader(
    this.file, {
    super.theme,
    super.colorMapper,
  });

  final XFile file;

  @override
  Future<Uint8List> prepareMessage(BuildContext? context) async =>
      (await file.readAsBytes()).buffer.asUint8List();

  @override
  String provideSvg(Uint8List? message) =>
      utf8.decode(message!, allowMalformed: true);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SvgXFileLoader &&
          runtimeType == other.runtimeType &&
          file == other.file;

  @override
  int get hashCode => file.hashCode;

  @override
  String toString() => 'SvgXFileLoader{file: $file}';
}
