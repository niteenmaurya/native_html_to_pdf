package com.nitemoraix.native_html_to_pdf

import android.annotation.SuppressLint
import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.print.PageRange
import android.print.PrintAttributes
import android.view.ViewGroup
import android.webkit.JavascriptInterface
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean

/**
 * NativeHtmlToPdfPlugin
 * A Flutter plugin that uses the native Android Print API to convert HTML files to PDF documents.
 */
class NativeHtmlToPdfPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel : MethodChannel
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "html_to_pdf")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "convertHtmlToPdf") {
            // Extract parameters sent from Dart
            val path = call.argument<String>("htmlFilePath") ?: ""
            val size = call.argument<String>("printSize") ?: "A4"
            val orientation = call.argument<String>("orientation") ?: "PORTRAIT"
            
            // Extract margin parameters (in Mils)
            val marginTop = call.argument<Int>("marginTop") ?: 0
            val marginBottom = call.argument<Int>("marginBottom") ?: 0
            val marginLeft = call.argument<Int>("marginLeft") ?: 0
            val marginRight = call.argument<Int>("marginRight") ?: 0
            
            // Extract page range and DPI parameters
            val startPage = call.argument<Int>("startPage") ?: 1
            val endPage = call.argument<Int>("endPage") ?: 0
            val dpi = call.argument<Int>("dpi") ?: 600

            // Ensure activity is available before proceeding
            if (activity == null) {
                result.error("NO_ACTIVITY", "Activity is null", null)
                return
            }

            // Start HTML to PDF conversion
            HtmlToPdfConverter().convert(path, activity!!, size, orientation, marginTop, marginBottom, marginLeft, marginRight, startPage, endPage, dpi, object : HtmlToPdfConverter.Callback {
                override fun onSuccess(filePath: String) = result.success(filePath)
                override fun onFailure(error: String) = result.error("ERR", error, null)
            })
        } else {
            result.notImplemented()
        }
    }

    // Lifecycle methods to handle Activity attachment and detachment
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) { channel.setMethodCallHandler(null) }
    override fun onAttachedToActivity(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivityForConfigChanges() { activity = null }
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) { activity = binding.activity }
    override fun onDetachedFromActivity() { activity = null }
}

class HtmlToPdfConverter {
    interface Callback {
        fun onSuccess(filePath: String)
        fun onFailure(error: String)
    }

