import 'dart:convert';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:fast_gbk/fast_gbk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ge_wb_app/utils/ext.dart';
import 'package:image/image.dart' as img;

//dpi
const _dpi = 8;

//半dpi
const _halfDpi = 4;

//设置打印参数
//[width] 纸宽
//[height] 纸高
//[speed] 打印速度  1.0 1.5 2 3 4 6 8 10
//[density] 打印浓度  0~15
//[sensor] 感应器类型  0:垂直間距感測器(gap sensor) 1:黑標感測器(black mark )
//[sensorDistance] 感应器距离
//[sensorOffset] 感应器偏移
Uint8List _tscSetup(
  int width,
  int height, {
  int speed = 4,
  int density = 6,
  int sensor = 0,
  int sensorDistance = 2,
  int sensorOffset = 0,
}) {
  String message;
  String size = 'SIZE $width mm, $height mm';
  String speedValue = 'SPEED $speed';
  String densityValue = 'DENSITY $density';
  String sensorValue = '';
  if (sensor == 0) {
    sensorValue = 'GAP $sensorDistance mm, $sensorOffset mm';
  } else if (sensor == 1) {
    sensorValue = 'BLINE $sensorDistance mm, $sensorOffset mm';
  }

  message = '$size\r\n$speedValue\r\n$densityValue\r\n$sensorValue\r\n';
  return utf8.encode(message);
}

// 清空缓冲区
Uint8List _tscClearBuffer() => utf8.encode('CLS\r\n');

// 打印指令
// [quantity] 打印次数
// [copy]  复制次数
Uint8List _tscPrint({int quantity = 1, int copy = 1}) =>
    utf8.encode('PRINT $quantity, $copy\r\n');

//下发拆切指令
Uint8List _tscCutter() => utf8.encode('SET CUTTER 1\r\n');

//关闭裁切模式
Uint8List _tscCutterOff() => utf8.encode('SET CUTTER OFF\r\n');

// 矩形
// [sx] 左上角x坐标
// [sy] 左上角y坐标
// [ex] 右下角x坐标
// [ey] 右下角y坐标
// [crude] 粗细
Uint8List _tscBox(int sx, int sy, int ex, int ey, {int? crude = 4}) =>
    utf8.encode('BOX $sx,$sy,$ex,$ey,$crude\n');

//圆形
//[x] x坐标
//[y] y坐标
//[diameter] 直径
//[thickness] 粗细
// ignore: unused_element
Uint8List _tscCircle(int x, int y, int diameter, int thickness) =>
    utf8.encode('CIRCLE $x,$y,$diameter,$thickness\r\n');

// 线
//[x] 左上角x坐标
//[y] 左上角y坐标
//[width] 线宽
//[height] 线高
Uint8List _tscLine(int x, int y, int width, int height) =>
    utf8.encode('BAR $x,$y,$width,$height\r\n');

//二维码
//[x] 左上角x坐标
//[y] 左上角y坐标
//[eccLevel] 纠错等级
//[cellWidth] 单元格宽度
//[mode] 编码模式
//[rotation] 旋转角度
//[version] 版本
//[mask] 掩码
//[content] 内容
Uint8List _tscQrCode(
  int x,
  int y,
  String content, {
  String ecc = 'H',
  String cell = '4',
  String mode = 'A',
  String rotation = '0',
  String version = 'M2',
  String mask = 'S7',
}) =>
    utf8.encode(
        'QRCODE $x,$y,$ecc,$cell,$mode,$rotation,$version,$mask,"$content"\r\n');

// 打印条形码
//[x] X坐标
//[y] Y坐标
//[content] 内容
//[sym] 条码类型，默认为"UCC128CCA"
//[rotate] 旋转角度，默认为0，范围0 - 270
//[moduleWidth] 模组宽度，默认为2，范围1 - 10
//[sepHt] 分隔符高度，默认为2，可选1或2
//[segWidth] UCC/EAN-128的高度，默认为35，单位DOT，范围1-500可选
// ignore: unused_element
Uint8List _tscBarCode(
  int x,
  int y,
  String content, {
  String sym = 'UCC128CCA',
  String rotate = '0',
  String moduleWidth = '2',
  String sepHt = '2',
  String segWidth = '35',
}) =>
    utf8.encode(
        'RSS $x,$y,"$sym",$rotate,$moduleWidth,$sepHt,$segWidth,"$content"\r\n');

