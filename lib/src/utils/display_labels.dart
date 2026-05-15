import 'package:flutter/material.dart';

import '../models/api_provider.dart';
import '../models/image_asset_kind.dart';
import '../models/sprite_sheet_frame_fit.dart';
import '../models/ui_state.dart';
import '../services/gif_composer_service.dart';

String imageQualityLabel(String value) {
  return switch (value) {
    'auto' => '自动',
    'low' => '低',
    'medium' => '中',
    'high' => '高',
    'standard' => '标准',
    'hd' => '高清',
    _ => value,
  };
}

String imageBackgroundLabel(String value) {
  return switch (value) {
    'auto' => '自动',
    'transparent' => '透明',
    'opaque' => '不透明',
    _ => value,
  };
}

String imageOutputFormatLabel(String value) {
  return switch (value) {
    'png' => 'PNG',
    'jpeg' => 'JPEG',
    'webp' => 'WebP',
    _ => value,
  };
}

String imageModerationLabel(String value) {
  return switch (value) {
    'auto' => '自动',
    'low' => '低',
    _ => value,
  };
}

String apiProviderKindLabel(ApiProviderKind kind) {
  return switch (kind) {
    ApiProviderKind.official => 'OpenAI 官方',
    ApiProviderKind.compatible => 'OpenAI 兼容',
    ApiProviderKind.gemini => 'Gemini',
  };
}

IconData apiProviderKindIcon(ApiProviderKind kind) {
  return switch (kind) {
    ApiProviderKind.official => Icons.verified_outlined,
    ApiProviderKind.compatible => Icons.swap_horiz,
    ApiProviderKind.gemini => Icons.auto_awesome_outlined,
  };
}

String apiProviderKindDescription(ApiProviderKind kind) {
  return switch (kind) {
    ApiProviderKind.official =>
      '发送完整 GPT Image 参数（quality/background/output_format 等）',
    ApiProviderKind.compatible => '只发送 model/prompt/size/n，避免兼容层 502',
    ApiProviderKind.gemini => '使用 Gemini generateContent 协议，支持文本生图和带参考图编辑',
  };
}

String apiKeyHintForProviderKind(ApiProviderKind kind) {
  return switch (kind) {
    ApiProviderKind.gemini => 'Google AI Studio API Key',
    _ => 'sk-...',
  };
}

String imageAssetKindLabel(ImageAssetKind kind) {
  return switch (kind) {
    ImageAssetKind.generatedImage => '生图',
    ImageAssetKind.spriteSheet => '切片',
    ImageAssetKind.spriteFrame => '帧图',
    ImageAssetKind.editedImage => '编辑',
    ImageAssetKind.gif => 'GIF',
  };
}

String imageLibraryKindFilterLabel(ImageLibraryKindFilter filter) {
  return switch (filter) {
    ImageLibraryKindFilter.all => '全部',
    ImageLibraryKindFilter.generated => '生图',
    ImageLibraryKindFilter.sprite => '切片 / 帧',
    ImageLibraryKindFilter.edited => '编辑',
    ImageLibraryKindFilter.gif => 'GIF',
  };
}

bool imageLibraryKindFilterMatches(
  ImageLibraryKindFilter filter,
  ImageAssetKind kind,
) {
  return switch (filter) {
    ImageLibraryKindFilter.all => true,
    ImageLibraryKindFilter.generated => kind == ImageAssetKind.generatedImage,
    ImageLibraryKindFilter.sprite =>
      kind == ImageAssetKind.spriteSheet || kind == ImageAssetKind.spriteFrame,
    ImageLibraryKindFilter.edited => kind == ImageAssetKind.editedImage,
    ImageLibraryKindFilter.gif => kind == ImageAssetKind.gif,
  };
}

String imageLibrarySortOrderLabel(ImageLibrarySortOrder sortOrder) {
  return switch (sortOrder) {
    ImageLibrarySortOrder.newest => '最新优先',
    ImageLibrarySortOrder.oldest => '最旧优先',
    ImageLibrarySortOrder.titleAscending => '标题 A-Z',
  };
}

String fileNameFromPath(String path) {
  final parts = path.split(RegExp(r'[\\/]')).where((part) => part.isNotEmpty);
  return parts.isEmpty ? path : parts.last;
}

String editorFrameOptionLabel(int index, int columns) {
  final row = index ~/ columns + 1;
  final column = index % columns + 1;
  return '${index + 1}帧 · $row 行 $column 列';
}

String spriteSheetFrameFitLabel(SpriteSheetFrameFit fit) {
  return switch (fit) {
    SpriteSheetFrameFit.contain => '完整放入',
    SpriteSheetFrameFit.cover => '裁剪填满',
    SpriteSheetFrameFit.stretch => '拉伸填满',
  };
}

String gifPlaybackModeLabel(GifPlaybackMode mode) {
  return switch (mode) {
    GifPlaybackMode.normal => '正向',
    GifPlaybackMode.reverse => '反向',
    GifPlaybackMode.pingPong => '乒乓',
  };
}
