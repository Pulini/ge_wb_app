import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ge_wb_app/app_init_service.dart';
import 'package:ge_wb_app/translation.dart';
import 'package:get/get.dart';

import 'do_http/web_api.dart';

main()  {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    Get.put(AppInitService(), permanent: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      scrollBehavior: ScrollConfiguration.of(context).copyWith(
        //适配鼠标滚动
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      onGenerateTitle: (context) => 'app_name'.tr,
      debugShowCheckedModeBanner: false,
      translations: Translation(),
      navigatorObservers: [GetObserver()],
      locale: View.of(context).platformDispatcher.locale,
      localeListResolutionCallback: (locales, supportedLocales) {
        language = locales?.first.languageCode == localeChinese.languageCode
            ? 'zh'
            : 'en';
        return null;
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(scrolledUnderElevation: 0.0),
      ),
      home: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isTestUrl()
                ? [Colors.lightBlueAccent, Colors.greenAccent]
                : [Colors.lightBlueAccent, Colors.blueAccent],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
      ),
    );
  }
}
