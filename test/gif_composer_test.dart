import 'dart:io';

import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;

void main() {
  test('reorders image paths with drag semantics', () {
    final reordered = reorderListItems(
      ['a.png', 'b.png', 'c.png', 'd.png'],
      0,
      3,
    );

    expect(reordered, ['b.png', 'c.png', 'a.png', 'd.png']);
    expect(reorderListItems(['a.png', 'b.png'], 1, 0), ['b.png', 'a.png']);
  });

  test('expands image sequence for gif playback modes', () {
    expect(
      expandGifFrameSequence([
        'a.png',
        'b.png',
        'c.png',
      ], GifPlaybackMode.normal),
      ['a.png', 'b.png', 'c.png'],
    );
    expect(
      expandGifFrameSequence([
        'a.png',
        'b.png',
        'c.png',
      ], GifPlaybackMode.reverse),
      ['c.png', 'b.png', 'a.png'],
    );
    expect(
      expandGifFrameSequence([
        'a.png',
        'b.png',
        'c.png',
      ], GifPlaybackMode.pingPong),
      ['a.png', 'b.png', 'c.png', 'b.png'],
    );
  });

  test('composes multiple images into a gif file', () async {
    final tempDir = await Directory.systemTemp.createTemp('gif_composer_test_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final firstPath = '${tempDir.path}${Platform.pathSeparator}first.png';
    final secondPath = '${tempDir.path}${Platform.pathSeparator}second.png';
    final outputPath = '${tempDir.path}${Platform.pathSeparator}output.gif';

    await File(firstPath).writeAsBytes(
      image_lib.encodePng(
        image_lib.Image(width: 2, height: 2)
          ..clear(image_lib.ColorRgb8(255, 0, 0)),
      ),
    );
    await File(secondPath).writeAsBytes(
      image_lib.encodePng(
        image_lib.Image(width: 2, height: 2)
          ..clear(image_lib.ColorRgb8(0, 255, 0)),
      ),
    );

    final result = await GifComposer.compose(
      frames: [
        GifSourceFrame(id: '1', path: firstPath, delayMs: 120),
        GifSourceFrame(id: '2', path: secondPath, delayMs: 160),
      ],
      outputPath: outputPath,
      loopCount: 0,
      playbackMode: GifPlaybackMode.normal,
    );

    expect(result, outputPath);
    expect(await File(outputPath).exists(), isTrue);
    expect(await File(outputPath).length(), greaterThan(0));
  });

  test('composes a gif into the app store output directory', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'gif_composer_store_test_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final firstFrame = image_lib.encodePng(
      image_lib.Image(width: 2, height: 2)
        ..clear(image_lib.ColorRgb8(255, 0, 0)),
    );
    final secondFrame = image_lib.encodePng(
      image_lib.Image(width: 2, height: 2)
        ..clear(image_lib.ColorRgb8(0, 255, 0)),
    );

    final result = await GifComposer.composeToStore(
      store: AppLocalStore(baseDirectoryOverride: tempDir),
      frames: [
        GifSourceFrame.fromBytes(
          firstFrame,
          sourcePath: 'first.png',
          delayMs: 120,
          seed: 1,
        ),
        GifSourceFrame.fromBytes(
          secondFrame,
          sourcePath: 'second.png',
          delayMs: 160,
          seed: 2,
        ),
      ],
      loopCount: 0,
      playbackMode: GifPlaybackMode.normal,
    );

    expect(result.path, endsWith('.gif'));
    expect(result.directoryPath, contains('generated-images'));
    expect(await File(result.path).exists(), isTrue);
  });
}
