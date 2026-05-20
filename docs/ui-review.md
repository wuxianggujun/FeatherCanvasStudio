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

**Phase 11：P0-1 第五个 Notifier（ImageLibraryNotifier，存储委托模式）**

| 改动 | 文件 | 对应评审项 |
|---|---|---|
| 新建 `ImageLibraryNotifier`（ChangeNotifier，纯托管 `List<ImageLibraryItem>`） | [lib/src/state/image_library_notifier.dart](lib/src/state/image_library_notifier.dart) | P0-1 |
| `_FeatherCanvasHomePageState` 加 notifier 字段，`MultiProvider` 加第五个 `ChangeNotifierProvider`，dispose 释放 | [lib/main.dart](lib/main.dart) | P0-1 |
| `_HomeShellStateMixin` 加 `ImageLibraryNotifier get _imageLibraryNotifier` 抽象 getter | [lib/src/home/home_shell_state.dart](lib/src/home/home_shell_state.dart) | P0-1 |
| `_ImageLibraryStateMixin` 删除 `_imageLibraryValue` 字段，`_imageLibrary` getter/setter 改为读写 `_imageLibraryNotifier.items`；存在性缓存逻辑（`_existingImageLibraryPaths` 等）保留在 mixin | [lib/src/home/image_library_state.dart](lib/src/home/image_library_state.dart) | P0-1 |

**Phase 11 关键设计决策**：
- `_imageLibrary` 跨 5 个 mixin 共享（生成、批量、编辑、GIF、库自身共 14+ 处写入），且**不在 `_ResetDefaultsSnapshot`** 里——重置不触库，所以纯激进迁移，无需 Hybrid。
- 存储委托模式：mixin 的 setter 保留存在性缓存的副作用逻辑（`_updateImageLibraryExistenceCacheAfterAssignment`），仅把存储底层从私有字段改为 notifier。其他 mixin 的 `_imageLibrary = [item, ..._imageLibrary]` 写法不变。
- 库 workspace 暂未改用 Consumer（仍由 `_buildImageLibraryWorkspace` 把 `viewData` 作为 prop 传入），因为 filter / sort / selection 仍在 mixin 内 setState；下一阶段 11B 可考虑把 viewData 计算移到 workspace 内的 Selector。

**Pilot 收益验证**：
- `flutter analyze` 通过（No issues found）。
- `flutter test` 191/191 全绿。
- 5 个 ChangeNotifier 全部接入 `MultiProvider`：图片生成、批量生成、GIF 合成、图片编辑、作品库。后续 phase 可基于 notifier 解耦各 workspace 的 prop 链。

每次改动后 `flutter analyze` 均通过（No issues found）。

**Phase 11B：兑现 ImageLibraryNotifier 的解耦收益（workspace Selector 化）**

| 改动 | 文件 | 对应评审项 |
|---|---|---|
| `ImageLibraryWorkspace` 删除 `viewData` prop，新增 `itemExists` 回调 prop，内容用 `Selector<ImageLibraryNotifier, List<ImageLibraryItem>>` 包装；`buildImageLibraryViewData` 计算移入 Selector builder | [lib/src/widgets/workspaces/image_library_workspace.dart](lib/src/widgets/workspaces/image_library_workspace.dart) | P0-1 |
| `onSelectVisible` 签名从 `VoidCallback` 改为 `ValueChanged<List<ImageLibraryItem>>`，filteredItems 由 workspace 在 builder 内传入回调 | [lib/src/widgets/workspaces/image_library_workspace.dart](lib/src/widgets/workspaces/image_library_workspace.dart) | P0-1 |
| `_buildImageLibraryWorkspace` 删除 `viewData` 计算与 `viewData` prop 透传，调用方简化 | [lib/src/home/image_library_state.dart](lib/src/home/image_library_state.dart) | P0-1 |
| `main.dart` 删除已不再使用的 `image_library_view_data.dart` import | [lib/main.dart](lib/main.dart) | P0-1 |

**Phase 11B 关键收益**：
- 库 workspace 现在直接订阅 `ImageLibraryNotifier`：当其他 workspace（图片生成、批量、编辑、GIF）调用 `_imageLibrary = [item, ..._imageLibrary]` 时，notifier listener 触发的 rebuild 只覆盖 `Selector` 子树（即 `ImageLibraryPanel`），不再依赖父级 `setState` 触发全树重渲。
- filter / sort / selection 仍由 mixin 内 setState 驱动（这些字段非 notifier-backed），但它们触发 rebuild 时只重算 `viewData` 一次，prop 变化在 Selector builder 内处理。
- 这是 Phase 11 的"存储委托"完成形态：notifier 不再只是隐藏的存储后端，而是真正的 reactive 信号源。

**Pilot 收益验证**：
- `flutter analyze` 通过（No issues found）。
- `flutter test` 191/191 全绿。
- 安全前提：所有 `setState(() => _imageLibrary = [item, ..._imageLibrary])` 调用点的 setState 包装仍可保留——现阶段它们作为 mixin-local 字段（如 `_selectedImageLibraryItemIds`）的同步保护是无害的；后续如要彻底删除冗余 setState，需先确认每处 setState 块内是否还有 mixin-local 字段共写。

每次改动后 `flutter analyze` 均通过（No issues found）。

**Phase 11C / 11D：清理冗余 setState 包装（共 43 处）**

Phase 11B 把 `ImageLibraryWorkspace` 接入 `Selector` 后，原来跨 mixin 的 `setState(() => _imageLibrary = [item, ..._imageLibrary]);` 包装就成了纯开销——notifier listener 已经能驱动 library workspace 重渲，setState 反而触发整棵 `FeatherCanvasHomePage` 子树重建。

| 阶段 | 范围 | 文件数 | 站点数 | 提交 |
|---|---|---:|---:|---|
| 11C | `_imageLibrary` 写入处 | 5 | 15 | `4b1fcda` |
| 11D | Phase 7/9/10 notifier 字段（`_isGenerating` / `_errorMessage` / `_isReplacingEditorFrame` / `_editorErrorMessage` / `_isProcessingGeneralImage` / `_generalEditorErrorMessage` / `_editorFrameFit` / `_gifDefaultFrameDelayMs` / `_gifLoopCount` / `_gifPlaybackMode` / `_gifErrorMessage` / `_isComposingGif`） | 2 | 28 | `19296be` |

**保留原则**：混合 setState 块（同时写 mixin-local 非 notifier 字段，如 `_selectedImageLibraryItemIds` / `_focusedFeature`）保持不动；只删纯单行 `setState(() => _x = Y);` 包装。

`flutter analyze` 通过、`flutter test` 191/191 全绿。

### P0-1（拆分上帝类 State）收尾

Phase 7-11D 已完整完成评审项 P0-1。最终形态：

- **5 个 `ChangeNotifier`** 全部接入根 `MultiProvider`：[ImageGenerationNotifier](lib/src/state/image_generation_notifier.dart) / [BatchGenerationNotifier](lib/src/state/batch_generation_notifier.dart) / [GifComposerNotifier](lib/src/state/gif_composer_notifier.dart) / [ImageEditorNotifier](lib/src/state/image_editor_notifier.dart) / [ImageLibraryNotifier](lib/src/state/image_library_notifier.dart)。
- **5 个 workspace** 全部走 `Selector` / `Consumer` 订阅 notifier 字段，各自只 rebuild 必要子树。
- **`_HistoryStateMixin` 评估为不迁**：每个工作区已有 `HistoryStack`（本身就是 `ChangeNotifier`），UI 层 [home_shell_state.dart](lib/src/home/home_shell_state.dart) 已用 `ListenableBuilder` 订阅；mixin 自身的 setState 仅在首次创建栈和 `_isApplyingHistory` 翻转时触发，频率低、收益不抵迁移成本。
- **API/local settings 字段（plan 中的 Phase 12）**：`TextEditingController` + 重置 snapshot 强耦合，且都是单 workspace 内部状态，跨 workspace 重渲收益小。当前不推进，待有具体性能信号再评估。

**P0-1 整体收益**：父级 `setState` 不再因 notifier 字段变更触发全树重建。生成图片、批量结果、GIF 合成、编辑器调整、库 prepend 等高频操作都只触发对应 `Selector` 子树重建。后续 P1/P2 工作（导航重组、历史工具栏统一、Sliver 化等）不依赖 P0-1 的剩余子项，可独立推进。

### P1 #4：统一历史工具栏可见性规则

之前形态：父级 `Column` 顶部条件渲染 `_buildHistoryToolbar()`，仅图片编辑器特殊处理（`_selectedFeature != WorkspaceFeature.imageEditor` 才显示），编辑器自己把 `historyControls` 塞进 `WorkspacePage.trailing`。规则不统一，新加工作区时容易遗漏。

| 改动 | 文件 | 备注 |
|---|---|---|
| 6 个 workspace 加 `historyControls` prop，并放入各自 `WorkspacePage.trailing` | [image_generation](lib/src/widgets/workspaces/image_generation_workspace.dart) / [animation_project](lib/src/widgets/workspaces/animation_project_workspace.dart) / [gif_composer](lib/src/widgets/workspaces/gif_composer_workspace.dart) / [pixel_art](lib/src/widgets/workspaces/pixel_art_workspace.dart) / [local_settings](lib/src/widgets/workspaces/local_settings_workspace.dart) | pixel_art 把 historyControls 与原有 focus toggle 合并到一个 Wrap |
| `image_library_workspace` 不走 `WorkspacePage`（保留自定义 Padding 布局，因含 `Expanded(Selector)`），自加 history header Row | [image_library_workspace.dart](lib/src/widgets/workspaces/image_library_workspace.dart) | 用 Row 在标题旁放 historyControls，避免 `Expanded` 在 SingleChildScrollView 内崩 |
| `WorkspacePage` 重构：header（title + trailing）固定在顶部，children 在下方 `Expanded > SingleChildScrollView` 内单独滚动 | [layout_navigation_widgets.dart](lib/src/widgets/layout_navigation_widgets.dart) | 关键修复：原来整体在 SingleChildScrollView 内，长表单滚动时 trailing 按钮会被推出视口（测试 hit test 落在 y=-1061） |
| 删 `_buildHistoryToolbar` 方法与父级条件渲染；6 个 `_build*Workspace` 调用方传 `_buildCompactHistoryControls()` | [home_shell_state.dart](lib/src/home/home_shell_state.dart) + 4 个 mixin | `_ImageLibraryStateMixin` / `_LocalSettingsStateMixin` 加 `_buildCompactHistoryControls` 抽象声明（mixin 线性化在 `_EditorGifStateMixin` 之前看不到 `_HomeShellStateMixin` 的实现） |

**收益**：
- 所有支持历史的工作区使用同一接入方式，可见性规则消失。
- header 固定带来副利：长表单（设置、动画工程）下撤销/重做按钮始终可达。
- `flutter analyze` 通过，`flutter test` 191/191 全绿。

| 评审项 | 优先级 | 工作量 |
|---|---|---|
| 2. 重组导航分组 / 收纳设置入口 | P1 | 2 天 |
| ~~8. 长列表 Sliver 化 + Scrollbar 主题~~ | ~~P1~~ | ~~已完成~~ |
| 5. l10n 字面量全量替换（剩余 50+ 处） | P2 | 3 天 |
| 10. 快捷键集中管理 + 速查表 | P2 | 1 天 |
| 12. 无障碍审计 | P3 | 持续 |

### 验证要点（手动测试）

下次启动应用后请确认：

1. 设置 → 外观 切换深色 / 浅色 / 跟随系统，9 个工作区视觉无破图。
2. 像素画工作区与 patch dialog 的棋盘格背景在深色模式下不再刺眼。
3. 窗口拖到 720px 以下时，导航栏自动进入 compact，标题行换行。
4. 进入图片编辑器或像素画工作区的焦点模式后正常隐藏导航栏，退出后恢复（验证合并字段无回归）。
5. 历史菜单在无历史时悬停显示「暂无历史」。

**Phase 12：P1 #8 长列表 Scrollbar 主题 + 显式滚动条**

| 改动 | 文件 | 对应评审项 |
|---|---|---|
| 新增 `ScrollbarThemeData`：8px 粗、4px 圆角、交互式、hover/drag 时高亮为 primary 色、idle 时 outline 半透明 | [lib/src/theme/app_theme.dart](lib/src/theme/app_theme.dart) | P1-8 |
| `WorkspacePage` 从 `StatelessWidget` 改为 `StatefulWidget`，内部持有 `ScrollController`，`SingleChildScrollView` 外包 `Scrollbar(controller:)` | [lib/src/widgets/layout_navigation_widgets.dart](lib/src/widgets/layout_navigation_widgets.dart) | P1-8 |
| 新增 `_ImageLibrarySliverScrollView`（StatefulWidget），持有 `ScrollController`，`CustomScrollView` 外包 `Scrollbar(controller:)` | [lib/src/widgets/image_library_panel.dart](lib/src/widgets/image_library_panel.dart) | P1-8 |
| `_BatchGenerationJobList` 从 `StatelessWidget` 改为 `StatefulWidget`，持有 `ScrollController`，`ListView.separated` 外包 `Scrollbar(controller:)` | [lib/src/widgets/workspaces/batch_generation_workspace.dart](lib/src/widgets/workspaces/batch_generation_workspace.dart) | P1-8 |

**设计决策**：
- `ScrollbarThemeData` 全局设置 `thumbVisibility: true`，所有 `Scrollbar` 默认始终可见，桌面端用户无需 hover 才能发现可滚动区域。
- 每个需要 `thumbVisibility` 的 `Scrollbar` 必须配对显式 `ScrollController`（Flutter 要求），因此三处 `StatelessWidget` 升级为 `StatefulWidget` 以管理 controller 生命周期。
- 作品库 `CustomScrollView` 已在 Phase 11B 完成 Sliver 化（`SliverGrid` + `SliverToBoxAdapter`），本轮只补 `Scrollbar` 包装。
- 批量生成任务队列 `ListView.separated` 本身已是 lazy builder，只需加 `Scrollbar` 提供视觉反馈。
- `WorkspacePage` 的 `Scrollbar` 覆盖所有 8 个使用它的工作区（文本生图、批量、动画、编辑器、像素画、GIF、设置、接口配置），一次改动全局受益。

**收益**：
- 桌面端所有可滚动面板都有始终可见的滚动条，用户能直观判断内容长度和当前位置。
- 滚动条样式统一：idle 半透明、hover 加深、drag 高亮为主题色，深色/浅色模式自适应。
- `flutter analyze` 通过（No issues found），`flutter test` 191/191 全绿。

### 验证要点（Phase 12 手动测试）

1. 所有工作区（尤其是设置、动画工程等长表单）右侧出现始终可见的滚动条。
2. 作品库网格滚动时右侧滚动条跟随，hover 时变深，拖拽时高亮为主题色。
3. 批量生成任务队列超过 4 条时出现滚动条，可拖拽定位。
4. 深色模式下滚动条颜色自适应，不刺眼。
5. 窗口缩小到 compact 断点时滚动条不溢出或遮挡内容。

**Phase 13：P1 #2 重组导航分组 / 收纳设置入口**

