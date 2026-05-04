import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'native_html_to_pdf_platform_interface.dart';

/// An implementation of [NativeHtmlToPdfPlatform] that uses method channels.
class MethodChannelNativeHtmlToPdf extends NativeHtmlToPdfPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('html_to_pdf'); // चैनल नाम 'html_to_pdf' रखें जो आपने कोटलिन में रखा है

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> convertHtmlToPdf(Map<String, dynamic> args) async {
    // यह कोटलिन/स्विफ्ट वाले convertHtmlToPdf को कॉल करेगा
    final path = await methodChannel.invokeMethod<String>('convertHtmlToPdf', args);
    return path;
  }
}