# 动画工程与序列帧轨道架构方案

本文档用于推进 FeatherCanvas Studio 从“Sprite Sheet 帧动画工具”升级为“完整动画工程工具”。

核心方向是：用统一的动画工程模型替代当前分散在帧动画、图片编辑、GIF 合成里的行列式旧设计。旧设计不继续长期兼容，只允许一次性迁移或重新导入，避免为了兼容旧路径让项目持续变乱。


## 1. 目标

### 1.1 产品目标

把当前的工作流：

```text
生成 Sprite Sheet → 按行列切片预览 → 转 GIF / 进入编辑器
```

升级为：

```text
创建动画工程
├── 导入 / 生成序列帧
├── 按轨道组织动作
├── 在时间轴中编辑片段、帧时长、播放范围
├── 逐帧编辑、像素化、替换、透明化
└── 导出 Sprite Sheet / GIF / PNG 序列
```

### 1.2 技术目标

1. 建立明确的动画领域模型，而不是继续把 `rows`、`columns`、`gridSpec` 分散传递。
2. 让 Sprite Sheet 只是导入和导出格式，不再是内部唯一数据结构。
3. 让 GIF 合成使用动画工程数据，而不是临时 `GifSourceFrame` 列表。
4. 删除长期兼容旧设计的分支逻辑，只保留一次性迁移入口。
5. 保留当前核心能力：生图、切片、编辑、像素化、作品库、撤销重做、导出。


## 2. 为什么要做完整功能

当前项目已经出现三个事实：

1. 帧动画工作区实际生成的是整张 Sprite Sheet。
2. 预览控件已经有“按行选择、按列播放”的轨道雏形。
3. GIF 合成和图片编辑已经在重复处理帧列表、帧顺序和帧时长。

如果继续在旧结构上补功能，会出现更多妥协：

- UI 上叫“轨道”，数据里还是 `row`。
- GIF 合成有一套帧模型，帧动画预览又有一套切片模型。
- 图片编辑器修改的是 Sprite Sheet，但用户理解的是某个动画帧。
- 作品库保存的是图片条目，却缺少动画工程级别的结构。

完整功能的意义不是一次做大 UI，而是先把内部模型拉直。


## 3. 当前旧设计问题

### 3.1 Sprite Sheet 被当成内部工程格式

现状：

- `SpriteSheetPreviewData` 保存整图、切片帧、行列、网格参数。
- `ImageLibraryItem` 用 `rows`、`columns`、`gridSpec` 描述 Sprite Sheet。
- `FrameAnimationPreviewPanel` 直接基于行列播放。

问题：

- Sprite Sheet 是导出格式，不适合作为动画编辑的核心状态。
- 一旦需要轨道命名、不同帧时长、片段裁剪、倒放、暂停帧，就会不断给行列模型打补丁。

### 3.2 GIF 合成与动画预览割裂

现状：

- GIF 合成使用 `GifSourceFrame`。
- Sprite Sheet 预览使用 `SpriteSheetPreviewData.frames`。
- 发送到 GIF 时会临时把切片转成 `GifSourceFrame.fromBytes`。

问题：

- 帧时长、播放模式、帧顺序不能自然回写到动画工程。
- GIF 只是导出目标，却反过来拥有了一套接近动画工程的模型。

### 3.3 “像素化编辑”命名和职责混杂

现状：

- 帧动画预览里的编辑入口显示“像素化编辑”。
- 图片编辑器既负责替换 Sprite Sheet 帧，也负责像素化整张或单帧。

问题：

- 用户会误以为帧动画只是像素处理功能。
- 编辑器的职责应该是“帧编辑”，像素化只是其中一个操作。


## 4. 新架构原则

1. **动画工程优先**
   - 内部状态以 `AnimationProject` 为中心。
   - Sprite Sheet、GIF、PNG 序列只是导入 / 导出适配器。

2. **轨道是真实模型**
   - 行不再只是 `row`，而是 `AnimationTrack`。
   - 每条轨道有名称、类型、播放范围、默认帧时长。

