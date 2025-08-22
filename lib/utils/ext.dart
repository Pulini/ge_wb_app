import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
