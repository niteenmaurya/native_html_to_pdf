import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'native_html_to_pdf_method_channel.dart';

/// The interface that implementations of native_html_to_pdf must implement.
abstract class NativeHtmlToPdfPlatform extends PlatformInterface {
  /// Constructs a NativeHtmlToPdfPlatform.
  NativeHtmlToPdfPlatform() : super(token: _token);

  static final Object _token = Object();
  static NativeHtmlToPdfPlatform _instance = MethodChannelNativeHtmlToPdf();

  /// The default instance of [NativeHtmlToPdfPlatform] to use.
  static NativeHtmlToPdfPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeHtmlToPdfPlatform].
  static set instance(NativeHtmlToPdfPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the platform version of the device.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  /// Converts the provided HTML content to a PDF file.
  /// Needs to be overridden by platform-specific implementations.
  Future<String?> convertHtmlToPdf(Map<String, dynamic> args) {
    throw UnimplementedError('convertHtmlToPdf() has not been implemented.');
  }
}