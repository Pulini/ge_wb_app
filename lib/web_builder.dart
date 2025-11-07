import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ge_wb_app/app_init_service.dart';
import 'package:ge_wb_app/do_http/response/user_info.dart';
import 'package:ge_wb_app/do_http/web_api.dart';
import 'package:ge_wb_app/login/login_view.dart';
import 'package:ge_wb_app/utils/consts.dart';
import 'package:ge_wb_app/widgets/dialogs.dart';
import 'package:ge_wb_app/utils/util.dart';
import 'package:ge_wb_app/widgets/downloader.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class WebBuilder extends StatefulWidget {
  const WebBuilder({super.key});

  @override
  State<WebBuilder> createState() => _WebBuilderState();
}

class _WebBuilderState extends State<WebBuilder> with WidgetsBindingObserver {
  late WebViewXController webviewController;
  var finishUrl = '';

  webBuilderBack() {
    showCupertinoModalPopup(
      context: Get.overlayContext!,
      builder: (BuildContext context) =>
          CupertinoActionSheet(
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                isDefaultAction: true,
                onPressed: () {
                  spSave(spSaveUserInfo, '');
                  Get.offAll(() => const LoginPage());
                },
                child: Text('home_user_setting_logout'.tr),
              ),
              CupertinoActionSheetAction(
                isDefaultAction: true,
                onPressed: () => exit(0),
                child: Text('dialog_default_exit'.tr),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Get.back(),
              child: Text(
                'dialog_default_cancel'.tr,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
    );
  }

  Future<void> callJsMethod({
    required String method,
    required List args,
  }) async {
    try {
      loggerF({'method': method, 'args': args});
      await webviewController.callJsMethod('app.$method', args);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  button({required String text, required Function() click}) =>
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          overlayColor: Colors.white,
          padding: const EdgeInsets.only(left: 8, right: 8),
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(25)),
          ),
        ),
        onPressed: click,
        child: Text(text, style: TextStyle(color: Colors.white)),
      );

  _faceVerify(String faceImageUrl) {
    Downloader(
      url: faceImageUrl,
      completed: (path) {
        Permission.camera
            .request()
            .isGranted
            .then((permission) {
          if (permission) {
            livenFaceVerify(
              faceFilePath: path,
              verifySuccess: (base64) =>
                  callJsMethod(
                    method: 'faceVerifyComplete',
                    args: ['data:image/jpeg;base64,$base64'],
                  ),
              verifyFail: (err) => errorDialog(content: '认证失败：$err'),
            );
          } else {
            errorDialog(content: '缺少相机权限');
          }
        });
      },
    );
  }

  _requestCameraPermission() async {
    var isGranted = await requestCameraPermission();
    callJsMethod(
      method: 'permissionResult',
      args: [
        <String, bool>{Permission.camera.toString(): isGranted}
      ],
    );
  }

  _requestBluetoothPermission() {
    requestBluetoothPermission(
      callback: (result) =>
          callJsMethod(
            method: 'permissionResult',
            args: [result],
          ),
    );
  }

  _openWeightDevice() async => await weighbridgeOpen();

  _scanBluetooth() {
    scanBluetooth().then((v) => logger.f('scanBluetooth=$v'));
  }

  _endScanBluetooth() {
    endScanBluetooth().then((v) => logger.f('endScanBluetooth=$v'));
  }

