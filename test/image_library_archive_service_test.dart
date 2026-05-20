import 'dart:convert';
import 'dart:io';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'exports and imports image library archive with assets and metadata',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'image_library_archive_service_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final sourceFile1 = File(
        '${tempDir.path}${Platform.pathSeparator}source-one.png',
      );
      final sourceFile2 = File(
        '${tempDir.path}${Platform.pathSeparator}source-two.webp',
      );
      await sourceFile1.writeAsBytes([1, 2, 3, 4], flush: true);
      await sourceFile2.writeAsBytes([5, 6, 7, 8], flush: true);

      final sourceItems = [
        ImageLibraryItem(
          id: 'source-1',
          path: sourceFile1.path,
          createdAt: DateTime.parse('2026-05-16T10:00:00Z'),
          kind: ImageAssetKind.generatedImage,
          title: 'Source One',
          source: '',
          note: 'kept note',
          tags: const ['hero', 'draft'],
          project: 'game-a',
          prompt: 'hero portrait',
          groupId: 'group-a',
        ),
        ImageLibraryItem(
          id: 'source-2',
          path: sourceFile2.path,
          createdAt: DateTime.parse('2026-05-16T10:01:00Z'),
          kind: ImageAssetKind.spriteSheet,
          title: 'Source Two',
          source: 'Sprite Sheet 导出',
          groupId: 'group-a',
          rows: 2,
          columns: 3,
          gridSpec: const SpriteSheetGridSpec(
            rows: 2,
            columns: 3,
            marginLeft: 1,
            columnGap: 1,
          ),
          frameWidth: 32,
          frameHeight: 32,
        ),
        ImageLibraryItem(
          id: 'missing',
          path: '${tempDir.path}${Platform.pathSeparator}missing.png',
          createdAt: DateTime.parse('2026-05-16T10:02:00Z'),
          kind: ImageAssetKind.generatedImage,
          title: 'Missing',
          source: 'Test',
        ),
      ];
      final archivePath =
          '${tempDir.path}${Platform.pathSeparator}library-export.zip';

      final exportResult = await const ImageLibraryArchiveService()
          .exportArchiveInBackground(
            items: sourceItems,
            outputPath: archivePath,
          );
      final importStore = AppLocalStore(
        baseDirectoryOverride: Directory(
          '${tempDir.path}${Platform.pathSeparator}import-target',
        ),
      );
      final importResult = await const ImageLibraryArchiveService()
          .importArchive(store: importStore, archivePath: archivePath);

      expect(exportResult.path, archivePath);
      expect(exportResult.exportedCount, 2);
      expect(exportResult.skippedMissingCount, 1);
      expect(await File(archivePath).exists(), isTrue);
      expect(importResult.importedCount, 2);
      expect(importResult.skippedItems, 0);

      final importedFirst = importResult.importedItems.first;
      final importedSecond = importResult.importedItems.last;

      expect(importedFirst.id, isNot('source-1'));
      expect(importedFirst.path, isNot(sourceFile1.path));
      expect(await File(importedFirst.path).exists(), isTrue);
      expect(await File(importedSecond.path).exists(), isTrue);
      expect(await File(importedFirst.path).readAsBytes(), [1, 2, 3, 4]);
      expect(await File(importedSecond.path).readAsBytes(), [5, 6, 7, 8]);
      expect(importedFirst.title, 'Source One');
      expect(importedFirst.source, '作品库导入');
      expect(importedFirst.note, 'kept note');
      expect(importedFirst.tags, ['hero', 'draft']);
      expect(importedFirst.project, 'game-a');
      expect(importedFirst.prompt, 'hero portrait');
      expect(importedSecond.source, 'Sprite Sheet 导出');
      expect(importedSecond.rows, 2);
      expect(importedSecond.columns, 3);
      expect(importedSecond.gridSpec?.columns, 3);
      expect(importedSecond.gridSpec?.columnGap, 1);
      expect(importedSecond.frameWidth, 32);
      expect(importedSecond.frameHeight, 32);
      expect(importedFirst.groupId, isNotNull);
      expect(importedSecond.groupId, importedFirst.groupId);
      expect(importedFirst.groupId, isNot('group-a'));
    },
  );

  test('suggests stable timestamped archive names', () {
    expect(
      ImageLibraryArchiveService.suggestedArchiveName(
        now: DateTime(2026, 5, 16, 9, 8),
      ),
      'feather-canvas-library-20260516-0908.zip',
    );
  });

  test(
    'archives animation project json with referenced frame assets',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'image_library_archive_animation_project_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final frameFile = File(
        '${tempDir.path}${Platform.pathSeparator}frame.png',
      );
      final projectFile = File(
        '${tempDir.path}${Platform.pathSeparator}project.json',
      );
      await frameFile.writeAsBytes([9, 8, 7], flush: true);
      await projectFile.writeAsString(
        jsonEncode({
          'id': 'project-1',
          'title': 'Project',
          'createdAt': DateTime.parse('2026-05-17T10:00:00Z').toIso8601String(),
          'updatedAt': DateTime.parse('2026-05-17T10:00:00Z').toIso8601String(),
          'canvasWidth': 4,
          'canvasHeight': 4,
          'tracks': [
            {
              'id': 'track-1',
              'name': 'Track',
              'kind': 'action',
              'visible': true,
              'locked': false,
              'defaultDelayMs': 100,
              'playbackMode': 'normal',
              'clips': [
                {
                  'id': 'clip-1',
                  'name': 'Clip',
                  'startFrame': 0,
                  'loop': true,
                  'frames': [
                    {'assetId': 'asset-1', 'delayMs': 100},
                  ],
                },
              ],
            },
          ],
          'assets': [
            {
              'id': 'asset-1',
              'path': frameFile.path,
              'width': 4,
              'height': 4,
              'source': 'spriteSheetSlice',
            },
          ],
          'timeline': {'defaultFrameDelayMs': 100},
          'exportSettings': {'loopCount': 0},
        }),
        flush: true,
      );

      final sourceItem = ImageLibraryItem(
        id: 'project-item',
        path: projectFile.path,
        createdAt: DateTime.parse('2026-05-17T10:00:00Z'),
        kind: ImageAssetKind.animationProject,
        title: 'Project',
        source: '动画工程',
        groupId: 'project-1',
        animationProject: const AnimationProjectSummary(
          id: 'project-1',
          title: 'Project',
          trackCount: 1,
          frameCount: 1,
          canvasWidth: 4,
          canvasHeight: 4,
        ),
      );
      final archivePath =
          '${tempDir.path}${Platform.pathSeparator}project-export.zip';

      final exportResult = await const ImageLibraryArchiveService()
          .exportArchive(items: [sourceItem], outputPath: archivePath);
      final importStore = AppLocalStore(
        baseDirectoryOverride: Directory(
          '${tempDir.path}${Platform.pathSeparator}import-target',
        ),
      );
      final importResult = await const ImageLibraryArchiveService()
          .importArchive(store: importStore, archivePath: archivePath);

      expect(exportResult.exportedCount, 1);
      expect(exportResult.skippedMissingCount, 0);
      expect(importResult.importedItems, hasLength(1));
      final importedItem = importResult.importedItems.single;
      final importedJson =
          jsonDecode(await File(importedItem.path).readAsString())
              as Map<String, dynamic>;
      final importedAsset = (importedJson['assets'] as List).single as Map;
      final importedFramePath = importedAsset['path'] as String;

      expect(importedItem.kind, ImageAssetKind.animationProject);
      expect(importedItem.groupId, isNot('project-1'));
      expect(importedItem.animationProject?.id, importedItem.groupId);
      expect(importedJson['id'], importedItem.groupId);
      expect(importedFramePath, isNot(frameFile.path));
      expect(await File(importedFramePath).readAsBytes(), [9, 8, 7]);
    },
  );
}