3. **帧是真实资产**
   - 每一帧有 `FrameAsset`。
   - 帧可以来自生成结果、Sprite Sheet 切片、作品库图片、像素画、编辑结果。

4. **删除旧长期兼容**
   - 不在新代码里到处判断旧 `rows/columns`。
   - 旧 Sprite Sheet 条目只通过导入器转换成新工程。
   - 转换后走新模型。

5. **导出不污染工程模型**
   - GIF、Sprite Sheet、PNG 序列都从工程渲染出来。
   - 导出参数保存在 `ExportProfile`，不反向改变轨道结构。


## 5. 目标数据模型

### 5.1 AnimationProject

动画工程是新的顶层结构。

建议字段：

```dart
class AnimationProject {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int canvasWidth;
  final int canvasHeight;
  final List<AnimationTrack> tracks;
  final List<FrameAsset> assets;
  final TimelineSettings timeline;
  final ExportSettings exportSettings;
}
```

职责：

- 描述一个完整动画项目。
- 管理轨道、帧资产、时间轴设置和导出默认值。
- 作为作品库里的新一等资产。

### 5.2 AnimationTrack

轨道表示一个动作、方向、层或序列。

建议字段：

```dart
class AnimationTrack {
  final String id;
  final String name;
  final AnimationTrackKind kind;
  final bool visible;
  final bool locked;
  final int defaultDelayMs;
  final PlaybackMode playbackMode;
  final List<TimelineClip> clips;
}
```

轨道类型：

- `action`：动作轨道，例如 idle、walk、run、attack。
- `direction`：方向轨道，例如 front、back、left、right。
- `layer`：图层轨道，例如 body、weapon、effect。

第一阶段可以只实现 `action`，但模型要允许扩展。

### 5.3 TimelineClip

片段表示轨道上的一段连续帧。

建议字段：

```dart
class TimelineClip {
  final String id;
  final String name;
  final int startFrame;
  final List<FrameRef> frames;
  final int? overrideDelayMs;
  final bool loop;
}
```

职责：

- 支持裁剪、重排、复制、倒放、插入空帧。
- 支持一个轨道内多个片段。

第一阶段可以限制为每条轨道一个 clip，但不要让 UI 和服务层假设永远只有一个。

### 5.4 FrameAsset

帧资产表示实际图像数据。

建议字段：

```dart
class FrameAsset {
  final String id;
  final String path;
  final int width;
  final int height;
  final FrameAssetSource source;
  final String? sourceLibraryItemId;
  final int? sourceFrameIndex;
}
```

来源类型：

- `generatedImage`
- `spriteSheetSlice`
- `pixelArt`
- `editedFrame`
- `importedFile`

### 5.5 FrameRef

时间轴里不要直接复制图片路径，而是引用资产。

建议字段：

```dart
class FrameRef {
  final String assetId;
  final int delayMs;
  final FrameTransform transform;
}
```

`FrameTransform` 初期可以只包含：

- 翻转
- 透明度
- 偏移

如果暂时不做图层和变换，也建议保留结构，默认值即可。


## 6. 新工作区规划

### 6.1 动画工程工作区

建议用新工作区替代现有“帧动画生成”作为主入口。

主要区域：

```text
动画工程
├── 左侧：工程 / 生成 / 导入控制
├── 中间：画布预览
├── 底部：时间轴轨道
└── 右侧：属性面板
```

核心能力：

1. 新建动画工程。
2. 生成 Sprite Sheet 并导入为轨道。
3. 导入已有 Sprite Sheet。
4. 导入多张单帧图。
5. 轨道命名、重排、删除、锁定。
6. 帧重排、复制、删除、插入空帧。
7. 当前轨道播放、全部轨道预览。
8. 导出 Sprite Sheet、GIF、PNG 序列。

### 6.2 帧编辑器

现有图片编辑器应升级为“帧编辑器”。

保留能力：

- 替换帧
- 复制上一帧
- 清空帧
- 像素化当前帧
- 像素化选区或整帧
- 背景透明化

删除或替换：

- 不再以“编辑整张 Sprite Sheet”为主语。
- 不再把 `targetFrameIndex + rows + columns` 作为主要编辑上下文。
- 改为 `projectId + trackId + clipId + frameIndex`。

