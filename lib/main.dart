import 'package:flutter/material.dart';

void main() {
  runApp(const FeatherCanvasApp());
}

enum ImageProviderType { openAI, stability, comfyUi, custom }

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
  static const List<String> _aspectRatios = <String>[
    '1:1',
    '3:4',
    '4:3',
    '16:9',
    '9:16',
  ];

  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _promptController = TextEditingController(
    text:
        'A clean product render of a futuristic camera on a neutral background',
  );
  final TextEditingController _negativePromptController =
      TextEditingController();

  ImageProviderType _provider = ImageProviderType.openAI;
  String _aspectRatio = '1:1';

  @override
  void dispose() {
    _apiKeyController.dispose();
    _endpointController.dispose();
    _promptController.dispose();
    _negativePromptController.dispose();
    super.dispose();
  }

  String get _providerLabel {
    return switch (_provider) {
      ImageProviderType.openAI => 'OpenAI Images',
      ImageProviderType.stability => 'Stability AI',
      ImageProviderType.comfyUi => 'ComfyUI',
      ImageProviderType.custom => '自定义接口',
    };
  }

  void _generateImage() {
    final messenger = ScaffoldMessenger.of(context);
    final prompt = _promptController.text.trim();

    if (prompt.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('先填写提示词，再开始生成。')));
      return;
    }

    messenger.showSnackBar(
      SnackBar(content: Text('已记录当前参数，后续会接入 $_providerLabel 生成流程。')),
    );
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
            constraints: const BoxConstraints(maxWidth: 1120),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FeatherCanvas Studio',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '一个面向 API 的生图客户端骨架，先把配置、提示词和历史管理串起来。',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  _Section(
                    title: 'API 配置',
                    child: Column(
                      children: [
                        DropdownButtonFormField<ImageProviderType>(
                          initialValue: _provider,
                          decoration: const InputDecoration(labelText: '图片提供方'),
                          items: const [
                            DropdownMenuItem(
                              value: ImageProviderType.openAI,
                              child: Text('OpenAI Images'),
                            ),
                            DropdownMenuItem(
                              value: ImageProviderType.stability,
                              child: Text('Stability AI'),
                            ),
                            DropdownMenuItem(
                              value: ImageProviderType.comfyUi,
                              child: Text('ComfyUI'),
                            ),
                            DropdownMenuItem(
                              value: ImageProviderType.custom,
                              child: Text('自定义接口'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => _provider = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _apiKeyController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'API Key',
                            hintText: '填入你自己的密钥',
                          ),
                        ),
                        if (_provider == ImageProviderType.custom) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _endpointController,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                              labelText: '接口地址',
                              hintText: 'http://127.0.0.1:8188',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: '提示词',
                    child: Column(
                      children: [
                        TextField(
                          controller: _promptController,
                          minLines: 5,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            labelText: '正向提示词',
                            hintText: '描述你想要生成的图片',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _negativePromptController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: '负向提示词',
                            hintText: '描述你不想要出现的内容',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: '生成参数',
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final aspectRatioField =
                            DropdownButtonFormField<String>(
                              initialValue: _aspectRatio,
                              decoration: const InputDecoration(
                                labelText: '画幅比例',
                              ),
                              items: _aspectRatios
                                  .map(
                                    (ratio) => DropdownMenuItem<String>(
                                      value: ratio,
                                      child: Text(ratio),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() => _aspectRatio = value);
                              },
                            );
                        final selectedRatio = Container(
                          height: 56,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '当前比例：$_aspectRatio',
                            style: theme.textTheme.bodyMedium,
                          ),
                        );

                        if (constraints.maxWidth < 640) {
                          return Column(
                            children: [
                              aspectRatioField,
                              const SizedBox(height: 16),
                              selectedRatio,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: aspectRatioField),
                            const SizedBox(width: 16),
                            Expanded(child: selectedRatio),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: _generateImage,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('生成图片'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Section(
                    title: '结果预览',
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 220),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        '生成后的图片会显示在这里',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

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
