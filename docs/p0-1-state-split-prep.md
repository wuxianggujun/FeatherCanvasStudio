# P0-1 状态拆分准备

目标：把 `main.dart` / `src/home/*_state.dart` 的大 State 和 mixin 边界拆清楚，降低后续维护风险。

## 现状

- `main.dart` 里的 `_FeatherCanvasHomePageState` 仍直接持有多个 controller、service、notifier 和全局开关。
- 业务状态主要分散在 7 个 mixin：
  - `_ApiConfigStateMixin`
  - `_LocalSettingsStateMixin`
  - `_ImageLibraryStateMixin`
  - `_EditorGifStateMixin`
  - `_ImageGenerationStateMixin`
  - `_BatchGenerationStateMixin`
  - `_HistoryStateMixin`
- 其中体量最大的是：
  - `image_generation_state.dart`
  - `image_library_state.dart`
  - `editor_gif_state.dart`
  - `local_settings_state.dart`
  - `home_shell_state.dart`

## 拆分原则

1. 先拆所有权，不先拆逻辑。
2. 每次只迁移一个业务域。
3. 迁移前先补一个最小回归测试，保证行为不变。
4. controller / notifier / service 尽量归位到自己的业务域，不继续堆在 `main.dart`。
5. 能保留现有行为的前提下，优先把只读派生值和缓存移出大 State。

## 首批候选

### 1. `image_library_state.dart`

适合先动的原因：
- 已经有 `ImageLibraryNotifier`、`ImageLibraryViewDataMemoizer` 和明显的派生数据边界。
- 作品库的筛选、排序、选择、删除、导入 / 导出逻辑相对独立。

建议拆法：
- 先把存在性缓存、筛选条件和选择状态按职责归拢。
- 再把与作品库列表构建直接相关的状态抽到独立控制器或辅助类。

### 2. `batch_generation_state.dart`

适合先动的原因：
- 已经有 `BatchGenerationNotifier`，队列状态比较清晰。
- 业务聚焦在队列管理、批量拆分、预览和失败处理。

建议拆法：
- 先把队列摘要、预览图上限、操作禁用原因这类纯派生逻辑收口。
- 再决定哪些 UI 相关状态可以脱离 `main.dart`。

### 3. `local_settings_state.dart`

适合先动的原因：
- 以设置持久化和导入 / 导出为主，边界清楚。
- 适合做小范围独立迁移。

## 暂缓项

- `home_shell_state.dart`：承载总装配和很多跨域状态，建议最后再拆。
- `image_generation_state.dart`：体量最大，业务最复杂，前面先做边界收敛。
- `editor_gif_state.dart`：和动画工程、图片编辑、预览链路耦合较深，适合在前面几个域拆出后再处理。

## 第一批执行顺序

1. 先确认 `image_library_state.dart` 的状态边界。
2. 再确认 `batch_generation_state.dart` 的状态边界。
3. 最后确认 `local_settings_state.dart` 是否可以继续独立化。

## 这批不做什么

- 不做大规模重命名。
- 不做跨业务域的同时迁移。
- 不改 UI 行为。
- 不再扩大性能主线。