| 改动 | 文件 | 对应评审项 |
|---|---|---|
| 新增 `WorkspaceCategory` 枚举 + `WorkspaceFeatureCategory` 扩展（category getter / isPrimary / primaryWorkspaceCategories / workspaceCategoryFeatures 常量 map） | [lib/src/models/workspace_feature.dart](lib/src/models/workspace_feature.dart) | P1-2 |
| 新增 l10n 键：`navGroupGenerate` / `navGroupEdit` / `navGroupAssets` / `navSettingsMenu` | [lib/src/l10n/app_zh.arb](lib/src/l10n/app_zh.arb) | P1-2 |
| **完全替换 `NavigationRail`**：`FeatureNavigationRail` 改为自定义 Column 布局，按 `primaryWorkspaceCategories` 分三组渲染 `_NavigationRailAction`，组间用 `_NavigationGroupHeader`（extended 模式显示文字标签，compact/labels 模式显示分隔线） | [lib/src/widgets/layout_navigation_widgets.dart](lib/src/widgets/layout_navigation_widgets.dart) | P1-2 |
| 新增 `_SettingsMenuButton`（PopupMenuButton）：齿轮图标，点击弹出「接口配置」「设置」两项；选中态高亮 | [lib/src/widgets/layout_navigation_widgets.dart](lib/src/widgets/layout_navigation_widgets.dart) | P1-2 |
| compact 模式 `_NavigationRailAction` 加 `Opacity(opacity: 0)` 隐藏 Text，保持 `find.text` 可发现（兼容测试） | [lib/src/widgets/layout_navigation_widgets.dart](lib/src/widgets/layout_navigation_widgets.dart) | P1-2 |
| 测试适配：`app_test.dart` 接口配置/设置改为先 tap 齿轮 tooltip 再选菜单项；`history_widget_test.dart` `_openSettings` 同理 | [test/app_test.dart](test/app_test.dart)、[test/history_widget_test.dart](test/history_widget_test.dart) | P1-2 |

**设计决策**：
- 三组分类：「生成」（文本生图 / 批量 / 动画工程）、「编辑」（图片编辑 / 像素画 / GIF 合成）、「资产」（作品库）。
- 设置入口收纳为底部齿轮 `PopupMenuButton`，不再占主导航位置。选中 apiSettings 或 localSettings 时齿轮高亮。
- 替换 Material `NavigationRail` 为自定义 Column：原因是 NavigationRail 不支持 inline 分组标题/分隔线。复用已有 `_NavigationRailAction` 保持三种模式（compact 48px / labels 64px / extended 168px）视觉一致。
- extended 模式显示分组文字标签（labelSmall + onSurfaceVariant），compact/labels 模式用 Divider 分隔。

**收益**：
- 7 个主功能按用途分组，新用户能快速定位「我要生成图」还是「我要编辑图」。
- 设置入口不再与主功能混淆，减少导航条目数（视觉上从 7+2 变为 7+齿轮+折叠）。
- `flutter analyze` 通过（No issues found），`flutter test` 191/191 全绿。

| 评审项 | 优先级 | 工作量 |
|---|---|---|
| ~~2. 重组导航分组 / 收纳设置入口~~ | ~~P1~~ | ~~已完成~~ |
| ~~8. 长列表 Sliver 化 + Scrollbar 主题~~ | ~~P1~~ | ~~已完成~~ |
| 5. l10n 字面量全量替换（剩余 50+ 处） | P2 | 3 天 |
| 10. 快捷键集中管理 + 速查表 | P2 | 1 天 |
| 12. 无障碍审计 | P3 | 持续 |

### 验证要点（Phase 13 手动测试）

1. 启动后导航栏分三组（生成/编辑/资产），组间有分隔线。
2. 展开侧栏后分组标签（「生成」「编辑」「资产」）可见。
3. 底部齿轮图标点击弹出菜单含「接口配置」「设置」两项，点击可切换工作区。
4. 当前在接口配置或设置工作区时，齿轮图标高亮。
5. compact 模式下所有图标可点击，tooltip 正确显示中文名。

## 2026-05-19：当前状态与下一任务队列

### 当前结论

动画工程主路径已经完成，不需要再创建新的动画工程主线任务。后续需要继续按小 Phase 收敛 UI 体验，其中“面板可拖拽”已经暴露为跨工作区 UX 问题，应优先于快捷键速查表处理。

已完成或已收敛：

1. P0-1 拆分上帝类 State：已完成，5 个 `ChangeNotifier` 已接入 `MultiProvider`，核心 workspace 已用 `Selector` / `Consumer` 降低重建范围。
2. P1-2 导航分组 / 收纳设置入口：已完成。
3. P1-4 历史工具栏统一：已完成。
4. P1-8 长列表 Sliver 化 + Scrollbar 主题：已完成。
5. 动画工程阶段 1-5：已完成，详见 [animation-timeline-architecture.md](animation-timeline-architecture.md)。
6. Phase 14：动画工程工作台布局重构已完成。
7. Phase 15：动画工程作品库序列导入与面板拖拽已完成。

最近验证：

- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\animation_project_workspace_test.dart` 通过（3/3）。

### Phase 14：P0-UX 动画工程工作台布局重构（已完成）

本轮已按用户反馈完成“旧帧动画入口删除，保留新的动画工程工作台”的重构。

完成项：

1. `AnimationProjectWorkspace` 改为两态入口：
   - 无工程：显示 `创建动画工程`，用于生成 Sprite Sheet、导入图片序列、把来源导入为动画工程。
   - 有工程：显示新的 `_AnimationProjectWorkbench`，不再把旧 `FrameAnimationPreviewPanel` 当作动画工程主视觉。
2. 新增底部 `_AnimationTimelineDock`：
   - 面板标题为 `轨道时间轴`。
   - 左侧显示轨道列表。
   - 右侧显示当前轨道的 `序列帧时间轴` 与单帧编辑控件。
3. 瘦身左侧 `工程控制`：
   - 保留工程摘要、导入、导出、工程设置和资源诊断。
   - 移除轨道列表和帧时间轴，避免左侧控制列无限变长。
4. `_AnimationProjectPreview` 只负责工程合成预览。
5. `WorkspacePage` 增加 `scrollable` 参数：创建态保留整页滚动，工程态关闭外层滚动。
6. 更新 `test/animation_project_workspace_test.dart` 覆盖新工作台结构。

### Phase 15：P1-UX 动画工程作品库导入与面板拖拽（已完成）

本轮针对用户反馈继续优化动画工程：

1. 导入入口拆分为两条清晰路径：
   - `导入本地图片序列`：继续使用本地文件选择器。
   - `从作品库导入序列`：复用作品库选择器，支持多选作品库静态图片。
2. 状态层新增 `_importLibraryImagesToAnimationProject()`：
   - 允许 `generatedImage`、`spriteSheet`、`spriteFrame`、`editedImage`。
   - 排除 GIF 与动画工程文件，避免把动态文件或工程文件误当作单帧序列。
   - 本地与作品库导入最终复用 `_importImagePathsToAnimationProject()`，避免两套导入逻辑漂移。
3. 动画工程工作台主面板支持拖拽调尺寸：
   - 左侧 `工程控制` 宽度可拖拽。
   - 底部 `轨道时间轴` 高度可拖拽。
   - 双击把手可复位。
   - 尺寸通过 `SharedPreferences` 持久化。
4. 创建态和已有工程态都提供作品库导入入口，避免创建工程后追加轨道时只能导入本地文件。
5. `test/animation_project_workspace_test.dart` 更新：
   - 覆盖本地导入按钮回调。
   - 覆盖作品库导入按钮回调。
   - 为拖拽尺寸持久化补 `SharedPreferences.setMockInitialValues({})`。

验证：

- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\animation_project_workspace_test.dart` 通过（3/3）。

### 下一任务队列

**Phase 16：P1-UX 全局面板拖拽与尺寸持久化审计**

目标：

- 审计所有多面板工作区，确认哪些已经使用 `ResponsiveWorkspaceSplit`，哪些仍是固定宽高或只能滚动。
- 统一可拖拽分割把手的可发现性、tooltip、hover/drag 视觉反馈和双击复位行为。
- 给需要长期工作的工作区补尺寸持久化，避免每次打开都恢复到不合适的固定布局。

建议优先区域：

1. 动画工程：已完成主面板宽度和时间轴高度，后续可评估时间轴内部轨道列表宽度。
2. 图片编辑、像素画、批量生成、文本生图：确认 `ResponsiveWorkspaceSplit` 把手是否足够明显。
3. 作品库、接口配置、本地设置：评估是否需要可折叠或可调尺寸，而不是盲目加入拖拽。

验收：

1. 列出所有工作区的面板布局状态。
2. 对固定多面板布局补可拖拽或明确说明不需要拖拽。
3. 关键拖拽尺寸可持久化，并可双击复位。
4. `flutter analyze` 通过。
5. 相关 widget 测试通过。

**Phase 17：P2-10 快捷键速查表 UI 收尾**

目标：

- 把已经抽出的 `AppShortcuts.global` 和 `appShortcutCheatSheet` 真正展示到本地设置工作区。
- 复用现有 `AppPanel` 风格，展示快捷键名称与键位组合。
- 用已有 l10n 键：`shortcutsSectionTitle`、`shortcutsSectionDescription`、`shortcutLabelUndo`、`shortcutLabelRedo`、`shortcutLabelRedoAlt`。

验收：

1. 本地设置页出现「快捷键」区块。
2. 显示撤销、重做、备选重做三条快捷键。
3. Windows/Linux 展示 Ctrl 组合；如后续需要，再补 macOS Meta 展示。
4. `flutter analyze` 通过。
5. 相关 widget 测试或 `test/app_test.dart` 通过。

### Phase 17：P2-10 快捷键速查表 UI 收尾（已完成）

本轮把已经抽出的全局快捷键数据展示到本地设置页。

完成项：

1. `LocalSettingsWorkspace` 新增「快捷键」区块：
   - 位置在「外观」之后、「默认生成设置」之前，打开设置页即可看到。
   - 复用 `AppPanel` 风格，与现有设置区块保持一致。
2. 快捷键列表复用 `appShortcutCheatSheet`：
   - 撤销：`Ctrl + Z`。
   - 重做：`Ctrl + Y`。
   - 重做（备选）：`Ctrl + Shift + Z`。
3. 文案复用已有 l10n 键：
   - `shortcutsSectionTitle`
   - `shortcutsSectionDescription`
   - `shortcutLabelUndo`
   - `shortcutLabelRedo`
   - `shortcutLabelRedoAlt`
4. `test/app_test.dart` 补充设置页断言，覆盖快捷键区块和键位展示。

验证：

- 待本轮收尾运行 `flutter analyze`。
- 待本轮收尾运行 `test/app_test.dart`。

**Phase 18：P2-5 l10n 字面量分批替换**

目标：

- 继续把 UI 层中文字面量迁移到 `AppLocalizations`。
- 分批推进，避免一次改动覆盖所有工作区导致回归难定位。

建议顺序：

1. 本地设置和接口配置。
2. 文本生图和批量生成。
3. 作品库。
4. 图片编辑和像素画。
5. 动画工程。

验收：

1. 每批新增必要 ARB 键。
2. 生成的 l10n 文件同步更新。
3. `flutter analyze` 通过。
4. 对应工作区测试通过。

**Phase 19：P3-12 无障碍审计**

目标：

- 补齐关键图标按钮、画布、时间轴、作品库操作的语义信息。
- 增加基础无障碍测试，覆盖键盘可达性、tooltip / semanticLabel、控件命名和对比度风险。

建议优先区域：

1. 导航栏和设置齿轮菜单。
2. 动画工程时间轴与预览控制。
3. 作品库批量操作与卡片菜单。
4. 像素画和图片编辑画布工具。

验收：

1. 关键纯图标按钮有可读语义。
2. 常用路径可用键盘聚焦和触发。
3. `meetsGuideline` 或等价 widget 测试覆盖核心页面。
4. `flutter analyze` 与相关测试通过。

### 是否需要创建新任务

不需要再创建新的动画工程主线任务。动画工程主路径已经替换为新工作台；后续只需要按 UX 子任务继续打磨。

下一步建议继续推进：

```text
Phase 18：P2-5 l10n 字面量替换第四批（图片编辑 + 像素画）
```

### Phase 16：P1-UX 全局面板拖拽与尺寸持久化审计（已完成）

本轮完成跨工作区面板拖拽审计，并统一已有分栏的拖拽体验。

审计结论：

1. 已接入 `ResponsiveWorkspaceSplit` 并具备宽度持久化：
   - 文本生图：`storageKey: image_generation`。
   - 批量生成：`storageKey: batch_generation`。
   - 图片编辑普通模式：`storageKey: general_image_editor`。
   - 图片编辑 Sprite Sheet 模式：`storageKey: image_editor`。
   - 像素画编辑：`storageKey: pixel_art`。
   - 动画工程创建态：`storageKey: animationProject.creation`。
2. 动画工程已有工程态继续保留两段可调布局：
   - 左侧工程控制宽度可拖拽并持久化。
   - 底部轨道时间轴高度可拖拽并持久化。
3. 作品库、接口配置、本地设置暂不强行加入拖拽：
   - 作品库当前是单主面板 + 内部筛选区 + Sliver 网格，不是左右多面板结构。
   - 接口配置和本地设置是表单型单栏工作区，加入分栏拖拽会增加操作噪音。

完成项：

1. 新增公共 `WorkspaceResizeHandle`：
   - 横向 / 纵向拖拽统一使用同一个组件。
   - tooltip 统一提示“拖动调整宽度，双击复位”或调用方传入的高度/工程控制提示。
   - 增加 `Semantics` 标签，便于测试和后续无障碍审计。
   - 加强把手可发现性：把手区域更宽，带浅色背景和中心线。
2. `ResponsiveWorkspaceSplit` 改为使用公共 `WorkspaceResizeHandle`。
3. 动画工程工作台删除重复的私有 `_AnimationWorkbenchResizeHandle`，改为复用公共把手。
4. 新增 `test/responsive_workspace_split_test.dart`：
   - 覆盖拖拽后宽度变化。
   - 覆盖 `SharedPreferences` 持久化后重建恢复宽度。
   - 覆盖双击复位并清除持久化值。
   - 覆盖把手语义标签。

验证：

- 待本轮收尾运行 `flutter analyze`。
- 待本轮收尾运行 `test/responsive_workspace_split_test.dart` 与相关工作区测试。

### Phase 18：P2-5 l10n 字面量分批替换（第一批已完成）

本轮先处理“本地设置 + 接口配置”，避免一次替换全项目文案导致回归范围过大。

完成项：

1. 新增 `appL10nOf(context)`：
   - 正常应用环境优先读取 `Localizations`。
   - 独立 widget 测试未挂 l10n delegate 时回退到生成的中文本地化实例。
   - 这样可复用 generated l10n，同时不破坏已有裸 `MaterialApp` 测试。
2. 本地设置迁移到 `AppLocalizations`：
   - 工作区标题和说明。
   - 外观区块和主题三选一。
   - 本地状态、默认生成设置、常用预设、作品库迁移、配置入口、存储清理、恢复默认等核心文案。
   - 预设摘要中的数量、循环次数等动态文案改为 ARB placeholder。
3. 接口配置迁移到 `AppLocalizations`：
   - 工作区标题和说明。
   - 配置选择器、面板标题、新增/删除配置 tooltip。
   - 接口名称、供应商、请求超时、生图尺寸能力、模型字段、模型列表获取状态。
   - 保存/测试按钮、保存状态、基础测试、密钥显示/隐藏等核心文案。
4. `apiModelFetchHelperText()` 保持纯函数测试可用：
   - 可选传入 `AppLocalizations`。
   - 未传入时使用生成的中文本地化实例。
5. `app_zh.arb` 新增本批所需键，并同步生成 `app_localizations.dart` / `app_localizations_zh.dart`。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\api_settings_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

下一步：

```text
Phase 18 第二批：继续迁移“文本生图 + 批量生成”核心 UI 文案。
```

### Phase 18：P2-5 l10n 字面量分批替换（第二批已完成）

本轮处理“文本生图 + 批量生成”，继续保持小范围迁移。

完成项：

1. 文本生图迁移到 `AppLocalizations`：
   - 工作区标题和说明。
   - `ControlPanel` 的生成配置标题、正向提示词、负向提示词、目标数量、生成按钮和忙碌状态。
