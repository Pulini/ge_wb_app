import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ge_wb_app/utils/consts.dart';
import 'package:ge_wb_app/utils/dialogs.dart';
import 'package:ge_wb_app/utils/ext.dart';
import 'package:ge_wb_app/utils/tsc_util.dart';
import 'package:ge_wb_app/utils/util.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

import 'main.dart';

class WebApp extends StatefulWidget {
  const WebApp({super.key});

  @override
  State<WebApp> createState() => _WebAppState();
}

class _WebAppState extends State<WebApp> {
  late WebViewXController webviewController;
  var controller = TextEditingController(text: 'code123456');

  Size get screenSize => MediaQuery.of(context).size;

  Future<void> callJsMethod({
    required String method,
    required List args,
  }) async {
    try {
      debugPrint(
          '-----------------callJsMethod method: app.$method with args: $args');
      await webviewController.callJsMethod('app.$method', args);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  _back() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('退出'),
        content: Text(
          '确定要退出吗？',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => exit(0),
            child: Text('退出'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
    scanBluetooth();
  }

  button({required String text, required Function() click}) => ElevatedButton(
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

  _faceVerify() {
    takePhoto((photo) {
      callJsMethod(
        method: 'setFace1',
        args: ['data:image/jpeg;base64,${photo.toBase64()}'],
      );
      livenFaceVerify(
        faceFilePath: photo.path,
        verifySuccess: (base64) => callJsMethod(
          method: 'setFace2',
          args: ['data:image/jpeg;base64,$base64'],
        ),
        verifyFail: (err) => errorDialog(content: '认证失败：$err'),
      );
    });
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
      callback: (result) => callJsMethod(
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
        'Mac($mac)：${type == 0 ? '连接成功' : type == 1 ? '连接失败' : type == 2 ? '未找到对应设备' : '蓝牙处于关闭状态'}'
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
    debugPrint('devicePixelRatio=${MediaQuery.of(context).devicePixelRatio}');
    callJsMethod(
      method: 'setPixelRatio',
      args: [MediaQuery.of(context).devicePixelRatio],
    );
  }

  _sendLabel(dynamic json) => sendLabel(handleJsByteArray(json));

  // _sendLabel(dynamic json) => createLabel(json).then((bytes) => sendLabel(bytes));

  @override
  void initState() {
    usbListener(
      usbAttached: () => callJsMethod(
        method: 'addLog',
        args: ['USB Attached'],
      ),
      usbDetached: () => callJsMethod(
        method: 'addLog',
        args: ['USB Detached'],
      ),
    );
    weighbridgeListener(
      weighbridgeState: (state) => callJsMethod(
        method: 'addLog',
        args: ['地磅称状态: $state'],
      ),
      weight: (w) => callJsMethod(
        method: 'addLog',
        args: ['地磅称重量: $w'],
      ),
    );
    addPDAScanListener(
      scan: (msg) => callJsMethod(
        method: 'addLog',
        args: ['已扫条码：$msg'],
      ),
    );
    addBluetoothListener(
      startScan: () => callJsMethod(
        method: 'addLog',
        args: ['开始扫描...'],
      ),
      endScan: () => callJsMethod(
        method: 'addLog',
        args: ['停止扫描'],
      ),
      connected: (mac) => callJsMethod(
        method: 'addLog',
        args: ['蓝牙已连接：Mac($mac)'],
      ),
      disconnected: (mac) => callJsMethod(
        method: 'addLog',
        args: ['蓝牙已断开：Mac($mac)'],
      ),
      stateOff: () => callJsMethod(
        method: 'addLog',
        args: ['蓝牙状态：关闭'],
      ),
      stateOn: () => callJsMethod(
        method: 'addLog',
        args: ['蓝牙状态：开启'],
      ),
      actionStateOff: () => callJsMethod(
        method: 'addLog',
        args: ['蓝牙已关闭'],
      ),
      actionStateOn: () => callJsMethod(
        method: 'addLog',
        args: ['蓝牙已开启'],
      ),
      deviceFind: (d) => callJsMethod(
        method: 'addLog',
        args: [
          '找到蓝牙设备: \n name:${d['DeviceName']} \n mac:${d['DeviceMAC']} \n isBond:${d['DeviceBondState']} \n isConnected:${d['DeviceIsConnected']} \n'
        ],
      ),
    );
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   webviewController.loadContent(
    //     webSrc,
    //     sourceType: SourceType.html,
    //     fromAssets: true,
    //   );
    // });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade100,
      body: SafeArea(
        child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              webviewController.canGoBack().then((canGoBack) {
                if (canGoBack) {
                  webviewController.goBack();
                } else {
                  _back();
                }
              });
            },
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: WebViewX(
                      key: const ValueKey('webviewx'),
                      initialContent: webUrl,
                      initialSourceType: SourceType.url,
                      height: screenSize.height,
                      width: screenSize.width,
                      onWebViewCreated: (controller) =>
                          webviewController = controller,
                      onPageStarted: (src) =>
                          debugPrint('onPageStarted: $src\n'),
                      onPageFinished: (src) {
                        debugPrint('onPageFinished: $src\n');
                        _sendDevicePixelRatio();
                      },
                      dartCallBacks: {
                        DartCallback(
                          name: 'StartLivenFaceVerify',
                          callBack: (_) => _faceVerify(),
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
                      },
                      webSpecificParams: const WebSpecificParams(
                        printDebugInfo: true,
                      ),
                      mobileSpecificParams: const MobileSpecificParams(
                        androidEnableHybridComposition: true,
                      ),
                      navigationDelegate: (navigation) {
                        debugPrint('navigation=$navigation');
                        return NavigationDecision.navigate;
                      },
                    ),
                  ),
                ),
                Container(
                  width: 400,
                  margin: const EdgeInsets.all(5),
                  height: 40,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.only(
                              top: 0,
                              bottom: 0,
                              left: 15,
                              right: 10,
                            ),
                            filled: true,
                            fillColor: Colors.grey[300],
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Colors.transparent,
                              ),
                            ),
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20)),
                            ),
                            hintStyle: const TextStyle(color: Colors.grey),
                            prefixIcon: IconButton(
                              onPressed: () => controller.clear(),
                              icon: const Icon(
                                Icons.replay_circle_filled,
                                color: Colors.red,
                              ),
                            ),
                            suffixIcon: button(
                              text: '发送条码',
                              click: () => callJsMethod(
                                method: 'addLog',
                                args: ['已扫条码：${controller.text}'],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      button(
                        text: '重新加载',
                        click: () => webviewController.reload(),
                      )
                    ],
                  ),
                ),
              ],
            )),
      ),
    );
  }

  @override
  void dispose() {
    webviewController.dispose();
    super.dispose();
  }
}