### 6.3 GIF 合成器

GIF 合成器应从独立拼图工具降级为导出面板。

保留能力：

- 帧时长
- 循环次数
- 正放、倒放、往返播放

删除或替换：

- 不再维护独立的 `GifSourceFrame` 主数据流。
- 不再把 Sprite Sheet 临时切片塞进 GIF 列表作为核心路径。
- 改为从 `AnimationProject` 渲染导出。

如果仍需要“快速 GIF 合成”，可以作为导入入口：

```text
选择多张图片 → 创建临时 AnimationProject → 进入导出面板
```


## 7. 旧设计删除清单

### 7.1 应替换的旧概念

1. 旧帧动画主工作区
   - 替换为 `AnimationProjectWorkspace`。

2. `FrameAnimationPreviewPanel`
   - 替换为工程级预览组件。
   - 旧的“切片播放 / 网格检查”变成 Sprite Sheet 导入器的一部分。

3. `SpriteSheetPreviewData` 作为主数据结构
   - 降级为导入 / 导出服务的临时结构。

4. `_animationRows`、`_animationColumns`、`_animationGridSpec`
   - 替换为当前工程的轨道和导入参数。

5. `_sendPreviewDataToGif`
   - 替换为 `AnimationProjectExportService.exportGif(...)`。

6. `GifSourceFrame` 作为主编辑模型
   - 降级为 GIF 编码器内部参数，或直接删除。

### 7.2 可以保留但要降级的能力

1. `SpriteSheetGridSpec`
   - 保留为 Sprite Sheet 导入 / 导出参数。
   - 不再作为动画工程内部布局核心。

2. `SpriteSheetEditorComposer`
   - 拆分能力，复用其中的裁剪、替换、像素化逻辑。
   - 不再暴露“编辑整张 Sprite Sheet”的主流程。

3. `GifComposer`
   - 保留编码能力。
   - 输入从工程渲染帧列表而来。

4. `PixelationService`
   - 保留。
   - 面向 `FrameAsset` 或渲染帧使用。


## 8. 迁移策略

### 8.1 不做长期兼容

不建议在新模型里长期支持两套路径：

```text
if oldSpriteSheet:
  old rows/columns path
else:
  new AnimationProject path
```

这种分支会快速污染 UI、服务层、测试和历史记录。

### 8.2 做一次性导入

旧 Sprite Sheet 的处理方式：

```text
旧 ImageLibraryItem(spriteSheet)
→ SpriteSheetImporter
→ AnimationProject
→ 保存为新动画工程条目
```

导入后：

- 每一行变成一条 `AnimationTrack`。
- 每一列变成该轨道里的帧。
- 默认轨道名为 `轨道 1`、`轨道 2`。
- 默认帧时长使用当前 GIF 默认帧时长。
- 原始 Sprite Sheet 可以继续作为普通图片资产保存，但不再作为工程主状态。

### 8.3 旧作品库字段处理

旧字段：

- `rows`
- `columns`
- `gridSpec`
- `frameWidth`
- `frameHeight`
- `frameIndex`

新处理：

- 在 `ImageLibraryItem` 中不再扩展更多动画字段。
- 新增 `AnimationProjectItem` 或把 `ImageLibraryItem.kind` 扩展为 `animationProject`。
- 工程详情保存到独立 JSON 文件，而不是塞进作品库条目。

推荐：

```text
image_library.json
└── 只保存条目索引和路径

animation_project_xxx.json
└── 保存完整 AnimationProject
```


## 9. 服务层拆分

### 9.1 新增服务

建议新增：

```text
lib/src/models/animation_project.dart
lib/src/services/animation_project_store.dart
lib/src/services/animation_project_importer.dart
lib/src/services/animation_project_renderer.dart
lib/src/services/animation_project_export_service.dart
```

职责：

1. `animation_project.dart`
   - 定义工程、轨道、片段、帧资产、导出设置。

2. `animation_project_store.dart`
   - 读写工程 JSON。
   - 管理工程资产目录。