2. 批量生成迁移到 `AppLocalizations`：
   - 工作区标题和说明。
   - 队列控制面板标题、批量提示词、负向提示词、目标数量、每批张数。
   - 队列拆分说明、入队、开始/继续/暂停/恢复/取消/重试/清理等操作按钮。
   - 队列运行状态提示、任务队列空状态、任务数量、任务摘要、单任务重试/移除 tooltip。
   - 任务状态文案在 UI 层改为 l10n 映射；底层 `batchGenerationJobStatusLabel()` 仍保留纯模型/测试用途。
3. `generation_form_widgets.dart` 中的动画工程 `SpriteSheetGenerationPanel` 本轮未迁移，留给后续“动画工程”批次，避免扩大回归范围。
4. `app_zh.arb` 新增本批所需键，并同步生成 `app_localizations.dart` / `app_localizations_zh.dart`。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\batch_generation_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

下一步：

```text
Phase 18 第三批：继续迁移“作品库”核心 UI 文案。
```

### Phase 18：P2-5 l10n 字面量分批替换（第三批已完成）

本轮处理“作品库”相关 UI 文案，覆盖作品库工作区、面板、卡片菜单、选择弹窗和切片管理弹窗。

完成项：

1. 作品库工作区迁移到 `AppLocalizations`：
   - 工作区标题和说明。
   - 作品库主面板标题、总数、搜索、项目/标签筛选、排序、选择当前结果、展开切片、已选数量、导出/删除已选。
   - 空状态、分页状态、分页 tooltip、每页数量文案。
2. 作品卡片迁移到 `AppLocalizations`：
   - 已保存帧数徽标。
   - 主操作按钮：切片、打开、复用、编辑。
   - 编辑作品信息、更多操作 tooltip。
   - 菜单项：打开动画工程、在编辑器中打开、复用/复制生成参数、背景转透明、复制图片、导出图片/文件、复制路径、打开位置、删除作品。
3. 作品库选择器和切片弹窗迁移到 `AppLocalizations`：
   - 选择按钮、选择数量。
   - 切片加载错误、切片管理标题、已保存状态、保存这一帧、全部保存为切片。
   - 切片选择器默认标题、已选/未选状态、确认选择。
4. 作品库相关通用弹窗迁移到 `AppLocalizations`：
   - 图片来源选择中的本地文件/作品库入口。
   - 编辑作品信息弹窗字段和按钮。
   - 删除作品确认弹窗，包括批量删除、单个删除和级联切片提示。
5. 服务层数据值未迁移：
   - 例如 `source: '作品库导入'`、测试数据标题等仍作为数据保留，不属于本批 UI 控件文案。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_pagination_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_menu_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_deletion_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

下一步：

```text
Phase 18 第四批：继续迁移“图片编辑 + 像素画”核心 UI 文案。
```

### Phase 18：P2-5 l10n 字面量分批替换（第四批已完成）

本轮处理“图片编辑 + 像素画”核心 UI 文案，继续按工作区分批迁移，避免一次性改完整个编辑器导致回归范围过大。

完成项：

1. 像素画工作区迁移到 `AppLocalizations`：
   - 工作区说明、全屏编辑 tooltip。
   - 工具面板、画布尺寸、宽高字段、应用画布尺寸。
   - 画笔 / 橡皮 / 取色工具、画笔大小、颜色、缩放。
   - 撤销 / 重做复用历史通用文案。
   - 新建空白、清空、保存到作品库、保存中。
   - 画布面板标题和色板 tooltip。
2. 通用图片编辑核心入口迁移到 `AppLocalizations`：
   - 控制面板标题、待编辑图片选择器、选择 / 更换 / 清除图片。
   - 快捷处理区块和四个主面板标签：几何、外观、标注、输出。
   - 主面板标题和说明：几何调整、外观处理、标注、输出。
   - 撤销 / 重做、生成完整预览、重置参数、应用并保存、处理中。
   - 编辑预览标题、空状态、加载中、失败标题、无结果兜底和预览底部提示。
3. `general_image_editor_widgets.dart` 的内部细分项暂未全部迁移：
   - 预设、版本、变换、裁剪、尺寸、色彩、效果、选区、标注字段、输出格式和摘要函数仍留给后续批次。
   - 本轮优先处理高频入口和测试覆盖路径，控制回归面。
4. `app_zh.arb` 新增本批所需键，并同步生成 `app_localizations.dart` / `app_localizations_zh.dart`。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\pixel_art_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_editor_pixelation_entry_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

下一步：

```text
Phase 18 第五批：继续迁移“动画工程”核心 UI 文案，重点覆盖动画工程工作台和 Sprite Sheet 生成面板。
```

### Phase 18：P2-5 l10n 字面量分批替换（第五批已完成）

本轮处理“动画工程”核心 UI 文案，覆盖创建态、Sprite Sheet 生成面板、工程控制主操作、工程设置和预览状态。

完成项：

1. `SpriteSheetGenerationPanel` 迁移到 `AppLocalizations`：
   - 序列帧生成配置标题、格数徽标。
   - 提示词内容、提示词提示、负向提示词提示。
   - 行数 / 列数字段和选项值。
   - 生成 Sprite Sheet 按钮和生成中状态。
2. 动画工程工作区入口迁移到 `AppLocalizations`：
   - 工作区说明。
   - 创建动画工程面板、工程来源、正在生成来源、暂无可导入来源。
   - 导入为动画工程、正在导入工程、导入本地图片序列、从作品库导入序列、导出来源 Sprite Sheet、正在导出。
3. 动画工程工作台主控制迁移到 `AppLocalizations`：
   - 工程控制面板、帧 / 轨道单位、工程摘要。
   - 新建轨道、导出合成 Sprite Sheet、导出工程 GIF、导出工程 PNG 序列、导出当前轨道 GIF、导出 PNG 序列、关闭工程。
   - 轨道时间轴面板标题。
4. 工程设置迁移到 `AppLocalizations`：
   - 工程设置标题、工程默认帧时长、工程播放方式、GIF 循环次数、次数后缀、导出包含隐藏轨道。
5. 动画工程预览迁移到 `AppLocalizations`：
   - 动画工程预览标题、正在渲染工程合成、渲染失败、没有可用的渲染数据、重新渲染、工程没有可见帧。
   - 播放 / 暂停、上一帧、下一帧、合成帧状态。
6. `app_zh.arb` 新增本批所需键，并同步生成 `app_localizations.dart` / `app_localizations_zh.dart`。
7. 本批暂未迁移动画工程细节：
   - 资源诊断、轨道卡片、单帧时间轴和单帧变换区的内部字段留给下一批。
   - 保持小批次推进，避免一次性改动影响所有动画工程测试路径。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\animation_project_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\animation_project_editor_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\animation_project_service_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 首次并行跑 `animation_project_workspace_test.dart` 时出现 Flutter 测试编译缓存文件冲突，单独重跑通过；这不是业务断言失败。

下一步：

```text
Phase 18 第六批：迁移动画工程剩余细节（资源诊断、轨道卡片、单帧时间轴、单帧变换）和图片编辑内部细分项。
```

### Phase 18：P2-5 l10n 字面量分批替换（第六批已完成）

本轮继续处理动画工程剩余细节，收掉 `animation_project_workspace.dart` 中的 UI 中文硬编码。

完成项：

1. 动画工程来源摘要迁移到 `AppLocalizations`：
   - 单张 Sprite Sheet 来源摘要。
   - 多张序列帧来源摘要。
   - 工程控制宽度和时间轴高度拖拽把手 tooltip。
2. 资源诊断迁移到 `AppLocalizations`：
   - 资源诊断标题、重新检查。
   - 检查中、检查失败、资源完整状态。
   - 缺失资源、工程可修复、时间轴引用资源缺失、未引用资源缺失、可自动修复说明。
   - 自动修复数量、未引用资源数量、空帧引用数量、自动修复按钮。
   - 未记录路径、资源问题的时间轴引用次数、重新绑定按钮。
3. 轨道列表迁移到 `AppLocalizations`：
   - 轨道标题、上移 / 下移 / 复制 / 删除轨道。
   - 显示 / 隐藏轨道，锁定 / 解锁轨道。
   - 轨道名称、帧时长、播放方式、帧数量。
4. 序列帧时间轴迁移到 `AppLocalizations`：
   - 未选择轨道、轨道无帧、锁定轨道无帧空状态。
   - 插入空白帧、插入图片帧。
   - 序列帧时间轴标题和当前轨道帧数量状态。
5. 单帧编辑区迁移到 `AppLocalizations`：
   - 单帧时长、当前帧。
   - 替换帧、清空帧、像素化当前帧、像素化帧、复制帧、删除帧。
   - 单帧变换、水平翻转、垂直翻转、重置单帧变换、不透明度。
6. `animation_project_workspace.dart` 通过 `rg "[\u4e00-\u9fff]"` 检查，已无中文 UI 硬编码命中。
7. `app_zh.arb` 新增本批所需键，并同步生成 `app_localizations.dart` / `app_localizations_zh.dart`。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\animation_project_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\animation_project_editor_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\animation_project_service_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

下一步：

```text
Phase 18 第七批：迁移图片编辑内部细分项（预设、版本、变换、裁剪、尺寸、色彩、效果、选区、标注字段、输出格式和摘要函数）。
```

### Phase 18：P2-5 l10n 字面量分批替换（第七批已完成）

本轮收掉 `general_image_editor_widgets.dart` 的图片编辑内部细分项 UI 中文硬编码。

完成项：

1. 图片编辑快捷预设和版本快照迁移到 `AppLocalizations`：
   - 常用预设标题、说明和透明 PNG / 社媒 JPEG / 清晰 JPEG / 像素风 PNG。
   - 版本快照标题、保存当前版本、暂无保存版本、自动版本标签。
   - 版本恢复 / 删除 tooltip 和版本摘要。
2. 几何、外观、选区、标注和输出细分项迁移到 `AppLocalizations`：
   - 旋转 / 翻转、裁剪边距、输出尺寸、色彩调整、效果处理。
   - 局部选区、标注类型 / 文字 / 坐标 / 线宽 / 字号 / 填充。
   - 输出格式、JPEG 质量和预览加载失败提示。
3. 摘要和枚举标签迁移到 `AppLocalizations`：
   - 旋转角度、裁剪、尺寸、色彩、滤镜、选区、版本、标注、输出摘要。
   - 标注类型、标注颜色、填充后缀和滤镜标签。
4. `general_image_editor_widgets.dart` 通过 `rg "[\u4e00-\u9fff]"` 检查，已无中文 UI 硬编码命中。
5. `general_image_editor_widgets_test.dart` 更新为当前折叠区标题，避免继续查找旧的“版本 / 效果 / 选区”标题。
6. `app_zh.arb` 新增本批所需键，并同步生成 `app_localizations.dart` / `app_localizations_zh.dart`。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_editor_pixelation_entry_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

下一步：

```text
Phase 18 第八批：迁移共享图片 / Sprite Sheet 编辑相关组件的中文硬编码，优先处理 common_form_widgets、image_size_widgets、image_advanced_settings_widgets 和 image_editor_workspace。
```

### Phase 18：P2-5 l10n 字面量分批替换（第八批已完成）

本轮处理共享图片 / Sprite Sheet 编辑组件，优先收掉多工作区复用组件里的用户可见中文硬编码。

完成项：

1. `common_form_widgets.dart` 迁移到 `AppLocalizations`：
   - `FrameCountBadge` 默认单位和 tooltip。
   - Sprite Sheet 切片校准标题、已调整徽标、说明、边距 / 间距字段、重置按钮和摘要。
   - 数字步进按钮 tooltip、请求调试按钮 / 弹窗、复制成功提示。
   - `TemplateImagePicker` 默认标题、选择 / 更换兜底、清除 tooltip 和加载失败提示。
2. `image_advanced_settings_widgets.dart` 迁移到 `AppLocalizations`：
   - 高级输出参数标题、摘要后缀、质量 / 背景 / 输出格式 / 审核强度字段。
   - 最终用户 ID、参考图保真度、高 / 低选项和输出压缩率提示。
3. `image_size_widgets.dart` 迁移到 `AppLocalizations`：
   - 宽度 / 高度、自定义尺寸、尺寸档位、方向、分辨率模式标签。
   - 方图 / 横图 / 竖图、约束说明、无效尺寸兜底、Gemini 画幅比例和请求尺寸摘要。
4. `image_editor_workspace.dart` 迁移到 `AppLocalizations`：
   - 图片编辑工作区标题、普通图片 / Sprite Sheet 模式说明和分段按钮。
   - 进入 / 退出专注模式 tooltip、切片查看标题和空状态。
5. 本批四个目标文件通过 `rg "[\u4e00-\u9fff]"` 检查，已无中文 UI 硬编码命中。
6. `app_zh.arb` 新增本批所需键，并同步生成 `app_localizations.dart` / `app_localizations_zh.dart`。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\batch_generation_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_generation_builders_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_editor_pixelation_entry_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\preview_display_fit_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 并行跑多条 Flutter widget 测试时再次出现 `build\test_cache` dill 文件并发写入冲突；清理残留测试进程后，单独重跑 `image_editor_pixelation_entry_test.dart` 通过。后续 widget 测试建议优先串行跑，减少 Flutter 测试编译缓存争用。

### Phase 18：P2-5 l10n 字面量分批替换（第九批已完成）

本轮收掉 Sprite Sheet 预览 / 旧编辑辅助组件剩余中文硬编码，重点覆盖
`frame_animation_preview_*`、`editor_gif_widgets.dart`、
`background_transparency_dialog.dart` 和 `patch_image_framing_dialog.dart`。

完成项：

1. `frame_animation_preview_widgets.dart`、`frame_animation_preview_parts.dart`
   和 `frame_animation_preview_builders.dart` 迁移到 `AppLocalizations`：
   - 生成 / 失败 / 预览失败 / 切片构建中等状态文案。
   - 播放模式、目标选择、网格检查模式标签。
   - 行标题、帧选项、播放速度、播放 / 导出 / 像素化按钮。
   - 当前状态、目标选择提示和播放查看提示。
2. `background_transparency_dialog.dart` 迁移到 `AppLocalizations`：
   - 标题、默认说明、来源说明、细节说明。
   - 容差标签和生成按钮。
3. `patch_image_framing_dialog.dart` 迁移到 `AppLocalizations`：
   - 标题、完整显示 / 填满格子 / 居中按钮。
   - 生成取景单帧按钮。
4. `editor_gif_widgets.dart` 迁移到 `AppLocalizations`：
   - 编辑配置、Sprite Sheet 图片、单帧图片、替换目标和适配方式。
   - 复制上一帧、清空当前格、插入 / 替换到当前格、替换中。
   - 目标帧位置说明、编辑工具区标题与摘要。
   - 调整取景、透明背景、像素块与像素化操作文案。
   - 适配方式下拉改为本地化映射，不再依赖旧中文 helper。
5. 本批 4 个目标文件通过 `rg "[\u4e00-\u9fff]"` 检查，已无中文 UI 硬编码命中。
6. `app_zh.arb` 新增本批所需键，并同步生成 `app_localizations.dart` /
   `app_localizations_zh.dart`。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\frame_animation_preview_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_editor_pixelation_entry_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，
  生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 之前并行跑多条 Flutter widget 测试时，再次撞到 `build\test_cache`
  / `engine.stamp` 的工具层冲突；清理并改为串行后，受影响测试已重新通过。
- 后续 widget 测试建议优先串行跑，减少 Flutter 工具缓存争用。

### Phase 18：P2-5 l10n 字面量分批替换（第十批已完成）

本轮收掉 home state 里的历史消息和可见提示，优先处理 `history_state.dart`
与 `home_shell_state.dart`。

完成项：

1. `history_state.dart` 迁移到 `AppLocalizations`：
   - 撤销成功 / 多步撤销 / 撤销失败提示。
   - 重做成功 / 多步重做 / 重做失败提示。
