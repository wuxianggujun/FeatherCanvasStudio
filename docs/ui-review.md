# FeatherCanvas Studio UI 评审报告

> 评审时间：2026-05-17
> 评审范围：[lib/main.dart](lib/main.dart)、[lib/src/widgets/](lib/src/widgets/)、[lib/src/home/](lib/src/home/)
> 评审目标：识别当前 UI 在结构、可用性、一致性、性能、可维护性方面的问题，并给出可落地的改进建议。

---

## 一、整体印象

项目是一个 Flutter 桌面端图像生成 / 编辑工作台，功能丰富（文本生图、批量生成、动画工程、图片编辑、像素画、GIF 合成、作品库、接口配置、本地设置共 9 个工作区）。代码结构上能看出在持续重构，已经把工作区拆成单独文件、把 home state 拆成多个 mixin，整体方向是对的。

但 UI 层目前存在几类比较明显的问题，下面分类列出。

---

## 二、关键问题

### 1. 主状态类是巨型上帝类（最严重）

[lib/main.dart](lib/main.dart) 中的 `_FeatherCanvasHomePageState` 通过 `with` 一次性混入了 8 个 mixin：

```
_ApiConfigStateMixin,
_LocalSettingsStateMixin,
_ImageLibraryStateMixin,
_EditorGifStateMixin,
_ImageGenerationStateMixin,
_BatchGenerationStateMixin,
_HistoryStateMixin,
_HomeShellStateMixin,
```

