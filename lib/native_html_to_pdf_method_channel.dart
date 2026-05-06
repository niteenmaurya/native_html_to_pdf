import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_html_to_pdf_platform_interface.dart';

/// An implementation of [NativeHtmlToPdfPlatform] that uses method channels.
class MethodChannelNativeHtmlToPdf extends NativeHtmlToPdfPlatform {
  
  /// The method channel used to interact with the native platform.
  /// The channel name 'html_to_pdf' matches the one used in Kotlin/Swift.
  @visibleForTesting
  final methodChannel = const MethodChannel('html_to_pdf');

  /// Retrieves the current platform version from the native side.
  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  /// Converts HTML to PDF by calling the native implementation.
  /// Accepts [args] containing the HTML string and other configurations.
  @override
  Future<String?> convertHtmlToPdf(Map<String, dynamic> args) async {
    final path = await methodChannel.invokeMethod<String>('convertHtmlToPdf', args);
    return path;
  }
}