import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PdfToolScreen(),
    ));

class PdfToolScreen extends StatefulWidget {
  const PdfToolScreen({super.key});

  @override
  State<PdfToolScreen> createState() => _PdfToolScreenState();
}

class _PdfToolScreenState extends State<PdfToolScreen> {
  final channel = const MethodChannel('html_to_pdf');

  PdfController? controller;
  bool loading = false;

  String size = "A4";
  bool landscape = false;
  double dpi = 600;

  int startPage = 1;
  int endPage = 0;

  final left = TextEditingController(text: "0");
  final top = TextEditingController(text: "0");
  final right = TextEditingController(text: "0");
  final bottom = TextEditingController(text: "0");

  final sizes = [
    "A0","A1","A2","A3","A4","A5",
    "B0","B1","B2","B3","B4","B5",
    "LETTER","LEGAL","TABLOID","LEDGER"
  ];

  Future<void> generate() async {
    setState(() => loading = true);

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/test.html');

      await file.writeAsString("""
<html>
<body style="background:red;color:white;text-align:center;">
<h1>PDF TEST</h1>
<p>DPI: ${dpi.toInt()}</p>
<p>Margins: L:${left.text} T:${top.text} R:${right.text} B:${bottom.text}</p>

${List.generate(10, (i) => "<div style='border:2px solid white;margin:10px;padding:10px;'>Block ${i + 1}</div>").join("")}

<script>
window.onload = function(){
 setTimeout(function(){
   if(window.AndroidBridge){
     window.AndroidBridge.notifyPdfReady();
   }
 },600);
}
</script>

</body>
</html>
""");

      final path = await channel.invokeMethod('convertHtmlToPdf', {
        'htmlFilePath': file.path,
        'printSize': size,
        'orientation': landscape ? "LANDSCAPE" : "PORTRAIT",
        'marginLeft': int.tryParse(left.text) ?? 0,
        'marginTop': int.tryParse(top.text) ?? 0,
        'marginRight': int.tryParse(right.text) ?? 0,
        'marginBottom': int.tryParse(bottom.text) ?? 0,
        'startPage': startPage,
        'endPage': endPage,
        'dpi': dpi.toInt(),
      });

      final doc = await PdfDocument.openFile(path);

      setState(() {
        controller = PdfController(document: Future.value(doc));
      });
    } catch (e) {
      debugPrint("Error: $e");
    }

    setState(() => loading = false);
  }

  Widget input(TextEditingController c) {
    return SizedBox(
      width: 45,
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // 📄 PDF PREVIEW (TOP)
      body: Column(
        children: [

          Expanded(
            child: Container(
              color: Colors.grey.shade300,
              child: controller != null
                  ? PdfView(controller: controller!)
                  : const Center(child: Text("Generate PDF")),
            ),
          ),

          // 🔧 TOOL PANEL (BOTTOM)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Row(
                  children: [
                    Expanded(
                      child: DropdownButton(
                        value: size,
                        isExpanded: true,
                        items: sizes.map((e) =>
                          DropdownMenuItem(value: e, child: Text(e))
                        ).toList(),
                        onChanged: (v) => setState(() => size = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: loading ? null : generate,
                      child: Text(loading ? "..." : "Generate"),
                    )
                  ],
                ),

                Row(
                  children: [
                    const Text("DPI"),
                    Expanded(
                      child: Slider(
                        value: dpi,
                        min: 72,
                        max: 1200,
                        onChanged: (v) => setState(() => dpi = v),
                      ),
                    ),
                    Text(dpi.toInt().toString())
                  ],
                ),

                Row(
                  children: [
                    const Text("Margins"),
                    input(left),
                    input(top),
                    input(right),
                    input(bottom),
                    const Spacer(),
                    const Text("Landscape"),
                    Switch(
                      value: landscape,
                      onChanged: (v) => setState(() => landscape = v),
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}