2. `home_shell_state.dart` 迁移到 `AppLocalizations`：
   - 恢复默认表单历史动作和重置提示。
   - 历史按钮工具条、历史菜单标题 / 空状态 / 撤销到 / 重做到 / 下一步 / 步数标签。
   - 像素画保存到作品库的标题、来源、提示词摘要、保存动作、成功 / 失败提示。
3. `history_state.dart` 通过 `rg "[\u4e00-\u9fff]"` 检查，已无中文硬编码。
4. `home_shell_state.dart` 只剩消息分类规则里的中文关键词，不再包含用户可见 UI 硬编码。
5. `app_zh.arb` 新增本批所需键，并同步生成 `app_localizations.dart` /
   `app_localizations_zh.dart`。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\history_widget_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，
  生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

下一步：

```text
Phase 18 第十一批：继续处理 editor_gif_state.dart 与 image_generation_state.dart 的剩余中文硬编码，优先收掉导入 / 导出 / 轨道 / 工程 / 生成结果相关文案。
```

### Phase 18：P2-5 l10n 字面量分批替换（第十一批已完成）

本轮收掉图片编辑状态层和文本生图 / 动画工程状态层的剩余用户可见文案。

完成项：

1. `editor_gif_state.dart` 迁移到 `AppLocalizations`：
   - Sprite Sheet 与单帧图片选择、清空、载入提示。
   - 背景转透明、单帧取景、模板图片选择。
   - GIF / Sprite Sheet 导出、替换 / 复制 / 清空单帧、像素化当前帧 / 整张。
   - 通用图片编辑的选图、载入、保存和错误提示。
2. `image_generation_state.dart` 迁移到 `AppLocalizations`：
   - 文本生图校验、生成成功、复制 / 导出、透明背景处理。
   - Sprite Sheet 生成、请求超时、异常兜底。
   - 动画工程导入、轨道 / 序列帧编辑、资源重绑、自动修复和导出。
3. `editor_gif_state.dart` 与 `image_generation_state.dart` 均通过
   `rg "[\u4e00-\u9fff]"` 检查，已无中文硬编码。
4. `app_zh.arb` 新增本批所需键，并同步生成 `app_localizations.dart` /
   `app_localizations_zh.dart`。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\image_editor_pixelation_entry_test.dart` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\frame_animation_preview_widgets_test.dart` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\animation_project_workspace_test.dart` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\animation_project_editor_test.dart` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\animation_project_service_test.dart` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_generation_builders_test.dart` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\history_widget_test.dart` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，
  生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮只执行编译，没有执行 `flutter run -d windows`，避免启动新的应用窗口。
- `app_test.dart` 曾因动画工程错误面板文案从带句号变成不带句号而失败；
  已补独立错误文案键并恢复原 UI 行为，重跑后通过。

下一步：

```text
Phase 18 第十二批：继续收尾剩余状态层 / 弹窗 / 预览组件中文硬编码，优先处理 api_config_state.dart、batch_generation_state.dart、image_library_state.dart、local_settings_state.dart、app_dialogs.dart 和 preview_panel.dart。
```

### Phase 18：P2-5 l10n 字面量分批替换（第十二批已完成）

本轮收掉接口配置状态提示、批量生成状态提示、结果预览面板和通用弹窗的用户可见中文硬编码。

完成项：

1. `api_config_state.dart` 迁移到 `AppLocalizations`：
   - 删除最后一个接口配置的阻止提示改为本地化文案。
   - 文件内剩余 `默认配置` 是 `TextEditingController` 初始数据默认名，和 `ApiConfig.defaults()` / 逻辑测试一致，暂不作为 UI 文案迁移。
2. `batch_generation_state.dart` 迁移到 `AppLocalizations`：
   - API Key / 模型 / 批量提示词校验提示。
   - 批量任务加入、暂停、恢复、停止、取消、失败重试提示。
   - 批量结果标题、作品来源、透明背景处理成功 / 失败和复制失败提示。
3. `preview_panel.dart` 与 `preview_common_widgets.dart` 迁移到 `AppLocalizations`：
   - 结果预览标题、生成中、失败、空状态。
   - 结果标题、等待占位、图片加载失败、复制 / 导出 / 关闭 / 背景转透明 tooltip。
   - `PreviewStateSurface` 的默认重试按钮文案改为本地化兜底。
4. `app_dialogs.dart` 迁移到 `AppLocalizations`：
   - 首次接口配置弹窗。
   - 恢复默认表单确认弹窗。
   - Sprite Sheet 单帧替换确认弹窗和三列预览标题。
5. `app_zh.arb` 新增本批所需键，并同步生成 `app_localizations.dart` /
   `app_localizations_zh.dart`。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\preview_panel_test.dart` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\batch_generation_workspace_test.dart` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\api_config_logic_test.dart` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_generation_builders_test.dart` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，
  生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮只执行编译，没有执行 `flutter run -d windows`，避免启动新的应用窗口。

下一步：

```text
Phase 18 第十三批：处理 image_library_state.dart 与 local_settings_state.dart 的剩余状态提示、导入 / 导出 / 删除 / 作品库归档等中文硬编码；完成后继续全局扫描剩余 UI 文案。
```

### Phase 18：P2-5 l10n 字面量分批替换（第十三批已完成）

本轮收掉作品库状态层和本地设置状态层的剩余用户可见文案。

完成项：

1. `image_library_state.dart` 迁移到 `AppLocalizations`：
   - 作品库选择、切片保存、切片管理、作品信息编辑提示。
   - 复制路径 / 图片、导出单个作品、批量导出、打开所在位置提示。
   - 从作品库打开动画工程、背景转透明、删除作品、在编辑器中打开作品。
   - 复用 / 复制生成参数、透明背景作品标题和提示词摘要。
2. `local_settings_state.dart` 迁移到 `AppLocalizations`：
   - 生成参数变更历史标签：分辨率、生成数量、正向 / 负向 / 动画工程提示词。
   - 高级输出参数历史标签：质量、背景、输出格式、压缩率、审核强度、参考图保真度和最终用户 ID。
   - 预设默认名称、保存 / 应用 / 删除提示和历史标签。
   - 存储清理、作品库归档导出 / 导入成功与失败提示。
3. `image_library_state.dart` 与 `local_settings_state.dart` 均通过
   `rg "[\u4e00-\u9fff]"` 检查，已无中文硬编码。
4. `app_zh.arb` 新增本批所需键，并同步生成 `app_localizations.dart` /
   `app_localizations_zh.dart`。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\history_widget_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_deletion_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_archive_service_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_menu_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_service_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\local_store_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，
  生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮只执行编译，没有执行 `flutter run -d windows`，避免启动新的应用窗口。

下一步：

```text
Phase 18 第十四批：做全局中文硬编码扫描，按“用户可见 UI 文案 / 业务数据默认值 / 开发注释或错误字符串”分类处理；优先迁移仍属于 UI 的残留项，再进入 Phase 19 无障碍审计。
```

### Phase 18：P2-5 l10n 字面量分批替换（第十四批已完成）

本轮做全局中文硬编码扫描，并优先收掉会写入作品库、历史摘要或预览结果的服务层用户可见文案。

完成项：

1. `image_generation_service.dart` 和 `batch_image_generation_service.dart` 不再内置文本生图 / 批量生成 / Sprite Sheet 来源文案，改由状态层从 `AppLocalizations` 传入。
2. `image_library_service.dart` 不再内置 GIF、动画工程、Sprite Sheet、切片帧等作品库条目标题 / 来源 / 摘要，改为标签对象由调用方提供。
3. `general_image_editing_service.dart` 的编辑摘要（裁剪、旋转、翻转、局部选区、滤镜、JPEG 质量等）改为 `GeneralImageEditSummaryLabels` 注入，预览与保存共用同一套本地化标签。
4. 新增 `library_label_builders.dart`，集中把 `AppLocalizations` 转成服务层需要的作品库和编辑摘要标签。
5. 全局扫描分类结果：
   - 已迁移：服务层中会进入作品库 / 历史 / 预览的标题、来源和编辑摘要。
   - 暂留：底层异常字符串、业务默认数据名、消息分类关键词、测试断言和注释。
   - 下一批优先：`display_labels.dart`、`image_dimensions.dart`、`api_config_logic.dart` 等工具层仍会被 UI 读取的显示标签与校验提示。
6. `app_zh.arb` 新增本批所需键，并同步生成 `app_localizations.dart` /
   `app_localizations_zh.dart`。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\general_image_editing_service_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_generation_service_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_service_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\history_widget_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_menu_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\batch_generation_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\animation_project_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，
  生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮只执行编译，没有执行 `flutter run -d windows`，避免启动新的应用窗口。

下一步：

```text
Phase 18 第十五批：继续迁移工具层显示标签和校验提示，优先处理 display_labels.dart、image_dimensions.dart、api_config_logic.dart、batch_generation_queue.dart；完成后重新全局扫描并继续收敛。
```

### Phase 18：P2-5 l10n 字面量分批替换（第十五批已完成）

本轮继续收敛工具层中会被 UI 直接读取的显示标签、校验提示和状态提示，同时保留底层纯函数的默认中文兜底，避免破坏测试、存储兼容和服务层独立调用。

完成项：

1. 新增 `localized_display_labels.dart` 中的尺寸和接口配置本地化 helper：
   - `localizedImageSizeDisplayLabels` 负责图片尺寸校验错误、能力标签、能力说明。
   - `localizedImageSizePresetLabel` 负责 1K / 2K / Gemini 比例档位的 UI 标签。
   - `localizedApiConfigServiceLabels` 负责接口测试、模型列表拉取等服务结果文案。
2. `image_dimensions.dart` 改为支持 `ImageSizeDisplayLabels` 注入：
   - `validateImageSizeForModel` / `requestSizeForModel` 可由 UI 传入 l10n 标签。
   - 图片尺寸能力标签、覆盖策略标签、能力说明均可本地化。
   - 保留默认中文兜底，供服务层、测试和非 UI 调用继续使用。
3. UI 调用点已接入本地化尺寸标签：
   - `image_size_widgets.dart` 的档位、方向、校验提示和摘要。
   - `api_settings_panel_widgets.dart` 的生图尺寸能力下拉和说明。
   - `generation_form_widgets.dart`、`batch_generation_workspace.dart` 的尺寸校验。
4. `api_config_service.dart` / `api_config_logic.dart` 支持接口配置服务文案注入：
   - API Key 缺失、基础 / 完整测试成功、测试失败、超时、官方档位兼容提示。
   - 获取模型列表成功、空列表、自动选择、超时和失败提示。
   - UI 状态层传入 `localizedApiConfigServiceLabels`，测试和底层调用仍走默认标签。
5. `batch_generation_queue.dart` 支持自动重试文案 builder 注入，`batch_generation_state.dart` 已传入 `AppLocalizations`。
6. 顺手收口明确 UI 可见的小项：
   - `layout_navigation_widgets.dart` 的分隔条 tooltip 使用 l10n，测试环境用 zh lookup 兜底。
   - `image_editor_workspace.dart` 的 Sprite Sheet 帧网格标签改由 l10n 生成。
7. 全局中文扫描分类结果：
   - 已迁移：本批涉及的尺寸 UI、接口测试 / 模型拉取 UI 消息、批量自动重试 UI 消息、分隔条 tooltip、图片编辑帧网格标签。
   - 暂留：业务默认数据名（如默认配置、动画工程 / 轨道 / 序列默认名）、底层异常字符串、消息分类关键词、调试摘要、测试断言和注释。
   - `display_labels.dart` 已不再作为主要 UI 标签来源；仍保留给调试摘要、兼容工具和少量非 UI 路径。
8. `app_zh.arb` 新增本批所需键，并同步生成 `app_localizations.dart` / `app_localizations_zh.dart`。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\api_config_logic_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\api_config_service_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\api_settings_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\batch_generation_job_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\batch_generation_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_generation_builders_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\sprite_sheet_text_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮只执行编译，没有执行 `flutter run -d windows`，避免启动新的应用窗口。

下一步：

```text
Phase 18 第十六批：做最后一轮 l10n 分类扫描，只处理仍会直接显示给用户的残留；默认数据名、底层异常、调试摘要、测试断言和注释统一记录为暂留。若没有新的 UI 硬编码，进入 Phase 19 无障碍审计。
```

### Phase 18：P2-5 l10n 字面量分批替换（第十六批已完成）

本轮执行最后一轮中文硬编码分类扫描，没有发现新的必须立即迁移的直接 UI 文案。

分类结果：

1. 直接用户可见 UI 文案：
   - 本轮未发现新的未迁移项。
   - 前序批次已经覆盖导航、工作区、弹窗、预览、作品库、状态提示、尺寸校验、接口测试和批量队列等主要路径。
2. 暂留项：
   - 业务默认数据名：`默认配置`、`动画工程`、`轨道 1`、`序列 1` 等，涉及存储兼容和默认模型数据。
   - 底层异常字符串：服务层 / 模型层文件不存在、图片无法解码、接口返回格式错误等。
   - 消息分类关键词：`home_shell_state.dart` 中用于 SnackBar 类型判断的中文关键词。
   - 调试摘要、测试断言、注释和兼容 helper。
3. 结论：
   - Phase 18 可收口。
   - 后续若要继续推进国际化，应单独立“底层异常本地化 / 默认数据名迁移”任务，不与 UI 字面量收尾混在一起。

验证：

- `rg -n "[\u4e00-\u9fff]" lib -g "!lib/src/l10n/generated/**" -g "!lib/src/l10n/app_zh.arb"` 已执行并完成分类。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。

### Phase 19：P3-12 无障碍审计（第一批已完成）

本轮先覆盖最影响桌面端操作的关键路径：导航、分栏拖拽、动画工程时间轴、预览画布、图片编辑画布和作品库卡片。

完成项：

1. `layout_navigation_widgets.dart`
   - `WorkspaceResizeHandle` 增加 `enabled` 语义。
   - 导航项增加 `Semantics`，暴露按钮、选中状态和标签。
   - `DesktopPickSourceTile` 增加按钮语义，禁用态也可被辅助技术识别。
2. `animation_project_workspace.dart`
   - 轨道卡片增加独立语义容器，暴露轨道名称和选中状态。
   - 时间轴帧块增加独立语义容器，暴露当前帧序号、帧时长和选中状态。
   - 单帧变换滑杆增加 `semanticFormatterCallback`。
   - 合成预览图增加图片语义，包含当前合成帧状态。
3. `frame_animation_preview_*`
   - 播放帧预览增加图片语义。
   - Sprite Sheet 画布增加图片 / 可点击语义，包含当前播放帧、行列位置。
   - 网格帧 tile 增加具体帧号语义。
4. `general_image_editor_widgets.dart`
   - 可编辑预览画布增加图片语义，复用预览底部说明作为可读标签。
   - 标注颜色 swatch 增加按钮、选中和启用语义。
5. `image_library_common_widgets.dart` / `image_library_tile.dart`
   - 作品预览增加图片语义，包含作品类型和标题。
   - 作品卡片增加独立语义容器，暴露作品类型、标题和选中状态。
   - 选择框同步暴露作品标签和选中状态。

新增 / 扩展测试：

- `test/animation_project_workspace_test.dart`
  - 覆盖轨道卡片、时间轴帧块和动画工程预览语义。
- `test/frame_animation_preview_widgets_test.dart`
  - 覆盖 Sprite Sheet 画布语义随选中帧更新。
- `test/general_image_editor_widgets_test.dart`
  - 覆盖通用图片编辑预览画布语义。
- `test/image_library_pagination_test.dart`
  - 覆盖作品库卡片 / 预览语义。

验证：

- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\animation_project_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\frame_animation_preview_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_menu_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_pagination_test.dart --timeout 60s` 通过。

