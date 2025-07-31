import 'dart:convert';
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