import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const FeatherCanvasApp());
}

class FeatherCanvasApp extends StatelessWidget {
  const FeatherCanvasApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'FeatherCanvas Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      home: const FeatherCanvasHomePage(),
    );
  }
}

class FeatherCanvasHomePage extends StatefulWidget {
  const FeatherCanvasHomePage({super.key});

  @override
  State<FeatherCanvasHomePage> createState() => _FeatherCanvasHomePageState();
}

class _FeatherCanvasHomePageState extends State<FeatherCanvasHomePage> {
  static const List<String> _sizes = <String>[
    '1024x1024',
    '1024x1536',
    '1536x1024',
    'auto',
  ];

  final TextEditingController _baseUrlController = TextEditingController(
    text: 'https://api.openai.com/v1',
  );
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelController = TextEditingController(
    text: 'gpt-image-2',
  );
  final TextEditingController _promptController = TextEditingController(
    text:
        'A clean product render of a futuristic camera on a neutral background',
  );
  final TextEditingController _negativePromptController =
      TextEditingController();

  final OpenAICompatibleImageClient _client = OpenAICompatibleImageClient();

  String _size = '1024x1024';
  int _imageCount = 1;
  bool _isGenerating = false;
  bool _showApiKey = false;
  String? _errorMessage;
  List<GeneratedImage> _generatedImages = const [];

  @override
  void dispose() {
    _client.close();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _promptController.dispose();
    _negativePromptController.dispose();
    super.dispose();
  }

  Future<void> _generateImage() async {
    final apiKey = _apiKeyController.text.trim();
    final prompt = _promptController.text.trim();

    if (apiKey.isEmpty) {
      _showMessage('请先填写 API Key。');
      return;
    }

    if (prompt.isEmpty) {
      _showMessage('请先填写正向提示词。');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedImages = const [];
    });

