import 'dart:math' as math;

import '../models/api_provider.dart';
import '../models/app_config.dart';
import '../models/exceptions.dart';

const int openAIDefaultImageSide = 1024;
const int gptImage2MinSide = 256;
const int gptImage2MaxSide = 3840;
const int gptImage2SizeStep = 16;
const int gptImage2MaxAspectRatio = 3;
const int gptImage2MinPixels = 655360;
const int gptImage2MaxPixels = 8294400;

enum ImageSizeMode { fixedPresets, customPixels, aspectRatio }

class ImageSizeConstraints {
  const ImageSizeConstraints({
    required this.minSide,
    required this.maxSide,
    required this.step,
    required this.maxAspectRatio,
    required this.minPixels,
    required this.maxPixels,
  });

  final int minSide;
  final int maxSide;
  final int step;
  final int maxAspectRatio;
  final int minPixels;
  final int maxPixels;
}

class ImageModelCapabilities {
  const ImageModelCapabilities({
    required this.sizeMode,
    required this.presets,
    this.constraints,
  });

  final ImageSizeMode sizeMode;
  final List<ImageSizePreset> presets;
  final ImageSizeConstraints? constraints;

  bool get allowsCustomPixels => sizeMode == ImageSizeMode.customPixels;
}

class ImageSizeValidationResult {
  const ImageSizeValidationResult.valid(this.dimensions)
    : isValid = true,
      message = null;

  const ImageSizeValidationResult.invalid(this.message)
    : isValid = false,
      dimensions = null;

  final bool isValid;
  final ImageDimensions? dimensions;
  final String? message;
}

class ImageSizePreset {
  const ImageSizePreset({required this.label, required this.dimensions});

  final String label;
  final ImageDimensions dimensions;

  String get size => dimensions.size;
}

class ImageDimensions {
  const ImageDimensions(this.width, this.height);

  final int width;
  final int height;

  String get size => '${width}x$height';