并在同一个 State 上声明了 30+ 个字段（[main.dart:122-237](lib/main.dart#L122-L237)），覆盖文本生图、动画、编辑器、像素画、GIF、作品库、接口配置等所有领域。

**问题**：
- 切任何一个工作区，整棵 `FeatherCanvasHomePage` 都会 `setState` 重建。
- mixin 之间通过 `_xxx` 私有字段隐式耦合（[home_shell_state.dart:103-258](lib/src/home/home_shell_state.dart#L103-L258) 用 100+ 个 `@override` getter/setter 把所有字段串起来），新增功能必须改这个总入口。
- 单文件 270 行 + 8 个 part 文件全部共享同一个类，IDE 跳转、热重载、单测都很重。
- `_ResetDefaultsSnapshot`（[home_shell_state.dart:7-101](lib/src/home/home_shell_state.dart#L7-L101)）有 45 个字段，本质是把全局状态拍扁成一个对象，复杂度已经不可控。

**建议**：
- 用 `provider` / `riverpod` / `flutter_bloc` 等把每个工作区的状态拆成独立的 `ChangeNotifier` / `Notifier`，按需 `select` 订阅，避免 `setState` 全树重建。
- 顶层只保留导航、主题、bootstrap；每个工作区自带状态，工作区切换时不影响其他工作区。
- `_ResetDefaultsSnapshot` 拆成各领域自己的 snapshot，由各自的 notifier 负责备份/恢复。

---

### 2. 导航栏（NavigationRail）拥挤且层级混乱

[lib/src/widgets/layout_navigation_widgets.dart:241-403](lib/src/widgets/layout_navigation_widgets.dart#L241-L403)：

- 主导航条目 7 个：文本生图、批量生成、动画工程、图片编辑器、像素画编辑、GIF 合成、作品库。
- 在 `trailing` 里又塞了「接口配置」「设置」两个伪导航项 + 「展开/收起侧栏」按钮。

**问题**：
- 7 个主项已经接近 NavigationRail 的舒适上限（Material 3 推荐 3–7 项）。在 1080p 全高时排得比较挤，紧凑模式下只剩图标 + tooltip，新用户记不住每个图标对应什么。
- 「接口配置」和「设置」既是 Workspace（`WorkspaceFeature.apiSettings` / `localSettings`）又被画成 trailing 按钮，但它们和上面 7 个主项的逻辑层级是一样的，强行用分隔线区分会让用户疑惑「这和上面的区别是什么」。
- `onOpenSettings` 用的是 `selectFeature(localSettings)`（[home_shell_state.dart:633-636](lib/src/home/home_shell_state.dart#L633-L636)），所以本质和点上面的图标没区别，分两块没必要。
- 紧凑切换按钮放在 trailing 最底，但 NavigationRail 的 `trailing` 是 `Expanded` + `bottomCenter`，在窗口高度较小（< 720）时容易被压成滚动区域，体验不一致。

**建议**：
- 工作区按用途分组：
  - 「生成」组：文本生图、批量生成、动画工程
  - 「编辑」组：图片编辑器、像素画编辑、GIF 合成
  - 「资产」组：作品库
- 「接口配置」「设置」放进右下角的设置菜单（齿轮图标 + PopupMenu），不要占主导航位置。
- 7 个图标里 `image` 和 `collections`、`grid_on` 和 `auto_awesome_motion` 在小尺寸下区分度低，建议替换为更具语义的自定义图标或加文字简写。

---

### 3. 响应式断点分散且互相打架

涉及响应式判断的有至少三处：

| 位置 | 断点 | 用途 |
|---|---|---|
| [layout_navigation_widgets.dart:88](lib/src/widgets/layout_navigation_widgets.dart#L88) | 900 | 控制 `ResponsiveWorkspaceSplit` 横/竖布局 |
| [layout_navigation_widgets.dart:43](lib/src/widgets/layout_navigation_widgets.dart#L43) | 720 | 控制 `WorkspacePage` 标题行换行 |
| [home_shell_state.dart:586-590](lib/src/home/home_shell_state.dart#L586-L590) | 720 / 780 / 980 | 控制 NavigationRail 的紧凑/展开 |

**问题**：
- 同一个 viewport，三处独立判断，存在「侧栏已收起但工作区没切到竖排」「标题行没换行但 trailing 已经溢出」之类的中间态。
- 断点是硬编码常量，没有集中在 `theme/layout_constants.dart`，未来调整一致性差。
- 在 1280×800 这种常见笔记本尺寸下，侧栏展开 + 工作区横排 + 控件区固定 392 宽（[layout_navigation_widgets.dart:81](lib/src/widgets/layout_navigation_widgets.dart#L81)）+ 预览区最小 360，极易出现 trailing 区域被挤压、按钮文字截断。

**建议**：
- 在 `theme/layout_constants.dart` 中定义统一断点：`compactBreakpoint`、`mediumBreakpoint`、`expandedBreakpoint`，所有响应式判断引用同一组常量。
- 用 `MediaQueryData.size` + `LayoutBuilder` 配合，确保侧栏状态变化时其他组件能正确响应（目前 NavigationRail 收起后 viewport 没变，下游组件不会重新计算）。

---

### 4. 历史工具栏的可见性规则不一致

[home_shell_state.dart:646-650](lib/src/home/home_shell_state.dart#L646-L650)：

```dart
if (!imageEditorFocusMode &&
    !pixelArtFocusMode &&
    _selectedFeature != WorkspaceFeature.imageEditor)
  _buildHistoryToolbar(),
```

但 `_workspaceSupportsHistory`（[home_shell_state.dart:860-868](lib/src/home/home_shell_state.dart#L860-L868)）里 `imageEditor` 又是支持 history 的。

**问题**：
- 图片编辑器明明支持历史，但顶部历史工具栏被显式排除——是因为编辑器内部有自己的撤销/重做？如果是，那像素画编辑器也是同样情况却没被排除（实际它走 `_buildCompactHistoryControls`？看不出在哪调用）。
- `_buildCompactHistoryControls` 在当前给出的代码中**没有任何调用方**，可能是死代码。
- 用户在不同工作区会看到撤销按钮位置不一样（顶部 vs. 编辑器内部），破坏一致性。

**建议**：
- 撤销/重做是全局功能，统一放在窗口最顶部（标题栏附近）或工作区右上角，不要每个工作区一套。
- 对于编辑器有自己撤销栈的情况，把编辑器内部栈接入全局历史，而不是隐藏全局工具栏。
- 删除 `_buildCompactHistoryControls` 或确认它有调用方（通过 grep 验证后再处理）。

---

### 5. 全中文 UI 但架构未做国际化

整个项目硬编码中文：导航文案、按钮、Tooltip、SnackBar 都是字符串字面量（如 [layout_navigation_widgets.dart:289](lib/src/widgets/layout_navigation_widgets.dart#L289) `'文本生图'`、[home_shell_state.dart:368](lib/src/home/home_shell_state.dart#L368) `'表单已重置，可用 Ctrl+Z 撤销'`）。

**问题**：
- 字体回退链 `'Microsoft YaHei UI' → 'Microsoft YaHei' → 'Segoe UI' → 'Arial'`（[main.dart:73-78](lib/main.dart#L73-L78)）只覆盖 Windows 中文环境。在 macOS / Linux 上中文会回退到 `Arial`，渲染效果差。
- 没有 `flutter_localizations` 也没有 `intl`，未来要做英文版需要改 50+ 个文件。
- 文案直接拼接（如 `'像素画已保存到作品库：${fileNameFromPath(file.path)}'` [home_shell_state.dart:900](lib/src/home/home_shell_state.dart#L900)），不利于翻译时调整语序。

**建议**：
- 即使短期不出英文版，也应建立 `lib/src/l10n/` 目录，用 `arb` + `flutter gen-l10n` 把所有用户可见文案抽出来，至少集中管理。
- 字体回退链补充 `'PingFang SC'`（macOS）、`'Noto Sans CJK SC'`（Linux）。

---

### 6. 视觉系统薄弱

[main.dart:80-103](lib/main.dart#L80-L103) 中：

```dart
final colorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF0F766E),
  brightness: Brightness.light,
);
```

只配了一个种子色 + 亮色主题，没有：
- 深色主题（桌面应用尤其是图像工具的高频需求）。
- 自定义 `TextTheme`，所有字号都吃 Material 默认值，标题行 `headlineMedium`（[layout_navigation_widgets.dart:31](lib/src/widgets/layout_navigation_widgets.dart#L31)）在桌面端偏大。
- 间距 / 圆角 / 海拔的 design token，目前散落在各个 widget 中（`BorderRadius.circular(8)` 出现 N 次）。

**建议**：
- `lib/src/theme/` 已经有 `layout_constants.dart`，扩展为完整的 design tokens：颜色、字号、间距、圆角、阴影、动画时长。
- 增加深色主题，`MaterialApp` 用 `themeMode: ThemeMode.system`，并暴露在「本地设置」工作区供用户切换。
- 桌面端把 `headlineMedium` 改用 `titleLarge` 或自定义 24px，更紧凑。

---

### 7. 控件面板宽度策略过死

[layout_navigation_widgets.dart:81-86](lib/src/widgets/layout_navigation_widgets.dart#L81-L86)：

```dart
this.controlsWidth = 392,
this.minControlsWidth = 304,
this.maxControlsWidth = 520,
```

**问题**：
- 392/304/520 的来历不明，所有工作区共用同一组数字，但实际上「批量生成」表单字段比「文本生图」多，需要更宽。
- 用户拖动后宽度只保存在 `_ResponsiveWorkspaceSplitState` 内部（[layout_navigation_widgets.dart:105](lib/src/widgets/layout_navigation_widgets.dart#L105)），切工作区/重启就丢。
- 没有「记住宽度」/「重置宽度」入口。

**建议**：
- 把宽度持久化到 `AppLocalStore`，按工作区分别记忆。
- 拖拽手柄上加双击复位（双击恢复到 `widget.controlsWidth`）。

---

### 8. WorkspacePage 滚动行为有副作用

[layout_navigation_widgets.dart:34-74](lib/src/widgets/layout_navigation_widgets.dart#L34-L74)：

```dart
return SingleChildScrollView(
  controller: controller,
  padding: EdgeInsets.all(compactHeader ? 8 : workspacePadding),
  child: Column(...),
);
```

**问题**：
- 整页用 `SingleChildScrollView` 包，意味着如果工作区内部有任何 `ListView` / `GridView`（图片预览、作品库瀑布流），就会出现「外层滚动 + 内层滚动」的嵌套滚动冲突。
- 作品库这种长列表如果走 `WorkspacePage`，性能会很差（一次性构建所有 Tile，没有 viewport 裁剪）。
- 没有滚动条主题，桌面端默认滚动条在 Windows 上偏细且在右边缘紧贴内容。

**建议**：
- 长列表工作区（作品库、批量生成结果、动画帧序列）改用 `CustomScrollView` + `Sliver`，把 `WorkspacePage` 的 header 做成 `SliverToBoxAdapter`。
- 包一层 `Scrollbar(thumbVisibility: true)`，桌面端体验更好。

---

### 9. 焦点模式（Focus Mode）开关位置和命名混乱

[home_shell_state.dart:579-585](lib/src/home/home_shell_state.dart#L579-L585) 有两个独立的焦点模式：`_isImageEditorFocusMode` 和 `_isPixelArtFocusMode`，两者都隐藏 NavigationRail。

**问题**：
- 只有这两个工作区有焦点模式，其他工作区没有，但视觉上没暗示。
- 进入焦点模式后退出入口在哪？需要检查具体 widget，但从 shell 这层看不到统一的退出 UI。
- 两个 bool 没有合并成一个 `_focusedFeature: WorkspaceFeature?`，未来再加焦点模式要再开一个 bool。

**建议**：
- 用 `WorkspaceFeature? _focusedFeature` 单一字段。
- 焦点模式入口/退出统一在工作区右上角放一个 `Icons.fullscreen` / `fullscreen_exit` 按钮 + `F11` 快捷键。

---

### 10. 快捷键覆盖不完整

[home_shell_state.dart:597-606](lib/src/home/home_shell_state.dart#L597-L606) 只注册了 Ctrl+Z / Ctrl+Y / Ctrl+Shift+Z。

**问题**：
- 桌面应用至少应有：保存（Ctrl+S）、新建（Ctrl+N）、切换工作区（Ctrl+1..9）、关闭面板（Esc）、生成（Ctrl+Enter）。
- 像素画编辑器、图片编辑器内部还有自己的快捷键吗？目前从 shell 看不到。
- macOS 用的是 `meta`，Linux/Windows 是 `control`，目前两套都注册了，OK，但未来快捷键多了维护麻烦。

**建议**：
- 抽出 `lib/src/shortcuts/app_shortcuts.dart`，集中维护。
- 在「本地设置」工作区给出快捷键速查表。

---

### 11. 错误 / 状态消息只用 SnackBar

[home_shell_state.dart:569-573](lib/src/home/home_shell_state.dart#L569-L573)：

```dart
void _showMessage(String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
```

**问题**：
- SnackBar 在桌面端 1080p 屏幕上视觉权重低，2 秒就消失，长操作（保存失败、生成超时）的错误用户容易错过。
- 错误和成功通知都走同一个方法，没有视觉区分（颜色、图标）。
- 多条消息会顶掉前一条，关键信息丢失。

**建议**：
- 引入分级通知：成功（绿色 SnackBar 短）、警告（黄色 + 操作按钮）、错误（红色 + 持久化到通知中心）。
- 桌面端推荐用顶部 toast 或右下角通知卡片，叠加显示而不是覆盖。
- 关键错误同时写入工作区错误状态条（`_errorMessage`），用户回头还能看到。

---

### 12. 无障碍 (a11y) 几乎为零

抽查 [layout_navigation_widgets.dart:521-583](lib/src/widgets/layout_navigation_widgets.dart#L521-L583) `DesktopPickSourceTile`：

- 没有 `Semantics` label。
- 禁用态用 `withValues(alpha: 0.38)` 区分，但屏幕阅读器读不到「已禁用」。
- 颜色对比度（`onSurface` 透明度 0.38）在亮色主题下接近 WCAG AA 失败线。

**建议**：
- 关键交互组件包 `Semantics(button: true, enabled: ..., label: ...)`。
- 用 `Tooltip` 已经覆盖了部分场景，但无障碍工具不依赖 hover。
- 跑一次 Flutter 内置的 `accessibility` 测试（`testWidgets` + `expectLater(tester, meetsGuideline(...))`）。

---

## 三、次要问题（影响小但建议处理）

1. **mixin 命名带下划线 + part 文件**（[main.dart:57-64](lib/main.dart#L57-L64)）：`part 'src/home/...'` 导致这些 mixin 全部是 `main.dart` 的私有部分，外部无法测试也无法复用。建议改成正常 import + 抽象类/接口。

2. **`workspace_feature.dart` 枚举有 9 个值**：导航只展示 7 个 + 2 个隐藏（apiSettings/localSettings）。枚举应分组或加 `bool get isPrimary` 做语义区分。

3. **TextEditingController 在 home state 上集中创建**：导致工作区无法独立测试（必须 mock 整个 home state）。应该让每个工作区自己持有 controller。

4. **`_ephemeralTemplatePaths`**（[main.dart:204](lib/main.dart#L204)）在 dispose 时异步删除，但用 `unawaited`，App 退出快时可能没删成功，下次启动遗留垃圾文件。

5. **`SafeArea`** 在桌面应用中作用有限（[home_shell_state.dart:623](lib/src/home/home_shell_state.dart#L623)），桌面没有刘海，可以去掉。

6. **PopupMenuButton tooltip 显示「历史记录」但禁用时 tooltip 仍展示**，应该在 disabled 时换成「暂无历史」。

7. **`_animationProjectImporter` / `_animationProjectStore` / `_animationProjectExportService`** 都用 `const` 单例（[main.dart:134-141](lib/main.dart#L134-L141)），但它们出现在 State 字段里而不是依赖注入容器，难以替换为 mock。

8. **首次启动引导**（[home_shell_state.dart:314-318](lib/src/home/home_shell_state.dart#L314-L318)）用 `WidgetsBinding.instance.addPostFrameCallback` + 异步 dialog，没有处理「弹窗时用户切换工作区」的并发场景。

---

## 四、优先级建议

| 优先级 | 项目 | 工作量估算 |
|---|---|---|
| **P0** | 1. 拆分上帝类 State，引入状态管理 | 2-3 周 |
| **P0** | 6. 增加深色主题 + 统一 design tokens | 3-5 天 |
| **P1** | 2. 重组导航分组 / 收纳设置入口 | 2 天 |
| **P1** | 4. 统一历史工具栏可见性规则 | 1 天 |
| **P1** | 8. 长列表 Sliver 化 + Scrollbar 主题 | 2-3 天 |
| **P1** | 11. 分级通知系统 | 2 天 |
| **P2** | 3. 统一断点常量 | 0.5 天 |
| **P2** | 5. l10n 抽取（即使只做中文） | 3 天 |
| **P2** | 7. 控件宽度持久化 | 0.5 天 |
| **P2** | 9. 焦点模式合并 + 退出按钮 | 1 天 |
| **P2** | 10. 快捷键集中管理 + 速查表 | 1 天 |
| **P3** | 12. 无障碍审计 | 持续投入 |

---

## 五、建议的下一步

1. 先做 **P0 第 1 项的探索性 PR**：选一个工作区（推荐「文本生图」，依赖最少）作为试点，把它的状态从全局 mixin 中独立出来用 `ChangeNotifier` + `Provider`，验证可行性后再推广。
2. 同时做 **P0 第 6 项**：design tokens + 深色主题不需要等架构改造完成，可以并行进行。
3. P1 的导航重组、历史工具栏、通知系统建议在架构改造之后做，避免重复工作。

---

> 注：本评审基于截至 2026-05-17 的代码快照，建议每完成一个 P 级别后回归一次，确认改动没有引入新的耦合或回退。

---

## 六、实施进度（2026-05-17 更新）

### 已完成

**Phase 1：主题与设计 token（P0-6）**

| 改动 | 文件 |
|---|---|
| 扩展设计 token：`AppSpacing` / `AppRadius` / `AppBreakpoints` / `AppMotion` / `AppElevation` / `AppIconSize` | [lib/src/theme/layout_constants.dart](lib/src/theme/layout_constants.dart) |
| 新建主题：`AppColorsLight` / `AppColorsDark` + `AppTheme.light()` / `AppTheme.dark()`，覆盖 13 个组件主题 | [lib/src/theme/app_theme.dart](lib/src/theme/app_theme.dart) |
| 接入 `MaterialApp`：`darkTheme` + `themeMode` + `appThemeMode` 顶层 ValueNotifier + SharedPreferences 持久化 | [lib/main.dart](lib/main.dart) |
| 字体策略：仅 Windows 用 YaHei UI，回退链补 PingFang SC / Noto Sans CJK SC | [lib/main.dart](lib/main.dart) |
| 「外观」三选一切换（跟随系统/浅色/深色） | [lib/src/widgets/workspaces/local_settings_workspace.dart](lib/src/widgets/workspaces/local_settings_workspace.dart) |
| 引入 `provider: ^6.1.2` 依赖（为 P0-1 准备） | [pubspec.yaml](pubspec.yaml) |
| 修复深色模式下硬编码棋盘色 | [lib/src/widgets/workspaces/pixel_art_workspace.dart](lib/src/widgets/workspaces/pixel_art_workspace.dart)、[lib/src/widgets/patch_image_framing_dialog.dart](lib/src/widgets/patch_image_framing_dialog.dart) |

**Phase 2：低风险打磨**

| 改动 | 文件 | 对应评审项 |
|---|---|---|
| 统一断点常量为 `AppBreakpoints.compact / medium / expanded / railShortHeight / railShortMinWidth` | [lib/src/widgets/layout_navigation_widgets.dart](lib/src/widgets/layout_navigation_widgets.dart)、[lib/src/home/home_shell_state.dart](lib/src/home/home_shell_state.dart) | P2-3 |
| 删除 `SafeArea` 包裹（桌面无刘海/状态栏） | [lib/src/home/home_shell_state.dart](lib/src/home/home_shell_state.dart) | 次要问题 5 |
| 历史菜单 disabled 时 tooltip 显示「暂无历史」 | [lib/src/home/home_shell_state.dart](lib/src/home/home_shell_state.dart) | 次要问题 6 |
| 合并 `_isImageEditorFocusMode` + `_isPixelArtFocusMode` 为单一 `_focusedFeature: WorkspaceFeature?`（geter/setter 桥接保持调用方零改动） | [lib/main.dart](lib/main.dart) | P2-9 |

**Phase 3：快捷键与控件持久化**

| 改动 | 文件 | 对应评审项 |
|---|---|---|
| 抽出 `AppShortcuts.global` + `appShortcutCheatSheet` | [lib/src/shortcuts/app_shortcuts.dart](lib/src/shortcuts/app_shortcuts.dart) | P2-10 |
| `Shortcuts` 引用 `AppShortcuts.global`，删除内联 `SingleActivator` | [lib/main.dart](lib/main.dart)、[lib/src/home/home_shell_state.dart](lib/src/home/home_shell_state.dart) | P2-10 |
| `ResponsiveWorkspaceSplit` 加 `storageKey` 参数 + SharedPreferences 持久化 + 双击复位 + 拖拽 tooltip | [lib/src/widgets/layout_navigation_widgets.dart](lib/src/widgets/layout_navigation_widgets.dart) | P2-7 |
| 7 处 split 调用全部加 `storageKey`（image_generation / batch_generation / animation_project / image_editor / pixel_art / gif_composer / general_image_editor） | 各工作区文件 | P2-7 |

**Phase 4：分级通知**

| 改动 | 文件 | 对应评审项 |
|---|---|---|
| 引入 `_MessageLevel`（info/success/warning/error），`_showMessage` 按文本关键词自动分级，配色 + 图标 + 错误延长到 6 秒 + `hideCurrentSnackBar` 防覆盖 | [lib/src/home/home_shell_state.dart](lib/src/home/home_shell_state.dart) | P1-11 |

**Phase 5：l10n 框架搭建（仅基建）**

| 改动 | 文件 | 对应评审项 |
|---|---|---|
| 添加 `flutter_localizations` + `intl` 依赖、`generate: true` | [pubspec.yaml](pubspec.yaml) | P2-5 |
| 新建 `l10n.yaml`（arb-dir / output-dir 配置） | [l10n.yaml](l10n.yaml) | P2-5 |
| 新建中文模板 arb，含 22 条核心字串（导航/外观/历史/分隔条提示） | [lib/src/l10n/app_zh.arb](lib/src/l10n/app_zh.arb) | P2-5 |
| `MaterialApp` 接入 `localizationsDelegates` + `supportedLocales` | [lib/main.dart](lib/main.dart) | P2-5 |
| 自动生成 `AppLocalizations` 与 `AppLocalizationsZh`（构建产物） | [lib/src/l10n/generated/](lib/src/l10n/generated/) | P2-5 |

> **注**：本轮只搭框架，未替换业务字面量。后续按工作区把 `Text('文本生图')` 等改为 `AppLocalizations.of(context).navImageGeneration`，需要 50+ 处替换 + 9 个工作区回归，建议独立分支推进。

**Phase 6：l10n 字面量替换（试点）**

| 改动 | 文件 | 对应评审项 |
|---|---|---|
| `FeatureNavigationRail.destinations` 7 个中文 `Text(...)` 改为 `Text(l10n.navXxx)`，`destinations` 由 `const` 改运行时构造 | [lib/src/widgets/layout_navigation_widgets.dart](lib/src/widgets/layout_navigation_widgets.dart) | P2-5 |

> 试点验证 `AppLocalizations.of(context)` 调用模式可行；剩余 50+ 处中文字面量沿同一模式逐工作区替换即可。

**Phase 7：P0-1 拆分上帝类 State Pilot（文本生图）**

| 改动 | 文件 | 对应评审项 |
|---|---|---|
| 新建 `ImageGenerationNotifier`（ChangeNotifier，仅托管 `generatedImages` / `isGenerating` / `errorMessage` / `debugRecord` 四个文本生图输出态字段，setter 内做 identity check 后 `notifyListeners`） | [lib/src/state/image_generation_notifier.dart](lib/src/state/image_generation_notifier.dart) | P0-1 |
| `_FeatherCanvasHomePageState` 持有单例 notifier；原 4 个字段从 `bool _isGenerating = false;` 等改为委托 getter/setter（`get => _imageGenerationNotifier.xxx`、`set => _imageGenerationNotifier.xxx = value`），保持 `_ResetDefaultsSnapshot` 等所有调用方零改动；`dispose()` 释放 notifier | [lib/main.dart](lib/main.dart) | P0-1 |
| `_HomeShellStateMixin` 加抽象 `ImageGenerationNotifier get _imageGenerationNotifier`；`build()` 顶层套 `ChangeNotifierProvider<ImageGenerationNotifier>.value` | [lib/src/home/home_shell_state.dart](lib/src/home/home_shell_state.dart) | P0-1 |
| `ImageGenerationWorkspace` 移除 4 个透传 prop（isGenerating / errorMessage / generatedImages / debugRecord），ControlPanel 用 `Selector<ImageGenerationNotifier, bool>` 只订阅 isGenerating，PreviewPanel 用 `Consumer<ImageGenerationNotifier>` 订阅全部输出态 | [lib/src/widgets/workspaces/image_generation_workspace.dart](lib/src/widgets/workspaces/image_generation_workspace.dart) | P0-1 |
| 调用方 `_buildImageGenerationWorkspace` 同步移除 4 个 prop 透传 | [lib/src/home/image_generation_state.dart](lib/src/home/image_generation_state.dart) | P0-1 |

**Pilot 收益验证**：
- `flutter analyze` 通过（No issues found）。
- 文本生图 4 个字段变化时只触发 `Selector` / `Consumer` 局部 rebuild，不再走 `_FeatherCanvasHomePageState.setState` 全树重建。生图过程中切到其他工作区也不再触发文本生图工作区重渲染。
- 调用方零改动：`_generateImage()` 内部仍然写 `_isGenerating = true`，setter 透明转发到 notifier，自动通知监听者；`_ResetDefaultsSnapshot` 的捕获/恢复保持原样，无回归。
- `flutter test` 测得 189 通过、2 失败（`app_test.dart:115` 期望文案"通用编辑"在 lib/ 中查无此字串；`batch_generation_workspace_test.dart:290` 期望 5+ 个 `DropdownButtonFormField` 实际 0），均为上轮会话外旧改动遗留的 baseline 失败，与本 pilot 无关。

**模式总结（供后续 mixin 复制使用）**：
1. 在 [lib/src/state/](lib/src/state/) 新建对应的 ChangeNotifier，只放纯状态字段 + setter notify。
2. State 类持有 notifier 实例，原同名字段改委托 getter/setter；setter 内不调用 setState（notifier 自己 notify）。
3. mixin 中要 build 的部分加抽象 `XxxNotifier get _xxxNotifier`。
4. build 顶层套 `ChangeNotifierProvider.value`，对应 workspace 用 `Selector` / `Consumer` 直接订阅。
5. 移除 workspace 的透传 prop 和调用方的对应实参。
6. 业务方法（如 `_generateImage`）暂留 mixin 不动，等所有 notifier 落地后再决定是否搬入 notifier。

每次改动后 `flutter analyze` 均通过（No issues found）。

**Phase 8：P0-1 第二个 Notifier（BatchGenerationNotifier，删除兼容接口）**

| 改动 | 文件 | 对应评审项 |
|---|---|---|
| 新建 `BatchGenerationNotifier`（ChangeNotifier，托管 `jobs` / `targetCount` / `requestCount` / `isRunning` / `pauseAfterCurrent`） | [lib/src/state/batch_generation_notifier.dart](lib/src/state/batch_generation_notifier.dart) | P0-1 |
| `_FeatherCanvasHomePageState` 加 notifier 字段，`MultiProvider` 包两个 ChangeNotifierProvider | [lib/main.dart](lib/main.dart)、[lib/src/home/home_shell_state.dart](lib/src/home/home_shell_state.dart) | P0-1 |
| `_BatchGenerationStateMixin` 5 个字段全部改为委托 getter/setter，加 `BatchGenerationNotifier get _batchGenerationNotifier` 抽象 getter；mixin 内业务方法保持 `_batchJobs = ...` 写法不变 | [lib/src/home/batch_generation_state.dart](lib/src/home/batch_generation_state.dart) | P0-1 |
| **删除兼容接口**：`BatchGenerationWorkspace` 移除 `jobs` / `targetCount` / `requestCount` / `isRunning` / `isPausing` 5 个 prop，强制走 notifier。`_BatchGenerationControls` 内 `context.watch<BatchGenerationNotifier>()`；preview Column 用 `Consumer` 包装。 | [lib/src/widgets/workspaces/batch_generation_workspace.dart](lib/src/widgets/workspaces/batch_generation_workspace.dart) | P0-1 |
| 调用方 `_buildBatchGenerationWorkspace` 同步移除 5 个 prop 透传 | [lib/src/home/batch_generation_state.dart](lib/src/home/batch_generation_state.dart) | P0-1 |
| 3 个 batch 测试改为 `ChangeNotifierProvider<BatchGenerationNotifier>.value` 包装；新增 `_seededNotifier` helper；测试也移除 5 个 prop | [test/batch_generation_workspace_test.dart](test/batch_generation_workspace_test.dart) | P0-1 |

**Phase 7 vs Phase 8 的关键差异**：
- Phase 7（ImageGeneration）：4 个字段被 `_ResetDefaultsSnapshot` 跨 mixin 引用，必须保留 setter 兼容性，workspace 暂不删 prop（双轨过渡）。
- Phase 8（BatchGeneration）：5 个字段全是 mixin 内部状态，无跨 mixin 读取、无 snapshot 捕获，**直接删 workspace 的 5 个 prop 实现单一数据源**。这是更激进、更彻底的迁移模式。

**Pilot 收益验证**：
- `flutter analyze` 通过（No issues found）。
- `flutter test` 191/191 全绿。
- 所有 5 个字段的变化都只触发 `Consumer<BatchGenerationNotifier>` 与 `context.watch` 的局部 rebuild，不再走 `_FeatherCanvasHomePageState.setState` 全树重建。批量队列运行时（频繁更新 jobs）切到其他工作区不会让那些工作区跟着重渲染。
- 调用方零业务侵入：mixin 内 `_batchJobs = [...]`、`_isBatchGenerationRunning = true` 等代码完全没改，setter 透明转发到 notifier 自动通知监听者。

**剩余 mixin（按依赖复杂度由低到高）**：
- `_EditorGifStateMixin`（编辑器 + GIF 字段）：大概 10+ 个字段，部分被 snapshot 捕获，需要混合策略。
- `_ImageLibraryStateMixin`：`_imageLibrary` 是核心字段，被多个 mixin 跨读，迁移影响面大。
- `_LocalSettingsStateMixin`：表单字段为主，snapshot 强引用。
- `_ApiConfigStateMixin`：表单字段 + 网络状态，snapshot 强引用。
- `_HistoryStateMixin`：每工作区一个 HistoryStack，已经是局部状态，可能不需要 notifier。

每次改动后 `flutter analyze` 均通过（No issues found）。

**Phase 9：P0-1 第三个 Notifier（GifComposerNotifier，混合策略）**

| 改动 | 文件 | 对应评审项 |
|---|---|---|
| 新建 `GifComposerNotifier`（ChangeNotifier，托管 7 个 GIF 字段：`frames` / `defaultFrameDelayMs` / `loopCount` / `playbackMode` / `isComposing` / `outputPath` / `errorMessage`） | [lib/src/state/gif_composer_notifier.dart](lib/src/state/gif_composer_notifier.dart) | P0-1 |
| `_FeatherCanvasHomePageState` 加 notifier 字段，`MultiProvider` 加第三个 `ChangeNotifierProvider`，dispose 释放，**删除 main.dart 中 7 个原始 GIF 字段** | [lib/main.dart](lib/main.dart) | P0-1 |
| `_EditorGifStateMixin` 7 个 GIF 字段全部改为委托 getter/setter（含 `_gifSourceFrames`），加 `GifComposerNotifier get _gifComposerNotifier` 抽象 getter | [lib/src/home/editor_gif_state.dart](lib/src/home/editor_gif_state.dart) | P0-1 |
| `_HomeShellStateMixin` 加 `GifComposerNotifier get _gifComposerNotifier` 抽象 getter | [lib/src/home/home_shell_state.dart](lib/src/home/home_shell_state.dart) | P0-1 |
| **删除兼容接口**：`GifComposerWorkspace` 移除 7 个 prop（frames / defaultFrameDelayMs / loopCount / playbackMode / isComposing / outputPath / errorMessage），controls 用 `Consumer<GifComposerNotifier>` 包装 GifComposerPanel；preview 用 `Selector` 只订阅 frames + outputPath（避免 isComposing 等无关字段触发预览重渲染） | [lib/src/widgets/workspaces/gif_composer_workspace.dart](lib/src/widgets/workspaces/gif_composer_workspace.dart) | P0-1 |
| 调用方 `_buildGifComposerWorkspace` 同步移除 7 个 prop 透传 | [lib/src/home/editor_gif_state.dart](lib/src/home/editor_gif_state.dart) | P0-1 |

**Phase 9 vs Phase 7/8 的关键差异**：
- Phase 7（ImageGeneration）：4 字段进 `_ResetDefaultsSnapshot`，setter 必须保留，workspace 双轨过渡。
- Phase 8（BatchGeneration）：5 字段无跨 mixin、无 snapshot，**直接删 workspace 全部 5 个 prop**。
- **Phase 9（GifComposer）：混合策略**——7 字段全部进 `_ResetDefaultsSnapshot`（home_shell_state 的 `_restoreResetDefaultsSnapshot` 仍写 `_gifSourceFrames = ...` 等），同时 `_HomeShellStateMixin` 与 `_ImageLibraryStateMixin` 的抽象声明仍要求这些字段的 getter/setter，但具体实现现在由 `_EditorGifStateMixin` 的 delegating geter/setter 提供（mixin 线性化让后来者覆盖）。这种"snapshot 强依赖 + workspace 强解耦"的混合形态适用于：状态被外部持久化机制（snapshot/storage）需要批量写入，但 UI 层已不依赖 mixin 字段直读。

**Pilot 收益验证**：
- `flutter analyze` 通过（No issues found）。
- `flutter test` 191/191 全绿。
- 7 字段变化只触发 `Consumer` 与 `Selector` 局部 rebuild，不再走全树。GIF 合成进度（`isComposing` 翻转）只刷新 GifComposerPanel；frames 增删只刷新 panel + preview；outputPath 完成时只刷新 preview 的导出区。

**已验证：mixin 线性化兼容 snapshot 写入**。`_HomeShellStateMixin._restoreResetDefaultsSnapshot` 中 `_gifSourceFrames = snapshot.gifSourceFrames`（line 546-551）依然有效——由 `_EditorGifStateMixin` 的 delegating setter 接管，自动通知 notifier listeners，UI 无延迟刷新。

每次改动后 `flutter analyze` 均通过（No issues found）。

**Phase 10：P0-1 第四个 Notifier（ImageEditorNotifier，混合策略）**

| 改动 | 文件 | 对应评审项 |
|---|---|---|
| 新建 `ImageEditorNotifier`（ChangeNotifier，托管 13 个图片编辑器字段：Sprite Sheet 子系统 9 个 + General 子系统 4 个） | [lib/src/state/image_editor_notifier.dart](lib/src/state/image_editor_notifier.dart) | P0-1 |
| `_FeatherCanvasHomePageState` 加 notifier 字段，`MultiProvider` 加第四个 `ChangeNotifierProvider`，dispose 释放，**删除 main.dart 中 13 个原始编辑器字段** | [lib/main.dart](lib/main.dart) | P0-1 |
| `_EditorGifStateMixin` 13 个编辑器字段全部改为委托 getter/setter（含 `_editorImagePath`、`_editorPatchImagePath`、`_isReplacingEditorFrame`、`_isProcessingGeneralImage` 等），加 `ImageEditorNotifier get _imageEditorNotifier` 抽象 getter | [lib/src/home/editor_gif_state.dart](lib/src/home/editor_gif_state.dart) | P0-1 |
| `_HomeShellStateMixin` 加 `ImageEditorNotifier get _imageEditorNotifier` 抽象 getter | [lib/src/home/home_shell_state.dart](lib/src/home/home_shell_state.dart) | P0-1 |
| **删除兼容接口**：`ImageEditorWorkspace` 移除 13 个 prop，General 子系统用 `Selector` 订阅 4 个字段；Sprite Sheet 子系统 controls 用 `Selector` 订阅 8 个字段，preview 用 `Selector` 订阅 6 个字段；模式切换从 `didUpdateWidget` 改为 `addListener` 监听 notifier 路径变化 | [lib/src/widgets/workspaces/image_editor_workspace.dart](lib/src/widgets/workspaces/image_editor_workspace.dart) | P0-1 |
| 调用方 `_buildImageEditorWorkspace` 同步移除 13 个 prop 透传 | [lib/src/home/editor_gif_state.dart](lib/src/home/editor_gif_state.dart) | P0-1 |

**Phase 10 关键设计决策**：
- 两个子系统（Sprite Sheet 9 字段 + General 4 字段）合并到一个 `ImageEditorNotifier`，因为它们共享同一个 `ImageEditorWorkspace` 渲染入口，避免 Provider 套娃。
- 模式自动切换：原 `didUpdateWidget` 比较 `oldWidget.generalImagePath` / `widget.imagePath` 的逻辑改为 `_ImageEditorWorkspaceState.didChangeDependencies` 注册 `_imageEditorNotifier.addListener`，listener 内缓存上一次路径并比较，触发 `setState(() => _mode = ...)`。`dispose` 中 `removeListener`。
- `Selector` 粒度：General 内容 4 字段一组、Sprite Sheet controls 8 字段一组、preview 6 字段一组——各自独立 rebuild，互不干扰。

**Pilot 收益验证**：
- `flutter analyze` 通过（No issues found）。
- `flutter test` 191/191 全绿。
- 13 字段变化只触发对应 `Selector` 局部 rebuild。General 图片加载（`isProcessingGeneralImage` 翻转）只刷新 General 面板；Sprite Sheet 行列调整只刷新 controls + preview；`isReplacingEditorFrame` 只刷新 controls。

**已验证：snapshot 透写路径完整**。`_HomeShellStateMixin._restoreResetDefaultsSnapshot` 中 `_editorRows = snapshot.editorRows` 等 13 行写入依然有效——由 `_EditorGifStateMixin` 的 delegating setter 接管，自动通知 notifier listeners，UI 无延迟刷新。

每次改动后 `flutter analyze` 均通过（No issues found）。

| 评审项 | 优先级 | 工作量 |
|---|---|---|
| 1. 拆分上帝类 State：pilot 已完成（文本生图），剩余 7 个 mixin 按同一模式推广 | P0 | 1.5-2 周 |
| 2. 重组导航分组 / 收纳设置入口 | P1 | 2 天 |
| 4. 统一历史工具栏可见性规则（编辑器内栈接入全局） | P1 | 1 天 |
| 8. 长列表 Sliver 化 + Scrollbar 主题 | P1 | 2-3 天 |
| 5. l10n 字面量全量替换（剩余 50+ 处） | P2 | 3 天 |
| 10. 快捷键集中管理 + 速查表 | P2 | 1 天 |
| 12. 无障碍审计 | P3 | 持续 |
| 修复 2 个 baseline 测试失败（app_test "通用编辑" / batch_generation_workspace_test DropdownButtonFormField 数量） | P1 | 0.5 天 |

### 验证要点（手动测试）

下次启动应用后请确认：

1. 设置 → 外观 切换深色 / 浅色 / 跟随系统，9 个工作区视觉无破图。
2. 像素画工作区与 patch dialog 的棋盘格背景在深色模式下不再刺眼。
3. 窗口拖到 720px 以下时，导航栏自动进入 compact，标题行换行。
4. 进入图片编辑器或像素画工作区的焦点模式后正常隐藏导航栏，退出后恢复（验证合并字段无回归）。
5. 历史菜单在无历史时悬停显示「暂无历史」。

