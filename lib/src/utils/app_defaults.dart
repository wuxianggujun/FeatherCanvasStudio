import '../models/app_config.dart';
import '../models/sprite_sheet_frame_fit.dart';
import '../services/gif_composer_service.dart';

const AppSettings defaultAppSettings = AppSettings(
  baseUrl: 'https://api.openai.com/v1',
  apiKey: '',
  model: '',
  prompt:
      'A clean product render of a futuristic camera on a neutral background',
  negativePrompt: '',
  size: '1024x1024',
  imageCount: 1,
);

const String defaultAnimationPrompt =
    'A small paper boat crossing a glowing city canal at night, cinematic pixel art, 16-bit, high contrast, clean outline, camera slowly pushes forward, water ripples';

const int defaultAnimationRows = 4;
const int defaultAnimationColumns = 4;
const int defaultEditorRows = 4;
const int defaultEditorColumns = 4;
const int defaultEditorTargetFrameIndex = 0;
const SpriteSheetFrameFit defaultEditorFrameFit = SpriteSheetFrameFit.contain;
const int defaultGifFrameDelayMs = 120;
const int defaultGifLoopCount = 0;
const GifPlaybackMode defaultGifPlaybackMode = GifPlaybackMode.normal;
