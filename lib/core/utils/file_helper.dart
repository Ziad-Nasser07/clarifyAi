import 'dart:io';
import 'dart:typed_data';

class FileHelper {
  /// تحويل الملف (صورة أو PDF) إلى بيانات ثنائية Uint8List لإرسالها إلى Gemini
  static Future<Uint8List> fileToBytes(File file) async {
    return await file.readAsBytes();
  }

  /// تحديد نوع الملف (MimeType) بدقة لـ Gemini API
  static String getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}