import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../main.dart';

class Downloader {
  var url = '';
  bool isDownloading = false;
  late String fileName;
  final cancel = CancelToken();
  final Function(int count, int total) onProgress;
  final Function(String path) onCompleted;
  final Function(String msg) onError;

  Downloader({
    required this.url,
    required this.onProgress,
    required this.onCompleted,
    required this.onError,
  }) {
    fileName = url.substring(url.lastIndexOf('/') + 1);
  }

  //下載文件
  start() async {
    try {
      var fileName = url.substring(url.lastIndexOf('/') + 1);
      var temporary = await getTemporaryDirectory();
      var savePath = '${temporary.path}/$fileName';
      logger.i('url:$url \nsavePath：$savePath\nfileName：$fileName');
      isDownloading=true;
      await Dio().download(
        url,
        savePath,
        cancelToken: cancel,
        options: Options(
          receiveTimeout: const Duration(minutes: 2),
          contentType: Headers.jsonContentType,
        ),
        onReceiveProgress: (int count, int total) {
          onProgress.call(count, total);
        },
      ).then((value) {
        isDownloading = false;
        onCompleted.call(savePath);
      });
    } on DioException catch (e) {
      isDownloading = false;
      logger.e('error:$e');
      if (e.type != DioExceptionType.cancel) {
        onError.call(e.message??'');
      }
    } on Exception catch (e) {
      logger.e('error:${e.toString()}');
      isDownloading = false;
      onError.call(e.toString());
    } on Error catch (e) {
      logger.e('error:${e.toString()}');
      isDownloading = false;
      onError.call(e.toString());
    }
  }
}
