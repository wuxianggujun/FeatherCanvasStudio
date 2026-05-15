class ImageGenerationException implements Exception {
  const ImageGenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}
