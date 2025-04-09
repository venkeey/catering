import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Utility class for file operations
class FileUtils {
  /// Gets a directory for saving temporary files
  /// Falls back to different options if the primary method fails
  static Future<Directory> getSafeDirectory() async {
    if (kIsWeb) {
      // Web platform doesn't support file system access in the same way
      throw UnsupportedError('File operations not supported on web platform');
    }
    
    try {
      // First try: temporary directory
      return await getTemporaryDirectory();
    } catch (e) {
      print('Error getting temporary directory: $e');
      
      try {
        // Second try: application documents directory
        return await getApplicationDocumentsDirectory();
      } catch (e) {
        print('Error getting application documents directory: $e');
        
        try {
          // Third try: application support directory
          return await getApplicationSupportDirectory();
        } catch (e) {
          print('Error getting application support directory: $e');
          
          try {
            // Fourth try: external storage directory (Android only)
            final dirs = await getExternalStorageDirectories();
            if (dirs != null && dirs.isNotEmpty) {
              return dirs.first;
            }
            throw Exception('No external storage directories available');
          } catch (e) {
            print('Error getting external storage directory: $e');
            
            // Last resort: current directory
            return Directory('.');
          }
        }
      }
    }
  }
  
  /// Creates a file in a safe directory
  static Future<File> createSafeFile(String filename) async {
    try {
      final dir = await getSafeDirectory();
      return File('${dir.path}/$filename');
    } catch (e) {
      print('Error creating safe file: $e');
      // Absolute last resort
      return File(filename);
    }
  }
}