3. `animation_project_importer.dart`
   - 从 Sprite Sheet、多图片、作品库条目创建工程。

4. `animation_project_renderer.dart`
   - 根据轨道、clip、播放模式渲染帧序列。

5. `animation_project_export_service.dart`
   - 导出 Sprite Sheet、GIF、PNG 序列。

### 9.2 现有服务调整

1. `ImageGenerationService`
   - `generateSpriteSheet` 改为生成后导入动画工程。
   - 返回 `AnimationProjectGenerationResult`。

2. `ImageLibraryService`
   - 增加 `animationProject` 类型。
   - 保存工程 JSON 路径，而不是只保存图片路径。

3. `SpriteSheetOutputCache`
   - 降级为导出工具。
   - 不再负责帧动画主保存。

4. `GifComposer`
   - 接收渲染后的帧序列。
   - 不直接依赖 UI 层的帧来源。


## 10. UI 重构范围

### 10.1 导航

建议把当前导航从：

```text
帧动画
图片编辑
像素画编辑
GIF 合成
```

调整为：

```text
动画工程
帧编辑
像素画
作品库
```

GIF 进入“动画工程”的导出面板。

### 10.2 动画工程主界面

首屏不做营销页面，直接进入可操作工程界面。

推荐布局：

```text
┌────────────────────────────────────┐
│ 顶部工具栏：播放 / 暂停 / 导出 / 保存 │
├───────────┬────────────────────────┤
│ 工程控制   │ 画布预览                 │
│ 生成/导入  │ 当前帧 / 当前轨道          │
├───────────┴────────────────────────┤
│ 时间轴轨道：轨道名 + 序列帧 + 播放头   │
└────────────────────────────────────┘
```

### 10.3 时间轴最低完整能力

完整功能的第一版至少要有：

1. 轨道列表。
2. 轨道命名。
3. 轨道重排。
4. 帧缩略图序列。
5. 播放头。
6. 单帧选择。
7. 帧拖拽重排。
8. 删除帧。
9. 复制帧。
10. 设置帧时长。
11. 当前轨道播放。
12. 工程导出。


## 11. 历史记录与撤销重做

当前项目已有按工作区区分的 `HistoryStack`。

新方案：

- 动画工程使用独立 history stack。
- 所有工程操作记录为 `AnimationProjectCommand`。
- UI 操作通过 command 修改工程状态。

建议命令：

```text
RenameTrackCommand
ReorderTrackCommand
AddFrameCommand
RemoveFrameCommand
MoveFrameCommand
DuplicateFrameCommand
SetFrameDelayCommand
ReplaceFrameAssetCommand
ImportSpriteSheetCommand
```

不要让 UI 直接散落调用多个 `setState` 改工程结构。


## 12. 测试策略

### 12.1 模型测试

覆盖：

- 工程 JSON 序列化 / 反序列化。
- 轨道、clip、帧引用的边界。
- 删除帧资产后的引用清理。
- 帧时长默认值。

### 12.2 导入测试

覆盖：

- 旧 Sprite Sheet 导入为多轨道工程。
- 带 margin / gap 的 Sprite Sheet 正确切片。
- 单帧图片导入为轨道。
- 多尺寸帧导入时尺寸归一化策略。

### 12.3 渲染测试

覆盖：

- 当前轨道渲染。
- 全工程渲染。
- 倒放、往返播放。
- 空帧、透明帧。

### 12.4 导出测试

覆盖：

- 导出 Sprite Sheet。
- 导出 GIF。
- 导出 PNG 序列。
- 导出元数据 JSON。

### 12.5 Widget 测试

覆盖：

- 时间轴显示轨道和帧。
- 点击帧更新预览。
- 播放头按帧时长推进。
- 拖拽重排后工程状态正确。
- 删除轨道 / 删除帧有确认。

测试命令：

```bash
flutter test
flutter analyze
dart format --set-exit-if-changed .
```


## 13. 分阶段推进

### 阶段 1：建立新模型

目标：

- 新增动画工程模型。
- 新增工程存储服务。
- 新增基础导入器。

产出：

