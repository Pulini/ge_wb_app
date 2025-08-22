import 'package:flutter/material.dart';
import 'package:get/get.dart';

// 提示弹窗
msgDialog({
  String title = '',
  required String? content,
  Function()? back,
}) {
  Get.dialog(
    PopScope(
      //拦截返回键
      canPop: false,
      child: AlertDialog(
        title: Text(
          title.isEmpty ? '温馨提示' : title,
          style: const TextStyle(color: Colors.orange),
        ),
        content: Text(content ?? ''),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Get.back();
              back?.call();
            },
            child: Text('知道了'),
          ),
        ],
      ),
    ),
    barrierDismissible: false, //拦截dialog外部点击
  );
}

//  咨询弹窗
askDialog({
  String title = '',
  required String? content,
  Color? contentColor,
  Function()? confirm,
  String? confirmText,
  Color? confirmColor,
  Function()? cancel,
  String? cancelText,
  Color? cancelColor,
}) {
  Get.dialog(
    PopScope(
      //拦截返回键
      canPop: false,
      child: AlertDialog(
        title: Text(title.isEmpty ? '确定吗?' : title,
            style: TextStyle(color: contentColor ?? Colors.black)),
        content: Text(content ?? ''),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Get.back();
              confirm?.call();
            },
            child: Text(
              confirmText ?? '确定',
              style: TextStyle(color: confirmColor ?? Colors.black87),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              cancel?.call();
            },
            child: Text(
              cancelText ?? '取消',
              style: TextStyle(color: cancelColor ?? Colors.grey),
            ),
          ),
        ],
      ),
    ),
    barrierDismissible: false, //拦截dialog外部点击
  );
}

// 提示弹窗
successDialog({
  String title = '',
  required String? content,
  Function()? back,
}) {
  Get.dialog(
    PopScope(
      //拦截返回键
      canPop: false,
      child: AlertDialog(
        title: Text(title.isEmpty ? '成功' : title,
            style: const TextStyle(color: Colors.green)),
        content: Text(content ?? ''),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Get.back();
              back?.call();
            },
            child: Text('知道了'),
          ),
        ],
      ),
    ),
    barrierDismissible: false, //拦截dialog外部点击
  );
}

//错误弹窗
errorDialog({
  String title = '',
  required String? content,
  Function()? back,
}) {
  Get.dialog(
    PopScope(
      //拦截返回键
      canPop: false,
      child: AlertDialog(
        title: Text(title.isEmpty ? '错误' : title,
            style: const TextStyle(color: Colors.red)),
        content: Text(content ?? ''),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Get.back();
              back?.call();
            },
            child: Text('知道了'),
          ),
        ],
      ),
    ),
    barrierDismissible: false, //拦截dialog外部点击
  );
}

exitDialog({
  required String content,
  Function()? confirm,
  Function()? cancel,
}) {
  Get.dialog(AlertDialog(
    title: Text('退出'),
    content: Text(
      content,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.red,
        fontSize: 18,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          Get.back(closeOverlays: true);
          confirm?.call();
        },
        child: Text('确定'),
      ),
      TextButton(
        onPressed: () {
          Get.back();
          cancel?.call();
        },
        child: Text(
          '取消',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    ],
  ));
}
