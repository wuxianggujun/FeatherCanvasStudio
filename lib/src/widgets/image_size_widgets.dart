import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_l10n.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/api_provider.dart';
import '../models/app_config.dart';
import '../theme/layout_constants.dart';
import '../utils/image_dimensions.dart';
import '../utils/localized_display_labels.dart';
import 'common_form_widgets.dart';

const String _customSizeValue = '__custom_pixels__';

enum _ImagePresetOrientation { square, landscape, portrait }

class ImageSizeInput extends StatefulWidget {
  const ImageSizeInput({
    required this.size,
    required this.providerKind,
    required this.model,
    required this.capabilityOverride,
    required this.onChanged,
    this.compact = false,
    this.enabled = true,
    this.onValidityChanged,
    super.key,
  });

  final String size;
  final ApiProviderKind providerKind;
  final String model;
  final ImageSizeCapabilityOverride capabilityOverride;
  final ValueChanged<String> onChanged;
  final bool compact;
  final bool enabled;
  final ValueChanged<bool>? onValidityChanged;

  @override
  State<ImageSizeInput> createState() => _ImageSizeInputState();
}

class _ImageSizeInputState extends State<ImageSizeInput> {
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    final dimensions = imageDimensionsFromSize(widget.size);
    _widthController = TextEditingController(text: dimensions.width.toString());
    _heightController = TextEditingController(
      text: dimensions.height.toString(),
    );
    _selectedValue = _selectedValueFor(widget.size);
    _notifyValidity();
  }

  @override
  void didUpdateWidget(covariant ImageSizeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.size == widget.size &&
        oldWidget.providerKind == widget.providerKind &&
        oldWidget.model == widget.model &&
        oldWidget.capabilityOverride == widget.capabilityOverride) {
      return;
    }

    final dimensions = tryParseImageDimensions(widget.size);
    if (dimensions != null) {
      _setControllerText(_widthController, dimensions.width.toString());
      _setControllerText(_heightController, dimensions.height.toString());
    }
    _selectedValue = _selectedValueFor(widget.size);
    _notifyValidity();
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10nOf(context);
    final imageSizeLabels = localizedImageSizeDisplayLabels(l10n);
    final capabilities = imageModelCapabilitiesFor(
      providerKind: widget.providerKind,
      model: widget.model,
      capabilityOverride: widget.capabilityOverride,
    );
    final validation = validateImageSizeForModel(
      size: widget.size,
      providerKind: widget.providerKind,
      model: widget.model,
      capabilityOverride: widget.capabilityOverride,
      labels: imageSizeLabels,
    );
    final isCustom = _selectedValue == _customSizeValue;
    final picker = capabilities.allowsCustomPixels
        ? _customPixelPresetPicker(l10n, capabilities)
        : _presetPicker(l10n, capabilities);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        picker,
        if (isCustom) ...[
          const SizedBox(height: fieldGap),
          ResponsivePair(
            first: _customSideInput(
              l10n: l10n,
              controller: _widthController,
              label: l10n.imageSizeWidth,
            ),
            second: _customSideInput(
              l10n: l10n,
              controller: _heightController,
              label: l10n.imageSizeHeight,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          _buildHelperText(l10n, capabilities, validation),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: validation.isValid
                ? null
                : Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _presetPicker(
    AppLocalizations l10n,
    ImageModelCapabilities capabilities,
  ) {
    final label = _pickerLabel(l10n, capabilities);
    final selectedLabel = _selectedValue == _customSizeValue
        ? l10n.imageSizeCustomSize
        : _presetLabelForValue(l10n, capabilities, _selectedValue);

    return Semantics(
      container: true,
      label: label,
      value: selectedLabel,
      enabled: widget.enabled,
      child: DropdownButtonFormField<String>(
        key: ValueKey(
          '${widget.providerKind}:${widget.model}:'
          '${widget.capabilityOverride}:$_selectedValue',
        ),
        decoration: InputDecoration(labelText: label),
        initialValue: _selectedValue,
        items: [
          for (final preset in capabilities.presets)
            DropdownMenuItem<String>(
              value: preset.size,
              child: Text(_presetMenuLabel(l10n, preset)),
            ),
        ],
        onChanged: widget.enabled
            ? (value) {
                if (value != null) {
                  _applySelection(value);
                }
              }
            : null,
      ),
    );
  }

  Widget _customPixelPresetPicker(
    AppLocalizations l10n,
    ImageModelCapabilities capabilities,
  ) {
    final scaleValues = _scaleValuesFor(capabilities);
    final selectedPreset = _selectedPresetFor(capabilities);
    final selectedScale = _selectedValue == _customSizeValue
        ? _customSizeValue
        : selectedPreset == null
        ? scaleValues.first
        : imageSizePresetScaleLabel(selectedPreset);
    final availableOrientations = selectedScale == _customSizeValue
        ? <_ImagePresetOrientation>[]
        : _orientationsForScale(capabilities, selectedScale);
    final selectedOrientation =
        selectedPreset == null || availableOrientations.isEmpty
        ? null
        : _orientationForDimensions(selectedPreset.dimensions);

    final scaleDropdown = Semantics(
      container: true,
      label: l10n.imageSizeScaleLabel,
      value: selectedScale == _customSizeValue
          ? l10n.imageSizeCustomSize
          : selectedScale,
      enabled: widget.enabled,
      child: DropdownButtonFormField<String>(
        key: ValueKey(
          '${widget.providerKind}:${widget.model}:'
          '${widget.capabilityOverride}:scale:$selectedScale',
        ),
        decoration: InputDecoration(labelText: l10n.imageSizeScaleLabel),
        initialValue: selectedScale,
        items: [
          for (final scale in scaleValues)
            DropdownMenuItem<String>(value: scale, child: Text(scale)),
          DropdownMenuItem<String>(
            value: _customSizeValue,
            child: Text(l10n.imageSizeCustomSize),
          ),
        ],
        onChanged: widget.enabled
            ? (value) {
                if (value != null) {
                  _applyScaleSelection(value);
                }
              }
            : null,
      ),
    );

    if (selectedScale == _customSizeValue) {
      return scaleDropdown;
    }

    final orientationDropdown = Semantics(
      container: true,
      label: l10n.imageSizeOrientation,
      value: selectedOrientation == null
          ? null
          : _orientationLabel(l10n, selectedOrientation),
      enabled: widget.enabled && availableOrientations.length > 1,
      child: DropdownButtonFormField<_ImagePresetOrientation>(
        key: ValueKey(
          '${widget.providerKind}:${widget.model}:'
          '${widget.capabilityOverride}:orientation:$selectedScale:'
          '$selectedOrientation',
        ),
        decoration: InputDecoration(labelText: l10n.imageSizeOrientation),
        initialValue: selectedOrientation,
        items: [
          for (final orientation in availableOrientations)
            DropdownMenuItem<_ImagePresetOrientation>(
              value: orientation,
              child: Text(_orientationLabel(l10n, orientation)),
            ),
        ],
        onChanged: !widget.enabled || availableOrientations.length <= 1
            ? null
            : (orientation) {
                if (orientation != null) {
                  _applyOrientationSelection(selectedScale, orientation);
                }
              },
      ),
    );

    return ResponsivePair(first: scaleDropdown, second: orientationDropdown);
  }

  List<String> _scaleValuesFor(ImageModelCapabilities capabilities) {
    final scales = <String>[];
    for (final preset in capabilities.presets) {
      final scale = imageSizePresetScaleLabel(preset);
      if (!scales.contains(scale)) {
        scales.add(scale);
      }
    }
    return scales;
  }

  List<_ImagePresetOrientation> _orientationsForScale(
    ImageModelCapabilities capabilities,
    String scale,
  ) {
    final orientations = <_ImagePresetOrientation>[];
    for (final preset in capabilities.presets) {
      if (imageSizePresetScaleLabel(preset) != scale) {
        continue;
      }
      final orientation = _orientationForDimensions(preset.dimensions);
      if (!orientations.contains(orientation)) {
        orientations.add(orientation);
      }
    }
    return orientations;
  }

  ImageSizePreset? _selectedPresetFor(ImageModelCapabilities capabilities) {
    final dimensions = tryParseImageDimensions(widget.size);
    if (dimensions == null) {
      return null;
    }
    return exactImageSizePresetForDimensions(
      dimensions,
      presets: capabilities.presets,
    );
  }

  ImageSizePreset _presetForScaleAndOrientation({
    required ImageModelCapabilities capabilities,
    required String scale,
    required _ImagePresetOrientation orientation,
  }) {
    return capabilities.presets.firstWhere(
      (preset) =>
          imageSizePresetScaleLabel(preset) == scale &&
          _orientationForDimensions(preset.dimensions) == orientation,
      orElse: () => capabilities.presets.firstWhere(
        (preset) => imageSizePresetScaleLabel(preset) == scale,
        orElse: () => capabilities.presets.first,
      ),
    );
  }

  void _applyScaleSelection(String scale) {
    if (scale == _customSizeValue) {
      setState(() => _selectedValue = scale);
      _commitCustomSize();
      return;
    }

    final capabilities = imageModelCapabilitiesFor(
      providerKind: widget.providerKind,
      model: widget.model,
      capabilityOverride: widget.capabilityOverride,
    );
    final currentPreset = _selectedPresetFor(capabilities);
    final currentOrientation = currentPreset == null
        ? _orientationsForScale(capabilities, scale).first
        : _orientationForDimensions(currentPreset.dimensions);
    final preset = _presetForScaleAndOrientation(
      capabilities: capabilities,
      scale: scale,
      orientation: currentOrientation,
    );
    _applyPreset(preset);
  }

  void _applyOrientationSelection(
    String scale,
    _ImagePresetOrientation orientation,
  ) {
    final capabilities = imageModelCapabilitiesFor(
      providerKind: widget.providerKind,
      model: widget.model,
      capabilityOverride: widget.capabilityOverride,
    );
    final preset = _presetForScaleAndOrientation(
      capabilities: capabilities,
      scale: scale,
      orientation: orientation,
    );
    _applyPreset(preset);
  }

  void _applyPreset(ImageSizePreset preset) {
    setState(() {
      _selectedValue = preset.size;
      _setControllerText(_widthController, preset.dimensions.width.toString());
      _setControllerText(
        _heightController,
        preset.dimensions.height.toString(),
      );
    });
    widget.onChanged(preset.size);
    _notifyValidityForSize(preset.size);
  }

  _ImagePresetOrientation _orientationForDimensions(
    ImageDimensions dimensions,
  ) {
    if (dimensions.width == dimensions.height) {
      return _ImagePresetOrientation.square;
    }
    return dimensions.width > dimensions.height
        ? _ImagePresetOrientation.landscape
        : _ImagePresetOrientation.portrait;
  }

  String _orientationLabel(
    AppLocalizations l10n,
    _ImagePresetOrientation orientation,
  ) {
    return switch (orientation) {
      _ImagePresetOrientation.square => l10n.imageAspectSquare,
      _ImagePresetOrientation.landscape => l10n.imageAspectLandscape,
      _ImagePresetOrientation.portrait => l10n.imageAspectPortrait,
    };
  }

  String _presetMenuLabel(AppLocalizations l10n, ImageSizePreset preset) {
    return '${localizedImageSizePresetLabel(l10n, preset)} · ${preset.size}';
  }

  String _presetLabelForValue(
    AppLocalizations l10n,
    ImageModelCapabilities capabilities,
    String value,
  ) {
    ImageSizePreset? preset;
    for (final candidate in capabilities.presets) {
      if (candidate.size == value) {
        preset = candidate;
        break;
      }
    }
    return preset == null ? value : _presetMenuLabel(l10n, preset);
  }

  TextField _customSideInput({
    required AppLocalizations l10n,
    required TextEditingController controller,
    required String label,
  }) {
    final constraints =
        imageModelCapabilitiesFor(
          providerKind: widget.providerKind,
          model: widget.model,
          capabilityOverride: widget.capabilityOverride,
        ).constraints ??
        gptImage2SizeConstraints;
    return TextField(
      controller: controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(constraints.maxSide.toString().length),
      ],
      decoration: InputDecoration(
        labelText: label,
        helperText: l10n.imageSizeConstraintHelper(
          constraints.minSide,
          constraints.maxSide,
          constraints.step,
        ),
      ),
      onChanged: (_) => _commitCustomSize(),
    );
  }

  void _applySelection(String value) {
    if (value == _customSizeValue) {
      setState(() => _selectedValue = value);
      _commitCustomSize();
      return;
    }

    final capabilities = imageModelCapabilitiesFor(
      providerKind: widget.providerKind,
      model: widget.model,
      capabilityOverride: widget.capabilityOverride,
    );
    final preset = capabilities.presets.firstWhere(
      (preset) => preset.size == value,
      orElse: () => nearestImageSizePresetInList(
        dimensions: imageDimensionsFromSize(value),
        presets: capabilities.presets,
      ),
    );
    setState(() {
      _selectedValue = preset.size;
      _setControllerText(_widthController, preset.dimensions.width.toString());
      _setControllerText(
        _heightController,
        preset.dimensions.height.toString(),
      );
    });
    widget.onChanged(preset.size);
    _notifyValidityForSize(preset.size);
  }

  void _commitCustomSize() {
    final size =
        '${_widthController.text.trim()}x${_heightController.text.trim()}';
    widget.onChanged(size);
    _notifyValidityForSize(size);
  }

  String _buildHelperText(
    AppLocalizations l10n,
    ImageModelCapabilities capabilities,
    ImageSizeValidationResult validation,
  ) {
    if (!validation.isValid) {
      return validation.message ?? l10n.imageSizeInvalidFallback;
    }

    final dimensions = validation.dimensions!;
    final preset = exactImageSizePresetForDimensions(
      dimensions,
      presets: capabilities.presets,
    );
    final fallbackLabel = imageAspectName(
      dimensions.width,
      dimensions.height,
      l10n: l10n,
    );
    if (capabilities.sizeMode == ImageSizeMode.aspectRatio) {
      final aspectRatio = geminiAspectRatioForDimensions(dimensions);
      return l10n.imageSizeGeminiAspectSummary(
        preset == null
            ? fallbackLabel
            : localizedImageSizePresetLabel(l10n, preset),
        aspectRatio,
      );
    }

    if (capabilities.allowsCustomPixels && preset == null) {
      return l10n.imageSizeCustomRequestSummary(dimensions.size);
    }

    return l10n.imageSizeRequestSummary(
      preset == null
          ? l10n.imageSizeFixedResolution
          : localizedImageSizePresetLabel(l10n, preset),
      dimensions.size,
    );
  }

  String _pickerLabel(
    AppLocalizations l10n,
    ImageModelCapabilities capabilities,
  ) {
    return switch (capabilities.sizeMode) {
      ImageSizeMode.customPixels => l10n.imageSizeModeResolution,
      ImageSizeMode.aspectRatio => l10n.imageSizeModeAspectRatio,
      ImageSizeMode.fixedPresets => l10n.imageSizeModeFixedPresets,
    };
  }

  String _selectedValueFor(String size) {
    final capabilities = imageModelCapabilitiesFor(
      providerKind: widget.providerKind,
      model: widget.model,
      capabilityOverride: widget.capabilityOverride,
    );
    final dimensions = tryParseImageDimensions(size);
    final preset = dimensions == null
        ? null
        : exactImageSizePresetForDimensions(
            dimensions,
            presets: capabilities.presets,
          );
    if (preset != null) {
      return preset.size;
    }
    if (capabilities.allowsCustomPixels) {
      return _customSizeValue;
    }
    return nearestImageSizePresetInList(
      dimensions: imageDimensionsFromSize(size),
      presets: capabilities.presets,
    ).size;
  }

  void _notifyValidity() {
    _notifyValidityForSize(widget.size);
  }

  void _notifyValidityForSize(String size) {
    final validation = validateImageSizeForModel(
      size: size,
      providerKind: widget.providerKind,
      model: widget.model,
      capabilityOverride: widget.capabilityOverride,
    );
    widget.onValidityChanged?.call(validation.isValid);
  }

  static void _setControllerText(
    TextEditingController controller,
    String value,
  ) {
    if (controller.text == value) {
      return;
    }
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}

String imageAspectName(
  int width,
  int height, {
  required AppLocalizations l10n,
}) {
  if (width == height) {
    return l10n.imageAspectSquare;
  }
  return width > height ? l10n.imageAspectLandscape : l10n.imageAspectPortrait;
}
