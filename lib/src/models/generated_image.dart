import 'dart:typed_data';

class GeneratedImage {
  const GeneratedImage._({
    required this.bytes,
    required this.url,
    required this.filePath,
    required this.revisedPrompt,
  });

  factory GeneratedImage.bytes(Uint8List bytes, {String? revisedPrompt}) {
    return GeneratedImage._(
      bytes: bytes,
      url: null,
      filePath: null,
      revisedPrompt: revisedPrompt,
    );
  }

  factory GeneratedImage.url(String url, {String? revisedPrompt}) {
    return GeneratedImage._(
      bytes: null,
      url: url,
      filePath: null,
      revisedPrompt: revisedPrompt,
    );
  }

  factory GeneratedImage.file(String filePath, {String? revisedPrompt}) {
    return GeneratedImage._(
      bytes: null,
      url: null,
      filePath: filePath,
      revisedPrompt: revisedPrompt,
    );
  }

  final Uint8List? bytes;
  final String? url;
  final String? filePath;
  final String? revisedPrompt;
}
