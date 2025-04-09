import 'dart:html' as html;
import 'dart:typed_data';

/// Web-specific implementation of file utilities
class FileUtilsWeb {
  /// Downloads a file with the given filename and content
  static void downloadFile(String filename, Uint8List content, String mimeType) {
    final blob = html.Blob([content], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
  
  /// Downloads a PDF file
  static void downloadPdf(String filename, Uint8List pdfContent) {
    downloadFile(filename, pdfContent, 'application/pdf');
  }
}