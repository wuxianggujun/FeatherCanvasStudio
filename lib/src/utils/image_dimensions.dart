import '../models/api_provider.dart';

const int openAIImageSizeStep = 16;
const int openAIDefaultImageSide = 1024;
const int openAIMinImageSide = 256;
const int openAIMaxImageSide = 4096;
const int openAIMaxImageAspectRatio = 4;

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

String requestSizeForProvider(String size, ApiProviderKind providerKind) {
  return requestDimensionsForProvider(
    imageDimensionsFromSize(size),
    providerKind,
  ).size;
}

ImageDimensions imageDimensionsFromSize(String size) {
  final parts = size.toLowerCase().split('x');
  if (parts.length != 2) {
    return const ImageDimensions(
      openAIDefaultImageSide,
      openAIDefaultImageSide,
    );
  }

  final width = int.tryParse(parts[0].trim());
  final height = int.tryParse(parts[1].trim());
  if (width == null || height == null || width <= 0 || height <= 0) {
    return const ImageDimensions(
      openAIDefaultImageSide,
      openAIDefaultImageSide,
    );
  }

  return ImageDimensions(width, height);
}

ImageDimensions requestDimensionsForProvider(
  ImageDimensions dimensions,
  ApiProviderKind providerKind,
) {
  if (providerKind == ApiProviderKind.gemini) {
    return dimensions;
  }

  return normalizeOpenAIImageDimensions(dimensions);
}

ImageDimensions normalizeOpenAIImageDimensions(ImageDimensions dimensions) {
  var width = _snapImageSideToStep(dimensions.width);
  var height = _snapImageSideToStep(dimensions.height);
  if (width > height * openAIMaxImageAspectRatio) {
    height = _ceilImageSideToStep(width ~/ openAIMaxImageAspectRatio);
  } else if (height > width * openAIMaxImageAspectRatio) {
    width = _ceilImageSideToStep(height ~/ openAIMaxImageAspectRatio);
  }
  return ImageDimensions(width, height);
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

int _snapImageSideToStep(int value) {
  final clamped = value.clamp(openAIMinImageSide, openAIMaxImageSide).toInt();
  final snapped = (clamped / openAIImageSizeStep).round() * openAIImageSizeStep;
  return snapped.clamp(openAIMinImageSide, openAIMaxImageSide).toInt();
}

int _ceilImageSideToStep(int value) {
  final clamped = value.clamp(openAIMinImageSide, openAIMaxImageSide).toInt();
  final snapped =
      ((clamped + openAIImageSizeStep - 1) ~/ openAIImageSizeStep) *
      openAIImageSizeStep;
  return snapped.clamp(openAIMinImageSide, openAIMaxImageSide).toInt();
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
