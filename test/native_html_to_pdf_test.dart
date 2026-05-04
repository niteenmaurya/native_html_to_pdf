import 'package:flutter_test/flutter_test.dart';
import 'package:native_html_to_pdf/native_html_to_pdf.dart';
import 'package:native_html_to_pdf/native_html_to_pdf_platform_interface.dart';
import 'package:native_html_to_pdf/native_html_to_pdf_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
class MockNativeHtmlToPdfPlatform
    with MockPlatformInterfaceMixin
    implements NativeHtmlToPdfPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String?> convertHtmlToPdf(Map<String, dynamic> args) async {
    return "mock_path.pdf"; // fake response
  }
}
void main() {
  final NativeHtmlToPdfPlatform initialPlatform = NativeHtmlToPdfPlatform.instance;

  test('$MethodChannelNativeHtmlToPdf is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativeHtmlToPdf>());
  });

  test('getPlatformVersion', () async {
    NativeHtmlToPdf nativeHtmlToPdfPlugin = NativeHtmlToPdf();
    MockNativeHtmlToPdfPlatform fakePlatform = MockNativeHtmlToPdfPlatform();
    NativeHtmlToPdfPlatform.instance = fakePlatform;

    expect(await nativeHtmlToPdfPlugin.getPlatformVersion(), '42');
  });
}