//文本
//[x] 左上角x坐标
//[y] 左上角y坐标
//[font] 字体
//[rotation] 旋转角度
//[xMultiplication] x方向放大倍数
//[yMultiplication] y方向放大倍数
//[string] 文本
// ignore: unused_element
List<int> _tscText(
  int x,
  int y,
  String fontSize,
  int rotation,
  int xMultiplication,
  int yMultiplication,
  String text,
) =>
    gbk.encode(
        'TEXT $x,$y,"$fontSize",$rotation,$xMultiplication,$yMultiplication,"$text"\r\n');

//图片文本
//[xAxis] 左上角x坐标
//[yAxis] 左上角y坐标
//[fontSize] 字体大小
//[text] 文本内容
Future<Uint8List> _tscBitmapText(
  int xAxis,
  int yAxis,
  double fontSize,
  String text,
) async {
  var recorder = ui.PictureRecorder();
  var canvas = Canvas(recorder);
  var tp = TextPainter()
    ..text = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    )
    ..textDirection = TextDirection.rtl
    ..layout();

  // 绘制矩形框，在文字绘制前可通过textPainter.width和textPainter.height来获取文字绘制的尺寸
  canvas.drawRect(
    Rect.fromLTWH(0, 0, tp.width, tp.height),
    Paint()..color = Colors.white,
  );

  // 绘制文字
  tp.paint(canvas, const Offset(0, 0));

  //生成uiImage
  final uiImage = await recorder
      .endRecording()
      .toImage(tp.width.toInt(), tp.height.toInt());

  //获取图像byte数据
  var byte = await uiImage.toByteData(format: ui.ImageByteFormat.png);

  //创建图像处理器
  var image = img.decodeImage(byte!.buffer.asUint8List())!;

  //创建一个灰阶图，大小与原图相同
  var grayImage = img.Image(width: image.width, height: image.height);

  //设置灰阶阈值
  const int threshold = 127;

  // 遍历图像的每个像素
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      // 获取当前像素的RGBA值
      final pixel = image.getPixel(x, y);

      // 计算灰度值
      var gray = (pixel.r * 0.3 + pixel.g * 0.59 + pixel.b * 0.11).round();

      // 将灰阶图二值化
      var newPixel = gray > threshold
          ? img.ColorRgba8(255, 255, 255, 255) // 白色
          : img.ColorRgba8(0, 0, 0, 255); // 黑色

      // 设置二值化后的图像的像素
      grayImage.setPixel(x, y, newPixel);
    }
  }

  //二值图位宽
  var widthByte = (grayImage.width + 7) ~/ 8;

  var width = grayImage.width;
  var height = grayImage.height;

  //二值图数据
  Uint8List stream = Uint8List(widthByte * height);

  //初始化二值图数据
  int y;
  for (y = 0; y < height * widthByte; ++y) {
    stream[y] = -1;
  }
  //遍历二值图，转换成tsc打印机可识别的数据
  for (y = 0; y < height; ++y) {
    for (int x = 0; x < width; ++x) {
      var pixelColor = grayImage.getPixel(x, y);
      var red = pixelColor.r;
      var green = pixelColor.g;
      var blue = pixelColor.b;
      var total = (red + green + blue) / 3;
      // 像素为黑色时，将二值图数据置为1
      if (total == 0) {
        //找到二值图数据在stream中的索引
        int byteIndex = y * ((width + 7) ~/ 8) + x ~/ 8;
        // 找到二值图数据在stream中的位掩码
        int targetBitMask = (128 >> (x % 8)).toInt();
        // 将二值图数据置为1
        stream[byteIndex] ^= targetBitMask;
      }
    }
  }

  return Uint8List.fromList(List.from(
    utf8.encode('BITMAP $xAxis,$yAxis,${(tp.width + 7) ~/ 8},${tp.height},0,'),
  )
    ..addAll(stream)
    ..addAll(utf8.encode('\r\n')));
}

