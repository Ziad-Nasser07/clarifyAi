import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class FileHelper {
  /// اختيار صورة مع ضبط الدقة (1600px) والجودة (85%) لقراءة النصوص بوضوح وسرعة رفع عالية
  static Future pickImage({required ImageSource source}) async {
    final ImagePicker picker = ImagePicker();

    final XFile? picked = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );

    if (picked == null) return null;
    return File(picked.path);
  }

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