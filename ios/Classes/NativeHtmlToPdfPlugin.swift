import Flutter
import UIKit
import WebKit

public class NativeHtmlToPdfPlugin: NSObject, FlutterPlugin, WKScriptMessageHandler, WKNavigationDelegate {

    private var webView: WKWebView?
    private var flutterResult: FlutterResult?
    private var pdfParams: [String: Any]?
    private var isGenerating = false
    private var didReceiveReadySignal = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "html_to_pdf", binaryMessenger: registrar.messenger())
        let instance = NativeHtmlToPdfPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "convertHtmlToPdf" else {
            result(FlutterMethodNotImplemented)
            return
        }

        self.flutterResult = result
        self.pdfParams = call.arguments as? [String: Any]

        guard
            let args = self.pdfParams,
            let path = args["htmlFilePath"] as? String
        else {
            result(FlutterError(code: "ERR", message: "Invalid parameters", details: nil))
            clearState()
            return
        }

        do {
            let htmlString = try String(contentsOfFile: path, encoding: .utf8)
            setupWebViewAndLoad(html: htmlString, htmlFilePath: path)
        } catch {
            result(FlutterError(code: "ERR", message: "Failed to read HTML file", details: nil))
            clearState()
        }
    }

    private func setupWebViewAndLoad(html: String, htmlFilePath: String) {
        DispatchQueue.main.async {
            self.didReceiveReadySignal = false
            self.isGenerating = false

            let args = self.pdfParams ?? [:]
            let printSize = (args["printSize"] as? String)?.uppercased() ?? "A4"
            let orientation = (args["orientation"] as? String)?.uppercased() ?? "PORTRAIT"

            var paperSize = self.paperSizeInPoints(printSize: printSize)
            if orientation == "LANDSCAPE" {
                paperSize = CGSize(width: paperSize.height, height: paperSize.width)
            }

            let config = WKWebViewConfiguration()
            let userController = WKUserContentController()

            let js = """
            window.AndroidBridge = window.AndroidBridge || {};
            window.AndroidBridge.notifyPdfReady = function() {
                window.webkit.messageHandlers.pdfBridge.postMessage('ready');
            };
            """
            let script = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            userController.addUserScript(script)
            userController.add(self, name: "pdfBridge")
            config.userContentController = userController

            let webView = WKWebView(frame: CGRect(origin: .zero, size: paperSize), configuration: config)
            webView.navigationDelegate = self
            webView.isHidden = true
            webView.backgroundColor = .clear
            webView.scrollView.isScrollEnabled = false
            webView.scrollView.bounces = false

            self.webView = webView

            let fileURL = URL(fileURLWithPath: htmlFilePath)
            let baseURL = fileURL.deletingLastPathComponent()

            webView.loadHTMLString(html, baseURL: baseURL)
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Fallback: if HTML never calls AndroidBridge.notifyPdfReady(),
        // still generate once the page has finished loading.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if !self.didReceiveReadySignal {
                self.generatePDF()
            }
        }
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "pdfBridge" else { return }
        didReceiveReadySignal = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.generatePDF()
        }
    }

    private func generatePDF() {
        guard !isGenerating else { return }
        isGenerating = true

        guard
            let args = pdfParams,
            let webView = webView,
            let result = flutterResult
        else {
            clearState()
            return
        }

        let printSize = (args["printSize"] as? String)?.uppercased() ?? "A4"
        let orientation = (args["orientation"] as? String)?.uppercased() ?? "PORTRAIT"

        let marginTopMils = (args["marginTop"] as? Int) ?? 0
        let marginBottomMils = (args["marginBottom"] as? Int) ?? 0
        let marginLeftMils = (args["marginLeft"] as? Int) ?? 0
        let marginRightMils = (args["marginRight"] as? Int) ?? 0

        var startPage = (args["startPage"] as? Int) ?? 1
        var endPage = (args["endPage"] as? Int) ?? 0

        let dpi = (args["dpi"] as? Int) ?? 600

        var paperSize = paperSizeInPoints(printSize: printSize)
        if orientation == "LANDSCAPE" {
            paperSize = CGSize(width: paperSize.height, height: paperSize.width)
        }

        let top = CGFloat(marginTopMils) * 72.0 / 1000.0
        let bottom = CGFloat(marginBottomMils) * 72.0 / 1000.0
        let left = CGFloat(marginLeftMils) * 72.0 / 1000.0
        let right = CGFloat(marginRightMils) * 72.0 / 1000.0

        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(webView.viewPrintFormatter(), startingAtPageAt: 0)

        let paperRect = CGRect(origin: .zero, size: paperSize)
        let printableRect = CGRect(
            x: left,
            y: top,
            width: max(1, paperSize.width - left - right),
            height: max(1, paperSize.height - top - bottom)
        )

        renderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

        let totalPages = renderer.numberOfPages
        if totalPages <= 0 {
            result(FlutterError(code: "ERR", message: "No pages were generated", details: nil))
            clearState()
            return
        }

        if startPage < 1 { startPage = 1 }
        if endPage < 1 || endPage > totalPages { endPage = totalPages }
        if startPage > totalPages { startPage = totalPages }

        let data = NSMutableData()
        let pdfInfo: [String: Any] = [
            kCGPDFContextAuthor as String: "Flutter",
            kCGPDFContextTitle as String: "HTML to PDF",
            kCGPDFContextCreator as String: "NativeHtmlToPdfPlugin",
            kCGPDFContextResolution as String: dpi
        ]

        UIGraphicsBeginPDFContextToData(data, paperRect, pdfInfo)

        if startPage <= endPage {
            for pageIndex in (startPage - 1)...(endPage - 1) {
                UIGraphicsBeginPDFPage()
                renderer.drawPage(at: pageIndex, in: UIGraphicsGetPDFContextBounds())
            }
        }

        UIGraphicsEndPDFContext()

        let fileName = "doc_\(Int(Date().timeIntervalSince1970 * 1000)).pdf"
        let filePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)

        do {
            try data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
            result(filePath)
        } catch {
            result(FlutterError(code: "ERR", message: "Failed to write PDF", details: nil))
        }

        clearState()
    }

    private func clearState() {
        webView?.navigationDelegate = nil
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "pdfBridge")
        webView = nil
        pdfParams = nil
        flutterResult = nil
        isGenerating = false
        didReceiveReadySignal = false
    }

    private func paperSizeInPoints(printSize: String) -> CGSize {
        // Android MediaSize values are in mils. iOS PDF uses points.
        // 1 mil = 0.072 points
        func milsToPoints(_ w: CGFloat, _ h: CGFloat) -> CGSize {
            CGSize(width: w * 0.072, height: h * 0.072)
        }

        switch printSize {
        case "A0": return milsToPoints(33110, 46810)
        case "A1": return milsToPoints(23390, 33110)
        case "A2": return milsToPoints(16540, 23390)
        case "A3": return milsToPoints(11690, 16540)
        case "A4": return milsToPoints(8270, 11690)
        case "A5": return milsToPoints(5830, 8270)

        case "B0": return milsToPoints(39370, 55670)
        case "B1": return milsToPoints(27830, 39370)
        case "B2": return milsToPoints(19685, 27830)
        case "B3": return milsToPoints(13900, 19685)
        case "B4": return milsToPoints(9840, 13900)
        case "B5": return milsToPoints(6930, 9840)

        case "LETTER": return milsToPoints(8500, 11000)
        case "LEGAL": return milsToPoints(8500, 14000)
        case "TABLOID": return milsToPoints(11000, 17000)
        case "LEDGER": return milsToPoints(17000, 11000)

        case "INDEX_3X5": return milsToPoints(3000, 5000)
        case "INDEX_4X6": return milsToPoints(4000, 6000)
        case "INDEX_5X8": return milsToPoints(5000, 8000)

        case "MONARCH": return milsToPoints(3500, 5500)
        case "QUARTO": return milsToPoints(8000, 10000)

        case "JIS_B4": return milsToPoints(10118, 14331)
        case "JIS_B5": return milsToPoints(7177, 10118)

        case "ROC_8K": return milsToPoints(10118, 14567)
        case "ROC_16K": return milsToPoints(7276, 10118)

        case "PRC_1": return milsToPoints(2891, 5170)
        case "PRC_2": return milsToPoints(3937, 5906)
        case "PRC_3": return milsToPoints(3937, 8661)
        case "PRC_4": return milsToPoints(4724, 6661)
        case "PRC_5": return milsToPoints(4724, 9055)
        case "PRC_6": return milsToPoints(5197, 7370)
        case "PRC_7": return milsToPoints(5197, 10236)
        case "PRC_8": return milsToPoints(5831, 8661)
        case "PRC_9": return milsToPoints(6299, 9055)
        case "PRC_10": return milsToPoints(6299, 12598)
        case "PRC_16K": return milsToPoints(6654, 9450)

        default:
            return milsToPoints(8270, 11690) // A4
        }
    }
}