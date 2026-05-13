import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  static const AppSettings _defaultSettings = AppSettings(
    baseUrl: 'https://api.openai.com/v1',
    apiKey: '',
    model: 'gpt-image-2',
    prompt:
        'A clean product render of a futuristic camera on a neutral background',
    negativePrompt: '',
    size: '1024x1024',
    imageCount: 1,
  );

  final TextEditingController _baseUrlController = TextEditingController(
    text: _defaultSettings.baseUrl,
  );
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelController = TextEditingController(
    text: _defaultSettings.model,
  );
  final TextEditingController _promptController = TextEditingController(
    text: _defaultSettings.prompt,
  );
  final TextEditingController _negativePromptController =
      TextEditingController();

  final OpenAICompatibleImageClient _client = OpenAICompatibleImageClient();
  final AppLocalStore _store = AppLocalStore();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _historySectionKey = GlobalKey();

  String _size = _defaultSettings.size;
  int _imageCount = _defaultSettings.imageCount;
  bool _isGenerating = false;
  bool _showApiKey = false;
  bool _isBootstrapping = true;
  bool _isRestoringState = false;
  String? _errorMessage;
  List<GeneratedImage> _generatedImages = const [];
  List<GenerationHistoryEntry> _history = const [];
  Timer? _settingsSaveDebounce;

  @override
  void initState() {
    super.initState();

    _baseUrlController.addListener(_scheduleSettingsSave);
    _apiKeyController.addListener(_scheduleSettingsSave);
    _modelController.addListener(_scheduleSettingsSave);
    _promptController.addListener(_scheduleSettingsSave);
    _negativePromptController.addListener(_scheduleSettingsSave);

    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _settingsSaveDebounce?.cancel();
    _client.close();
    _scrollController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _promptController.dispose();
    _negativePromptController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final settings = await _store.loadSettings();
    final history = await _store.loadHistory();

    if (!mounted) {
      return;
    }

    _isRestoringState = true;
    _baseUrlController.text = settings.baseUrl;
    _apiKeyController.text = settings.apiKey;
    _modelController.text = settings.model;
    _promptController.text = settings.prompt;
    _negativePromptController.text = settings.negativePrompt;

    setState(() {
      _size = settings.size;
      _imageCount = settings.imageCount;
      _history = history;
      _isBootstrapping = false;
    });
    _isRestoringState = false;
  }

  void _scheduleSettingsSave() {
    if (_isBootstrapping || _isRestoringState) {
      return;
    }

    _settingsSaveDebounce?.cancel();
    _settingsSaveDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_saveSettings());
    });
  }

  Future<void> _saveSettings() async {
    await _store.saveSettings(
      AppSettings(
        baseUrl: _baseUrlController.text.trim(),
        apiKey: _apiKeyController.text,
        model: _modelController.text.trim(),
        prompt: _promptController.text,
        negativePrompt: _negativePromptController.text,
        size: _size,
        imageCount: _imageCount,
      ),
    );
  }

  Future<void> _resetToDefaults() async {
    _settingsSaveDebounce?.cancel();
    _isRestoringState = true;

    _baseUrlController.text = _defaultSettings.baseUrl;
    _apiKeyController.clear();
    _modelController.text = _defaultSettings.model;
    _promptController.text = _defaultSettings.prompt;
    _negativePromptController.clear();

    setState(() {
      _size = _defaultSettings.size;
      _imageCount = _defaultSettings.imageCount;
      _errorMessage = null;
      _generatedImages = const [];
    });

    _isRestoringState = false;
    await _saveSettings();
    if (mounted) {
      _showMessage('表单已重置。');
    }
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

    await _saveSettings();

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
      final historyEntry = GenerationHistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        baseUrl: _baseUrlController.text.trim(),
        model: _modelController.text.trim(),
        prompt: prompt,
        negativePrompt: _negativePromptController.text.trim(),
        size: _size,
        imageCount: _imageCount,
        resultCount: response.images.length,
      );
      await _store.addHistoryEntry(historyEntry);
      if (mounted) {
        setState(() => _history = [historyEntry, ..._history]);
      }
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

  Future<void> _reuseHistoryEntry(GenerationHistoryEntry entry) async {
    _isRestoringState = true;
    _baseUrlController.text = entry.baseUrl;
    _modelController.text = entry.model;
    _promptController.text = entry.prompt;
    _negativePromptController.text = entry.negativePrompt;

    setState(() {
      _size = entry.size;
      _imageCount = entry.imageCount;
      _errorMessage = null;
    });

    _isRestoringState = false;
    await _saveSettings();
    _showMessage('已载入历史参数。');
  }

  Future<void> _deleteHistoryEntry(String id) async {
    final nextHistory = _history.where((entry) => entry.id != id).toList();
    await _store.saveHistory(nextHistory);
    if (!mounted) {
      return;
    }
    setState(() => _history = nextHistory);
  }

  Future<void> _clearHistory() async {
    await _store.saveHistory(const []);
    if (!mounted) {
      return;
    }
    setState(() => _history = const []);
    _showMessage('历史记录已清空。');
  }

  Future<void> _scrollToHistory() async {
    final context = _historySectionKey.currentContext;
    if (context == null) {
      return;
    }

    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  Future<void> _showSettingsDialog() async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('本地设置'),
          content: const Text('这里可以重置本地表单或清空历史记录。'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetToDefaults();
              },
              child: const Text('重置表单'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _clearHistory();
              },
              child: const Text('清空历史'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isBootstrapping) {
      return Scaffold(
        appBar: AppBar(title: const Text('FeatherCanvas Studio')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('FeatherCanvas Studio'),
        actions: [
          Tooltip(
            message: '历史记录',
            child: IconButton(
              onPressed: _scrollToHistory,
              icon: const Icon(Icons.history_outlined),
            ),
          ),
          Tooltip(
            message: '设置',
            child: IconButton(
              onPressed: _showSettingsDialog,
              icon: const Icon(Icons.settings_outlined),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: SingleChildScrollView(
              controller: _scrollController,
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
                  const SizedBox(height: 20),
                  _HistoryPanel(
                    key: _historySectionKey,
                    entries: _history,
                    onReuse: _reuseHistoryEntry,
                    onDelete: _deleteHistoryEntry,
                    onClear: _history.isEmpty ? null : _clearHistory,
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
  const _Panel({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

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
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    super.key,
    required this.entries,
    required this.onReuse,
    required this.onDelete,
    required this.onClear,
  });

  final List<GenerationHistoryEntry> entries;
  final ValueChanged<GenerationHistoryEntry> onReuse;
  final ValueChanged<String> onDelete;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _Panel(
      title: '生成历史',
      trailing: onClear == null
          ? null
          : TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('清空'),
            ),
      child: entries.isEmpty
          ? Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 120),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                '暂无历史记录，生成一次图片后会自动保存。',
                style: theme.textTheme.bodyMedium,
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < entries.length; index++) ...[
                  _HistoryEntryTile(
                    entry: entries[index],
                    onReuse: onReuse,
                    onDelete: onDelete,
                  ),
                  if (index != entries.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _HistoryEntryTile extends StatelessWidget {
  const _HistoryEntryTile({
    required this.entry,
    required this.onReuse,
    required this.onDelete,
  });

  final GenerationHistoryEntry entry;
  final ValueChanged<GenerationHistoryEntry> onReuse;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onReuse(entry),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.image_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shorten(entry.prompt.replaceAll('\n', ' '), 80),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${entry.model} · ${entry.size} · ${entry.imageCount} 张 · ${entry.resultCount} 结果 · ${_formatTimestamp(entry.createdAt)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Tooltip(
                    message: '复用参数',
                    child: IconButton(
                      onPressed: () => onReuse(entry),
                      icon: const Icon(Icons.restore_outlined),
                    ),
                  ),
                  Tooltip(
                    message: '删除记录',
                    child: IconButton(
                      onPressed: () => onDelete(entry.id),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _shorten(String text, int maxLength) {
  if (text.length <= maxLength) {
    return text;
  }

  return '${text.substring(0, maxLength - 1)}…';
}

String _formatTimestamp(DateTime value) {
  final local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
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

class AppSettings {
  const AppSettings({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.prompt,
    required this.negativePrompt,
    required this.size,
    required this.imageCount,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      baseUrl: 'https://api.openai.com/v1',
      apiKey: '',
      model: 'gpt-image-2',
      prompt:
          'A clean product render of a futuristic camera on a neutral background',
      negativePrompt: '',
      size: '1024x1024',
      imageCount: 1,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final defaults = AppSettings.defaults();
    return AppSettings(
      baseUrl: json['baseUrl'] as String? ?? defaults.baseUrl,
      apiKey: json['apiKey'] as String? ?? defaults.apiKey,
      model: json['model'] as String? ?? defaults.model,
      prompt: json['prompt'] as String? ?? defaults.prompt,
      negativePrompt:
          json['negativePrompt'] as String? ?? defaults.negativePrompt,
      size: json['size'] as String? ?? defaults.size,
      imageCount: (json['imageCount'] as num?)?.toInt() ?? defaults.imageCount,
    );
  }

  final String baseUrl;
  final String apiKey;
  final String model;
  final String prompt;
  final String negativePrompt;
  final String size;
  final int imageCount;

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
      'prompt': prompt,
      'negativePrompt': negativePrompt,
      'size': size,
      'imageCount': imageCount,
    };
  }
}

class GenerationHistoryEntry {
  const GenerationHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.baseUrl,
    required this.model,
    required this.prompt,
    required this.negativePrompt,
    required this.size,
    required this.imageCount,
    required this.resultCount,
  });

  factory GenerationHistoryEntry.fromJson(Map<String, dynamic> json) {
    return GenerationHistoryEntry(
      id: json['id'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      baseUrl: json['baseUrl'] as String? ?? '',
      model: json['model'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      negativePrompt: json['negativePrompt'] as String? ?? '',
      size: json['size'] as String? ?? '',
      imageCount: (json['imageCount'] as num?)?.toInt() ?? 1,
      resultCount: (json['resultCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final DateTime createdAt;
  final String baseUrl;
  final String model;
  final String prompt;
  final String negativePrompt;
  final String size;
  final int imageCount;
  final int resultCount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'baseUrl': baseUrl,
      'model': model,
      'prompt': prompt,
      'negativePrompt': negativePrompt,
      'size': size,
      'imageCount': imageCount,
      'resultCount': resultCount,
    };
  }
}

class AppLocalStore {
  static const String _baseUrlKey = 'settings.baseUrl';
  static const String _apiKeyKey = 'settings.apiKey';
  static const String _modelKey = 'settings.model';
  static const String _promptKey = 'settings.prompt';
  static const String _negativePromptKey = 'settings.negativePrompt';
  static const String _sizeKey = 'settings.size';
  static const String _imageCountKey = 'settings.imageCount';
  static const String _historyKey = 'history.entries';
  static const int _maxHistoryEntries = 20;

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = AppSettings.defaults();
    return AppSettings(
      baseUrl: prefs.getString(_baseUrlKey) ?? defaults.baseUrl,
      apiKey: prefs.getString(_apiKeyKey) ?? defaults.apiKey,
      model: prefs.getString(_modelKey) ?? defaults.model,
      prompt: prefs.getString(_promptKey) ?? defaults.prompt,
      negativePrompt:
          prefs.getString(_negativePromptKey) ?? defaults.negativePrompt,
      size: prefs.getString(_sizeKey) ?? defaults.size,
      imageCount: prefs.getInt(_imageCountKey) ?? defaults.imageCount,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, settings.baseUrl);
    await prefs.setString(_apiKeyKey, settings.apiKey);
    await prefs.setString(_modelKey, settings.model);
    await prefs.setString(_promptKey, settings.prompt);
    await prefs.setString(_negativePromptKey, settings.negativePrompt);
    await prefs.setString(_sizeKey, settings.size);
    await prefs.setInt(_imageCountKey, settings.imageCount);
  }

  Future<List<GenerationHistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (entry) =>
              GenerationHistoryEntry.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList()
        .reversed
        .toList();
  }

  Future<void> saveHistory(List<GenerationHistoryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = history.take(_maxHistoryEntries).toList();
    await prefs.setString(
      _historyKey,
      jsonEncode(normalized.reversed.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> addHistoryEntry(GenerationHistoryEntry entry) async {
    final history = await loadHistory();
    await saveHistory([entry, ...history]);
  }
}
