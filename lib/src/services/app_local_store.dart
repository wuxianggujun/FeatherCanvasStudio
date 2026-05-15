import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_config.dart';
import '../models/image_advanced_settings.dart';
import '../models/image_library_item.dart';

class AppLocalStore {
  AppLocalStore({Directory? baseDirectoryOverride})
    : _baseDirectoryOverride = baseDirectoryOverride;

  final Directory? _baseDirectoryOverride;

  static const String _baseUrlKey = 'settings.baseUrl';
  static const String _apiKeyKey = 'settings.apiKey';
  static const String _modelKey = 'settings.model';
  static const String _promptKey = 'settings.prompt';
  static const String _negativePromptKey = 'settings.negativePrompt';
  static const String _sizeKey = 'settings.size';
  static const String _imageCountKey = 'settings.imageCount';
  static const String _apiConfigsKey = 'apiConfigs.entries';
  static const String _selectedApiConfigIdKey = 'apiConfigs.selectedId';
  static const String _imageLibraryKey = 'imageLibrary.entries';
  static const int _maxImageLibraryEntries = 200;

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
    await prefs.setString(_apiKeyKey, settings.apiKey);
    await prefs.setString(_modelKey, settings.model);
    await prefs.setString(_promptKey, settings.prompt);
    await prefs.setString(_negativePromptKey, settings.negativePrompt);
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

    return decoded
        .whereType<Map>()
        .map((entry) => ApiConfig.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  Future<void> saveApiConfigs(List<ApiConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _apiConfigsKey,
      jsonEncode(configs.map((config) => config.toJson()).toList()),
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
  }) async {
    final directory = await ensureGeneratedImagesDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}${groupId}_${(index + 1).toString().padLeft(2, '0')}.png',
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
      'sheet_${rows}x${columns}_$dateStamp.png',
    );
  }
}
