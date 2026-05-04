package android.print

import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import java.io.File

/**
 * PdfPrinter
 * A helper class that uses Android's PrintDocumentAdapter to write PDF content to a physical file.
 */
class PdfPrinter(private val attributes: PrintAttributes) {
    
    // Callback interface to notify the result of the PDF generation
    interface Callback {
        fun onSuccess(filePath: String)
        fun onFailure()
    }

    /**
     * Starts the PDF generation process.
     * 
     * @param adapter The PrintDocumentAdapter provided by the WebView.
     * @param path The directory where the PDF will be saved.
     * @param fileName The name of the generated PDF file.
     * @param ranges The specific pages to print.
     * @param callback The callback to handle success or failure.
     */
    fun print(adapter: PrintDocumentAdapter, path: File, fileName: String, ranges: Array<PageRange>, callback: Callback) {
        
        // Step 1: Trigger the layout phase to prepare the document based on print attributes
        adapter.onLayout(null, attributes, null, object : PrintDocumentAdapter.LayoutResultCallback() {
            
            override fun onLayoutFinished(info: PrintDocumentInfo, changed: Boolean) {
                try {
                    // Prepare the file and directory
                    val file = File(path, fileName)
                    if (!path.exists()) path.mkdirs()
                    
                    // Open a file descriptor to write the PDF data
                    val output = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_WRITE or ParcelFileDescriptor.MODE_CREATE or ParcelFileDescriptor.MODE_TRUNCATE)

                    // Step 2: Trigger the write phase to save the document to the file
                    adapter.onWrite(ranges, output, CancellationSignal(), object : PrintDocumentAdapter.WriteResultCallback() {
                        
                        override fun onWriteFinished(pages: Array<PageRange>) {
                            output.close()
                            // Check if pages were actually written
                            if (pages.isNotEmpty()) {
                                callback.onSuccess(file.absolutePath)
                            } else {
                                callback.onFailure()
                            }
                        }
                        
                        override fun onWriteFailed(error: CharSequence?) {
                            output.close()
                            callback.onFailure()
                        }
                    })
                } catch (e: Exception) {
                    // Handle file system or execution errors
                    callback.onFailure()
                }
            }
            
            override fun onLayoutFailed(error: CharSequence?) {
                // Handle layout preparation failure
                callback.onFailure()
            }
        }, null)
    }
}