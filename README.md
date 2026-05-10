# native_html_to_pdf

[![Pub Version](https://img.shields.io/pub/v/native_html_to_pdf?style=for-the-badge)](https://pub.dev/packages/native_html_to_pdf)
[![Pub Likes](https://img.shields.io/pub/likes/native_html_to_pdf?style=for-the-badge)](https://pub.dev/packages/native_html_to_pdf)
[![Pub Points](https://img.shields.io/pub/points/native_html_to_pdf?style=for-the-badge)](https://pub.dev/packages/native_html_to_pdf)
[![Downloads](https://img.shields.io/badge/dynamic/json?color=blue&label=Downloads&query=%24.downloadCount30Days&url=https%3A%2F%2Fpub.dev%2Fapi%2Fpackages%2Fnative_html_to_pdf%2Fscore&style=for-the-badge)](https://pub.dev/packages/native_html_to_pdf)
A Flutter plugin to convert local HTML files into PDF using native Android and iOS rendering engines.

## Features

- Native rendering on Android and iOS
- Converts local HTML files to PDF
- Supports full HTML and CSS
- Handles complex layouts like cards, tables, and multi-page content
- Multiple paper sizes
- Portrait and landscape orientation
- Custom margins: left, top, right, bottom
- Page range selection
- DPI control for output quality
- Works offline
- Hidden WebView rendering
- Supports dynamic/generated HTML content
- Same API for Android and iOS

## How it works

1. HTML file is loaded into a hidden WebView
2. JavaScript notifies when rendering is complete
3. Native print engine generates the PDF
4. The PDF is saved locally and returned to Flutter

## Supported Paper Sizes

Use one of these exact values for `printSize`:

A0, A1, A2, A3, A4, A5  
B0, B1, B2, B3, B4, B5  
LETTER, LEGAL, TABLOID, LEDGER  
INDEX_3X5, INDEX_4X6, INDEX_5X8  
MONARCH, QUARTO  
JIS_B4, JIS_B5  
ROC_8K, ROC_16K  
PRC_1, PRC_2, PRC_3, PRC_4, PRC_5  
PRC_6, PRC_7, PRC_8, PRC_9, PRC_10, PRC_16K

Default: `A4`

## Parameters

### `htmlFilePath`
Path of the local HTML file.

### `printSize`
Paper size name. Use one of the supported values listed above.

### `orientation`
Use:

- `PORTRAIT`
- `LANDSCAPE`

### `marginLeft`, `marginTop`, `marginRight`, `marginBottom`
Margins in mils.

Note:
- 1000 mils = 1 inch
- 500 mils = 0.5 inch

### `startPage`
First page to export.

### `endPage`
Last page to export.

Use `0` for all pages.

### `dpi`
Output resolution.

Recommended values:
- `300` for normal quality
- `600` for high quality

## Usage

```dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

final MethodChannel htmlChannel = MethodChannel('html_to_pdf');

Future<void> generatePdf() async {
  final tempDir = await getTemporaryDirectory();
  final htmlFile = File('${tempDir.path}/demo.html');

  await htmlFile.writeAsString('''
<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      background: red;
      color: white;
      font-family: Arial;
      padding: 20px;
    }
    .box {
      border: 2px solid white;
      margin: 10px 0;
      padding: 10px;
    }
  </style>
</head>
<body>
  <h1>native_html_to_pdf Demo</h1>
  <p>This PDF is generated from HTML.</p>

  <div class="box">Block 1</div>
  <div class="box">Block 2</div>
  <div class="box">Block 3</div>

  <script>
    window.onload = function() {
      setTimeout(function() {
        if (window.AndroidBridge) {
          window.AndroidBridge.notifyPdfReady();
        }
      }, 500);
    };
  </script>
</body>
</html>
''');

  final String path = await htmlChannel.invokeMethod('convertHtmlToPdf', {
    'htmlFilePath': htmlFile.path,
    'printSize': 'A4',
    'orientation': 'PORTRAIT',
    'marginLeft': 0,
    'marginTop': 0,
    'marginRight': 0,
    'marginBottom': 0,
    'startPage': 1,
    'endPage': 0,
    'dpi': 600,
  });

  print('PDF saved at: $path');
}
