import '../models/app_config.dart';
import 'display_labels.dart';
import 'image_dimensions.dart';

String formatGenerationSnapshotSummary(GenerationSnapshot generation) {
  return [
    'Provider: ${apiProviderKindLabel(generation.providerKind)}',
    'Base URL: ${generation.baseUrl}',
    'Model: ${generation.model}',
    'Size capability: '
        '${imageSizeCapabilityOverrideLabel(generation.imageSizeCapabilityOverride)}',
    'Size: ${generation.size}',
    'Count: ${generation.imageCount}',
    'Result count: ${generation.resultCount}',
    'Quality: ${generation.advancedSettings.quality}',
    'Background: ${generation.advancedSettings.background}',
    'Output format: ${generation.advancedSettings.outputFormat}',
    'Output compression: ${generation.advancedSettings.outputCompression}',
    'Moderation: ${generation.advancedSettings.moderation}',
    if (generation.advancedSettings.user.trim().isNotEmpty)
      'User: ${generation.advancedSettings.user}',
    'Input fidelity: ${generation.advancedSettings.inputFidelity}',
    'Prompt: ${generation.prompt}',
    if (generation.negativePrompt.trim().isNotEmpty)
      'Negative: ${generation.negativePrompt}',
  ].join('\n');
}
