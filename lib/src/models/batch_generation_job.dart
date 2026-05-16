import 'app_config.dart';
import 'generated_image.dart';
import 'image_advanced_settings.dart';
import 'image_library_item.dart';
import '../services/image_request_debug_record.dart';
import '../utils/generation_limits.dart';

enum BatchGenerationJobStatus { queued, running, succeeded, failed, skipped }

int _batchGenerationJobIdSeed = 0;

class BatchGenerationJob {
  const BatchGenerationJob({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.apiConfig,
    required this.prompt,
    required this.negativePrompt,
    required this.size,
    required this.imageCount,
    required this.advancedSettings,
    required this.user,
    this.batchIndex = 1,
    this.batchTotal = 1,
    this.resultImages = const <GeneratedImage>[],
    this.libraryItems = const <ImageLibraryItem>[],
    this.debugRecord,
    this.errorMessage,
  });

  factory BatchGenerationJob.create({
    required ApiConfig apiConfig,
    required String prompt,
    required String negativePrompt,
    required String size,
    required int imageCount,
    required ImageAdvancedSettings advancedSettings,
    required String user,
    int batchIndex = 1,
    int batchTotal = 1,
  }) {
    final createdAt = DateTime.now();
    return BatchGenerationJob(
      id: _newId(createdAt),
      createdAt: createdAt,
      status: BatchGenerationJobStatus.queued,
      apiConfig: apiConfig,
      prompt: prompt,
      negativePrompt: negativePrompt,
      size: size,
      imageCount: normalizeImageGenerationRequestCount(imageCount),
      advancedSettings: advancedSettings,
      user: user,
      batchIndex: batchIndex,
      batchTotal: batchTotal,
    );
  }

  final String id;
  final DateTime createdAt;
  final BatchGenerationJobStatus status;
  final ApiConfig apiConfig;
  final String prompt;
  final String negativePrompt;
  final String size;
  final int imageCount;
  final ImageAdvancedSettings advancedSettings;
  final String user;
  final int batchIndex;
  final int batchTotal;
  final List<GeneratedImage> resultImages;
  final List<ImageLibraryItem> libraryItems;
  final ImageRequestDebugRecord? debugRecord;
  final String? errorMessage;

  bool get hasMultipleBatches => batchTotal > 1;
  bool get canDelete => status != BatchGenerationJobStatus.running;
  bool get isPending => status == BatchGenerationJobStatus.queued;
  bool get isRunning => status == BatchGenerationJobStatus.running;
  bool get isTerminal =>
      status == BatchGenerationJobStatus.succeeded ||
      status == BatchGenerationJobStatus.failed ||
      status == BatchGenerationJobStatus.skipped;

  BatchGenerationJob copyWith({
    String? id,
    DateTime? createdAt,
    BatchGenerationJobStatus? status,
    ApiConfig? apiConfig,
    String? prompt,
    String? negativePrompt,
    String? size,
    int? imageCount,
    ImageAdvancedSettings? advancedSettings,
    String? user,
    int? batchIndex,
    int? batchTotal,
    List<GeneratedImage>? resultImages,
    List<ImageLibraryItem>? libraryItems,
    ImageRequestDebugRecord? debugRecord,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return BatchGenerationJob(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      apiConfig: apiConfig ?? this.apiConfig,
      prompt: prompt ?? this.prompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      size: size ?? this.size,
      imageCount: imageCount == null
          ? this.imageCount
          : normalizeImageGenerationRequestCount(imageCount),
      advancedSettings: advancedSettings ?? this.advancedSettings,
      user: user ?? this.user,
      batchIndex: batchIndex ?? this.batchIndex,
      batchTotal: batchTotal ?? this.batchTotal,
      resultImages: resultImages ?? this.resultImages,
      libraryItems: libraryItems ?? this.libraryItems,
      debugRecord: debugRecord ?? this.debugRecord,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }

  static String _newId(DateTime now) {
    _batchGenerationJobIdSeed += 1;
    return '${now.microsecondsSinceEpoch}_$_batchGenerationJobIdSeed';
  }
}

String batchGenerationJobStatusLabel(BatchGenerationJobStatus status) {
  return switch (status) {
    BatchGenerationJobStatus.queued => '等待中',
    BatchGenerationJobStatus.running => '生成中',
    BatchGenerationJobStatus.succeeded => '已完成',
    BatchGenerationJobStatus.failed => '失败',
    BatchGenerationJobStatus.skipped => '已取消',
  };
}
