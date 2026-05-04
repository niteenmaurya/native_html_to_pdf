import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_html_to_pdf/native_html_to_pdf_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelNativeHtmlToPdf platform = MethodChannelNativeHtmlToPdf();
  const MethodChannel channel = MethodChannel('native_html_to_pdf');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
