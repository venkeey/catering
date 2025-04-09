import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

// Conditionally import the appropriate implementation
import 'file_utils.dart';
import 'file_utils_web.dart' if (dart.library.io) 'file_utils_stub.dart';

// Conditionally export the appropriate implementation
export 'file_utils.dart' if (dart.library.html) 'file_utils_web.dart';

/// Factory class that provides the appropriate file utilities based on the platform
class FileUtilsFactory {
  /// Saves or downloads a file with the given filename and content
  static Future<void> saveFile(String filename, Uint8List content, String mimeType) async {
    if (kIsWeb) {
      // For web platforms, use the web-specific implementation
      FileUtilsWeb.downloadFile(filename, content, mimeType);
    } else {
      // For non-web platforms, use the regular implementation
      final file = await FileUtils.createSafeFile(filename);
      await file.writeAsBytes(content);
    }
  }
  
  /// Saves or downloads a PDF file
  static Future<void> savePdf(String filename, Uint8List pdfContent) async {
    return saveFile(filename, pdfContent, 'application/pdf');
  }
}