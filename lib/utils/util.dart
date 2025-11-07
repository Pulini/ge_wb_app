import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ge_wb_app/app_init_service.dart';
import 'package:ge_wb_app/do_http/response/user_info.dart';
import 'package:ge_wb_app/do_http/response/version_info.dart';
import 'package:ge_wb_app/do_http/web_api.dart';
import 'package:ge_wb_app/utils/ext.dart';
import 'package:ge_wb_app/widgets/dialogs.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'consts.dart';

/// 获取相机权限
/// rue:授权成功
/// false:授权失败
Future<bool> requestCameraPermission() async =>
    await Permission.camera.request().isGranted;

/// 获取蓝牙相关权限
/// allGranted:相关选贤授权成功
/// hasDenied:相关权限授权失败  return 授权失败的相关权限名称
/// 位置信息权限  location
/// 蓝牙连接权限  bluetoothConnect
/// 蓝牙扫描权限  bluetoothScan
/// 蓝牙权限  bluetooth
/// 蓝牙广播权限  bluetoothAdvertise
requestBluetoothPermission({
  required Function(Map<String, bool> result) callback,
}) {
  [
    Permission.location,
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
    Permission.bluetooth,
    Permission.bluetoothAdvertise,
  ].request().then((result) {
    logger.f(result);
    var map = <String, bool>{};
    result.forEach((k, v) {
      map[k.toString()] = v.isGranted;
    });
    callback.call(map);
  });
}

/// 活体人脸检测
/// faceFilePath:人脸图片路径
/// verifySuccess:活体检测成功 return 检测成功时拍下的照片base64数据
/// verifyFail:活体检测失败 return 错误信息
livenFaceVerify({
  required String faceFilePath,
  required Function(String) verifySuccess,
  required Function(String) verifyFail,
}) {
  const MethodChannel(channelFaceVerifyF2A)
      .invokeMethod('StartDetect', faceFilePath)
      .then((v) {
    logger.f('livenFaceVerify：success');
    verifySuccess.call((v as Uint8List).toBase64());
  }).catchError((e) {
    logger.f('livenFaceVerify：fail');
    verifyFail.call(e.toString());
  });
}

/// PDA扫码
/// scan:扫码结果 return 枪扫码探头返回的数据
addPDAScanListener({required Function(String code) scan}) {
  const MethodChannel(channelScanF2A).setMethodCallHandler((call) {
    logger.f('pdaScanner：${call.method}  arguments:${call.arguments}');
    if (call.method == 'PdaScanner') {
      scan.call(call.arguments);
    }
    return Future.value(call);
  });
}

MethodChannel _bluetoothChannel = MethodChannel(channelBluetoothF2A);

///蓝牙广播监听
/// startScan:开始扫描
/// endScan:结束扫描
/// connected:连接成功 return 连接成功的设备MAC
/// disconnected:连接断开 return 断开的设备MAC
/// stateOff:蓝牙处于关闭状态
/// stateOn:蓝牙处于开启状态
/// actionStateOff:蓝牙切换为关闭状态
/// actionStateOn:蓝牙切换为开启状态
/// deviceFind:发现蓝牙设备 return 发现的设备信息Map
/// Map={
/// "DeviceName":(String)设备名称，
/// "DeviceMAC":(String)设备Mac地址
/// "DeviceBondState":(bool)设备是否对接过
/// "DeviceIsConnected":(bool)当前状态是否已连接
/// }
addBluetoothListener({
  required Function() startScan,
  required Function() endScan,
  required Function(String mac) connected,
  required Function(String mac) disconnected,
  required Function() stateOff,
  required Function() stateOn,
  required Function() actionStateOff,
  required Function() actionStateOn,
  required Function(Map device) deviceFind,
}) {
  _bluetoothChannel.setMethodCallHandler((call) {
    logger.f('bluetooth：${call.method}  arguments:${call.arguments}');
    switch (call.method) {
      case 'BluetoothState':
        {
          switch (call.arguments) {
            case 'StartScan':
              {
                startScan.call();
                break;
              }
            case 'EndScan':
              {
                endScan.call();
                break;
              }
            case 'Connected':
              {
                connected.call(call.arguments['MAC']);
                break;
              }
            case 'Disconnected':
              {
                disconnected.call(call.arguments['MAC']);
                break;
              }
            case 'Off':
              {
                stateOff.call();
                break;
              }
            case 'On':
              {
                stateOn.call();
                break;
              }
            case 'Open':
              {
                actionStateOff.call();
                break;
              }
            case 'Close':
              {
                actionStateOn.call();
                break;
              }
          }
        }
      case 'BluetoothFind':
        {
          deviceFind.call({
            'DeviceName': call.arguments['DeviceName'],
            'DeviceMAC': call.arguments['DeviceMAC'],
            'DeviceBondState': call.arguments['DeviceBondState'],
            'DeviceIsConnected': call.arguments['DeviceIsConnected'],
          });
          break;
        }
    }
    return Future.value(call);
  });
}

