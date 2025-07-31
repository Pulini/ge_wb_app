import 'package:flutter/material.dart';
import 'package:ge_wb_app/web.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

void main() {
  runApp(const MyApp());

}

// 日志工具
var logger = Logger();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GE Web App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: WebApp(),
    );
  }
}
