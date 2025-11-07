import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:ge_wb_app/app_init_service.dart';
import 'package:ge_wb_app/do_http/dio_manager.dart';
import 'package:ge_wb_app/do_http/response/base_data.dart';
import 'package:ge_wb_app/widgets/dialogs.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

//接口返回异常
const resultError = 0;

//接口返回成功
const resultSuccess = 1;

//重新登录
const resultReLogin = 2;

//版本升级
const resultToUpdate = 3;

//MES正式库
const baseUrlForMES = 'https://geapp.goldemperor.com:1226/';

//MES测试库
// const testUrlForMES = 'https://geapptest.goldemperor.com:1224/';
const testUrlForMES = 'https://apptest.goldemperor.com:1207/';
// const testUrlForMES = 'https://apptest.goldemperor.com:1208/';

//SAP正式库
const baseUrlForSAP = 'https://erpprd01.goldemperor.com:8003/';

// //SAP测试库
// const testUrlForSAP = 'https://erpqas01.goldemperor.com:8002/';

//SAP开发库
const developUrlForSAP = 'https://erpdev01.goldemperor.com:8001/';
// const developUrlForSAP = 'https://s4devapp01.goldemperor.com:8005/';

const sfUser = 'PI_USER';
const sfPassword = 'PI@Passw0rd';

//SAP正式库
const baseClientForSAP = 800;

//SAP开发库
const developClientForSAP = 300;

// 日志工具
var logger = Logger();

//当前语言
var language = 'zh';

//初始化网络请求
Future<BaseData> _doHttp({
  required bool isPost,
  required String method,
  required String baseUrl,
  String? loading,
  Map<String, dynamic>? params,
  Object? body,
}) async {
  if (isTestUrl()) {
    if (baseUrl == baseUrlForMES) {
      baseUrl = testUrlForMES;
    } else if (baseUrl == baseUrlForSAP) {
      baseUrl = developUrlForSAP;
    }
  }
  if (baseUrl == baseUrlForSAP || baseUrl == developUrlForSAP) {
    params = {
      'sap-client':
          baseUrl == baseUrlForSAP ? baseClientForSAP : developClientForSAP,
      ...?params,
    };
  }


  if (loading != null && loading.isNotEmpty) {
    loadingShow(loading);
  }


  //设置请求的headers
  var options = Options(headers: {
    'Content-Type': 'application/json',
    'FunctionID':'0',
    'Version': 0,
    'Language': language,
    'Token': userInfo()?.token ?? '',
    'GUID': 'appLogin',
    'Authorization': 'Basic ${base64Encode(utf8.encode("$sfUser:$sfPassword"))}',

  });

  //创建返回数据载体
  var base = BaseData()..resultCode = resultError;

  try {
    //获取单例Dio对象
    var dio = DioManager().getDio(baseUrl);

    //发起post/get请求
    var response = isPost
        ? await dio.post(
            method,
            queryParameters: params,
            data: body,
            options: options,
          )
        : await dio.get(
            method,
            queryParameters: params,
            data: body,
            options: options,
          );
    if (response.statusCode == 200) {
      var json = response.data.runtimeType == String
          ? jsonDecode(response.data)
          : response.data;
      base.resultCode = json['ResultCode'];
      base.data = json['Data'];
      base.message = '接口提示：${json['Message']}';
    } else {
      if (loading != null && loading.isNotEmpty) Get.back();
      logger.e('网络异常');
      base.message = '网络异常';
    }
  } on DioException catch (e) {
    logger.e('error:${e.toString()}');
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        base.message = '连接服务器超时';
        break;
      case DioExceptionType.sendTimeout:
        base.message = '发送数据超时';
        break;
      case DioExceptionType.receiveTimeout:
        base.message = '接收数据超时';
        break;
      case DioExceptionType.badResponse:
        base.message = '请求配置错误';
        break;
      case DioExceptionType.cancel:
        base.message = '取消请求';
        break;
      case DioExceptionType.connectionError:
        base.message = '连接服务器异常';
        break;
      case DioExceptionType.badCertificate:
        base.message = '服务器证书错误';
        break;
      case DioExceptionType.unknown:
        base.message = '未知异常';
        break;
    }
  } on Exception catch (e) {
    logger.e('error:${e.toString()}');
    base.message = '发生错误：${e.toString()}';
  } on Error catch (e) {
    logger.e('error:${e.toString()}');
    base.message = '发生异常：${e.toString()}';
  } finally {
    if (loading != null && loading.isNotEmpty) loadingDismiss();
    base.baseUrl = baseUrl;
  }
  return base;
}

//post请求
Future<BaseData> httpPost({
  String? loading,
  required String method,
  Map<String, dynamic>? params,
  Object? body,
}) {
  return _doHttp(
    loading: loading,
    params: params,
    body: body,
    baseUrl: baseUrlForMES,
    isPost: true,
    method: method,
  );
}

//get请求
Future<BaseData> httpGet({
  String? loading,
  required String method,
  Map<String, dynamic>? params,
  Object? body,
}) {
  return _doHttp(
    loading: loading,
    params: params,
    body: body,
    baseUrl: baseUrlForMES,
    isPost: false,
    method: method,
  );
}

//检查版本更新接口
const webApiCheckVersion = 'api/Public/FlutterVersionUpgrade';

//登录接口
const webApiLogin = 'api/User/Login';

//获取用户头像
const webApiGetUserPhoto = 'api/User/GetEmpPhotoByPhone';

//获取验证码接口
const webApiVerificationCode = 'api/User/SendVerificationCode';