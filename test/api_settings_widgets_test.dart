import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('describes default model list state before first fetch', () {
    expect(
      apiModelFetchHelperText(
        availableModels: const [],
        isFetchingModels: false,
        modelFetchErrorMessage: null,
        modelFetchedAt: null,
      ),
      '尚未获取模型列表',
    );
  });

  test('describes cached model list after a successful fetch', () {
    expect(
      apiModelFetchHelperText(
        availableModels: const [ApiModelInfo(id: 'gpt-image-2')],
        isFetchingModels: false,
        modelFetchErrorMessage: null,
        modelFetchedAt: DateTime(2026, 5, 15, 10, 30),
      ),
      '已缓存 1 个模型，上次成功：2026-05-15 10:30',
    );
  });

  test('distinguishes an empty but successfully fetched model list', () {
    expect(
      apiModelFetchHelperText(
        availableModels: const [],
        isFetchingModels: false,
        modelFetchErrorMessage: null,
        modelFetchedAt: DateTime(2026, 5, 15, 10, 30),
      ),
      '已缓存 0 个模型，上次成功：2026-05-15 10:30',
    );
  });

  test('describes fallback to cached models after a refresh failure', () {
    expect(
      apiModelFetchHelperText(
        availableModels: const [ApiModelInfo(id: 'gpt-image-2')],
        isFetchingModels: false,
        modelFetchErrorMessage: '502 Bad Gateway',
        modelFetchedAt: DateTime(2026, 5, 15, 10, 30),
      ),
      '刷新失败，继续显示 1 个缓存模型，上次成功：2026-05-15 10:30',
    );
  });

  test('describes refresh failure after an empty cached fetch', () {
    expect(
      apiModelFetchHelperText(
        availableModels: const [],
        isFetchingModels: false,
        modelFetchErrorMessage: '502 Bad Gateway',
        modelFetchedAt: DateTime(2026, 5, 15, 10, 30),
      ),
      '模型列表刷新失败，当前缓存为空，上次成功：2026-05-15 10:30',
    );
  });
}