下一步：

```text
Phase 19 第二批：继续做键盘可达性和对比度审计；优先覆盖图片编辑 / 像素画画布键盘操作、作品库批量选择、弹窗焦点顺序，并评估是否引入 meetsGuideline 测试。
```

### Phase 19：P3-12 无障碍审计（第二批已完成）

本轮先推进最容易阻断桌面端非鼠标操作的路径：像素画画布键盘操作，以及 Sprite Sheet 切片选择弹窗的帧级语义。

完成项：

1. `pixel_art_workspace.dart`
   - 像素画画布增加可聚焦键盘光标。
   - 支持方向键移动当前像素格，空格 / 回车在当前格按当前工具绘制。
   - 鼠标点击画布时同步移动键盘光标，避免鼠标和键盘状态脱节。
   - 画布语义标签暴露尺寸、当前键盘光标位置和键盘操作方式。
   - 画布绘制层增加高对比度光标描边，键盘移动时可视反馈明确。
2. `sprite_sheet_slice_picker_dialog.dart`
   - 切片选择弹窗中的每个帧格增加独立 `Semantics`。
   - 暴露帧序号、总帧数、按钮角色和选中状态。
   - `Image.memory` 同步使用帧语义标签，减少纯图片节点不可读问题。
3. `app_zh.arb`
   - 新增像素画画布键盘操作语义文案。
   - 新增切片选择帧语义文案，并重新生成 l10n 代码。

新增 / 扩展测试：

- `test/pixel_art_workspace_test.dart`
  - 覆盖画布键盘焦点、方向键移动、回车绘制和语义标签更新。
- `test/sprite_sheet_slice_picker_dialog_test.dart`
  - 覆盖切片选择弹窗帧语义标签和选中状态。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\pixel_art_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\sprite_sheet_slice_picker_dialog_test.dart --timeout 60s` 通过。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。
- 测试必须串行执行；并行跑 Flutter widget test 会触发 `build\test_cache` 写入冲突。

下一步：

```text
Phase 19 第三批：继续补作品库批量选择键盘操作、分页 / 菜单焦点顺序和通用弹窗按钮焦点顺序；随后选择稳定页面试引入 meetsGuideline 基线测试。
```

### Phase 19：P3-12 无障碍审计（第三批已完成）

本轮补齐作品库卡片的键盘可达性，优先解决批量选择只能依赖鼠标的问题。

完成项：

1. `image_library_tile.dart`
   - 作品卡片增加 `FocusableActionDetector`，卡片本身成为稳定焦点承载层。
   - 点击卡片时同步请求卡片焦点，后续键盘操作作用在当前卡片上。
   - 空格切换当前作品选择状态，支持键盘进入 / 退出批量选择。
   - 回车 / 小键盘回车触发卡片主操作，保持与鼠标点击一致。
   - 卡片语义提示新增“按空格切换选择，按回车打开主要操作”。
   - 为卡片容器增加稳定 key，便于后续焦点 / 键盘回归测试。
2. `image_library_panel.dart`
   - 引入 `flutter/services.dart`，为作品卡片快捷键声明提供键盘键值。
3. `app_zh.arb`
   - 新增作品库卡片键盘操作语义提示，并重新生成 l10n 代码。

新增 / 扩展测试：

- `test/image_library_pagination_test.dart`
  - 覆盖作品卡片语义提示。
  - 覆盖鼠标点击后卡片获得键盘焦点。
  - 覆盖空格切换选择、再次空格取消选择。
  - 覆盖卡片主操作仍保持可触发。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_pagination_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_menu_test.dart --timeout 60s` 通过。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。

下一步：

```text
Phase 19 第四批：继续做分页 / 菜单焦点顺序、通用弹窗按钮焦点顺序，并选择静态页面引入第一组 meetsGuideline 基线测试。
```

### Phase 19：P3-12 无障碍审计（第四批已完成）

本轮补齐作品库分页控制区语义，给常用通用弹窗加焦点遍历分组，并引入第一组稳定页面 `meetsGuideline` 基线测试。

完成项：

1. `image_library_panel.dart`
   - 作品库分页条增加整体 `Semantics` 容器。
   - 分页语义标签包含当前页、总页数、结果范围和每页数量。
   - 保留原有按钮 tooltip 与 Dropdown 行为，分页功能无变化。
2. `app_dialogs.dart`
   - 首次运行设置弹窗、图片来源弹窗、作品元数据编辑弹窗、删除确认弹窗、恢复默认弹窗增加 `FocusTraversalGroup`。
   - 统一使用 `ReadingOrderTraversalPolicy`，保证按钮和输入框按视觉阅读顺序遍历。
3. `app_zh.arb`
   - 新增作品库分页控制区语义文案，并重新生成 l10n 代码。

新增 / 扩展测试：

- `test/image_library_pagination_test.dart`
  - 覆盖分页控制区语义标签随页码变化更新。
  - 首次引入 `meetsGuideline(labeledTapTargetGuideline)` 基线测试，验证稳定作品库分页页中可点击目标均有标签。
- `test/app_dialogs_accessibility_test.dart`
  - 覆盖删除确认弹窗存在焦点遍历分组。
  - 覆盖 Tab 顺序到确认按钮后可用 Enter 键确认。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_pagination_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_dialogs_accessibility_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。

下一步：

```text
Phase 19 第五批：继续扩展 meetsGuideline 到更多稳定页面；重点审计弹窗内部复杂内容（作品库选择、切片管理、图片预览弹窗）的焦点顺序和可读标签。
```

### Phase 19：P3-12 无障碍审计（第五批已完成）

本轮收口复杂图片弹窗内部内容，重点处理作品库选择、切片管理和生成结果预览弹窗的可读标签与焦点分组。

完成项：

1. `image_library_picker_dialog.dart`
   - 作品库选择弹窗外层增加 `FocusTraversalGroup`。
   - 每个作品选择项增加独立 `Semantics`，暴露作品类型、标题、序号、总数、按钮角色和选中状态。
2. `image_library_dialog_widgets.dart`
   - 切片管理弹窗外层增加 `FocusTraversalGroup`。
   - 每个切片帧增加独立语义标签，区分“已保存 / 未保存”状态。
   - 切片预览 `Image.memory` 同步传入 `semanticLabel`。
3. `preview_panel.dart`
   - 生成结果缩略图和预览弹窗大图增加图片语义标签。
   - 生成结果预览弹窗增加 `FocusTraversalGroup`，复制、导出、关闭按钮按阅读顺序遍历。
4. `app_zh.arb`
   - 新增作品选择项语义、切片帧保存状态语义等文案，并同步生成 l10n 代码。

新增 / 扩展测试：

- `test/image_library_dialog_widgets_accessibility_test.dart`
  - 覆盖作品库选择项语义标签和选中状态。
  - 覆盖切片管理弹窗已保存 / 未保存帧语义，以及图片 `semanticLabel`。
- `test/preview_panel_test.dart`
  - 覆盖预览缩略图和预览弹窗大图的语义标签。
  - 覆盖生成结果预览弹窗存在焦点遍历分组。

验证：

- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\preview_panel_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_dialog_widgets_accessibility_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_dialogs_accessibility_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\sprite_sheet_slice_picker_dialog_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_pagination_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。
- `preview_panel_test.dart` 的新增弹窗语义测试使用桌面尺寸视口，避免默认 800x600 测试视口触发既有面板溢出。

下一步：

```text
Phase 19 第六批：继续做无障碍收尾，优先检查剩余复杂弹窗（背景透明、单帧取景、替换确认）、设置 / API 表单控件的标签完整性，并评估是否能在稳定表单页面继续扩展 meetsGuideline 基线。
```

### Phase 19：P3-12 无障碍审计（第六批已完成）

本轮继续收口剩余复杂弹窗，覆盖背景转透明、单帧取景和 Sprite Sheet 单帧替换确认。

完成项：

1. `background_transparency_dialog.dart`
   - 弹窗外层增加 `FocusTraversalGroup`。
   - 容差滑杆增加 `semanticFormatterCallback`，辅助技术可读取当前容差值。
2. `patch_image_framing_dialog.dart`
   - 弹窗外层增加 `FocusTraversalGroup`。
   - 缩放滑杆增加本地化语义值。
   - 单帧取景预览区域增加图片语义，包含目标尺寸、缩放百分比和偏移量。
   - 预览图 `Image.memory` 同步传入 `semanticLabel`。
3. `app_dialogs.dart`
   - Sprite Sheet 单帧替换确认弹窗增加 `FocusTraversalGroup`。
   - 原帧、单帧图片、替换后三张预览图增加图片语义标签。
   - 将替换确认弹窗内容从 `ConstrainedBox(maxWidth)` 调整为固定内容宽度，修复 `AlertDialog` 计算 intrinsic 尺寸时遇到 `LayoutBuilder` 的断言风险。
4. `app_zh.arb`
   - 新增单帧取景缩放滑杆和预览区域语义文案，并同步生成 l10n 代码。

新增测试：

- `test/complex_dialogs_accessibility_test.dart`
  - 覆盖背景转透明弹窗焦点分组、容差语义值和确认返回值。
  - 覆盖单帧取景弹窗焦点分组、预览语义和缩放语义。
  - 覆盖替换确认弹窗焦点分组、三张预览图片语义和确认路径。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\complex_dialogs_accessibility_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_dialogs_accessibility_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_dialog_widgets_accessibility_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。

下一步：

```text
Phase 19 第七批：继续检查设置 / API 表单控件、图片高级参数和批量生成配置的标签完整性；优先在稳定表单页面扩展 meetsGuideline 基线，并补齐下拉框、开关、滑杆的语义回归测试。
```

### Phase 19：P3-12 无障碍审计（第七批已完成）

本轮继续收口稳定表单页面，重点覆盖设置 / API 表单控件、图片高级参数和批量生成配置的可读标签与辅助技术数值。

完成项：

1. `common_form_widgets.dart`
   - 通用下拉框外层增加语义容器，暴露当前标签、选中值和启用状态。
   - Sprite Sheet 行列 / 切片网格数字输入增加语义值，辅助技术可读取当前像素或数量。
   - `IntegerStepperField` 增加语义标签、数值和启用状态，补齐步进控件的可读性。
   - 模板图片选择预览图增加文件名语义标签。
2. `image_advanced_settings_widgets.dart`
   - 输出压缩率滑杆增加本地化 `semanticFormatterCallback`，读屏可读取百分比。
3. `api_settings_widgets.dart`、`api_settings_panel_widgets.dart`
   - 接口配置选择、供应商选择、生图尺寸能力选择增加语义标签和当前值。
4. `image_size_widgets.dart`
   - 图片尺寸预设、比例和方向下拉框增加语义标签和当前选项值。

新增测试：

- `test/form_accessibility_test.dart`
  - 覆盖 API 设置面板的供应商、生图尺寸能力、密钥显示和模型选择按钮标签。
  - 覆盖文本生图控制面板的接口配置、目标数量、高级输出参数、质量 / 背景 / 输出格式 / 审核强度和输出压缩率语义。
  - 覆盖 Sprite Sheet 行列与切片校准步进控件的语义标签、像素值和增减按钮 tooltip。
  - 在稳定表单页面扩展 `meetsGuideline(labeledTapTargetGuideline)` 基线。

验证：

- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\api_settings_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\form_accessibility_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。

下一步：

```text
Phase 19 第八批：继续做无障碍收尾扫描，优先检查剩余稳定页面的键盘焦点顺序、禁用态语义、错误提示可读性和常用弹出菜单；把可复用表单 / 弹窗控件继续纳入 labeledTapTargetGuideline 回归。
```

### Phase 19：P3-12 无障碍审计（第八批已完成）

本轮继续收口常用弹出菜单入口和禁用态语义，重点避免只有 tooltip、缺少稳定语义节点的问题。

完成项：

1. `layout_navigation_widgets.dart`
   - 设置菜单按钮增加外层 `Semantics`，明确菜单标签、按钮角色、选中态和启用态。
2. `image_library_tile.dart`
   - 作品库卡片“更多操作”菜单增加外层 `Semantics`，读屏可稳定识别为可用按钮。
3. `animation_project_workspace.dart`
   - 单帧编辑区“像素化当前帧”弹出菜单增加外层 `Semantics`，同步暴露按钮角色和禁用 / 启用状态。

扩展测试：

- `test/app_test.dart`
  - 覆盖设置菜单入口的语义标签、按钮角色和启用态。
- `test/image_library_menu_test.dart`
  - 覆盖作品库“更多操作”菜单入口语义。
- `test/animation_project_workspace_test.dart`
  - 覆盖动画工程“像素化当前帧”菜单入口语义，并继续验证原有像素化回调路径。

验证：

- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_menu_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\animation_project_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。

下一步：

```text
Phase 19 第九批：继续无障碍收尾，优先检查错误 / 空状态提示是否能被辅助技术读取，补齐重要禁用按钮的原因说明，并对剩余高频工具栏按钮做语义回归测试。
```

### Phase 19：P3-12 无障碍审计（第九批已完成）

本轮优先收口公共预览状态组件，让空状态、加载状态和错误状态都能被辅助技术稳定读取。

完成项：

1. `preview_common_widgets.dart`
   - `PreviewStateSurface` 增加外层 `Semantics`。
   - 空状态暴露状态文案，避免只作为视觉占位。
   - 加载 / 错误状态设置 `liveRegion`，便于辅助技术感知状态变化。
   - 错误状态语义合并标题和错误详情，例如“生成失败 · network error”。
   - 重试按钮保留原按钮语义和回调路径。

扩展测试：

- `test/preview_panel_test.dart`
  - 覆盖空状态语义文案。
  - 覆盖错误状态语义文案。
  - 覆盖错误状态下“重试生成”按钮仍可触发回调。

验证：

- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\preview_panel_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\frame_animation_preview_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。

下一步：

```text
Phase 19 第十批：继续补齐高频工具栏按钮和重要禁用按钮的语义原因，优先检查图片编辑、像素画、批量队列中的撤销 / 重做 / 删除 / 重试等操作入口。
```

### Phase 19：P3-12 无障碍审计（第十批已完成）

本轮继续收口高频工具栏按钮、禁用态原因和批量队列状态提示，重点覆盖撤销 / 重做、空队列和失败任务错误。

完成项：

1. `app_zh.arb` 与生成的 l10n 代码
   - 新增“暂无可撤销操作”“暂无可重做操作”两条禁用态原因文案。
2. `general_image_editor_widgets.dart`
   - 图片编辑器撤销 / 重做按钮增加外层 `Semantics`。
   - 禁用时暴露明确原因，避免辅助技术只读到不可用按钮。
3. `pixel_art_workspace.dart`
   - 像素画撤销 / 重做按钮增加外层 `Semantics`。
   - 初始无历史时暴露“暂无可撤销 / 重做操作”。
4. `batch_generation_workspace.dart`
   - 批量队列空状态增加语义容器。
   - 失败任务错误文本增加 `liveRegion`，错误出现时可被辅助技术感知。

扩展测试：

- `test/general_image_editor_widgets_test.dart`
  - 覆盖图片编辑撤销 / 重做按钮禁用原因语义。
- `test/pixel_art_workspace_test.dart`
  - 覆盖像素画撤销 / 重做按钮禁用原因语义。
- `test/batch_generation_workspace_test.dart`
  - 覆盖批量队列空状态语义。
  - 覆盖失败任务错误语义。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 已执行并生成新增本地化访问器。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\pixel_art_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\batch_generation_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。
- 本轮曾误把 `.arb` 传给 `dart format`，该格式化步骤失败但未修改 `.arb`；随后已通过 `gen-l10n`、`analyze` 和构建验证。

下一步：

```text
Phase 19 第十一批：继续无障碍收尾，优先检查剩余选择器、颜色 swatch、分页 / 滚动区域和导出类按钮的语义标签、选中态与禁用态。
```

