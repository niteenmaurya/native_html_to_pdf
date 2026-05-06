/// A Flutter plugin for converting HTML strings into PDF files natively.
///
/// This library provides the main interface for the HTML to PDF conversion.
library;

import 'native_html_to_pdf_platform_interface.dart';

/// Main class for interacting with the Native HTML to PDF plugin.
class NativeHtmlToPdf {
  
  /// Creates a new instance of [NativeHtmlToPdf].
  NativeHtmlToPdf();

  /// Fetches the version of the operating system the app is running on.
  Future<String?> getPlatformVersion() {
    return NativeHtmlToPdfPlatform.instance.getPlatformVersion();
  }

  /// Initiates the conversion process from HTML to PDF.
  /// The [args] map should contain the HTML string and output path.
  Future<String?> convertHtmlToPdf(Map<String, dynamic> args) {
    return NativeHtmlToPdfPlatform.instance.convertHtmlToPdf(args);
  }
}