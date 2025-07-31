import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ge_wb_app/utils/consts.dart';
import 'package:ge_wb_app/utils/util.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class WebApp extends StatefulWidget {
  const WebApp({super.key});

  @override
  State<WebApp> createState() => _WebAppState();
}

class _WebAppState extends State<WebApp> {
  late WebViewXController webviewController;

  Size get screenSize => MediaQuery.of(context).size;

  Future<void> callJsMethod(String msg) async {
    try {
      await webviewController.callJsMethod('app.getCode', [msg]);
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

  @override
  void initState() {
    addPDAScanListener(scan: (msg) => callJsMethod(msg));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  child: WebViewX(
                    key: const ValueKey('webviewx'),
                    initialContent: webUrl,
                    // initialSourceType: SourceType.html,
                    height: screenSize.height,
                    width: screenSize.width,
                    onWebViewCreated: (controller) =>
                    webviewController = controller,
                    onPageStarted: (src) => debugPrint('onPageStarted: $src\n'),
                    onPageFinished: (src) =>
                        debugPrint('onPageFinished: $src\n'),
                    dartCallBacks: {
                      DartCallback(
                        name: 'TestDartCallback',
                        callBack: (msg) {},
                      )
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
                Container(
                  color: Colors.blue,
                  child: TextButton(
                      onPressed: () => callJsMethod('123456'),
                      child: Text('scan')),
                )
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