Future<Uint8List> _tscBitmap(
  int xAxis,
  int yAxis,
  Uint8List bitmapData,
) async {
  //创建图像处理器
  var image = img.decodeImage(bitmapData)!;

  //创建一个灰阶图，大小与原图相同
  var grayImage = img.Image(width: image.width, height: image.height);

  //设置灰阶阈值
  const int threshold = 127;

  // 遍历图像的每个像素
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      // 获取当前像素的RGBA值
      final pixel = image.getPixel(x, y);

      // 计算灰度值
      var gray = (pixel.r * 0.3 + pixel.g * 0.59 + pixel.b * 0.11).round();

      // 将灰阶图二值化
      var newPixel = gray > threshold
          ? img.ColorRgba8(255, 255, 255, 255) // 白色
          : img.ColorRgba8(0, 0, 0, 255); // 黑色

      // 设置二值化后的图像的像素
      grayImage.setPixel(x, y, newPixel);
    }
  }

  //二值图位宽
  var widthByte = (grayImage.width + 7) ~/ 8;

  var width = grayImage.width;
  var height = grayImage.height;

  //二值图数据
  Uint8List stream = Uint8List(widthByte * height);

  //初始化二值图数据
  int y;
  for (y = 0; y < height * widthByte; ++y) {
    stream[y] = -1;
  }
  //遍历二值图，转换成tsc打印机可识别的数据
  for (y = 0; y < height; ++y) {
    for (int x = 0; x < width; ++x) {
      var pixelColor = grayImage.getPixel(x, y);
      var red = pixelColor.r;
      var green = pixelColor.g;
      var blue = pixelColor.b;
      var total = (red + green + blue) / 3;
      // 像素为黑色时，将二值图数据置为1
      if (total == 0) {
        //找到二值图数据在stream中的索引
        int byteIndex = y * ((width + 7) ~/ 8) + x ~/ 8;
        // 找到二值图数据在stream中的位掩码
        int targetBitMask = (128 >> (x % 8)).toInt();
        // 将二值图数据置为1
        stream[byteIndex] ^= targetBitMask;
      }
    }
  }
  return Uint8List.fromList(List.from(
    utf8.encode(
        'BITMAP $xAxis,$yAxis,${(image.width + 7) ~/ 8},${image.height},0,'),
  )
    ..addAll(stream)
    ..addAll(utf8.encode('\r\n')));
}

Uint8List getImageBytes(dynamic data) {
  var dataMap = (data as Map).values.map((v) => (v as int)).toList();
  //创建图像处理器
  var image = img.decodeImage(Uint8List.fromList(dataMap))!;

  //创建一个灰阶图，大小与原图相同
  var grayImage = img.Image(width: image.width, height: image.height);

  //设置灰阶阈值
  const int threshold = 127;

  // 遍历图像的每个像素
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      // 获取当前像素的RGBA值
      final pixel = image.getPixel(x, y);

      // 计算灰度值
      var gray = (pixel.r * 0.3 + pixel.g * 0.59 + pixel.b * 0.11).round();

      // 将灰阶图二值化
      var newPixel = gray > threshold
          ? img.ColorRgba8(255, 255, 255, 255) // 白色
          : img.ColorRgba8(0, 0, 0, 255); // 黑色

      // 设置二值化后的图像的像素
      grayImage.setPixel(x, y, newPixel);
    }
  }

  //二值图位宽
  var widthByte = (grayImage.width + 7) ~/ 8;

  var width = grayImage.width;
  var height = grayImage.height;

  //二值图数据
  Uint8List stream = Uint8List(widthByte * height);

  //初始化二值图数据
  int y;
  for (y = 0; y < height * widthByte; ++y) {
    stream[y] = -1;
  }
  //遍历二值图，转换成tsc打印机可识别的数据
  for (y = 0; y < height; ++y) {
    for (int x = 0; x < width; ++x) {
      var pixelColor = grayImage.getPixel(x, y);
      var red = pixelColor.r;
      var green = pixelColor.g;
      var blue = pixelColor.b;
      var total = (red + green + blue) / 3;
      // 像素为黑色时，将二值图数据置为1
      if (total == 0) {
        //找到二值图数据在stream中的索引
        int byteIndex = y * ((width + 7) ~/ 8) + x ~/ 8;
        // 找到二值图数据在stream中的位掩码
        int targetBitMask = (128 >> (x % 8)).toInt();
        // 将二值图数据置为1
        stream[byteIndex] ^= targetBitMask;
      }
    }
  }
  debugPrint(
      'image.width=${image.width}  width=${(image.width + 7) ~/ 8} image.height=${image.height} height=${(image.height + 7) ~/ 8}');
  return Uint8List.fromList(List.from(
    utf8.encode('BITMAP 1,1,${(image.width + 7) ~/ 8},${image.height},0,'),
  )
    ..addAll(stream)
    ..addAll(utf8.encode('\r\n')));
}

//创建一个文本列表，将传入的文本根据字体大小和限宽进行拆分换行
//[text] 文本内容
//[fontSize] 字体大小
//[maxWidthPx] 最大宽度
List<String> contextFormat(String text, double fontSize, double maxWidthPx) {
  final List<String> lines = <String>[];
  String currentLine = '';
  final TextPainter textPainter = TextPainter(
    textDirection: ui.TextDirection.ltr,
  );

  for (var char in text.characters) {
    textPainter.text = TextSpan(
      text: currentLine + char,
      style: TextStyle(fontSize: fontSize),
    );

    textPainter.layout();
    if (textPainter.width <= maxWidthPx) {
      currentLine += char;
    } else {
      lines.add(currentLine);
      currentLine = char;
    }
  }

  lines.add(currentLine);
  return lines;
}

