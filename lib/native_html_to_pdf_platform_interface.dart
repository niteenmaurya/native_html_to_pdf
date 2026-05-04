import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'native_html_to_pdf_method_channel.dart';

abstract class NativeHtmlToPdfPlatform extends PlatformInterface {
  NativeHtmlToPdfPlatform() : super(token: _token);

  static final Object _token = Object();
  static NativeHtmlToPdfPlatform _instance = MethodChannelNativeHtmlToPdf();

  static NativeHtmlToPdfPlatform get instance => _instance;

  static set instance(NativeHtmlToPdfPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  // इसे ऐड करना ज़रूरी है ताकि Web/Android इसे Override कर सकें
  Future<String?> convertHtmlToPdf(Map<String, dynamic> args) {
    throw UnimplementedError('convertHtmlToPdf() has not been implemented.');
  }
}