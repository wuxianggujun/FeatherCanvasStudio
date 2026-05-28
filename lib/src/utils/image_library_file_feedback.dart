import '../services/image_library_file_service.dart';

String imageLibraryClipboardCopyMessage({
  required ImageClipboardCopyStatus status,
  required String imageCopiedMessage,
  required String pathCopiedMessage,
}) {
  switch (status) {
    case ImageClipboardCopyStatus.imageCopied:
      return imageCopiedMessage;
    case ImageClipboardCopyStatus.pathCopied:
      return pathCopiedMessage;
  }
}

String imageLibraryOpenLocationMessage({
  required OpenFileLocationStatus status,
  required String openedMessage,
  required String directoryMissingMessage,
  required String copiedUnsupportedPlatformMessage,
  required String copiedAfterFailureMessage,
}) {
  switch (status) {
    case OpenFileLocationStatus.opened:
      return openedMessage;
    case OpenFileLocationStatus.directoryMissing:
      return directoryMissingMessage;
    case OpenFileLocationStatus.copiedUnsupportedPlatform:
      return copiedUnsupportedPlatformMessage;
    case OpenFileLocationStatus.copiedAfterFailure:
      return copiedAfterFailureMessage;
  }
}
