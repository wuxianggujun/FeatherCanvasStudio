import 'package:feather_canvas_studio/feather_canvas_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clipboard copy status maps to the expected message', () {
    expect(
      imageLibraryClipboardCopyMessage(
        status: ImageClipboardCopyStatus.imageCopied,
        imageCopiedMessage: 'image',
        pathCopiedMessage: 'path',
      ),
      'image',
    );
    expect(
      imageLibraryClipboardCopyMessage(
        status: ImageClipboardCopyStatus.pathCopied,
        imageCopiedMessage: 'image',
        pathCopiedMessage: 'path',
      ),
      'path',
    );
  });

  test('open location status maps to the expected message', () {
    expect(
      imageLibraryOpenLocationMessage(
        status: OpenFileLocationStatus.opened,
        openedMessage: 'opened',
        directoryMissingMessage: 'missing',
        copiedUnsupportedPlatformMessage: 'fallback',
        copiedAfterFailureMessage: 'failure',
      ),
      'opened',
    );
    expect(
      imageLibraryOpenLocationMessage(
        status: OpenFileLocationStatus.directoryMissing,
        openedMessage: 'opened',
        directoryMissingMessage: 'missing',
        copiedUnsupportedPlatformMessage: 'fallback',
        copiedAfterFailureMessage: 'failure',
      ),
      'missing',
    );
    expect(
      imageLibraryOpenLocationMessage(
        status: OpenFileLocationStatus.copiedUnsupportedPlatform,
        openedMessage: 'opened',
        directoryMissingMessage: 'missing',
        copiedUnsupportedPlatformMessage: 'fallback',
        copiedAfterFailureMessage: 'failure',
      ),
      'fallback',
    );
    expect(
      imageLibraryOpenLocationMessage(
        status: OpenFileLocationStatus.copiedAfterFailure,
        openedMessage: 'opened',
        directoryMissingMessage: 'missing',
        copiedUnsupportedPlatformMessage: 'fallback',
        copiedAfterFailureMessage: 'failure',
      ),
      'failure',
    );
  });
}