    @SuppressLint("SetJavaScriptEnabled")
    fun convert(filePath: String, activity: Activity, printSize: String, orientation: String, marginTop: Int, marginBottom: Int, marginLeft: Int, marginRight: Int, startPage: Int, endPage: Int, dpi: Int, callback: Callback) {
        // Read the HTML content from the given file path
        val html = File(filePath).readText()
        val isDone = AtomicBoolean(false)
        val handler = Handler(Looper.getMainLooper())
        
        // Create a hidden WebView to render the HTML
        var webView: WebView? = WebView(activity)

        // Helper function to clean up the WebView after PDF generation
        fun cleanup() {
            webView?.let { (it.parent as? ViewGroup)?.removeView(it); it.destroy() }
            webView = null
        }

        // Function triggered by Javascript when the HTML is fully ready
        fun createPdf() {
            if (isDone.get() || webView == null) return

            // Map string sizes to native Android PrintAttributes.MediaSize
            var mediaSize = when (printSize.uppercase()) {
                "A0" -> PrintAttributes.MediaSize.ISO_A0
                "A1" -> PrintAttributes.MediaSize.ISO_A1
                "A2" -> PrintAttributes.MediaSize.ISO_A2
                "A3" -> PrintAttributes.MediaSize.ISO_A3
                "A4" -> PrintAttributes.MediaSize.ISO_A4
                "A5" -> PrintAttributes.MediaSize.ISO_A5
                "B0" -> PrintAttributes.MediaSize.ISO_B0
                "B1" -> PrintAttributes.MediaSize.ISO_B1
                "B2" -> PrintAttributes.MediaSize.ISO_B2
                "B3" -> PrintAttributes.MediaSize.ISO_B3
                "B4" -> PrintAttributes.MediaSize.ISO_B4
                "B5" -> PrintAttributes.MediaSize.ISO_B5
                "LETTER" -> PrintAttributes.MediaSize.NA_LETTER
                "LEGAL" -> PrintAttributes.MediaSize.NA_LEGAL
                "TABLOID" -> PrintAttributes.MediaSize.NA_TABLOID
                "LEDGER" -> PrintAttributes.MediaSize.NA_LEDGER
                "INDEX_3X5" -> PrintAttributes.MediaSize.NA_INDEX_3X5
                "INDEX_4X6" -> PrintAttributes.MediaSize.NA_INDEX_4X6
                "INDEX_5X8" -> PrintAttributes.MediaSize.NA_INDEX_5X8
                "MONARCH" -> PrintAttributes.MediaSize.NA_MONARCH
                "QUARTO" -> PrintAttributes.MediaSize.NA_QUARTO
                "JIS_B4" -> PrintAttributes.MediaSize.JIS_B4
                "JIS_B5" -> PrintAttributes.MediaSize.JIS_B5
                "ROC_8K" -> PrintAttributes.MediaSize.ROC_8K
                "ROC_16K" -> PrintAttributes.MediaSize.ROC_16K
                "PRC_1" -> PrintAttributes.MediaSize.PRC_1
                "PRC_2" -> PrintAttributes.MediaSize.PRC_2
                "PRC_3" -> PrintAttributes.MediaSize.PRC_3
                "PRC_4" -> PrintAttributes.MediaSize.PRC_4
                "PRC_5" -> PrintAttributes.MediaSize.PRC_5
                "PRC_6" -> PrintAttributes.MediaSize.PRC_6
                "PRC_7" -> PrintAttributes.MediaSize.PRC_7
                "PRC_8" -> PrintAttributes.MediaSize.PRC_8
                "PRC_9" -> PrintAttributes.MediaSize.PRC_9
                "PRC_10" -> PrintAttributes.MediaSize.PRC_10
                "PRC_16K" -> PrintAttributes.MediaSize.PRC_16K
                else -> PrintAttributes.MediaSize.ISO_A4
            }

            // Set Portrait or Landscape orientation
            mediaSize = if (orientation.uppercase() == "LANDSCAPE") mediaSize.asLandscape() else mediaSize.asPortrait()
            
            // Set Print Margins (Left, Top, Right, Bottom) and Resolution (DPI)
            val printMargins = PrintAttributes.Margins(marginLeft, marginTop, marginRight, marginBottom)
            val resolution = PrintAttributes.Resolution("pdf_gen", "Processing", dpi, dpi)

            // Build the PrintAttributes object
            val attributes = PrintAttributes.Builder()
                .setMediaSize(mediaSize)
                .setResolution(resolution)
                .setMinMargins(printMargins)
                .setColorMode(PrintAttributes.COLOR_MODE_COLOR)
                .build()

            // Calculate the page ranges to be printed
            val ranges = if (startPage > 0 && endPage >= startPage) {
                arrayOf(android.print.PageRange(startPage - 1, endPage - 1))
            } else {
                arrayOf(android.print.PageRange.ALL_PAGES)
            }

            // Initialize the custom PdfPrinter and generate the file
            val printer = android.print.PdfPrinter(attributes)
            printer.print(webView!!.createPrintDocumentAdapter("Document"), activity.filesDir, "doc_${System.currentTimeMillis()}.pdf", ranges, object : android.print.PdfPrinter.Callback {
                override fun onSuccess(path: String) {
                    if (isDone.compareAndSet(false, true)) { cleanup(); callback.onSuccess(path) }
                }
                override fun onFailure() {
                    if (isDone.compareAndSet(false, true)) { cleanup(); callback.onFailure("Failed") }
                }
            })
        }

        // Configure WebView settings for proper rendering before printing
        webView?.apply {
            webViewClient = WebViewClient()
            settings.javaScriptEnabled = true
            settings.useWideViewPort = true
            settings.loadWithOverviewMode = true
            
            // Inject AndroidBridge to allow JavaScript to notify Android when rendering is complete
            addJavascriptInterface(object {
                @JavascriptInterface fun notifyPdfReady() { handler.post { createPdf() } }
            }, "AndroidBridge")
        }
        
        // Add the hidden WebView to the Activity and load the HTML content
        activity.addContentView(webView, ViewGroup.LayoutParams(1, 1))
        webView?.loadDataWithBaseURL("file:///android_asset/", html, "text/html", "UTF-8", null)
    }
}