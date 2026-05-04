import 'native_html_to_pdf_platform_interface.dart';

class NativeHtmlToPdf {
  Future<String?> getPlatformVersion() {
    return NativeHtmlToPdfPlatform.instance.getPlatformVersion();
  }

  // इसे जोड़ें ताकि यूजर ऐप से इसे कॉल कर सके
  Future<String?> convertHtmlToPdf(Map<String, dynamic> args) {
    return NativeHtmlToPdfPlatform.instance.convertHtmlToPdf(args);
  }
}