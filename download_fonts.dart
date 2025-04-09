import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

void main() async {
  // Create the fonts directory if it doesn't exist
  final fontsDir = Directory('assets/fonts');
  if (!await fontsDir.exists()) {
    await fontsDir.create(recursive: true);
  }

  // Download Roboto fonts - using actual TTF files from GitHub
  await downloadFont(
    'https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Regular.ttf',
    'assets/fonts/Roboto-Regular.ttf'
  );
  
  await downloadFont(
    'https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Bold.ttf',
    'assets/fonts/Roboto-Bold.ttf'
  );
  
  await downloadFont(
    'https://github.com/google/fonts/raw/main/apache/roboto/Roboto-Italic.ttf',
    'assets/fonts/Roboto-Italic.ttf'
  );
  
  print('Fonts downloaded successfully!');
}

Future<void> downloadFont(String url, String path) async {
  print('Downloading $url to $path...');
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final file = File(path);
    await file.writeAsBytes(response.bodyBytes);
    print('Downloaded $path');
  } else {
    print('Failed to download $url: ${response.statusCode}');
  }
}