  @override
  bool operator ==(Object other) {
    return other is ImageDimensions &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(width, height);
}

const List<ImageSizePreset> imageSizePresets = <ImageSizePreset>[
  ImageSizePreset(label: '1K 方图', dimensions: ImageDimensions(1024, 1024)),
  ImageSizePreset(label: '1.5K 横图', dimensions: ImageDimensions(1536, 1024)),
  ImageSizePreset(label: '1.5K 竖图', dimensions: ImageDimensions(1024, 1536)),
];

const List<ImageSizePreset> customPixelImageSizePresets = <ImageSizePreset>[
  ...imageSizePresets,
  ImageSizePreset(label: '2K 方图', dimensions: ImageDimensions(2048, 2048)),
  ImageSizePreset(label: '2K 横图', dimensions: ImageDimensions(2048, 1152)),
  ImageSizePreset(label: '2K 竖图', dimensions: ImageDimensions(1152, 2048)),
  ImageSizePreset(label: '4K 横图', dimensions: ImageDimensions(3840, 2160)),
  ImageSizePreset(label: '4K 竖图', dimensions: ImageDimensions(2160, 3840)),
];

const List<ImageSizePreset> geminiAspectRatioPresets = <ImageSizePreset>[
  ImageSizePreset(label: '1:1 方图', dimensions: ImageDimensions(1024, 1024)),
  ImageSizePreset(label: '2:3 竖图', dimensions: ImageDimensions(1024, 1536)),
  ImageSizePreset(label: '3:2 横图', dimensions: ImageDimensions(1536, 1024)),
  ImageSizePreset(label: '3:4 竖图', dimensions: ImageDimensions(1200, 1600)),
  ImageSizePreset(label: '4:3 横图', dimensions: ImageDimensions(1600, 1200)),
  ImageSizePreset(label: '4:5 竖图', dimensions: ImageDimensions(1280, 1600)),
  ImageSizePreset(label: '5:4 横图', dimensions: ImageDimensions(1600, 1280)),
  ImageSizePreset(label: '9:16 竖图', dimensions: ImageDimensions(900, 1600)),
  ImageSizePreset(label: '16:9 横图', dimensions: ImageDimensions(1600, 900)),
  ImageSizePreset(label: '21:9 宽屏', dimensions: ImageDimensions(1680, 720)),
];

const ImageSizeConstraints gptImage2SizeConstraints = ImageSizeConstraints(
  minSide: gptImage2MinSide,
  maxSide: gptImage2MaxSide,
  step: gptImage2SizeStep,
  maxAspectRatio: gptImage2MaxAspectRatio,
  minPixels: gptImage2MinPixels,
  maxPixels: gptImage2MaxPixels,
);

const ImageModelCapabilities fixedOpenAIImageCapabilities =
    ImageModelCapabilities(
      sizeMode: ImageSizeMode.fixedPresets,
      presets: imageSizePresets,
    );

const ImageModelCapabilities gptImage2Capabilities = ImageModelCapabilities(
  sizeMode: ImageSizeMode.customPixels,
  presets: customPixelImageSizePresets,
  constraints: gptImage2SizeConstraints,
);

const ImageModelCapabilities geminiImageCapabilities = ImageModelCapabilities(
  sizeMode: ImageSizeMode.aspectRatio,
  presets: geminiAspectRatioPresets,
);

String requestSizeForModel({
  required String size,
  required ApiProviderKind providerKind,
  required String model,
  ImageSizeCapabilityOverride capabilityOverride =
      ImageSizeCapabilityOverride.auto,
}) {
  final validation = validateImageSizeForModel(
    size: size,
    providerKind: providerKind,
    model: model,
    capabilityOverride: capabilityOverride,
  );
  if (!validation.isValid) {
    throw ImageGenerationException(validation.message ?? '当前图片尺寸无效。');
  }
  return validation.dimensions!.size;
}

String safeImageSizeForModel({
  required String size,
  required ApiProviderKind providerKind,
  required String model,
  ImageSizeCapabilityOverride capabilityOverride =
      ImageSizeCapabilityOverride.auto,
}) {
  final capabilities = imageModelCapabilitiesFor(
    providerKind: providerKind,
    model: model,
    capabilityOverride: capabilityOverride,
  );
  final validation = validateImageSizeForModel(
    size: size,
    providerKind: providerKind,
    model: model,
    capabilityOverride: capabilityOverride,
  );
  if (validation.isValid) {
    return validation.dimensions!.size;
  }
  return nearestImageSizePresetInList(
    dimensions: imageDimensionsFromSize(size),
    presets: capabilities.presets,
  ).size;
}

ImageSizeValidationResult validateImageSizeForModel({
  required String size,
  required ApiProviderKind providerKind,
  required String model,
  ImageSizeCapabilityOverride capabilityOverride =
      ImageSizeCapabilityOverride.auto,
}) {
  final capabilities = imageModelCapabilitiesFor(
    providerKind: providerKind,
    model: model,
    capabilityOverride: capabilityOverride,
  );
  final dimensions = tryParseImageDimensions(size);
  if (dimensions == null) {
    return const ImageSizeValidationResult.invalid('请输入有效的宽度和高度。');
  }

  if (capabilities.allowsCustomPixels) {
    return _validateCustomPixelDimensions(
      dimensions,
      capabilities.constraints!,
    );
  }

  final preset = exactImageSizePresetForDimensions(
    dimensions,
    presets: capabilities.presets,
  );
  if (preset == null) {
    final labels = capabilities.presets.map((preset) => preset.size).join('、');
    return ImageSizeValidationResult.invalid('当前模型只支持固定分辨率：$labels。');
  }

  return ImageSizeValidationResult.valid(preset.dimensions);
}

ImageModelCapabilities imageModelCapabilitiesFor({
  required ApiProviderKind providerKind,
  required String model,
  ImageSizeCapabilityOverride capabilityOverride =
      ImageSizeCapabilityOverride.auto,
}) {
  final effectiveOverride = _effectiveImageSizeCapabilityOverride(
    providerKind: providerKind,
    capabilityOverride: capabilityOverride,
  );
  final overrideCapabilities = imageModelCapabilitiesForOverride(
    effectiveOverride,
  );
  if (overrideCapabilities != null) {
    return overrideCapabilities;
  }

  if (providerKind == ApiProviderKind.gemini) {
    return geminiImageCapabilities;
  }

  final normalizedModel = normalizeImageModelName(model);
  if (normalizedModel == 'gpt-image-2') {
    return gptImage2Capabilities;
  }

  return fixedOpenAIImageCapabilities;
}

ImageSizeCapabilityOverride _effectiveImageSizeCapabilityOverride({
  required ApiProviderKind providerKind,
  required ImageSizeCapabilityOverride capabilityOverride,
}) {
  if (providerKind == ApiProviderKind.gemini &&
      capabilityOverride == ImageSizeCapabilityOverride.customPixels) {
    return ImageSizeCapabilityOverride.aspectRatio;
  }
  if (providerKind != ApiProviderKind.gemini &&
      capabilityOverride == ImageSizeCapabilityOverride.aspectRatio) {
    return ImageSizeCapabilityOverride.fixedPresets;
  }
  return capabilityOverride;
}

ImageModelCapabilities? imageModelCapabilitiesForOverride(
  ImageSizeCapabilityOverride override,
) {
  return switch (override) {
    ImageSizeCapabilityOverride.auto => null,
    ImageSizeCapabilityOverride.fixedPresets => fixedOpenAIImageCapabilities,
    ImageSizeCapabilityOverride.customPixels => gptImage2Capabilities,
    ImageSizeCapabilityOverride.aspectRatio => geminiImageCapabilities,
  };
}

String imageSizeCapabilityLabel(ImageModelCapabilities capabilities) {
  return switch (capabilities.sizeMode) {
    ImageSizeMode.fixedPresets => '固定分辨率',
    ImageSizeMode.customPixels => '自定义像素尺寸',
    ImageSizeMode.aspectRatio => '画幅比例',
  };
}

String imageSizeCapabilityOverrideLabel(ImageSizeCapabilityOverride override) {
  return switch (override) {
    ImageSizeCapabilityOverride.auto => '自动识别',
    ImageSizeCapabilityOverride.fixedPresets => '固定分辨率',
    ImageSizeCapabilityOverride.customPixels => '自定义像素尺寸',
    ImageSizeCapabilityOverride.aspectRatio => 'Gemini 画幅比例',
  };
}

String imageSizeCapabilityDescription(ImageModelCapabilities capabilities) {
  final presetSizes = capabilities.presets
      .map((preset) => preset.size)
      .join(' / ');
  return switch (capabilities.sizeMode) {
    ImageSizeMode.fixedPresets => '仅允许固定档位：$presetSizes。',
    ImageSizeMode.customPixels =>
      '允许固定档位或自定义宽高，宽高必须是 '
          '${capabilities.constraints!.step}px 倍数。',
    ImageSizeMode.aspectRatio => '按所选尺寸换算为最接近的 Gemini 画幅比例。',
  };
}

String normalizeImageModelName(String model) {
  return model.trim().toLowerCase().replaceFirst(RegExp(r'^models/'), '');
}

ImageDimensions imageDimensionsFromSize(String size) {
  return tryParseImageDimensions(size) ??
      const ImageDimensions(openAIDefaultImageSide, openAIDefaultImageSide);
}

ImageDimensions? tryParseImageDimensions(String size) {
  final parts = size.toLowerCase().split('x');
  if (parts.length != 2) {
    return null;
  }

  final width = int.tryParse(parts[0].trim());
  final height = int.tryParse(parts[1].trim());
  if (width == null || height == null || width <= 0 || height <= 0) {
    return null;
  }

  return ImageDimensions(width, height);
}

ImageSizePreset nearestImageSizePresetForSize(String size) {
  return nearestImageSizePresetForDimensions(imageDimensionsFromSize(size));
}

ImageSizePreset? exactImageSizePresetForDimensions(
  ImageDimensions dimensions, {
  List<ImageSizePreset> presets = imageSizePresets,
}) {
  for (final preset in presets) {
    if (preset.dimensions == dimensions) {
      return preset;
    }
  }
  return null;
}

ImageSizePreset nearestImageSizePresetForDimensions(
  ImageDimensions dimensions,
) {
  return nearestImageSizePresetInList(
    dimensions: dimensions,
    presets: imageSizePresets,
  );
}

ImageSizePreset nearestImageSizePresetInList({
  required ImageDimensions dimensions,
  required List<ImageSizePreset> presets,
}) {
  final target = dimensions.width > 0 && dimensions.height > 0
      ? dimensions
      : const ImageDimensions(openAIDefaultImageSide, openAIDefaultImageSide);
  var best = presets.first;
  var bestDistance = _presetDistance(best.dimensions, target);

  for (final preset in presets.skip(1)) {
    final distance = _presetDistance(preset.dimensions, target);
    if (distance < bestDistance) {
      best = preset;
      bestDistance = distance;
    }
  }

  return best;
}

String geminiAspectRatioForDimensions(ImageDimensions dimensions) {
  final ratio = dimensions.width / dimensions.height;
  var best = _geminiAspectRatioOptions.first;
  var bestDistance = (ratio - best.value).abs();
  for (final option in _geminiAspectRatioOptions.skip(1)) {
    final distance = (ratio - option.value).abs();
    if (distance < bestDistance) {
      best = option;
      bestDistance = distance;
    }
  }
  return best.label;
}

ImageSizeValidationResult _validateCustomPixelDimensions(
  ImageDimensions dimensions,
  ImageSizeConstraints constraints,
) {
  if (dimensions.width < constraints.minSide ||
      dimensions.height < constraints.minSide) {
    return ImageSizeValidationResult.invalid(
      '宽高都不能小于 ${constraints.minSide}px。',
    );
  }

  if (dimensions.width > constraints.maxSide ||
      dimensions.height > constraints.maxSide) {
    return ImageSizeValidationResult.invalid(
      '宽高都不能超过 ${constraints.maxSide}px。',
    );
  }

  if (dimensions.width % constraints.step != 0 ||
      dimensions.height % constraints.step != 0) {
    return ImageSizeValidationResult.invalid(
      '宽高都必须是 ${constraints.step}px 的倍数。',
    );
  }

  final longSide = math.max(dimensions.width, dimensions.height);
  final shortSide = math.min(dimensions.width, dimensions.height);
  if (longSide > shortSide * constraints.maxAspectRatio) {
    return ImageSizeValidationResult.invalid(
      '长边不能超过短边的 ${constraints.maxAspectRatio} 倍。',
    );
  }

  final pixels = _openAITotalPixels(dimensions);
  if (pixels < constraints.minPixels) {
    return ImageSizeValidationResult.invalid(
      '总像素不能低于 ${constraints.minPixels}。',
    );
  }
  if (pixels > constraints.maxPixels) {
    return ImageSizeValidationResult.invalid(
      '总像素不能超过 ${constraints.maxPixels}。',
    );
  }

  return ImageSizeValidationResult.valid(dimensions);
}

int _openAITotalPixels(ImageDimensions dimensions) {
  return dimensions.width * dimensions.height;
}

double _presetDistance(ImageDimensions preset, ImageDimensions target) {
  final presetRatio = preset.width / preset.height;
  final targetRatio = target.width / target.height;
  final ratioDistance = (math.log(presetRatio / targetRatio)).abs();
  final presetPixels = _openAITotalPixels(preset);
  final targetPixels = _openAITotalPixels(target);
  final pixelDistance = (math.log(presetPixels / targetPixels)).abs();

  return ratioDistance * 4 + pixelDistance;
}

class _GeminiAspectRatioOption {
  const _GeminiAspectRatioOption(this.label, this.width, this.height);

  final String label;
  final int width;
  final int height;

  double get value => width / height;
}

const List<_GeminiAspectRatioOption> _geminiAspectRatioOptions =
    <_GeminiAspectRatioOption>[
      _GeminiAspectRatioOption('1:1', 1, 1),
      _GeminiAspectRatioOption('2:3', 2, 3),
      _GeminiAspectRatioOption('3:2', 3, 2),
      _GeminiAspectRatioOption('3:4', 3, 4),
      _GeminiAspectRatioOption('4:3', 4, 3),
      _GeminiAspectRatioOption('4:5', 4, 5),
      _GeminiAspectRatioOption('5:4', 5, 4),
      _GeminiAspectRatioOption('9:16', 9, 16),
      _GeminiAspectRatioOption('16:9', 16, 9),
      _GeminiAspectRatioOption('21:9', 21, 9),
    ];
