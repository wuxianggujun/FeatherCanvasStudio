import 'dart:io';

import 'package:feather_canvas_studio/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'delete plan cascades sprite sheet child frames from the same group',
    () {
      final sheet = _item(
        id: 'sheet',
        path: '/tmp/sheet.png',
        kind: ImageAssetKind.spriteSheet,
        groupId: 'group-a',
      );
      final childFrame = _item(
        id: 'frame-1',
        path: '/tmp/frame-1.png',
        kind: ImageAssetKind.spriteFrame,
        groupId: 'group-a',
      );
      final unrelatedFrame = _item(
        id: 'frame-2',
        path: '/tmp/frame-2.png',
        kind: ImageAssetKind.spriteFrame,
        groupId: 'group-b',
      );

      final plan = buildImageLibraryDeletePlan(
        library: [sheet, childFrame, unrelatedFrame],
        selectedItems: [sheet],
      );

      expect(plan.cascadeChildFrames, [childFrame]);
      expect(plan.ids, {'sheet', 'frame-1'});
    },
  );

  test('delete impact splits removed and remaining library items', () {
    final first = _item(id: 'first', path: '/tmp/first.png');
    final second = _item(id: 'second', path: '/tmp/second.png');
    final third = _item(id: 'third', path: '');

    final impact = buildImageLibraryDeleteImpact(
      [first, second, third],
      {'first', 'third'},
    );

    expect(impact.removedItems, [first, third]);
    expect(impact.removedPaths, {'/tmp/first.png'});
    expect(impact.remainingItems, [second]);
  });

  test('reference cleanup removes deleted paths from editor and gif state', () {
    final cleanup = cleanDeletedImageLibraryReferences(
      removedIds: {'deleted-id'},
      removedPaths: {'/tmp/deleted.png', '/tmp/template.png'},
      selectedItemIds: {'deleted-id', 'kept-id'},
      editorImagePath: '/tmp/deleted.png',
      editorPatchImagePath: '/tmp/patch.png',
      animationTemplateImagePath: '/tmp/template.png',
      gifSourceFrames: const [
        GifSourceFrame(id: 'a', path: '/tmp/deleted.png', delayMs: 120),
        GifSourceFrame(id: 'b', path: '/tmp/kept.png', delayMs: 120),
      ],
    );

    expect(cleanup.selectedItemIds, {'kept-id'});
    expect(cleanup.editorImagePath, isNull);
    expect(cleanup.editorPatchImagePath, '/tmp/patch.png');
    expect(cleanup.animationTemplateImagePath, isNull);
    expect(cleanup.gifSourceFrames.map((frame) => frame.id), ['b']);
  });

  test('generation snapshot summary includes reusable request details', () {
    final summary = formatGenerationSnapshotSummary(
      GenerationSnapshot(
        id: 'generation',
        createdAt: DateTime.parse('2026-05-15T12:00:00Z'),
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-image-2',
        providerKind: ApiProviderKind.official,
        prompt: 'draw a small robot',
        negativePrompt: 'blurry',
        size: '1024x1024',
        imageCount: 1,
        resultCount: 2,
        advancedSettings: const ImageAdvancedSettings(
          quality: 'high',
          background: 'transparent',
          outputFormat: 'webp',
          outputCompression: 80,
          moderation: 'low',
          user: 'user-1',
          inputFidelity: 'high',
        ),
      ),
    );

    expect(summary, contains('Provider: OpenAI 官方'));
    expect(summary, contains('Model: gpt-image-2'));
    expect(summary, contains('Output format: webp'));
    expect(summary, contains('User: user-1'));
    expect(summary, contains('Negative: blurry'));
  });

  test('builds reusable generation draft and finds matching API config', () {
    final generation = GenerationSnapshot(
      id: 'generation',
      createdAt: DateTime.parse('2026-05-15T12:00:00Z'),
      baseUrl: 'https://proxy.example.com/v1',
      model: 'gpt-image-2',
      providerKind: ApiProviderKind.compatible,
      prompt: 'draw a robot',
      negativePrompt: '',
      size: '683x1024',
      imageCount: 2,
      resultCount: 2,
      advancedSettings: const ImageAdvancedSettings(user: 'user-1'),
    );

    final draft = buildImageLibraryGenerationReuseDraft(
      generation: generation,
      apiConfigs: const [
        ApiConfig(
          id: 'matching',
          name: 'Matching',
          baseUrl: 'https://proxy.example.com/v1',
          apiKey: 'token',
          model: 'gpt-image-2',
          providerKind: ApiProviderKind.compatible,
        ),
      ],
    );

    expect(draft.matchingConfigId, 'matching');
    expect(draft.size, '683x1024');
    expect(draft.imageCount, 2);
    expect(draft.advancedSettings.user, 'user-1');
  });

  test('reusable generation draft tolerates malformed size strings', () {
    final generation = GenerationSnapshot(
      id: 'generation',
      createdAt: DateTime.parse('2026-05-15T12:00:00Z'),
      baseUrl: 'https://proxy.example.com/v1',
      model: 'gpt-image-2',
      providerKind: ApiProviderKind.compatible,
      prompt: 'draw a robot',
      negativePrompt: '',
      size: 'bad-size',
      imageCount: 1,
      resultCount: 1,
    );

    final draft = buildImageLibraryGenerationReuseDraft(
      generation: generation,
      apiConfigs: const [],
    );

    expect(draft.matchingConfigId, isNull);
    expect(draft.size, '1024x1024');
  });

  test(
    'file service deletes existing files and ignores missing files',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'image_library_file_service_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final file = File('${tempDir.path}${Platform.pathSeparator}stale.png');
      await file.writeAsString('stale');

      const service = ImageLibraryFileService();
      await service.safeDeleteFile(file.path);
      await service.safeDeleteFile(file.path);

      expect(await file.exists(), isFalse);
    },
  );
}

ImageLibraryItem _item({
  required String id,
  required String path,
  ImageAssetKind kind = ImageAssetKind.generatedImage,
  String? groupId,
}) {
  return ImageLibraryItem(
    id: id,
    path: path,
    createdAt: DateTime.parse('2026-05-15T12:00:00Z'),
    kind: kind,
    title: id,
    source: 'test',
    groupId: groupId,
  );
}