### Phase 19：P3-12 无障碍审计（第十一批已完成）

本轮继续收口剩余选择器和高频工具栏按钮，重点覆盖颜色 swatch 和预览缩放按钮的语义标签、选中态与启用态。

完成项：

1. `pixel_art_workspace.dart`
   - 像素画调色板颜色块增加外层 `Semantics`。
   - 语义标签包含颜色十六进制值，例如“选择颜色 #EF4444”。
   - 暴露按钮角色、启用态和当前选中态，避免只依赖边框颜色。
2. `frame_animation_preview_parts.dart`
   - 播放帧缩放按钮增加外层 `Semantics`。
   - 补齐按钮角色和启用态，保留原 tooltip 与点击行为。

扩展测试：

- `test/pixel_art_workspace_test.dart`
  - 覆盖默认选中颜色的语义标签和选中态。
  - 覆盖点击红色 swatch 后选中态更新。
- `test/frame_animation_preview_widgets_test.dart`
  - 覆盖“放大播放帧”缩放按钮的语义标签、按钮角色和启用态。

验证：

- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\pixel_art_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\frame_animation_preview_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。

下一步：

```text
Phase 19 第十二批：继续无障碍收尾，优先检查导出类按钮、剩余分页 / 滚动区域、预览播放控制和批量操作按钮的语义标签、禁用态与回归测试。
```

### Phase 19：P3-12 无障碍审计（第十二批已完成）

本轮继续处理导出类按钮和批量操作按钮的禁用态原因，重点避免读屏只能感知“不可用”，但不知道为什么不可用。

完成项：

1. `batch_generation_workspace.dart`
   - 批量生成主操作区增加禁用态语义包装。
   - 覆盖“按行拆分入队”“开始 / 继续队列”“暂停后续”“继续后续”“取消等待任务”“重试失败任务”“清理完成 / 失败 / 取消”。
   - 禁用时暴露明确原因，例如队列运行中、没有等待任务、没有失败任务、队列未暂停、没有可清理任务。
   - 开始队列还会透传尺寸校验失败原因，避免尺寸不合法时只有视觉禁用。
2. `animation_project_workspace.dart`
   - 动画工程已有工程态的导入 / 导出 / 新建 / 关闭操作增加禁用态语义包装。
   - 覆盖导入本地图片序列、从作品库导入序列、新建轨道、导出合成 Sprite Sheet、导出工程 GIF、导出工程 PNG 序列、导出当前轨道 GIF、导出 PNG 序列、关闭工程。
   - 工程忙碌时统一暴露“当前工程正在处理任务，完成后可继续操作”。
3. `app_zh.arb` 与生成的 l10n 代码
   - 新增批量操作禁用原因文案。
   - 新增动画工程忙碌态操作不可用原因文案。

扩展测试：

- `test/batch_generation_workspace_test.dart`
  - 覆盖批量操作按钮在队列运行时的禁用原因、按钮角色和禁用态。
- `test/animation_project_workspace_test.dart`
  - 覆盖动画工程忙碌时导出工程 GIF、从作品库导入序列的禁用原因、按钮角色和禁用态。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 已执行并生成新增本地化访问器。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\batch_generation_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\animation_project_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。
- 动画工程新增忙碌态语义测试使用 `1400x1100` 桌面视口，避免把本轮无障碍收尾扩大成面板高度布局重构。

下一步：

```text
Phase 19 第十三批：继续无障碍收尾，优先检查预览播放控制、结果预览按钮、作品库导入 / 导出和本地设置导入 / 导出按钮的语义标签、禁用态原因与回归测试。
```

### Phase 19：P3-12 无障碍审计（第十三批已完成）

本轮继续处理作品库相关的批量操作和迁移操作，重点覆盖“空状态 / 忙碌状态下按钮禁用但缺少原因”的问题。

完成项：

1. `local_settings_widgets.dart`
   - 本地设置的作品库导出 / 导入按钮增加禁用态语义包装。
   - 作品库为空时，导出按钮暴露“作品库为空，暂无可导出的内容”。
   - 正在导出 / 导入时，按钮暴露对应忙碌原因。
2. `image_library_panel.dart`
   - 作品库“选择当前结果”按钮增加禁用态语义包装。
   - 当前结果为空时暴露“当前没有可选择的作品”。
   - 当前结果已全部选中时暴露“当前结果已全部选中”。
3. `app_zh.arb` 与生成的 l10n 代码
   - 新增本地设置作品库导入 / 导出禁用原因文案。
   - 新增作品库选择当前结果禁用原因文案。

扩展测试：

- `test/app_test.dart`
  - 覆盖本地设置里“导出作品库”空状态禁用原因、按钮角色和禁用态。
- `test/image_library_pagination_test.dart`
  - 覆盖作品库“选择当前结果”在空结果和全部选中时的禁用原因。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 已执行并生成新增本地化访问器。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_pagination_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。
- 新增作品库选择语义测试使用明确桌面视口，避免默认小视口把本轮无障碍收尾变成布局重构。

下一步：

```text
Phase 19 第十四批：继续无障碍收尾，优先检查结果预览浮层按钮、预览播放控制、清理存储 / 恢复默认等剩余高频按钮的语义标签、禁用态原因与回归测试。
```

### Phase 19：P3-12 无障碍审计（第十四批已完成）

本轮继续处理预览播放控制和本地设置存储清理按钮，重点补齐单帧 / 忙碌状态下的禁用原因。

完成项：

1. `frame_animation_preview_builders.dart`
   - Sprite Sheet 预览的播放、上一帧、下一帧按钮增加禁用态语义包装。
   - 当前行只有 1 帧时，禁用按钮暴露“当前行只有 1 帧，无法播放或切换帧”。
   - 保留原有播放、切帧和 tooltip 行为，不改变视觉结构。
2. `local_settings_widgets.dart`
   - 本地设置“清理未引用文件”按钮增加禁用态语义包装。
   - 存储清理进行中时暴露“正在清理存储，完成后可继续操作”。
3. `app_zh.arb` 与生成的 l10n 代码
   - 新增 Sprite Sheet 单帧播放 / 切帧不可用原因文案。
   - 新增本地设置存储清理忙碌态不可用原因文案。

扩展测试：

- `test/frame_animation_preview_widgets_test.dart`
  - 覆盖单帧 Sprite Sheet 预览的禁用原因、按钮角色和禁用态。
- `test/local_settings_widgets_test.dart`
  - 覆盖存储清理中按钮的禁用原因、按钮角色和禁用态。
- `test/app_test.dart`
  - 确认本地设置页仍展示清理入口。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 已执行并生成新增本地化访问器。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\frame_animation_preview_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\local_settings_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。

下一步：

```text
Phase 19 第十五批：继续无障碍收尾，优先检查结果预览浮层按钮的语义细节、恢复默认确认入口、预设列表操作和剩余 IconButton 的标签 / 禁用态回归。
```

### Phase 19：P3-12 无障碍审计（第十五批已完成）

本轮继续处理结果预览按钮和本地设置预设操作，重点让图标按钮和重复文本按钮有稳定、可区分的语义标签。

完成项：

1. `local_settings_widgets.dart`
   - 预设列表的“应用”按钮增加外层 `Semantics`。
   - 预设列表的删除图标按钮增加外层 `Semantics`。
   - 语义标签包含预设名称，例如“应用预设：常用方图”“删除预设：常用方图”，避免多条预设时只读到重复的“应用 / 删除预设”。
2. `preview_panel_test.dart`
   - 补充结果预览浮层按钮语义回归。
   - 覆盖结果卡片上的复制图片、导出图片、背景转透明按钮。
   - 覆盖预览弹窗里的复制图片、导出图片、关闭按钮。
3. `app_zh.arb` 与生成的 l10n 代码
   - 新增指定预设的应用 / 删除语义标签文案。

扩展测试：

- `test/local_settings_widgets_test.dart`
  - 覆盖预设行“应用预设：{name}”“删除预设：{name}”的按钮角色、启用态和点击回调。
- `test/preview_panel_test.dart`
  - 覆盖结果预览浮层和弹窗图标按钮的可访问名称、按钮角色和启用态。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 已执行并生成新增本地化访问器。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat test test\local_settings_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\preview_panel_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。

下一步：

```text
Phase 19 第十六批：继续无障碍收尾，优先做剩余 IconButton / PopupMenuButton 全局扫描，检查是否还有仅依赖 tooltip、重复标签或缺少禁用态原因的入口；完成后评估 Phase 19 是否可以收口。
```

### Phase 19：P3-12 无障碍审计（第十六批已完成）

本轮做剩余 `IconButton` / `PopupMenuButton` 全局扫描，并优先修复仍缺少禁用原因的 API 配置删除入口。

完成项：

1. `api_settings_widgets.dart`
   - “删除当前配置”按钮在只剩一个接口配置时增加禁用态语义包装。
   - 禁用时暴露“至少需要保留一个接口配置”，避免读屏用户只知道按钮不可用但不知道原因。
   - 保留原有 tooltip、图标和删除回调行为；可删除多个配置时仍走原按钮语义。
2. `app_zh.arb` 与生成的 l10n 代码
   - 新增 `apiSettingsDeleteConfigUnavailable` 文案。
3. 剩余入口扫描
   - 本轮复查了主要 `IconButton` / `PopupMenuButton` 候选：预览按钮、作品库菜单、分页、动画工程导入 / 导出、批量任务操作、本地设置预设操作等此前批次已经覆盖。
   - 当前未发现新的高优先级无障碍缺口；Phase 19 可以进入收口评估。

扩展测试：

- `test/api_settings_widgets_test.dart`
  - 覆盖只剩一个 API 配置时“删除当前配置”的禁用原因、按钮角色和禁用态。

验证：

- `D:\Programs\flutter\bin\flutter.bat gen-l10n` 已执行并生成新增本地化访问器。
- `D:\Programs\flutter\bin\flutter.bat test test\api_settings_widgets_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。

下一步：

```text
Phase 19 收口评估：做一次轻量全局回归扫描，确认无障碍审计文档、核心测试和 Windows debug 编译均稳定；若没有新增高优先级问题，Phase 19 可收口并转入下一条主线。
```

### Phase 19：P3-12 无障碍审计（第十七批 / 收口评估已完成）

本轮执行 Phase 19 收口评估，复查剩余低风险入口，并补齐最后一个实际缺口：全局历史工具条禁用态原因。

完成项：

1. `home_shell_state.dart`
   - 全局历史工具条的撤销、重做、历史菜单增加禁用态语义包装。
   - 无可撤销操作时暴露“暂无可撤销操作”。
   - 无可重做操作时暴露“暂无可重做操作”。
   - 无历史记录时，历史菜单暴露“暂无历史”。
   - 历史操作执行中时，禁用入口暴露“历史操作执行中”。
2. 收口扫描
   - 复查剩余 `IconButton` / `PopupMenuButton` 候选，包括数字步进按钮、图片编辑版本 / 标注按钮、动画工程轨道按钮、预览按钮、作品库菜单和分页入口。
   - 数字步进字段已有整体字段语义和 tooltip；版本 / 标注 / 轨道按钮有稳定 tooltip 且无新增高优先级禁用原因缺口。
   - Phase 19 当前可收口。

扩展测试：

- `test/app_test.dart`
  - 覆盖全局撤销、重做、历史菜单在无历史状态下的禁用原因、按钮角色和禁用态。

验证：

- `D:\Programs\flutter\bin\flutter.bat test test\app_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。

结论：

```text
Phase 19：P3-12 无障碍审计可收口。下一主线建议进入 P1-8 长列表 Sliver 化 / 虚拟化评估，优先处理作品库和批量队列的大列表滚动性能与可维护性。
```

### Phase 20：P1-8 长列表 Sliver 化 / 虚拟化评估（第一批已完成）

本轮开始性能主线，先做低风险评估和批量队列重建成本优化。作品库已经具备分页、`SliverGrid` 和 builder 渲染，第一批不再重复改造作品库结构。

完成项：

1. `batch_generation_workspace.dart`
   - 新增 `summarizeBatchGenerationJobs` 和 `BatchGenerationJobSummary`。
   - 将批量队列的等待数、运行数、完成数、失败数、预览图、目标预览数量、预览宽高比和最新调试记录合并为一次遍历。
   - 替代原来 build 阶段多次 `where` / `fold` / 单独循环的做法，降低大队列重建成本。
   - 保留原 UI、按钮状态、预览面板行为和队列列表 builder，不改变业务行为。
2. 性能评估结论
   - 作品库当前已经使用分页和 `SliverGrid`，不是本轮最紧急瓶颈。
   - 批量队列已经使用 `ListView.separated` builder 和高度上限，但控制面板统计存在可优化的重复遍历，本轮已处理。

扩展测试：

- `test/batch_generation_workspace_test.dart`
  - 新增 `summarizeBatchGenerationJobs` 纯逻辑测试，覆盖等待 / 运行 / 完成 / 失败计数、预览图数量、目标图数、预览宽高比和最新调试记录。

验证：

- `D:\Programs\flutter\bin\flutter.bat test test\batch_generation_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。

下一步：

```text
Phase 20 第二批：继续 P1-8 性能主线，优先补作品库分页 / Sliver 回归测试与批量队列大列表边界测试；如测试显示现有结构稳定，再评估是否需要抽公共列表性能工具或进入 P0-1 状态拆分。
```

### Phase 20：P1-8 长列表 Sliver 化 / 虚拟化评估（第二批已完成）

本轮继续性能主线，但不做重复重构，重点补齐大列表行为回归测试，确认现有 Sliver / builder 路径在大数据量下不会退化。

完成项：

1. `image_library_pagination_test.dart`
   - 新增作品库 Sliver 路径分页回归测试，构造 80 个作品。
   - 验证作品库使用 `CustomScrollView` + `SliverGrid`，并确认没有退回 `GridView`。
   - 验证第一页只展示 1-24，第二页只展示 25-48，确保分页边界稳定。
2. `batch_generation_workspace_test.dart`
   - 将批量队列有界列表测试扩展到 120 个任务。
   - 验证队列仍使用 `ListView` builder 路径。
   - 验证首屏不会构建末尾任务内容，并确认列表高度保持在 320 像素以内。
3. 性能结论
   - 作品库当前分页 / Sliver 结构稳定，短期不需要再次替换列表实现。
   - 批量队列在 100+ 任务下保持有界滚动容器，上一批的一次遍历摘要优化可以继续保留。

验证：

- `D:\Programs\flutter\bin\flutter.bat test test\image_library_pagination_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\batch_generation_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。

下一步：

```text
Phase 20 第三批：继续性能主线，优先评估作品库 view data 构建是否每次 build 都全量排序 / 过滤，可考虑在 notifier 或派生数据层做缓存；同时检查预览面板和批量队列预览图聚合在大结果场景下是否需要上限或懒加载。若没有明确性能收益，再转入 P0-1 状态拆分。
```

### Phase 20：P1-8 长列表 Sliver 化 / 虚拟化评估（第三批已完成）

本轮继续性能主线，处理作品库 view data 在 UI rebuild 时重复全量计算的问题。改动保持在派生数据层和工作区接入层，不改变作品库筛选、排序、分页和选择行为。

完成项：

1. `image_library_view_data.dart`
   - 新增 `ImageLibraryViewDataMemoizer`。
   - 当作品库列表引用、筛选条件、排序、搜索词、项目 / 标签筛选、独立帧显示开关、存在性判断和 l10n 实例都未变化时，直接复用上一份 `ImageLibraryViewData`。
   - 避免 UI rebuild 时重复执行文件存在性检查、Sprite Sheet 分组统计、项目 / 标签集合构建和筛选结果排序。
