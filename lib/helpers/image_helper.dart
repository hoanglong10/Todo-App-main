import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Chọn ảnh từ camera hoặc gallery
  static Future<String?> pickAndSaveImage({
    required ImageSource source,
    double? maxWidth = 512,
    double? maxHeight = 512,
    int? imageQuality = 80,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (image != null) {
        return await _saveImageToAppDirectory(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi chọn ảnh: $e');
    }
  }

  /// Lưu ảnh vào thư mục của app
  static Future<String> _saveImageToAppDirectory(String imagePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newPath = path.join(directory.path, 'images', fileName);

      // Tạo thư mục images nếu chưa có
      final imageDir = Directory(path.dirname(newPath));
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      await File(imagePath).copy(newPath);
      return newPath;
    } catch (e) {
      throw Exception('Lỗi lưu ảnh: $e');
    }
  }

  /// Xóa ảnh cũ khi cập nhật ảnh mới
  static Future<void> deleteImageFile(String? imagePath) async {
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Không throw error khi xóa file cũ thất bại
        print('Không thể xóa file cũ: $e');
      }
    }
  }

  /// Kiểm tra xem file ảnh có tồn tại không
  static Future<bool> imageExists(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return false;
    try {
      return await File(imagePath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Lấy kích thước file ảnh (MB)
  static Future<double> getImageSize(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final bytes = await file.length();
        return bytes / (1024 * 1024); // Convert to MB
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Dọn dẹp các file ảnh cũ (gọi định kỳ để tiết kiệm dung lượng)
  static Future<void> cleanupOldImages({int daysOld = 30}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imageDir = Directory(path.join(directory.path, 'images'));

      if (await imageDir.exists()) {
        final files = await imageDir.list().toList();
        final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

        for (var entity in files) {
          if (entity is File) {
            final stat = await entity.stat();
            if (stat.modified.isBefore(cutoffDate)) {
              await entity.delete();
            }
          }
        }
      }
    } catch (e) {
      print('Lỗi dọn dẹp ảnh cũ: $e');
    }
  }
}