  _connectBluetooth(String mac) async {
    debugPrint('----------mac=$mac');
    var type = await connectBluetooth(deviceMac: mac);
    callJsMethod(
      method: 'addLog',
      args: [
        'Mac($mac)：${type == 0 ? '连接成功' : type == 1 ? '连接失败' : type == 2
            ? '未找到对应设备'
            : '蓝牙处于关闭状态'}'
      ],
    );
  }

  _closeBluetooth(String mac) async {
    var type = await closeBluetooth(mac);
    callJsMethod(
      method: 'addLog',
      args: ['Mac($mac)：${type ? '关闭成功' : '关闭失败'}'],
    );
  }

  _getScannedDevices() async {
    var devices = await getScannedDevices();
    if (devices.isEmpty) {
      callJsMethod(
        method: 'addLog',
        args: ['已扫设备列表为空'],
      );
    } else {
      for (var d in devices) {
        callJsMethod(
          method: 'addLog',
          args: [
            '已扫描到的蓝牙设备: \n name:${d['DeviceName']} \n mac:${d['DeviceMAC']} \n isBond:${d['DeviceBondState']} \n isConnected:${d['DeviceIsConnected']} \n'
          ],
        );
      }
    }
  }

  _bluetoothIsEnable() async {
    var isEnable = await bluetoothIsEnable();
    callJsMethod(
      method: 'addLog',
      args: ['蓝牙模块：${isEnable ? '已开启' : '未开启'}'],
    );
  }

  _bluetoothIsLocationOn() async {
    var isOn = await bluetoothIsLocationOn();
    callJsMethod(
      method: 'addLog',
      args: ['位置信息：${isOn ? '已开启' : '未开启'}'],
    );
  }

  _sendDevicePixelRatio() {
    debugPrint('devicePixelRatio=${MediaQuery
        .of(context)
        .devicePixelRatio}');
    callJsMethod(
      method: 'setPixelRatio',
      args: [MediaQuery
          .of(context)
          .devicePixelRatio
      ],
    );
  }

  _sendLabel(dynamic json) {
    callJsMethod(
      method: 'setPixelRatio',
      args: [MediaQuery
          .of(context)
          .devicePixelRatio
      ],
    );
  }

  _setUserInfo(UserInfo userInfo) {
    callJsMethod(
      method: 'setUserInfo',
      args: [jsonEncode(userInfo.toJson()), language],
    );
  }

  _checkVersion() {
    upData();
    callJsMethod(
      method: 'checkVersion',
      args: [],
    );
  }

  String generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  @override
  void initState() {
    usbListener(
      usbAttached: () =>
          callJsMethod(
            method: 'addLog',
            args: ['USB Attached'],
          ),
      usbDetached: () =>
          callJsMethod(
            method: 'addLog',
            args: ['USB Detached'],
          ),
    );
    weighbridgeListener(
      weighbridgeState: (state) =>
          callJsMethod(
            method: 'addLog',
            args: ['地磅称状态: $state'],
          ),
      weight: (w) =>
          callJsMethod(
            method: 'addLog',
            args: ['地磅称重量: $w'],
          ),
    );
    addPDAScanListener(
      scan: (msg) =>
          callJsMethod(
            method: 'scan',
            args: [msg],
          ),
    );
    addBluetoothListener(
      startScan: () =>
          callJsMethod(
            method: 'addLog',
            args: ['开始扫描...'],
          ),
      endScan: () =>
          callJsMethod(
            method: 'addLog',
            args: ['停止扫描'],
          ),
      connected: (mac) =>
          callJsMethod(
            method: 'addLog',
            args: ['蓝牙已连接：Mac($mac)'],
          ),
      disconnected: (mac) =>
          callJsMethod(
            method: 'addLog',
            args: ['蓝牙已断开：Mac($mac)'],
          ),
      stateOff: () =>
          callJsMethod(
            method: 'addLog',
            args: ['蓝牙状态：关闭'],
          ),
      stateOn: () =>
          callJsMethod(
            method: 'addLog',
            args: ['蓝牙状态：开启'],
          ),
      actionStateOff: () =>
          callJsMethod(
            method: 'addLog',
            args: ['蓝牙已关闭'],
          ),
      actionStateOn: () =>
          callJsMethod(
            method: 'addLog',
            args: ['蓝牙已开启'],
          ),
      deviceFind: (d) =>
          callJsMethod(
            method: 'addLog',
            args: [
              '找到蓝牙设备: \n name:${d['DeviceName']} \n mac:${d['DeviceMAC']} \n isBond:${d['DeviceBondState']} \n isConnected:${d['DeviceIsConnected']} \n'
            ],
          ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Permission.notification.request();
      webviewController.clearCache();
      // const webSrc = 'assets/web/test.html';
      // webviewController.loadContent(webSrc,sourceType: SourceType.html,fromAssets: true,);
      webviewController.loadContent(webUrl);
      // upData();
    });
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
      // 应用恢复到前台，屏幕亮起
        debugPrint('Screen is on / App resumed');
        // _checkVersion();
        break;
      case AppLifecycleState.paused:
      // 应用暂停，可能屏幕熄灭或应用进入后台
        debugPrint('Screen might be off / App paused');
        break;
      case AppLifecycleState.inactive:
      // 应用处于非活跃状态
        debugPrint('App inactive');
        break;
      case AppLifecycleState.detached:
      // 应用即将被销毁
        debugPrint('App detached');
        break;
      case AppLifecycleState.hidden:
        debugPrint('App hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(packageInfo().appName),
        actions: [
          IconButton(
            onPressed: () => webviewController.reload(),
            icon: Icon(Icons.refresh),
          ),
          // IconButton(
          //   onPressed: () => callJsMethod(
          //     method: 'scan',
          //     args: [generateRandomString(30)],
          //   ),
          //   icon: Icon(Icons.add_circle),
          // ),
        ],
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          debugPrint('onPopInvokedWithResult--------');
          webviewController.canGoBack().then((canGoBack) {
            debugPrint('canGoBack--------');
            if (canGoBack) {
              if (finishUrl.startsWith(webUrl)){
                webBuilderBack();
              }else{
                webviewController.goBack();
              }
            }
          });
        },
        child: WebViewX(
          key: const ValueKey('webviewx'),
          initialSourceType: SourceType.url,
          // initialSourceType: SourceType.html,
          javascriptMode: JavascriptMode.unrestricted,
          height: MediaQuery
              .of(context)
              .size
              .height,
          width: MediaQuery
              .of(context)
              .size
              .width,
          onWebViewCreated: (controller) => webviewController = controller,
          onPageStarted: (url) =>
              debugPrint('---------WebView---------START: \r\n$url'),
          onPageFinished: (url) {
            finishUrl = url;
            debugPrint('---------WebView---------FINISH: \r\n$url');
          },
          onWebResourceError: (err) =>
              debugPrint(
                  '---------WebView---------ERROR: \r\n${err.description}'),
          dartCallBacks: {
            DartCallback(
              name: 'Relogin',
              callBack: (_) =>
                  reLoginPopup(
                    reLoginCallBack: (u) => _setUserInfo(u),
                  ),
            ),
            DartCallback(
              name: 'Upgrade',
              callBack: (_) => upData(),
            ),
            DartCallback(
              name: 'StartLivenFaceVerify',
              callBack: (url) => _faceVerify(url.toString()),
            ),
            DartCallback(
              name: 'RequestCameraPermission',
              callBack: (_) => _requestCameraPermission(),
            ),
            DartCallback(
              name: 'RequestBluetoothPermission',
              callBack: (_) => _requestBluetoothPermission(),
            ),
            DartCallback(
              name: 'OpenWeightDevice',
              callBack: (_) => _openWeightDevice(),
            ),
            DartCallback(
              name: 'ScanBluetooth',
              callBack: (_) => _scanBluetooth(),
            ),
            DartCallback(
              name: 'EndScanBluetooth',
              callBack: (_) => _endScanBluetooth(),
            ),
            DartCallback(
              name: 'ConnectBluetooth',
              callBack: (mac) => _connectBluetooth(mac.toString()),
            ),
            DartCallback(
              name: 'CloseBluetooth',
              callBack: (mac) => _closeBluetooth(mac.toString()),
            ),
            DartCallback(
              name: 'GetScannedDevices',
              callBack: (_) => _getScannedDevices(),
            ),
            DartCallback(
              name: 'BluetoothIsEnable',
              callBack: (_) => _bluetoothIsEnable(),
            ),
            DartCallback(
              name: 'BluetoothIsLocationOn',
              callBack: (_) => _bluetoothIsLocationOn(),
            ),
            DartCallback(
              name: 'GetDevicePixelRatio',
              callBack: (_) => _sendDevicePixelRatio(),
            ),
            DartCallback(
              name: 'SendLabelData',
              callBack: (labelDate) => _sendLabel(labelDate),
            ),
            DartCallback(
              name: 'GetUserInfo',
              callBack: (_) => _setUserInfo(userInfo()!),
            ),
          },
          webSpecificParams: const WebSpecificParams(printDebugInfo: true),
          mobileSpecificParams: const MobileSpecificParams(
            androidEnableHybridComposition: true,
          ),
          navigationDelegate: (navigation) {
            debugPrint('---------WebView---------navigation:\r\n$navigation');
            return NavigationDecision.navigate;
          },
        ),
      ),
    );
  }
}
