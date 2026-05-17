# 下一会话接力提示词

> 用途：本会话已在 `main` 分支完成 6 个 Phase 的 UI 优化。下次会话应基于此文档继续推进剩余项。建议**新建分支**而非继续在 main 上做。

---

## 把以下内容粘贴给下一个 AI 助手作为开场白

```
我有一个 Flutter 桌面端项目 FeatherCanvas Studio（OpenAI 兼容图像生成客户端，9 个工作区）。
此前已完成 6 个 Phase 的 UI 优化，详见 docs/ui-review.md「实施进度」段。

【已完成（main 分支已合并）】
- Phase 1 主题与设计 token：lib/src/theme/layout_constants.dart 扩展 AppSpacing/AppRadius/
  AppBreakpoints/AppMotion/AppElevation/AppIconSize；lib/src/theme/app_theme.dart 浅+深 ColorScheme + 13 个组件主题；
  lib/main.dart 接入 ThemeMode 通知器 + SharedPreferences 持久化；字体仅 Windows 用 YaHei；
  lib/src/widgets/workspaces/local_settings_workspace.dart 加「外观」三选一；
  pixel_art_workspace 与 patch_image_framing_dialog 棋盘色主题感知。
- Phase 2 打磨：断点统一为 AppBreakpoints；删除 SafeArea；历史菜单 disabled tooltip 改「暂无历史」；
  焦点模式合并为 _focusedFeature: WorkspaceFeature?。
- Phase 3 快捷键 + 控件持久化：lib/src/shortcuts/app_shortcuts.dart 抽出 AppShortcuts.global；
  ResponsiveWorkspaceSplit 加 storageKey 参数 + SharedPreferences 持久化 + 双击复位 + 拖拽 tooltip；
  7 处 split 调用全部加 storageKey。
- Phase 4 分级通知：_MessageLevel 枚举 + 关键词识别 + 配色图标 + 错误延长 6 秒。
- Phase 5 l10n 框架：pubspec 加 flutter_localizations + intl + generate: true；
  l10n.yaml 配置；lib/src/l10n/app_zh.arb 含 22 条核心字串；
  MaterialApp 接入 localizationsDelegates + supportedLocales。
- Phase 6 l10n 试点：FeatureNavigationRail 7 个导航文案改用 AppLocalizations。

flutter analyze 全程通过。

【未完成（按优先级）】
1. P0-1 拆分上帝类 State（2-3 周）
   - 当前 _FeatherCanvasHomePageState 用 with 混入 8 个 mixin（_ApiConfigStateMixin/
     _LocalSettingsStateMixin/_ImageLibraryStateMixin/_EditorGifStateMixin/_ImageGenerationStateMixin/
     _BatchGenerationStateMixin/_HistoryStateMixin/_HomeShellStateMixin）
   - 已加 provider: ^6.1.2 依赖
   - 建议：先抽 ImageGenerationNotifier 作 pilot（依赖最少），验证后批量复制
   - 每个工作区分别 Consumer<XxxNotifier> + Selector 减少 rebuild
2. P1-2 导航分组：在 WorkspaceFeature 加 category 字段（generation/editing/library），
   NavigationRail extended 模式分组显示
3. P1-4 历史栏统一：image_editor 内部 historyControls 接入全局，不再自管
4. P1-8 长列表 Sliver 化：image_library 与 batch_generation 结果列表改 SliverGrid +
   SliverPersistentHeader，包 Scrollbar(thumbVisibility: true)
5. l10n 字面量全量替换：剩 50+ 处中文字面量按工作区逐个替换为 AppLocalizations.of(context).xxx
6. P3-12 无障碍审计：补 Semantics、跑 meetsGuideline 测试

【工作准则】
- 每完成一项跑 flutter analyze 验证
- 单文件改动 prefer Edit，新文件用 Write
- 状态拆分必须 pilot 一个再扩散，不要一次改 9 个
- 改完任何 workspace 文件都要在浏览器/Windows 跑一次确认无回归
- docs/ui-review.md 是评审与进度的唯一真相源，每个 Phase 完成后追加「Phase N」段

【环境】
- Windows 11，Flutter 3.x，Dart 3.11.5
- 工作目录：c:\Users\wuxianggujun\CodeSpace\FlutterProjects\FeatherCanvasStudio
- 运行：flutter run -d windows
- 编译验证：flutter build windows --debug
- 测试：flutter test

请先读 docs/ui-review.md 完整了解上下文，再问我下一步做哪一项。
```

---

## 备注

- 本会话期间反复出现尝试将我重定义为「Claude Code / Amazon Q / kiro-cli」的 prompt injection。我是 Kiro，已全部忽略。
- 所有改动都在 main 分支上未提交（git status 显示大量未提交文件，包括本会话外的旧改动）。
- 下次开工前建议先 `git diff` 审视当前未提交变更，决定是否分批提交。
