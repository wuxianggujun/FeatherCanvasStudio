import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_config.dart';
import '../models/app_preset.dart';
import '../models/image_advanced_settings.dart';
import '../models/image_asset_kind.dart';
import '../models/image_library_item.dart';
import '../utils/generation_limits.dart';
import 'secure_value_store.dart';

class AppLocalStore {
  AppLocalStore({
    Directory? baseDirectoryOverride,
    SecureValueStore? secureValueStore,
  }) : _baseDirectoryOverride = baseDirectoryOverride,
       _secureValueStore = secureValueStore ?? const FlutterSecureValueStore();

  final Directory? _baseDirectoryOverride;
  final SecureValueStore _secureValueStore;

  static const String _baseUrlKey = 'settings.baseUrl';
  static const String _apiKeyKey = 'settings.apiKey';
  static const String _modelKey = 'settings.model';
  static const String _promptKey = 'settings.prompt';
  static const String _negativePromptKey = 'settings.negativePrompt';
  static const String _imageToImagePromptKey = 'settings.imageToImagePrompt';
  static const String _imageToImageNegativePromptKey =
      'settings.imageToImageNegativePrompt';
  static const String _sizeKey = 'settings.size';
  static const String _imageCountKey = 'settings.imageCount';
  static const String _apiConfigsKey = 'apiConfigs.entries';
  static const String _selectedApiConfigIdKey = 'apiConfigs.selectedId';
  static const String _imageLibraryKey = 'imageLibrary.entries';
  static const String _appPresetsKey = 'appPresets.entries';
  static const String _onboardingCompletedKey = 'onboarding.completed';
  static const int _maxImageLibraryEntries = 200;
  static const String _apiConfigSecretPrefix = 'apiConfigs.apiKey.';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = AppSettings.defaults();
    final legacyApiKey = prefs.getString(_apiKeyKey);
    final apiKey = await _readSecretWithLegacyMigration(
      secretKey: _apiKeyKey,
      legacyValue: legacyApiKey,
    );
    await prefs.remove(_apiKeyKey);
    return AppSettings(
      baseUrl: prefs.getString(_baseUrlKey) ?? defaults.baseUrl,
      apiKey: apiKey ?? defaults.apiKey,
      model: prefs.getString(_modelKey) ?? defaults.model,
      prompt: prefs.getString(_promptKey) ?? defaults.prompt,
      negativePrompt:
          prefs.getString(_negativePromptKey) ?? defaults.negativePrompt,
      imageToImagePrompt:
          prefs.getString(_imageToImagePromptKey) ??
          defaults.imageToImagePrompt,
      imageToImageNegativePrompt:
          prefs.getString(_imageToImageNegativePromptKey) ??
          defaults.imageToImageNegativePrompt,
      size: prefs.getString(_sizeKey) ?? defaults.size,
      imageCount: normalizeImageGenerationTargetCount(
        prefs.getInt(_imageCountKey) ?? defaults.imageCount,
      ),
      advancedSettings: ImageAdvancedSettings(
        quality:
            prefs.getString('settings.quality') ??
            defaults.advancedSettings.quality,
        background:
            prefs.getString('settings.background') ??
            defaults.advancedSettings.background,
        outputFormat:
            prefs.getString('settings.outputFormat') ??
            defaults.advancedSettings.outputFormat,
        outputCompression:
            prefs.getInt('settings.outputCompression') ??
            defaults.advancedSettings.outputCompression,
        moderation:
            prefs.getString('settings.moderation') ??
            defaults.advancedSettings.moderation,
        user:
            prefs.getString('settings.user') ?? defaults.advancedSettings.user,
        inputFidelity:
            prefs.getString('settings.inputFidelity') ??
            defaults.advancedSettings.inputFidelity,
      ),
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, settings.baseUrl);
    await _writeOrDeleteSecret(_apiKeyKey, settings.apiKey);
    await prefs.remove(_apiKeyKey);
    await prefs.setString(_modelKey, settings.model);
    await prefs.setString(_promptKey, settings.prompt);
    await prefs.setString(_negativePromptKey, settings.negativePrompt);
    await prefs.setString(_imageToImagePromptKey, settings.imageToImagePrompt);
    await prefs.setString(
      _imageToImageNegativePromptKey,
      settings.imageToImageNegativePrompt,
    );
    await prefs.setString(_sizeKey, settings.size);
    await prefs.setInt(_imageCountKey, settings.imageCount);
    await prefs.setString(
      'settings.quality',
      settings.advancedSettings.quality,
    );
    await prefs.setString(
      'settings.background',
      settings.advancedSettings.background,
    );
    await prefs.setString(
      'settings.outputFormat',
      settings.advancedSettings.outputFormat,
    );
    await prefs.setInt(
      'settings.outputCompression',
      settings.advancedSettings.outputCompression,
    );
    await prefs.setString(
      'settings.moderation',
      settings.advancedSettings.moderation,
    );
    await prefs.setString('settings.user', settings.advancedSettings.user);
    await prefs.setString(
      'settings.inputFidelity',
      settings.advancedSettings.inputFidelity,
    );
  }

  Future<List<ApiConfig>> loadApiConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_apiConfigsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    final configs = decoded
        .whereType<Map>()
        .map((entry) => ApiConfig.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
    final migratedConfigs = <ApiConfig>[];
    var shouldRewritePrefs = false;
    for (final config in configs) {
      final rawEntry = decoded.whereType<Map>().firstWhere(
        (entry) => entry['id'] == config.id,
        orElse: () => const {},
      );
      final legacyApiKey = rawEntry['apiKey'] as String?;
      final secretKey = _apiConfigSecretKey(config.id);
      final apiKey = await _readSecretWithLegacyMigration(
        secretKey: secretKey,
        legacyValue: legacyApiKey ?? config.apiKey,
      );
      if (legacyApiKey != null) {
        shouldRewritePrefs = true;
      }
      migratedConfigs.add(config.copyWith(apiKey: apiKey ?? config.apiKey));
    }
    if (shouldRewritePrefs) {
      await saveApiConfigs(migratedConfigs);
    }
    return migratedConfigs;
  }

  Future<void> saveApiConfigs(List<ApiConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    final previousIds = _decodeApiConfigIds(prefs.getString(_apiConfigsKey));
    final nextIds = configs.map((config) => config.id).toSet();
    for (final removedId in previousIds.difference(nextIds)) {
      await _secureValueStore.delete(_apiConfigSecretKey(removedId));
    }
    for (final config in configs) {
      await _writeOrDeleteSecret(_apiConfigSecretKey(config.id), config.apiKey);
    }
    await prefs.setString(
      _apiConfigsKey,
      jsonEncode(configs.map(_apiConfigMetadataJson).toList()),
    );
  }

  Future<String?> loadSelectedApiConfigId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedApiConfigIdKey);
  }

  Future<void> saveSelectedApiConfigId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedApiConfigIdKey, id);
  }

  Future<bool> loadOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> saveOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, completed);
  }

  Future<List<AppPreset>> loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_appPresetsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }

      return decoded
          .whereType<Map>()
          .map((entry) => AppPreset.fromJson(Map<String, dynamic>.from(entry)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> savePresets(List<AppPreset> presets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _appPresetsKey,
      jsonEncode(presets.map((preset) => preset.toJson()).toList()),
    );
  }

  Future<void> addPreset(AppPreset preset) async {
    final presets = await loadPresets();
    final filtered = presets.where((entry) => entry.id != preset.id).toList();
    await savePresets([...filtered, preset]);
  }

  Future<void> deletePreset(String id) async {
    final presets = await loadPresets();
    await savePresets(presets.where((preset) => preset.id != id).toList());
  }

  Future<List<ImageLibraryItem>> loadImageLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_imageLibraryKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    final items = decoded
        .whereType<Map>()
        .map(
          (entry) =>
              ImageLibraryItem.fromJson(Map<String, dynamic>.from(entry)),
        )
        .where((item) => item.path.isNotEmpty)
        .toList();

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(_maxImageLibraryEntries).toList();
  }

  Future<void> saveImageLibrary(List<ImageLibraryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = items.take(_maxImageLibraryEntries).toList();
    await prefs.setString(
      _imageLibraryKey,
      jsonEncode(normalized.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> addImageLibraryItems(List<ImageLibraryItem> items) async {
    if (items.isEmpty) {
      return;
    }

    final library = await loadImageLibrary();
    await saveImageLibrary([...items, ...library]);
  }

  Future<Directory> ensureGeneratedImagesDirectory() async {
    Directory baseDirectory;
    final baseDirectoryOverride = _baseDirectoryOverride;
    if (baseDirectoryOverride != null) {
      baseDirectory = baseDirectoryOverride;
    } else {
      try {
        baseDirectory = await getApplicationSupportDirectory();
      } catch (_) {
        baseDirectory = Directory.systemTemp;
      }
    }
    final directory = Directory(
      '${baseDirectory.path}${Platform.pathSeparator}generated-images',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<File> saveGeneratedImageBytes({
    required String groupId,
    required int index,
    required Uint8List bytes,
    String extension = 'png',
  }) async {
    final directory = await ensureGeneratedImagesDirectory();
    final safeExtension = extension
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toLowerCase();
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      '${groupId}_${(index + 1).toString().padLeft(2, '0')}.${safeExtension.isEmpty ? 'png' : safeExtension}',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> createGeneratedGifFile() async {
    final directory = await ensureGeneratedImagesDirectory();
    return File(
      '${directory.path}${Platform.pathSeparator}gif_${DateTime.now().microsecondsSinceEpoch}.gif',
    );
  }

  Future<Directory> ensureEphemeralDirectory() async {
    Directory baseDirectory;
    final baseDirectoryOverride = _baseDirectoryOverride;
    if (baseDirectoryOverride != null) {
      baseDirectory = baseDirectoryOverride;
    } else {
      try {
        baseDirectory = await getApplicationSupportDirectory();
      } catch (_) {
        baseDirectory = Directory.systemTemp;
      }
    }
    final directory = Directory(
      '${baseDirectory.path}${Platform.pathSeparator}ephemeral',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<File> saveEphemeralBytes({
    required String prefix,
    required Uint8List bytes,
  }) async {
    final directory = await ensureEphemeralDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> createGeneratedSpriteSheetFile({
    required int rows,
    required int columns,
  }) async {
    final directory = await ensureGeneratedImagesDirectory();
    final timestamp = DateTime.now().toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final dateStamp =
        '${timestamp.year}${twoDigits(timestamp.month)}${twoDigits(timestamp.day)}'
        '_${twoDigits(timestamp.hour)}${twoDigits(timestamp.minute)}${twoDigits(timestamp.second)}';
    return File(
      '${directory.path}${Platform.pathSeparator}'
      'sheet_${rows}x${columns}_${dateStamp}_${timestamp.microsecondsSinceEpoch}.png',
    );
  }

  Future<StorageCleanupSummary> cleanupGeneratedFiles({
    required List<ImageLibraryItem> libraryItems,
  }) async {
    final generatedDirectory = await ensureGeneratedImagesDirectory();
    final ephemeralDirectory = await ensureEphemeralDirectory();
    final referencedPaths = await _referencedPathsForLibrary(libraryItems);
    final generatedResult = await _cleanupUnreferencedFiles(
      directory: generatedDirectory,
      referencedPaths: referencedPaths,
    );
    final ephemeralResult = await _cleanupDirectory(ephemeralDirectory);
    return StorageCleanupSummary(
      removedGeneratedFiles: generatedResult.removedFiles,
      removedEphemeralFiles: ephemeralResult.removedFiles,
      freedBytes: generatedResult.freedBytes + ephemeralResult.freedBytes,
    );
  }

  static Future<Set<String>> _referencedPathsForLibrary(
    List<ImageLibraryItem> libraryItems,
  ) async {
    final referencedPaths = <String>{
      for (final item in libraryItems) ...[
        item.path,
        '${item.path}.metadata.json',
      ],
    };
    for (final item in libraryItems) {
      if (item.kind != ImageAssetKind.animationProject || item.path.isEmpty) {
        continue;
      }
      try {
        final decoded = jsonDecode(await File(item.path).readAsString());
        if (decoded is! Map) {
          continue;
        }
        final assets = decoded['assets'];
        if (assets is! List) {
          continue;
        }
        for (final asset in assets.whereType<Map>()) {
          final path = asset['path'];
          if (path is String && path.isNotEmpty) {
            referencedPaths.add(path);
          }
        }
      } catch (_) {
        // 清理失败时保守处理：至少保留工程 JSON 本身。
      }
    }
    return referencedPaths;
  }

  Future<String?> _readSecretWithLegacyMigration({
    required String secretKey,
    required String? legacyValue,
  }) async {
    final storedValue = await _secureValueStore.read(secretKey);
    if (storedValue != null) {
      return storedValue;
    }
    if (legacyValue == null || legacyValue.isEmpty) {
      return null;
    }
    await _secureValueStore.write(secretKey, legacyValue);
    return legacyValue;
  }

  Future<void> _writeOrDeleteSecret(String key, String value) async {
    if (value.isEmpty) {
      await _secureValueStore.delete(key);
      return;
    }
    await _secureValueStore.write(key, value);
  }

  static String _apiConfigSecretKey(String configId) {
    return '$_apiConfigSecretPrefix$configId';
  }

  static Map<String, dynamic> _apiConfigMetadataJson(ApiConfig config) {
    final json = config.toJson();
    json.remove('apiKey');
    return json;
  }

  static Set<String> _decodeApiConfigIds(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const {};
      }
      return decoded
          .whereType<Map>()
          .map((entry) => entry['id'])
          .whereType<String>()
          .toSet();
    } catch (_) {
      return const {};
    }
  }

  static Future<_CleanupResult> _cleanupUnreferencedFiles({
    required Directory directory,
    required Set<String> referencedPaths,
  }) async {
    if (!await directory.exists()) {
      return const _CleanupResult();
    }

    var removedFiles = 0;
    var freedBytes = 0;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || referencedPaths.contains(entity.path)) {
        continue;
      }
      final length = await entity.length();
      await entity.delete();
      removedFiles += 1;
      freedBytes += length;
    }
    return _CleanupResult(removedFiles: removedFiles, freedBytes: freedBytes);
  }

  static Future<_CleanupResult> _cleanupDirectory(Directory directory) async {
    if (!await directory.exists()) {
      return const _CleanupResult();
    }

    var removedFiles = 0;
    var freedBytes = 0;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File) {
        final length = await entity.length();
        await entity.delete();
        removedFiles += 1;
        freedBytes += length;
      }
    }
    return _CleanupResult(removedFiles: removedFiles, freedBytes: freedBytes);
  }
}

class StorageCleanupSummary {
  const StorageCleanupSummary({
    required this.removedGeneratedFiles,
    required this.removedEphemeralFiles,
    required this.freedBytes,
  });

  final int removedGeneratedFiles;
  final int removedEphemeralFiles;
  final int freedBytes;

  int get removedFiles => removedGeneratedFiles + removedEphemeralFiles;
}

class _CleanupResult {
  const _CleanupResult({this.removedFiles = 0, this.freedBytes = 0});

  final int removedFiles;
  final int freedBytes;
}
