import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as image_lib;

import '../models/exceptions.dart';
import '../models/generated_image.dart';
import '../models/sprite_sheet_frame_fit.dart';
import '../models/sprite_sheet_grid_spec.dart';
import 'app_local_store.dart';

part 'sprite_sheet_preview_service.dart';
part 'sprite_sheet_output_service.dart';
part 'sprite_sheet_editor_service.dart';

Future<Uint8List> _resolveGeneratedImageBytesForPreview(
  GeneratedImage image,
) async {
  if (image.bytes != null) {
    return image.bytes!;
  }

  if (image.filePath != null) {
    return File(image.filePath!).readAsBytes();
  }

  if (image.url != null) {
    final response = await http
        .get(Uri.parse(image.url!))
        .timeout(const Duration(minutes: 2));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ImageGenerationException(
        '切片预览下载图片失败：HTTP ${response.statusCode} ${response.reasonPhrase ?? ''}',
      );
    }
    return response.bodyBytes;
  }

  throw const ImageGenerationException('图片没有可供切片预览的内容。');
}
