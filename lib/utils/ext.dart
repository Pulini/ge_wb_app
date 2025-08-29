import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:decimal/decimal.dart';

extension Uint8ListExt on Uint8List {
  toHexString() {
    var hexString = '';
    for (int i = 0; i < length; i++) {
      String hex = this[i].toRadixString(16);
      if (hex.length == 1) {
        hexString += '0';
      }
      hexString += hex;
    }
    return hexString.toUpperCase();
  }

  String toBase64() => base64Encode(this);
}

//File扩展方法
extension FileExt on File {
  //图片转 base64
  String toBase64() => base64Encode(readAsBytesSync());
}

//Double扩展方法
extension DoubleExt on double? {
  //double转string并去除小数点后为0的位数，非0不去除
  String toShowString() {
    if (this == null) {
      return '0';
    } else {
      return Decimal.parse(toString()).toString();
    }
  }

  //double转string并保留最大6位小数
  String toMaxString() => toFixed(6).toShowString();

  double toFixed(int fractionDigits) {
    if (this == null) return 0;
    return double.parse(this!.toStringAsFixed(fractionDigits));
  }

  double add(double value) =>
      (Decimal.parse(toString()) + Decimal.parse(value.toString())).toDouble();

  double sub(double value) =>
      (Decimal.parse(toString()) - Decimal.parse(value.toString())).toDouble();

  double mul(double value) =>
      (Decimal.parse(toString()) * Decimal.parse(value.toString())).toDouble();

  double div(double value) {
    if (value == 0) return 0;
    return (Decimal.parse(toString()) / Decimal.parse(value.toString()))
        .toDouble();
  }
}

//String扩展方法
extension StringExt on String? {
  String md5Encode() =>
      md5.convert(const Utf8Encoder().convert(this ?? '')).toString();

  bool isNullOrEmpty() => this?.isEmpty ?? true;

  double toDoubleTry() {
    try {
      return double.parse(this ?? '');
    } on Exception catch (_) {
      return 0.0;
    }
  }

  int toIntTry() {
    try {
      return int.parse(this ?? '');
    } on Exception catch (_) {
      return 0;
    }
  }

  String ifEmpty(String v) {
    if (this != null && this?.isNotEmpty == true) {
      return this!;
    } else {
      return v;
    }
  }

  int hexToInt() {
    return int.parse(this ?? '', radix: 16);
  }
}