    try {
      final response = await _client.generate(
        OpenAIImageRequest(
          baseUrl: _baseUrlController.text.trim(),
          apiKey: apiKey,
          model: _modelController.text.trim(),
          prompt: prompt,
          negativePrompt: _negativePromptController.text.trim(),
          size: _size,
          imageCount: _imageCount,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() => _generatedImages = response.images);
      _showMessage('图片生成完成。');
    } on ImageGenerationException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = '请求超时，请检查接口地址或稍后重试。');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = '生成失败：$error');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FeatherCanvas Studio'),
        actions: const [
          Tooltip(
            message: '历史记录',
            child: IconButton(
              onPressed: null,
              icon: Icon(Icons.history_outlined),
            ),
          ),
          SizedBox(width: 4),
          Tooltip(
            message: '设置',
            child: IconButton(
              onPressed: null,
              icon: Icon(Icons.settings_outlined),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OpenAI 兼容生图', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    '填写兼容 OpenAI Images 的接口地址和密钥，然后用统一格式生成图片。',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final controls = _ControlPanel(
                        baseUrlController: _baseUrlController,
                        apiKeyController: _apiKeyController,
                        modelController: _modelController,
                        promptController: _promptController,
                        negativePromptController: _negativePromptController,
                        size: _size,
                        sizes: _sizes,
                        imageCount: _imageCount,
                        showApiKey: _showApiKey,
                        isGenerating: _isGenerating,
                        onSizeChanged: (value) => setState(() => _size = value),
                        onImageCountChanged: (value) =>
                            setState(() => _imageCount = value),
                        onToggleApiKeyVisibility: () =>
                            setState(() => _showApiKey = !_showApiKey),
                        onGenerate: _generateImage,
                      );
                      final preview = _PreviewPanel(
                        errorMessage: _errorMessage,
                        generatedImages: _generatedImages,
                        isGenerating: _isGenerating,
                      );

                      if (constraints.maxWidth < 900) {
                        return Column(
                          children: [
                            controls,
                            const SizedBox(height: 20),
                            preview,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 430, child: controls),
                          const SizedBox(width: 20),
                          Expanded(child: preview),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.baseUrlController,
    required this.apiKeyController,
    required this.modelController,
    required this.promptController,
    required this.negativePromptController,
    required this.size,
    required this.sizes,
    required this.imageCount,
    required this.showApiKey,
    required this.isGenerating,
    required this.onSizeChanged,
    required this.onImageCountChanged,
    required this.onToggleApiKeyVisibility,
    required this.onGenerate,
  });

  final TextEditingController baseUrlController;
  final TextEditingController apiKeyController;
  final TextEditingController modelController;
  final TextEditingController promptController;
  final TextEditingController negativePromptController;
  final String size;
  final List<String> sizes;
  final int imageCount;
  final bool showApiKey;
  final bool isGenerating;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<int> onImageCountChanged;
  final VoidCallback onToggleApiKeyVisibility;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: '生成配置',
      child: Column(
        children: [
          TextField(
            controller: baseUrlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Base URL',
              hintText: 'https://api.openai.com/v1',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: apiKeyController,
            obscureText: !showApiKey,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'sk-...',
              suffixIcon: IconButton(
                tooltip: showApiKey ? '隐藏密钥' : '显示密钥',
                onPressed: onToggleApiKeyVisibility,
                icon: Icon(
                  showApiKey
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: modelController,
            decoration: const InputDecoration(
              labelText: '模型',
              hintText: 'gpt-image-2',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: promptController,
            minLines: 5,
            maxLines: 9,
            decoration: const InputDecoration(
              labelText: '正向提示词',
              hintText: '描述你想生成的图片',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: negativePromptController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: '负向提示词',
              hintText: '会合并到 prompt 中，不额外发送非 OpenAI 字段',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          _ResponsivePair(
            first: DropdownButtonFormField<String>(
              initialValue: size,
              decoration: const InputDecoration(labelText: '尺寸'),
              items: sizes
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onSizeChanged(value);
                }
              },
            ),
            second: DropdownButtonFormField<int>(
              initialValue: imageCount,
              decoration: const InputDecoration(labelText: '数量'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 张')),
                DropdownMenuItem(value: 2, child: Text('2 张')),
                DropdownMenuItem(value: 3, child: Text('3 张')),
                DropdownMenuItem(value: 4, child: Text('4 张')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onImageCountChanged(value);
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isGenerating ? null : onGenerate,
              icon: isGenerating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(isGenerating ? '生成中' : '生成图片'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.errorMessage,
    required this.generatedImages,
    required this.isGenerating,
  });

  final String? errorMessage;
  final List<GeneratedImage> generatedImages;
  final bool isGenerating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _Panel(
      title: '结果预览',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: _buildContent(context, theme),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    if (isGenerating) {
      return const SizedBox(
        key: ValueKey('loading'),
        height: 420,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Container(
        key: const ValueKey('error'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          errorMessage!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onErrorContainer,
          ),
        ),
      );
    }

    if (generatedImages.isEmpty) {
      return Container(
        key: const ValueKey('empty'),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 420),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Text('生成后的图片会显示在这里', style: theme.textTheme.bodyLarge),
      );
    }

    return LayoutBuilder(
      key: const ValueKey('images'),
      builder: (context, constraints) {
        final width = generatedImages.length <= 1 || constraints.maxWidth < 540
            ? constraints.maxWidth
            : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final image in generatedImages)
              SizedBox(
                width: width,
                child: _GeneratedImageTile(image: image),
              ),
          ],
        );
      },
    );
  }
}

class _GeneratedImageTile extends StatelessWidget {
  const _GeneratedImageTile({required this.image});

  final GeneratedImage image;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 1,
            child: ColoredBox(
              color: theme.colorScheme.surfaceContainerHighest,
              child: image.bytes != null
                  ? Image.memory(image.bytes!, fit: BoxFit.cover)
                  : Image.network(
                      image.url!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('图片加载失败：$error'),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
        if (image.revisedPrompt != null && image.revisedPrompt!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            image.revisedPrompt!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(children: [first, const SizedBox(height: 16), second]);
        }

        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 16),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class OpenAICompatibleImageClient {
  OpenAICompatibleImageClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<OpenAIImageResponse> generate(OpenAIImageRequest request) async {
    final endpoint = request.endpoint;
    final response = await _httpClient
        .post(
          endpoint,
          headers: {
            'Authorization': 'Bearer ${request.apiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(minutes: 2));

    final decoded = _decodeJsonObject(response.bodyBytes);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ImageGenerationException(
        _extractErrorMessage(decoded) ??
            '请求失败：HTTP ${response.statusCode} ${response.reasonPhrase ?? ''}',
      );
    }

    final data = decoded['data'];
    if (data is! List || data.isEmpty) {
      throw const ImageGenerationException('接口没有返回图片数据。');
    }

    final images = <GeneratedImage>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final b64Json = item['b64_json'];
      final url = item['url'];
      final revisedPrompt = item['revised_prompt'];

      if (b64Json is String && b64Json.trim().isNotEmpty) {
        images.add(
          GeneratedImage.bytes(
            _decodeBase64Image(b64Json),
            revisedPrompt: revisedPrompt is String ? revisedPrompt : null,
          ),
        );
        continue;
      }

      if (url is String && url.trim().isNotEmpty) {
        images.add(
          GeneratedImage.url(
            url,
            revisedPrompt: revisedPrompt is String ? revisedPrompt : null,
          ),
        );
      }
    }

    if (images.isEmpty) {
      throw const ImageGenerationException('接口返回了 data，但未包含 b64_json 或 url。');
    }

    return OpenAIImageResponse(images: images);
  }

  void close() => _httpClient.close();

  static Map<String, dynamic> _decodeJsonObject(List<int> bodyBytes) {
    final decoded = jsonDecode(utf8.decode(bodyBytes));
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const ImageGenerationException('接口返回的不是 JSON 对象。');
  }

  static Uint8List _decodeBase64Image(String value) {
    final normalized = value.contains(',') ? value.split(',').last : value;
    return base64Decode(normalized.trim());
  }

  static String? _extractErrorMessage(Map<String, dynamic> decoded) {
    final error = decoded['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    final message = decoded['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    return null;
  }
}

class OpenAIImageRequest {
  const OpenAIImageRequest({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.prompt,
    required this.negativePrompt,
    required this.size,
    required this.imageCount,
  });

  final String baseUrl;
  final String apiKey;
  final String model;
  final String prompt;
  final String negativePrompt;
  final String size;
  final int imageCount;

  Uri get endpoint {
    final normalizedBaseUrl = _normalizeBaseUrl(baseUrl);
    if (normalizedBaseUrl.endsWith('/images/generations')) {
      return Uri.parse(normalizedBaseUrl);
    }

    return Uri.parse('$normalizedBaseUrl/images/generations');
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model.isEmpty ? 'gpt-image-2' : model,
      'prompt': _mergedPrompt,
      'size': size,
      'n': imageCount,
    };
  }

  String get _mergedPrompt {
    final negative = negativePrompt.trim();
    if (negative.isEmpty) {
      return prompt;
    }

    return '$prompt\n\nAvoid: $negative';
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    final fallback = trimmed.isEmpty ? 'https://api.openai.com/v1' : trimmed;
    return fallback.replaceFirst(RegExp(r'/+$'), '');
  }
}

class OpenAIImageResponse {
  const OpenAIImageResponse({required this.images});

  final List<GeneratedImage> images;
}

class GeneratedImage {
  const GeneratedImage._({
    required this.bytes,
    required this.url,
    required this.revisedPrompt,
  });

  factory GeneratedImage.bytes(Uint8List bytes, {String? revisedPrompt}) {
    return GeneratedImage._(
      bytes: bytes,
      url: null,
      revisedPrompt: revisedPrompt,
    );
  }

  factory GeneratedImage.url(String url, {String? revisedPrompt}) {
    return GeneratedImage._(
      bytes: null,
      url: url,
      revisedPrompt: revisedPrompt,
    );
  }

  final Uint8List? bytes;
  final String? url;
  final String? revisedPrompt;
}

class ImageGenerationException implements Exception {
  const ImageGenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}