///开启蓝牙扫描
///true:成功
///false:失败
Future<bool> scanBluetooth() async =>
    await _bluetoothChannel.invokeMethod('ScanBluetooth');

///结束蓝牙扫描
///true:成功
///false:失败
Future<bool> endScanBluetooth() async =>
    await _bluetoothChannel.invokeMethod('EndScanBluetooth');

///连接蓝牙
///deviceMac：设备MAC
/// 0:连接成功
/// 1:连接失败
/// 2:未找到对应设备
/// 3:蓝牙处于关闭状态
Future<int> connectBluetooth({required String deviceMac}) async =>
    await _bluetoothChannel.invokeMethod('ConnectBluetooth', deviceMac);

///关闭蓝牙
///deviceMac:设备MAC地址
///true:成功
///false:失败
Future<bool> closeBluetooth(String deviceMac) async =>
    await _bluetoothChannel.invokeMethod('CloseBluetooth', deviceMac);

///获取已扫描到的蓝牙设备
///返回设备列表Map
///Map={
/// "DeviceName":(String)设备名称，
/// "DeviceMAC":(String)设备Mac地址
/// "DeviceBondState":(bool)设备是否对接过
/// "DeviceIsConnected":(bool)当前状态是否已连接
/// }
Future<List<Map>> getScannedDevices() async => [
      for (var json
          in await _bluetoothChannel.invokeMethod('GetScannedDevices'))
        {
          'DeviceName': json['DeviceName'],
          'DeviceMAC': json['DeviceMAC'],
          'DeviceBondState': json['DeviceBondState'],
          'DeviceIsConnected': json['DeviceIsConnected'],
        }
    ];

///检查蓝牙是否启用
/// true:已启用
/// false:未启用
Future<bool> bluetoothIsEnable() async =>
    await _bluetoothChannel.invokeMethod('IsEnable');

///检查蓝牙定位是否打开
/// true:已打开
/// false:未打开
Future<bool> bluetoothIsLocationOn() async =>
    await _bluetoothChannel.invokeMethod('IsLocationOn');

///发送标签
///label:标签数据 byte数组
///1000:成功
///1003:失败
///1007:通道断开
Future<int> sendLabel(List<Uint8List> label) async =>
    await _bluetoothChannel.invokeMethod('SendTSC', label);

///地磅秤设备监听
/// weighbridgeState:设备状态
///   WEIGHT_MSG_DEVICE_DETACHED,
///   WEIGHT_MSG_DEVICE_NOT_CONNECTED,
///   WEIGHT_MSG_OPEN_DEVICE_SUCCESS,
///   WEIGHT_MSG_OPEN_DEVICE_FAILED,
///   WEIGHT_MSG_READ_ERROR,
/// weight:称重结果
weighbridgeListener({
  required Function(String) weighbridgeState,
  required Function(double) weight,
}) {
  const MethodChannel(channelWeighbridgeF2A).setMethodCallHandler((call) {
    logger.f('weighbridge：${call.method}  arguments:${call.arguments}');
    switch (call.method) {
      case 'WeighbridgeState':
        {
          weighbridgeState.call(call.arguments);
        }
        break;
      case 'WeighbridgeRead':
        {
          weight.call(call.arguments);
        }
        break;
    }
    return Future.value(call);
  });
}

///打开地磅秤设备
weighbridgeOpen() async {
  await const MethodChannel(channelWeighbridgeA2F).invokeMethod('OpenDevice');
}

///usb插拔监听
///usbAttached:USB插入
///usbDetached:USB拔出
usbListener({
  required Function() usbAttached,
  required Function() usbDetached,
}) {
  const MethodChannel(channelUsbF2A).setMethodCallHandler((call) {
    logger.f('usb：${call.method}  arguments:${call.arguments}');
    switch (call.method) {
      case 'UsbState':
        {
          if (call.arguments == 'Attached') {
            debugPrint('USB设备插入');
            usbAttached.call();
          }
          if (call.arguments == 'Detached') {
            debugPrint('USB设备拔出');
            usbAttached.call();
          }
        }
        break;
    }
    return Future.value(call);
  });
}

///打开文件
///filePath:文件路径
openFile(String filePath) {
  const MethodChannel(channelUsbA2F).invokeMethod('OpenFile', filePath);
}

//照片选择器
takePhoto(Function(File) callback) {
  showCupertinoModalPopup(
    context: Get.overlayContext!,
    builder: (BuildContext context) => CupertinoActionSheet(
      title: Text('选择照片'),
      message: Text('选择要进行人脸对比的照片'),
      actions: <CupertinoActionSheetAction>[
        CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
            ImagePicker()
                .pickImage(
                  imageQuality: 75,
                  maxWidth: 700,
                  maxHeight: 700,
                  source: ImageSource.camera,
                )
                .then((photo) => callback.call(File(photo!.path)));
          },
          child: Text('拍照'),
        ),
        CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
            ImagePicker()
                .pickImage(
                    imageQuality: 75,
                    maxWidth: 700,
                    maxHeight: 700,
                    source: ImageSource.gallery)
                .then((v) => v == null ? null : callback.call(File(v.path)));
          },
          child: Text('相册'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(context),
        child: Text(
          '取消',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    ),
  );
}