2. `image_library_workspace.dart`
   - `ImageLibraryWorkspace` 从 `StatelessWidget` 调整为 `StatefulWidget`。
   - 在 State 内持有 `ImageLibraryViewDataMemoizer`，让缓存生命周期跟随作品库工作区，而不是泄露到全局。
   - 面板入参和交互回调保持不变。
3. `image_library_view_data_test.dart`
   - 新增缓存回归测试。
   - 覆盖相同输入复用同一份 view data，筛选条件变化时重新构建，避免缓存导致搜索结果过期。

验证：

- `D:\Programs\flutter\bin\flutter.bat test test\image_library_view_data_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_pagination_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。

下一步：

```text
Phase 20 第四批：继续性能主线，优先检查结果预览面板和批量队列预览图聚合在大量结果场景下的内存与重建成本；如果已有上限和懒构建足够稳定，再转入 P0-1 状态拆分准备。
```

### Phase 20：P1-8 长列表 Sliver 化 / 虚拟化评估（第四批已完成）

本轮继续性能主线，重点处理结果预览区域的大结果构建成本。此前 `PreviewPanel` 使用 `Wrap` 一次性创建全部结果图和 pending 占位；当目标数量很大或批量队列累计很多结果时，容易在 build 阶段创建过多 widget。

完成项：

1. `preview_panel.dart`
   - 将结果预览布局从一次性 `Wrap` 改为 `GridView.builder`。
   - 预览区使用稳定高度上限，按可见区域懒构建 tile。
   - 保留原有图片操作、预览弹窗、语义标签、缩略图缓存尺寸和 pending 占位逻辑。
2. `batch_generation_workspace.dart`
   - 批量队列预览聚合增加显示上限，最多向预览面板传递 120 张结果图。
   - 保留完成任务计数和队列状态统计，避免大量历史结果反复传递给预览 UI。
3. 回归测试
   - `preview_panel_test.dart` 新增大结果 lazy grid 测试，确认不会一次性构建全部图片。
   - `batch_generation_workspace_test.dart` 新增批量预览上限测试，确认 180 个完成任务时只保留 120 张预览图。

验证：

- `D:\Programs\flutter\bin\flutter.bat test test\preview_panel_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\batch_generation_workspace_test.dart --timeout 60s` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

注意：

- 本轮未执行 `flutter run -d windows`，避免启动新的应用窗口。

下一步：

```text
Phase 20 第五批：性能主线进入收口评估，复查本阶段已覆盖的作品库、批量队列和预览面板；如果没有新的明确性能瓶颈，就转入 P0-1 状态拆分准备，优先拆分大 State / mixin 的边界。
```

### Phase 20：P1-8 长列表 Sliver 化 / 虚拟化评估（第五批 / 收口评估已完成）

本轮执行性能主线收口评估，复查当前大列表和大结果构建路径。Phase 20 已覆盖作品库、批量队列和结果预览三个最容易卡顿的区域，当前没有发现新的高优先级大列表性能瓶颈。

完成项：

1. 性能覆盖复查
   - 作品库：已有分页、`SliverGrid`、builder 渲染和 view data memoizer。
   - 批量队列：已有有界 `ListView.separated`、单次队列摘要聚合和预览图聚合上限。
   - 结果预览：已从一次性 `Wrap` 改为 `GridView.builder`，大结果按可见区域懒构建。
2. 剩余风险判断
   - 现阶段继续扩大性能主线的收益不明确。
   - 更大的维护风险来自 `main.dart` + `src/home/*_state.dart` 的大 State / mixin 结构。
   - `image_generation_state.dart`、`image_library_state.dart`、`editor_gif_state.dart`、`local_settings_state.dart` 和 `home_shell_state.dart` 仍是后续状态拆分的重点。
3. 下一阶段入口
   - Phase 20 可收口。
   - 下一主线进入 `P0-1` 状态拆分准备。
   - 优先梳理 `_FeatherCanvasHomePageState` 当前持有的 controller、notifier、service 和各业务 mixin 边界，再做小批次迁移。

验证：

- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

运行状态：

- 检测到已有 `feather_canvas_studio` 进程正在运行。
- 为避免重复启动第二个应用窗口，本轮未再执行新的 `flutter run -d windows`。

结论：

```text
Phase 20：P1-8 长列表 Sliver 化 / 虚拟化评估可收口。下一主线进入 P0-1 状态拆分准备，优先为 main.dart 与 src/home/*_state.dart 建立清晰的状态所有权边界。
```

### Phase 21：P0-1 状态拆分准备（第一批已完成）

本轮开始进入状态拆分主线，但先不做大规模代码迁移。当前目标是把 `_FeatherCanvasHomePageState` 与 `src/home/*_state.dart` 的所有权边界写清楚，避免后续拆分时一次性改动过大。

完成项：

1. 新增 `docs/p0-1-state-split-prep.md`
   - 记录当前 `_FeatherCanvasHomePageState` 持有 controller、service、notifier 和跨域状态的问题。
   - 列出当前 7 个业务 mixin。
   - 明确体量最大的后续重点文件：`image_generation_state.dart`、`image_library_state.dart`、`editor_gif_state.dart`、`local_settings_state.dart`、`home_shell_state.dart`。
2. 拆分顺序
   - 第一优先级：`image_library_state.dart`，因为已有 `ImageLibraryNotifier` 和 view data 缓存边界。
   - 第二优先级：`batch_generation_state.dart`，因为已有 `BatchGenerationNotifier` 且队列状态清晰。
   - 第三优先级：`local_settings_state.dart`，设置持久化和导入 / 导出边界相对独立。
3. 暂缓项
   - `home_shell_state.dart` 作为总装配层暂缓。
   - `image_generation_state.dart` 与 `editor_gif_state.dart` 业务耦合更深，等前面几个域收敛后再拆。

验证：

- `D:\Programs\flutter\bin\flutter.bat analyze` 通过（No issues found）。
- `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

运行状态：

- 检测到已有 `feather_canvas_studio` 进程正在运行。
- 为避免重复启动第二个应用窗口，本轮未再执行新的 `flutter run -d windows`。

下一步：

```text
Phase 21 第二批：从 image_library_state.dart 开始做小批次状态边界收敛，优先补最小回归测试，再迁移低风险的筛选 / 选择 / 存在性缓存相关状态。
```

### Phase 22：图片编辑器布局优化（第一批已完成）

本轮按“左侧参数面板、右侧画布工具栏”的方向，继续整理通用图片编辑器。重点不是只移动“几何 / 外观 / 标注 / 输出”分类入口，而是把真正的执行型功能按钮也放到右侧预览顶部，让编辑器更接近常见图片编辑器布局。

完成项：

1. `general_image_editor_widgets.dart`
   - 右侧预览顶部保留面板切换入口。
   - 新增右侧顶部执行工具条：撤销、重做、生成完整预览、重置参数、应用并保存。
   - 当前面板为“几何”时，右侧顶部额外显示：左转、右转、水平翻转、垂直翻转。
   - 左侧控制区收敛为参数配置区，几何面板只保留裁剪和尺寸参数，不再堆叠旋转 / 翻转执行按钮。
2. 验证：
   - `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat test test\image_editor_pixelation_entry_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat analyze` 通过。
   - `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。
3. 运行状态：
   - 已清理旧的 `feather_canvas_studio` 进程。
   - 已启动当前 Debug exe，当前只保留一个应用进程。

下一步：

```text
继续做图片编辑器第二批布局优化：检查右侧工具条在窄宽度下的换行、预览区域高度占比和左侧参数分组密度；如果布局稳定，再回到 Phase 21 第二批状态边界收敛。
```

### Phase 22：图片编辑器布局优化（第二批已完成）

本轮继续收敛通用图片编辑器的几何功能布局。几何功能不再以左侧展开参数区为主，而是合并到右侧预览顶部工具条，通过对话框完成配置。

完成项：

1. `general_image_editor_widgets.dart`
   - 右侧预览顶部的几何工具条新增“裁剪边距”和“输出尺寸”入口。
   - 点击“裁剪边距”打开裁剪对话框，可配置左 / 上 / 右 / 下边距，也可一键套用 1:1、4:3、16:9 或清除裁剪。
   - 点击“输出尺寸”打开尺寸对话框，可启用输出尺寸、保持比例，并配置宽高。
   - 左侧几何面板不再展示可编辑控件，只保留裁剪和尺寸的当前状态摘要。
   - 保留右侧顶部的左转、右转、水平翻转、垂直翻转，形成统一的几何工具区。
2. 测试：
   - `general_image_editor_widgets_test.dart` 新增“geometry tools open from preview toolbar dialogs”回归测试。
   - 覆盖从顶部按钮打开裁剪 / 尺寸对话框、保存配置、应用后输出对应 `crop` 与 `resize` 参数。
3. 验证：
   - `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat test test\image_editor_pixelation_entry_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat analyze` 通过。
   - `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

下一步：

```text
继续做图片编辑器第三批布局优化：检查外观 / 标注 / 输出中是否也有适合上移到右侧顶部或弹窗化的高频执行按钮；保留左侧为低频参数和状态摘要。
```

### Phase 22：图片编辑器布局优化（第二批修正已完成）

本轮根据实际界面反馈修正第二批布局：几何工具条此前仍残留在左侧，且“应用并保存”被放在了右侧顶部，不符合当前编辑器布局目标。

修正项：

1. `general_image_editor_widgets.dart`
   - “应用并保存”回到左侧控制区，作为主提交操作保留在左栏。
   - “几何 / 外观 / 标注 / 输出”切换、撤销 / 重做、生成完整预览、重置参数和几何工具条全部放到右侧预览顶部。
   - 左侧不再显示“几何调整”卡片，也不再显示裁剪边距 / 输出尺寸摘要。
   - 右侧几何工具仍保留裁剪边距、输出尺寸、左转、右转、水平翻转、垂直翻转。
2. 测试：
   - `general_image_editor_widgets_test.dart` 覆盖工具条只在预览面板外层显示，不再落到左侧控制区。
3. 验证：
   - `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat test test\image_editor_pixelation_entry_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat analyze` 通过。
   - `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过，生成 `build\windows\x64\runner\Debug\feather_canvas_studio.exe`。

补充修正：
- 已确认按钮摆放根因：分类、预览操作与几何工具曾残留在左侧 _buildControls。
- 现已移除左侧残留，仅由右侧 _buildPreviewSurface 渲染这些工具。
- general_image_editor_widgets_test.dart、image_editor_pixelation_entry_test.dart、flutter analyze、flutter build windows --debug 均已重新通过。

### Phase 22：图片编辑器布局与几何弹窗稳定性修复（第三批前置修复已完成）

本轮针对实际使用反馈处理两个高优先级问题：一是再次确认右侧工具条没有残留在左侧控制区；二是修复连续点击裁剪 / 输出尺寸入口时可能重复打开弹窗并导致崩溃的问题。

完成项：

1. `general_image_editor_widgets.dart`
   - 确认 `general-image-editor-panel-tabs`、`general-image-editor-preview-actions`、`general-image-editor-geometry-actions` 只由右侧 `_buildPreviewSurface` 渲染。
   - 左侧 `_buildControls` 继续只承载图片源、快捷处理、版本快照、`应用并保存` 和非几何参数面板。
   - 新增 `_geometryDialogOpen` 单实例锁，裁剪边距和输出尺寸弹窗打开期间不允许再次触发同类几何弹窗。
   - 几何工具条按钮在弹窗打开期间会进入不可用状态，避免快速连点重复入栈。
2. `general_image_editor_widgets_test.dart`
   - 新增 `geometry dialogs ignore rapid repeated toolbar taps` 回归测试。
   - 测试直接连续触发裁剪 / 输出尺寸按钮回调，断言不会抛异常且只出现一个 `AlertDialog`。
3. 验证：
   - `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat test test\image_editor_pixelation_entry_test.dart --timeout 60s` 通过。

下一步：

```text
继续 Phase 22 第三批：检查外观 / 标注 / 输出中是否还有适合上移到右侧顶部或弹窗化的高频执行按钮，同时保持左侧只做参数与状态承载。
```

### Phase 22：图片编辑器右侧工具条对齐修正（第三批前置修正已完成）

本轮根据截图反馈继续修正右侧预览顶部布局：撤销、重做、生成完整预览、重置参数这组执行按钮虽然已经位于右侧预览区，但仍靠左显示，视觉上占用了画布上方主区域。

完成项：

1. `general_image_editor_widgets.dart`
   - 新增 `_buildPreviewTopToolbar`，将右侧预览顶部拆成左右分区。
   - 左侧保留 `几何 / 外观 / 标注 / 输出` 分类切换。
   - 右侧对齐 `撤销 / 重做 / 生成完整预览 / 重置参数` 执行按钮。
   - 几何执行工具条也改为右对齐，避免继续从预览区左侧展开。
   - 窄宽度下保留换行布局，执行按钮仍靠右对齐。
2. `general_image_editor_widgets_test.dart`
   - 扩展布局测试，断言预览执行按钮位于分类入口右侧。
   - 断言 `重置参数` 和几何工具条末尾按钮贴齐各自工具区右边界。
3. 验证：
   - `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat test test\image_editor_pixelation_entry_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat analyze` 通过。
   - `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过。

补充验证：
- 新增动态窗口尺寸回归测试：同一个 `GeneralImageEditorContent` 先在小窗口下验证工具栏拆成两行，再将窗口宽度扩大，验证执行按钮自动回到与分类入口同一行并向右展开。
- 该测试用于防止“小窗口正常，但切回大窗口不自动重排”的回归。

再修正：
- `GeneralImageEditorContent` 现在监听 `WidgetsBindingObserver.didChangeMetrics`，窗口尺寸变化时主动重建，避免拖拽窗口后局部布局状态没有刷新。
- 顶部工具栏单行判断同时参考预览区约束和整窗宽度；当整窗宽度达到大窗口阈值时，即使外层局部约束暂时偏窄，也会恢复右上角单行布局。
- `general_image_editor_widgets_test.dart` 的动态窗口尺寸测试已覆盖该路径。

最终修正：
- 移除顶部工具栏对固定宽度阈值的依赖，改为 `Wrap(alignment: WrapAlignment.spaceBetween)`。
- 当前宽度能容纳分类入口和执行按钮时，自动排成同一行：分类在左，执行按钮在右。
- 当前宽度不能容纳两组工具时，自动换成两行，第二行从左侧开始。
- 动态窗口尺寸测试已调整为从 1100 逻辑宽拖到 1800 逻辑宽，验证同一个 widget 会从两行自动回到单行。

### Phase 22：图片编辑器外观 / 标注动作上移（第三批已完成）

本轮继续收口右侧预览顶部工具栏，把仍停留在左侧参数面板中的执行动作上移，左侧只保留低频参数和状态列表。

完成项：

1. `general_image_editor_widgets.dart`
   - 外观面板新增右侧顶部动作区 `general-image-editor-appearance-actions`。
   - “居中半幅”和“全图处理”从左侧局部选区参数区移到右侧顶部动作区。
   - 标注面板新增右侧顶部动作区 `general-image-editor-annotation-actions`。
   - “添加标注”和“清空标注”从左侧标注参数区移到右侧顶部动作区。
   - 左侧外观 / 标注面板保留参数输入、颜色、位置、现有标注列表等配置内容。
2. `general_image_editor_widgets_test.dart`
   - 新增 `appearance and annotation actions stay in preview toolbar`。
   - 覆盖外观 / 标注动作按钮只在右侧顶部动作区出现，避免重新落回左侧参数面板。
3. 验证：
   - `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat test test\image_editor_pixelation_entry_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat analyze` 通过。
   - `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过。

### Phase 22：图片编辑器小窗口工具条响应式修正（第三批补充修正已完成）

本轮修复小窗口 / 中等预览宽度下的顶部工具条排版问题。此前规则只按较小断点切换，导致分类入口和执行按钮在中等宽度下被挤压到同一行，执行按钮贴近右侧滚动条，视觉上像布局溢出。

完成项：

1. `general_image_editor_widgets.dart`
   - 新增 `_previewToolbarSingleRowMinWidth`，将单行工具栏切换阈值提高到 1280。
   - 预览区不足 1280 宽时，顶部工具栏改为两行：第一行分类入口，第二行执行按钮。
   - 两行均左对齐，避免按钮组被硬推到右侧或贴近滚动条。
   - 宽屏仍保持分类入口和执行按钮同一行紧凑排列。
2. `general_image_editor_widgets_test.dart`
   - 新增窄预览工具栏测试，断言执行按钮位于分类入口下一行并保持左对齐，且不越过预览面板右边界。
   - 新增宽屏工具栏测试，断言执行按钮仍紧跟分类入口，避免宽屏退化成松散布局。
3. 验证：
   - `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat test test\image_editor_pixelation_entry_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat analyze` 通过。
   - `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过。

### Phase 22：图片编辑器小窗口切回宽屏右上角修正（第三批再修正已完成）

本轮继续根据“从小窗口恢复到大窗口后，顶部工具条应该回到右上角”的反馈修正布局。之前的窄屏换行规则保留，但宽屏单行布局仍需保证执行按钮回到右上角，而不是停留在中间或被内容宽度限制。

完成项：

1. `general_image_editor_widgets.dart`
   - 将单行切换阈值降为 `1080`，更符合顶部工具组真实宽度。
   - 宽屏时恢复为单行布局，执行按钮通过 `Expanded + Align.centerRight` 回到右上角。
   - 预览根节点和整个编辑器根节点都显式撑满可用宽度，避免内部工具条拿到过窄的收缩宽度。
2. `general_image_editor_widgets_test.dart`
   - 宽屏测试改为验证执行按钮与分类入口同一行，且在视觉上明显向右展开。
   - 小窗口两行布局测试继续保留。
3. 验证：
   - `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat test test\image_editor_pixelation_entry_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat analyze` 通过。
   - `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过。

### Phase 22：图片编辑器顶部工具条空白修正（第三批补充修正已完成）

本轮继续根据截图反馈修正右侧预览顶部工具条：上一轮为了把执行按钮推到右侧，使用了拉伸布局，导致分类入口和执行按钮之间出现大面积空白。

完成项：

1. `general_image_editor_widgets.dart`
   - `_buildPreviewTopToolbar` 去掉会撑开空白的 `Expanded + Align.centerRight`。
   - 改为两个不强制拉伸的 `Flexible` 分区：分类入口在前，执行按钮紧跟其后。
   - 工具条仍保留在右侧预览区域顶部，但不再制造中间大空白。
2. `general_image_editor_widgets_test.dart`
   - 布局测试新增紧凑间距断言，确保预览执行按钮紧跟分类入口，避免回退到大空白布局。
3. 验证：
   - `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat test test\image_editor_pixelation_entry_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat analyze` 通过。
   - `D:\Programs\flutter\bin\flutter.bat build windows --debug` 通过。

### Phase 22：像素画预览区右侧空白修正（补充修正已完成）

本轮根据像素画编辑界面反馈修正右侧预览区布局：默认 32 x 32 画布在宽预览区内此前贴左显示，导致右边出现大面积空白，看起来不像画布编辑器的主工作区。

完成项：

1. `pixel_art_workspace.dart`
   - 右侧画布区域新增 `LayoutBuilder`，让滚动内容至少撑满当前预览面板宽高。
   - 小画布在横向可用空间大于内容宽度时自动居中，避免默认贴左。
   - 非专注模式下的画布面板高度改为更贴近页面实际可用高度，减少高窗口底部白底留空。
   - 移除 `16 x 16`、`32 x 32`、`64 x 64`、`128 x 128`、`256 x 256` 固定尺寸快捷按钮，避免绕过“应用画布尺寸”直接改变作品。
   - 保留原有横向 / 纵向滚动逻辑，大画布或高缩放时仍可滚动查看。
   - 新增稳定 key `pixel-art-canvas-panel`，用于布局回归测试定位预览面板。
2. `pixel_art_workspace_test.dart`
   - 新增 `pixel art canvas is centered in the preview panel` 回归测试。
   - 断言默认画布不会贴左，且画布水平中心接近预览面板中心。
   - 新增 `pixel art canvas panel fills tall windows vertically` 回归测试，防止高窗口下右侧画布面板提前结束。
   - 新增 `pixel art size changes require applying the draft` 回归测试，确认修改宽高输入不会立即改变画布，必须点击“应用画布尺寸”才生效。
3. 验证：
   - `D:\Programs\flutter\bin\flutter.bat test test\pixel_art_workspace_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat test test\image_editor_pixelation_entry_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat analyze` 通过。

### Phase 22：像素画画布长按拖动（补充修正已完成）

本轮补齐像素画大画布的平移交互：画笔短拖继续绘制，长按约 500ms 后再拖动会切换为画布平移，便于在高缩放或大尺寸画布中查看不同区域。

完成项：

1. `pixel_art_workspace.dart`
   - 画布区域新增长按拖动平移逻辑，同时控制横向和纵向滚动条。
   - 未达到长按时间的拖动仍按原画笔逻辑绘制，不改变原有绘画手感。
   - 指针提前移动超过容差时取消长按平移计时，避免普通绘制中途被误判成平移。
   - 长按平移结束后抑制后续点击上色，避免拖动画布时误画一个像素。
2. 验证：
   - `D:\Programs\flutter\bin\flutter.bat test test\pixel_art_workspace_test.dart --timeout 60s` 通过。

### Phase 22：像素画 PNG 导出补齐（补充修正已完成）

本轮补齐像素画编辑器的直接导出能力。此前像素画只能“保存到作品库”，没有直接选择路径导出为图片文件的入口，和其他图片/动画导出工作流不一致。

完成项：

1. `pixel_art_workspace.dart`
   - 新增 `导出 PNG` 按钮，和“保存到作品库”并列。
   - 新增导出忙碌态，避免重复点击触发多个保存对话框。
   - 继续由像素画工作区负责生成 PNG 字节，文件路径选择和写入交给外层状态层处理。
2. `home_shell_state.dart`
   - 新增 `_exportPixelArtPng`，使用现有 `getSaveLocation` + `ImageLibraryFileService.exportBytesToPath` 导出 PNG。
   - 导出成功 / 失败使用本地化消息提示。
   - 导出建议文件名包含画布尺寸和时间戳，降低覆盖已有文件的概率。
3. `app_zh.arb` 与生成的本地化代码
   - 新增像素画导出按钮、导出中、导出成功和导出失败文案。
4. `pixel_art_workspace_test.dart`
   - 新增 `pixel art workspace exports png bytes` 回归测试。
   - 覆盖绘制像素后点击导出，校验导出的 PNG 字节、尺寸和像素透明度。
5. 验证：
   - `D:\Programs\flutter\bin\flutter.bat test test\pixel_art_workspace_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat test test\image_editor_pixelation_entry_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat analyze` 通过。

### Phase 22：动画工程导入卡顿与分栏把手可发现性修正（补充修正已完成）

本轮针对实际使用反馈继续收敛两个高优先级问题：导入图片序列时主界面卡死，以及部分多面板工作区看起来无法拖动调整大小。

完成项：

1. `animation_project_service.dart`
   - 图片序列导入创建动画工程时，逐帧读取、解码、缩放和 PNG 编码改为后台 isolate 执行。
   - 已有动画工程追加图片序列轨道时，也复用后台归一化路径。
   - 单帧图片插入 / 替换时，帧归一化也复用后台 isolate，避免大图换帧时短暂卡住。
   - 主线程只保留保存文件、组装工程模型和更新状态，降低大图或多图导入时 UI 卡死概率。
   - 导入输出仍保持原行为：第一帧决定新工程画布尺寸，追加轨道按当前工程画布尺寸归一化。
2. `layout_navigation_widgets.dart`
   - 公共 `WorkspaceResizeHandle` 命中区域从原来的窄小把手扩大到 20px。
   - 在有高度约束的工作区内，纵向分栏把手撑满整条分隔线；无高度约束时使用更高的 128px 兜底显示。
   - 横向时间轴把手同步扩大高度和可见条宽，提升拖动可发现性。
   - `responsive_workspace_split_test.dart` 新增把手 20px 宽、撑满 500px 高的回归断言。
3. 验证：
   - `D:\Programs\flutter\bin\flutter.bat test test\animation_project_service_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat test test\responsive_workspace_split_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat analyze` 通过。

### Phase 22：图生图入口补齐（补充修正已完成）

本轮确认底层已经支持参考图请求，但普通图片生成工作区缺少清晰入口，导致用户会误以为没有图生图能力。

完成项：

1. `generation_form_widgets.dart` / `image_generation_workspace.dart`
   - 普通图片生成面板新增“参考图（图生图）”选择器。
   - 选择参考图后，生成按钮切换为“图生图”，高级参数显示“参考图保真度”。
2. `image_generation_state.dart`
   - 普通图生图参考图单独保存，不和动画工程模板图混用。
   - 支持从本地文件和作品库选择参考图。
   - 作品库中的 Sprite Sheet 可继续选择单帧切片作为参考图。
3. `image_generation_service.dart`
   - `generateTextImages` 透传 `templateImagePath`，复用现有 OpenAI image edit endpoint / Gemini inlineData 请求能力。
4. `image_library_deletion.dart`
   - 删除作品库图片时同步清理普通图生图参考图引用。
5. 验证：
   - `D:\Programs\flutter\bin\flutter.bat gen-l10n` 通过。
   - `D:\Programs\flutter\bin\flutter.bat analyze` 通过。
   - `D:\Programs\flutter\bin\flutter.bat test test\image_generation_builders_test.dart test\image_generation_service_test.dart test\image_library_deletion_test.dart test\form_accessibility_test.dart --timeout 60s` 通过。

补充收口：

- `image_generation_service_test.dart` 新增服务层图生图回归，确认普通图片生成传入参考图后会进入 image edit multipart 路径。
- `sprite_sheet_output_service.dart` 的导出 metadata 检查改为后台 isolate 执行，降低编辑 Sprite Sheet 后保存时的主线程解码成本。
- `D:\Programs\flutter\bin\flutter.bat test test\sprite_sheet_preview_test.dart test\image_generation_service_test.dart --timeout 60s` 通过。

### Phase 22：GIF 合成后台化（补充修正已完成）

本轮继续性能收口，处理 GIF 合成路径的主线程重计算问题。此前 `GifComposer.compose` 会在调用线程逐帧读取图片、解码、缩放并编码 GIF，帧数多或图片较大时容易造成界面卡顿。

完成项：

1. `gif_composer_service.dart`
   - `GifComposer.compose` 保持原调用接口不变，内部改为通过 `compute` 在后台 isolate 执行合成。
   - 后台任务负责展开播放顺序、读取文件或 inline bytes、解码图片、按首帧尺寸归一化和 GIF 编码。
   - 清理原同步主线程合成代码，并修正服务内乱码错误文案为正常中文。
2. 验证：
   - `D:\Programs\flutter\bin\flutter.bat test test\gif_composer_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat analyze` 通过。

---

### Phase 22：Sprite Sheet 预览后台化（补充性能修正已完成）

本轮继续收口动画和 Sprite Sheet 相关性能问题。此前导入、GIF 合成和导出 metadata 已经后台化，但预览面板在生成切片预览时仍可能在 UI 线程执行图片解码、裁切、整表合成和 PNG 编码，遇到大图或多帧时仍有卡顿风险。

完成项：

1. `sprite_sheet_preview_service.dart`
   - `SpriteSheetPreviewComposer.build` 的单张 Sprite Sheet 路径改为调用后台入口。
   - 新增 `buildFromSheetBytesInBackground`，通过 `compute` 在后台 isolate 中执行整图解码、网格裁切和帧 PNG 编码。
   - 多帧输入路径先解析 `GeneratedImage` 字节，再把帧字节和网格配置交给后台 isolate 合成整张 Sprite Sheet。
   - 保留同步 `buildFromSheetBytes`，供底层测试和明确同步场景继续使用。
2. `frame_animation_preview_widgets_test.dart`
   - 预览等待 helper 改为使用 `tester.runAsync` 等待真实 isolate Future 返回。
   - 修复 widget test 只推进测试时钟时无法等到后台任务完成的问题。
3. 验证：
   - `D:\Programs\flutter\bin\flutter.bat test test\sprite_sheet_preview_test.dart test\frame_animation_preview_widgets_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat analyze` 通过。

### Phase 22：Sprite Sheet 编辑辅助路径后台化（补充性能修正已完成）

本轮继续沿 Sprite Sheet 交互链路收口。预览面板后台化后，切片弹窗、作品库切片浏览、旧编辑器替换帧确认和保存服务里的替换 / 复制 / 清空帧仍可能同步解码、裁切和编码整张表。

完成项：

1. `sprite_sheet_editor_service.dart`
   - 新增 `copyFrameInBackground`、`clearFrameInBackground`、`replaceFrameInBackground` 和 `buildReplacementPreviewInBackground`。
   - 同步方法继续保留给底层测试和明确同步场景，UI 与保存链路改走后台入口。
2. `sprite_sheet_output_service.dart`
   - `saveSheetOnly` 改用后台预览入口读取帧尺寸。
   - `replaceFrameAndSave`、`copyFrameAndSave`、`clearFrameAndSave` 改用后台编辑入口，主线程只负责文件读写和导出 metadata。
3. `sprite_sheet_slice_picker_dialog.dart` / `image_library_dialog_widgets.dart` / `editor_gif_state.dart`
   - 切片选择、切片浏览和替换帧确认前的预览构建都改为后台执行。
4. 验证：
   - `D:\Programs\flutter\bin\flutter.bat test test\sprite_sheet_preview_test.dart test\image_library_dialog_widgets_accessibility_test.dart test\sprite_sheet_slice_picker_dialog_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart test\image_editor_pixelation_entry_test.dart --timeout 60s` 通过。
   - `D:\Programs\flutter\bin\flutter.bat analyze` 通过。

### Phase 22：补充性能收口（2026-05-20）

本轮继续处理用户反馈的“导入 / 导出 / 预览卡死”风险，把更多重图像计算移出 UI 线程。

完成项：

1. `patch_image_framing_service.dart`
   - 新增后台 `renderInBackground` 入口，单帧取景渲染可通过 `compute` 执行。
   - 旧图片编辑器调用取景渲染时已切换到后台入口。
2. `editor_gif_state.dart`
   - 背景转透明调用已切换到 `BackgroundTransparencyService.makeBackgroundTransparentInBackground`。
   - Patch 取景调用已切换到 `PatchImageFramingService.renderInBackground`。
3. `sprite_sheet_preview_service.dart` / `sprite_sheet_editor_service.dart` / `sprite_sheet_output_service.dart`
   - Sprite Sheet 预览、切片、替换预览、复制帧、清空帧、替换帧与保存链路继续后台化。
   - UI 链路只保留状态更新、文件读写和结果展示，重计算交给后台 isolate。
4. `pixel_art_workspace.dart`
   - 像素画保存到作品库和导出 PNG 的编码改为后台 isolate。
   - 避免大画布或高缩放场景下 PNG 编码阻塞主界面。
5. `pixel_art_workspace_test.dart`
   - 补齐 `SharedPreferences` mock。
   - 后台编码后的测试等待改为真实异步等待，避免只推进测试时钟导致误判。

已验证：

- `D:\Programs\flutter\bin\flutter.bat test test\pixel_art_workspace_test.dart --timeout 60s --reporter expanded` 通过。

后续建议：

- 继续用定向测试覆盖图片编辑器滤镜预览、作品库批量导入缩略图生成、动画工程导出校验等可能残留的同步大图路径。