//表格格式化
//[title] 表格标题
//[bottom] 表格底部
//[tableData] 表格数据
List<List<String>> tableFormat(
  String title,
  String bottom,
  Map<String, List<List<String>>> tableData,
) {
  var list = <List<String>>[];
  if (tableData.isEmpty) return [];
  //取出所有尺码
  var titleList = <String>[];
  var columnsTitleList = <String>[];
  tableData.forEach((k, v) {
    for (var v2 in v) {
      if (!titleList.contains(v2[0])) {
        titleList.add(v2[0]);
      }
    }
  });
  titleList = titleList.sorted();

  //指令缺的尺码做补位处理
  tableData.forEach((k, v) {
    var text = <List<String>>[];
    for (var indexText in titleList) {
      text.add(v.firstWhere((e) => e[0] == indexText,
          orElse: () => [indexText, '']));
    }
    v.clear();
    v.addAll(text);
  });

  //添加表格头行
  var printList = <List<String>>[];

  //保存表格列第一格
  columnsTitleList.add(title);
  //保存表格第一行
  printList.add(titleList);

  //添加表格体
  tableData.forEach((k, v) {
    //保存表格列第一格
    columnsTitleList.add(k);
    //保存表格本体所有行
    printList.add([for (var v2 in v) v2[1]]);
  });

  //保存表格列第一格
  columnsTitleList.add(bottom);
  var print = <String>[];
  //保存表格最后一行
  for (var i = 0; i < titleList.length; ++i) {
    var sum = 0.0;
    tableData.forEach((k, v) {
      if (i < titleList.length) {
        sum = sum.add(v[i][1].toDoubleTry());
      }
    });
    print.add(sum.toShowString());
  }
  printList.add(print);

  var max = 6;
  var maxColumns =
      (titleList.length / max) + (titleList.length % max) > 0 ? 1 : 0;
  for (var i = 0; i < maxColumns; ++i) {
    //添加表格
    printList.forEachIndexed((index, data) {
      var s = i * max;
      var t = i * max + max;
      var subData = <String>[];
      //添加行表头
      subData.add(columnsTitleList[index]);
      //添加行
      subData.addAll(data.sublist(
          s, (s < data.length && t <= data.length) ? t : data.length));

      list.add(subData);
    });

    if (i < maxColumns - 1) {
      //加入空行用于区分表格换行
      list.add([]);
    }
  }

  return list;
}

//------------------------------------以上为tsc指令集--------------------------------------

Future<Uint8List> labelImageResize(Uint8List image) async {
  var reImage = img.copyResize(
    img.decodeImage(image)!,
    width: 75 * 8,
    height: 45 * 8,
  );
  return Uint8List.fromList(img.encodePng(reImage));
}

Future<List<Uint8List>> imageResizeToLabel(Map<String, dynamic> image) async =>
    await compute(_imageResizeToLabel, image);

Future<List<Uint8List>> _imageResizeToLabel(Map<String, dynamic> image) async {
  double pixelRatio = image['pixelRatio'] ?? 1;
  int speed = image['speed'] ?? 4;
  int density = image['density'] ?? 15;
  bool isDynamic = image['isDynamic'] ?? false;
  int width = ((image['width'] as int) / 5.5 / pixelRatio).toInt();
  int height = ((image['height'] as int) / 5.5 / pixelRatio).toInt();
  var reImage = img.copyResize(
    img.decodeImage(image['image'])!,
    width: width * 8,
    height: height * 8,
    backgroundColor: img.ColorRgb8(0, 0, 0),
  );
  var imageUint8List = Uint8List.fromList(img.encodePng(reImage));
  debugPrint('imageUint8List: ${imageUint8List.lengthInBytes / (1024 * 1024)}');
  return [
    _tscClearBuffer(),
    _tscSetup(
      width,
      height,
      density: density,
      speed: speed,
      sensorDistance: isDynamic ? 0 : 2,
    ),
    await _tscBitmap(1, 1, imageUint8List),
    _tscCutter(),
    _tscPrint(),
  ];
}

List<Uint8List> handleJsByteArray(dynamic jsData) {
  List<Uint8List> list = [];
  if (jsData is String) {
    final parsed = jsonDecode(jsData);
    if (parsed is List) {
      for (var i = 0; i < parsed.length; ++i) {
        var item = parsed[i];
        if (item is String) {
          Uint8List code;
          if (item == 'BITMAP') {
            i++;
            code = getImageBytes(parsed[i]);
          } else {
            code = utf8.encode('$item\r\n');
          }
          list.add(code);
        }
      }
      debugPrint('---------List=${list.length}');
    }
  }
  return list;
}