//显示SnackBar
showSnackBar({
  bool? isWarning,
  String? title,
  required String message,
}) {
  isWarning ??= false;
  title ??= isWarning
      ? 'snack_bar_default_wrong'.tr
      : 'dialog_default_title_information'.tr;
  Get.snackbar(
    title,
    message,
    margin: const EdgeInsets.all(10),
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: isWarning == true
        ? Colors.redAccent.shade100
        : Colors.greenAccent.shade100,
    colorText: isWarning == true ? Colors.white : Colors.blue.shade900,
  );
}

//隐藏键盘而不丢失文本字段焦点：
hideKeyBoard() {
  SystemChannels.textInput.invokeMethod('TextInput.hide');
}

loggerF(Map<String, dynamic> map) {
  if (map.toString().length > 500) {
    map['日志类型'] = '异步打印日志';
    compute(_logF, map);
  } else {
    map['日志类型'] = '直接打印日志';
    logger.f(map);
  }
}

_logF(Map<String, dynamic> data) {
  logger.f(data);
}

// 保存SP数据
spSave(String key, Object value) {
  if (value is String) {
    sharedPreferences().setString(key, value);
    logger.d('save\nclass:${value.runtimeType}\nkey:$key\nvalue:$value');
  } else if (value is int) {
    sharedPreferences().setInt(key, value);
    logger.d('save\nclass:${value.runtimeType}\nkey:$key\nvalue:$value');
  } else if (value is double) {
    sharedPreferences().setDouble(key, value);
    logger.d('save\nclass:${value.runtimeType}\nkey:$key\nvalue:$value');
  } else if (value is bool) {
    sharedPreferences().setBool(key, value);
    logger.d('save\nclass:${value.runtimeType}\nkey:$key\nvalue:$value');
  } else if (value is List<String>) {
    sharedPreferences().setStringList(key, value);
    logger.d('save\nclass:${value.runtimeType}\nkey:$key\nvalue:$value');
  } else {
    logger.e('error\nclass:${value.runtimeType}');
  }
}

// 获取SP数据
dynamic spGet(String key) {
  try {
    var value = sharedPreferences().get(key);
    logger.d('read\nclass:${value.runtimeType}\nkey:$key\nvalue:$value');
    switch (value.runtimeType) {
      case const (String):
        return value ?? '';
      case const (int):
        return value ?? 0;
      case const (double):
        return value ?? 0.0;
      case const (bool):
        return value ?? false;
      case const (List<Object?>):
        return sharedPreferences().getStringList(key) ?? [];
      default:
        return value;
    }
  } catch (e) {
    debugPrint('$key--------read sp error-------');
    return null;
  }
}

UserInfo? getUserInfo() {
  try {
    var spUserInfo = sharedPreferences().get(spSaveUserInfo) as String?;
    debugPrint('spUserInfo=$spUserInfo');
    if (spUserInfo != null) {
      return UserInfo.fromJson(jsonDecode(spUserInfo));
    }
  } on Error catch (e) {
    logger.e(e.runtimeType);
  } on Exception catch (e) {
    logger.e(e.runtimeType);
  }
  return null;
}

//更新app
upData() {
  httpGet(
    method: webApiCheckVersion,
    loading: '正在检查版本更新...',
  ).then((versionInfoCallback) {
    if (versionInfoCallback.resultCode == resultSuccess) {
      logger.i(packageInfo);
      var versionInfo = VersionInfo.fromJson(versionInfoCallback.data);
      if (packageInfo().version.replaceAll('.', '').toIntTry() <
          versionInfo.versionName!.replaceAll('.', '').toIntTry()) {
        doUpdate(version: versionInfo);
      } else {
        showSnackBar(
          title: '版本更新',
          message: '当前已是最新版本',
        );
      }
    } else {
      errorDialog(content: versionInfoCallback.message);
    }
  });
}

Future<Database> openDb() async {
  return openDatabase(join(await getDatabasesPath(), jdDatabase));
}

/// 获取屏幕逻辑尺寸（考虑了设备像素比）
Size getScreenSize() {
  final view = WidgetsBinding.instance.platformDispatcher.implicitView;
  if (view != null) {
    final physicalSize = view.physicalSize;
    final devicePixelRatio = view.devicePixelRatio;
    return physicalSize / devicePixelRatio;
  } else {
    final physicalSize = View.of(Get.context!).physicalSize;
    final devicePixelRatio = View.of(Get.context!).devicePixelRatio;
    return physicalSize / devicePixelRatio;
  }
}
