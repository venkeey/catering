import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// A utility class to handle font loading for PDF generation
class FontLoader {
  /// Loads Roboto fonts from assets
  static Future<Map<String, pw.Font>> loadRobotoFonts() async {
    try {
      final Map<String, pw.Font> fonts = {};
      
      // Load regular font
      final regularData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      fonts['regular'] = pw.Font.ttf(regularData);
      
      // Load bold font
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      fonts['bold'] = pw.Font.ttf(boldData);
      
      // Load italic font
      final italicData = await rootBundle.load('assets/fonts/Roboto-Italic.ttf');
      fonts['italic'] = pw.Font.ttf(italicData);
      
      print('Successfully loaded Roboto fonts');
      return fonts;
    } catch (e) {
      print('Error loading Roboto fonts: $e');
      throw Exception('Failed to load Roboto fonts: $e');
    }
  }
  
  /// Creates a PDF document with Roboto fonts
  static Future<pw.Document> createPdfWithRoboto() async {
    try {
      final fonts = await loadRobotoFonts();
      
      return pw.Document(
        theme: pw.ThemeData.withFont(
          base: fonts['regular']!,
          bold: fonts['bold']!,
          italic: fonts['italic']!,
        ),
      );
    } catch (e) {
      print('Falling back to Courier font: $e');
      
      // Fallback to Courier which has better Unicode support than Helvetica
      return pw.Document(
        theme: pw.ThemeData.withFont(
          base: pw.Font.courier(),
          bold: pw.Font.courierBold(),
          italic: pw.Font.courierOblique(),
          boldItalic: pw.Font.courierBoldOblique(),
        ),
      );
    }
  }
}