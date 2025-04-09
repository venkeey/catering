import 'dart:typed_data';

/// Stub implementation for non-web platforms
/// This class provides empty implementations of web-specific methods
/// to avoid compilation errors when importing on non-web platforms
class FileUtilsWeb {
  /// Stub implementation that will never be called
  static void downloadFile(String filename, Uint8List content, String mimeType) {
    throw UnsupportedError('FileUtilsWeb.downloadFile is only supported on web platforms');
  }
  
  /// Stub implementation that will never be called
  static void downloadPdf(String filename, Uint8List pdfContent) {
    throw UnsupportedError('FileUtilsWeb.downloadPdf is only supported on web platforms');
  }
}