```text
AnimationProject
AnimationTrack
TimelineClip
FrameAsset
FrameRef
AnimationProjectStore
AnimationProjectImporter
```

验收：

- 可以从旧 Sprite Sheet 创建动画工程 JSON。
- 可以从多张图片创建动画工程 JSON。
- 单元测试覆盖序列化和导入。

### 阶段 2：替换帧动画预览

目标：

- 新增动画工程工作区。
- 用轨道时间轴替代旧切片播放 UI。

产出：

```text
AnimationProjectWorkspace
AnimationTimelinePanel
AnimationCanvasPreview
AnimationProjectInspector
```

验收：

- 可以播放当前轨道。
- 可以选择轨道和帧。
- 可以重命名轨道。
- 旧 `FrameAnimationPreviewPanel` 不再作为主入口。

### 阶段 3：工程导出

目标：

- 从动画工程导出 Sprite Sheet、GIF、PNG 序列。

产出：

```text
AnimationProjectRenderer
AnimationProjectExportService
```

验收：

- 同一工程可以导出三种格式。
- GIF 不再依赖 UI 临时帧列表。
- Sprite Sheet 导出保留网格参数。

### 阶段 4：帧编辑器接入工程

目标：

- 图片编辑器升级为帧编辑器。
- 编辑目标从 Sprite Sheet 单元格改为工程帧。

产出：

```text
FrameEditorWorkspace
ReplaceFrameCommand
PixelateFrameCommand
ClearFrameCommand
DuplicateFrameCommand
```

验收：

- 可以从时间轴进入某一帧编辑。
- 编辑后回写工程。
- 撤销重做能恢复帧资产引用。

### 阶段 5：删除旧主路径

目标：

- 删除旧帧动画主工作区。
- 删除旧 GIF 临时主路径。
- 删除旧行列式状态在主流程中的使用。

删除范围：

```text
AnimationProjectWorkspace 主入口
AnimationProjectRenderer 主预览路径
_sendPreviewDataToGif 主路径
_animationRows / _animationColumns / _animationGridSpec 主状态
GifSourceFrame 作为 UI 主状态
```

保留范围：

```text
SpriteSheetGridSpec 导入 / 导出
SpriteSheetPreviewComposer 导入器内部
GifComposer 编码器内部
PixelationService 帧处理
```


## 14. 风险与决策

### 14.1 破坏旧数据

决策：

- 接受破坏旧主流程。
- 不接受静默丢失用户文件。

处理方式：

- 旧 Sprite Sheet 仍在作品库中作为图片存在。
- 用户打开旧 Sprite Sheet 时提示“导入为动画工程”。
- 导入成功后进入新工程。

### 14.2 重构范围大

决策：

- 先落模型和导入器。
- 再替换 UI。
- 最后删除旧路径。

原因：

- 直接删 UI 会让项目中间态不可用。
- 先建模型可以让测试稳定推进。

### 14.3 GIF 合成功能短期变化

决策：

- GIF 合成不再是独立主工作区。
- 作为动画工程导出能力保留。

过渡：

- 多图快速合成 GIF 可以创建临时动画工程。


## 15. 完成标准

功能完成需要同时满足：

1. 用户可以创建动画工程。
2. 用户可以把 Sprite Sheet 导入为多轨道工程。
3. 用户可以在时间轴上编辑轨道和帧。
4. 用户可以播放当前轨道。
5. 用户可以编辑单帧。
6. 用户可以导出 Sprite Sheet。
7. 用户可以导出 GIF。
8. 用户可以导出 PNG 序列。
9. 旧帧动画主路径已移除。
10. 旧 GIF 临时主路径已移除或降级。
11. `flutter test`、`flutter analyze` 通过。


## 16. 第一轮任务建议

第一轮不要先做 UI。

建议先做：

1. 新增动画工程模型。
2. 新增工程 JSON 存储。
3. 新增 Sprite Sheet 导入器。
4. 新增多图片导入器。
5. 新增工程渲染器最小版本。
6. 给这些模型和服务补测试。

原因：

- UI 可以变，但模型一旦清楚，后面不会越改越乱。
- 旧路径删除也需要新模型先接住现有能力。
