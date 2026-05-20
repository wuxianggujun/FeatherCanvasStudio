# 下一会话接力提示词

> 用途：记录当前真实进度与下一批可执行任务。动画工程主路径已经完成，不需要再为它创建新主线任务；后续继续按小批次推进 l10n 和无障碍收尾。

---

## 当前状态

项目：FeatherCanvas Studio，Flutter Windows 桌面端。

当前工作树有大量未提交改动，包含 UI 评审迁移、动画工程迁移和测试适配。继续工作前先看 `git status --short`，不要回滚未确认的变更。

已完成主线：

1. `docs/animation-timeline-architecture.md` 的阶段 1-5 已完成。
2. 动画工程完成标准 11 项已审计满足。
3. 旧 GIF 独立工作区、旧 GIF notifier、旧 GIF UI 主路径已删除或降级为底层编码能力。
4. Sprite Sheet 行列式主状态已对象化为 `SpriteSheetImportConfig` / `SpriteSheetImportNotifier`。
5. UI 评审已完成 P0-1、P1-2、P1-4、P1-8 等核心项。
6. Phase 14 动画工程工作台布局重构已完成：旧 `Sprite Sheet 来源预览` 不再作为动画工程入口；有工程时显示左侧工程控制、中央工程预览、底部轨道时间轴。
7. Phase 15 动画工程作品库导入与面板拖拽已完成：本地导入和作品库导入拆分为两个入口，动画工程左侧控制宽度和底部时间轴高度可拖拽并持久化。
8. Phase 16 全局面板拖拽与尺寸持久化审计已完成：统一 `WorkspaceResizeHandle`，`ResponsiveWorkspaceSplit` 复用公共把手。
9. Phase 17 快捷键速查表已完成：本地设置页展示撤销、重做、备选重做。
10. Phase 18 l10n 第一批已完成：本地设置 + 接口配置核心 UI 文案迁移到 `AppLocalizations`。
11. Phase 18 l10n 第二批已完成：文本生图 + 批量生成核心 UI 文案迁移到 `AppLocalizations`。
12. Phase 18 l10n 第三批已完成：作品库工作区、面板、卡片菜单、选择弹窗和切片管理弹窗核心 UI 文案迁移到 `AppLocalizations`。
13. Phase 18 l10n 第四批已完成：像素画工作区完整核心文案、通用图片编辑核心入口和预览状态迁移到 `AppLocalizations`。
14. Phase 18 l10n 第五批已完成：动画工程创建态、Sprite Sheet 生成面板、工程控制主操作、工程设置和预览状态迁移到 `AppLocalizations`。
15. Phase 18 l10n 第六批已完成：动画工程资源诊断、轨道卡片、序列帧时间轴和单帧编辑区迁移到 `AppLocalizations`，`animation_project_workspace.dart` 已无中文 UI 硬编码。
16. Phase 18 l10n 第七批已完成：`general_image_editor_widgets.dart` 的图片编辑内部细分项、摘要函数、标注 / 颜色 / 滤镜标签和 tooltip 迁移到 `AppLocalizations`，该文件已无中文 UI 硬编码。
17. Phase 18 l10n 第八批已完成：`common_form_widgets.dart`、`image_size_widgets.dart`、`image_advanced_settings_widgets.dart`、`image_editor_workspace.dart` 迁移到 `AppLocalizations`，这些文件已无中文 UI 硬编码。
18. 最近一次验证（第八批）：`flutter analyze`、`test\app_test.dart`、`test\batch_generation_workspace_test.dart`、`test\image_generation_builders_test.dart`、`test\image_editor_pixelation_entry_test.dart`、`test\general_image_editor_widgets_test.dart`、`test\preview_display_fit_test.dart`、`flutter build windows --debug` 均通过。
19. Phase 18 l10n 第九批已完成：`frame_animation_preview_*`、`editor_gif_widgets.dart`、`background_transparency_dialog.dart`、`patch_image_framing_dialog.dart` 迁移到 `AppLocalizations`，`image_editor_pixelation_entry_test.dart`、`frame_animation_preview_widgets_test.dart`、`app_test.dart` 和 `flutter build windows --debug` 均通过。
20. Phase 18 l10n 第十批已完成：`history_state.dart` 和 `home_shell_state.dart` 的用户可见历史 / 重置 / 像素画保存文案迁移到 `AppLocalizations`，`history_widget_test.dart`、`app_test.dart` 和 `flutter build windows --debug` 均通过；`home_shell_state.dart` 仅剩消息分类关键词，不再有用户可见 UI 硬编码。
21. Phase 18 l10n 第十一批已完成：`editor_gif_state.dart` 与 `image_generation_state.dart` 的图片编辑、文本生图、Sprite Sheet 生成、动画工程导入 / 编辑 / 导出状态文案迁移到 `AppLocalizations`；两文件均已无中文硬编码。`flutter analyze`、`image_editor_pixelation_entry_test.dart`、`frame_animation_preview_widgets_test.dart`、`animation_project_workspace_test.dart`、`animation_project_editor_test.dart`、`animation_project_service_test.dart`、`image_generation_builders_test.dart`、`history_widget_test.dart`、`app_test.dart` 和 `flutter build windows --debug` 均通过。
22. Phase 18 l10n 第十二批已完成：`api_config_state.dart`、`batch_generation_state.dart`、`preview_panel.dart`、`preview_common_widgets.dart`、`app_dialogs.dart` 的用户可见提示 / 预览 / 弹窗文案迁移到 `AppLocalizations`。`api_config_state.dart` 仅剩 `默认配置` 这个默认数据名，暂与 `ApiConfig.defaults()` 保持一致。`flutter analyze`、`preview_panel_test.dart`、`batch_generation_workspace_test.dart`、`app_test.dart`、`api_config_logic_test.dart`、`image_generation_builders_test.dart` 和 `flutter build windows --debug` 均通过。
23. Phase 18 l10n 第十三批已完成：`image_library_state.dart` 与 `local_settings_state.dart` 的作品库状态提示、本地设置历史标签、预设提示、存储清理、作品库归档导入 / 导出文案迁移到 `AppLocalizations`；两文件均已无中文硬编码。`flutter analyze`、`history_widget_test.dart`、`image_library_deletion_test.dart`、`image_library_archive_service_test.dart`、`image_library_menu_test.dart`、`image_library_service_test.dart`、`local_store_test.dart`、`app_test.dart` 和 `flutter build windows --debug` 均通过。
24. Phase 18 l10n 第十四批已完成：全局中文硬编码扫描后，优先迁移会进入作品库 / 历史 / 预览的服务层标题、来源和编辑摘要；`ImageGenerationService`、`BatchImageGenerationService`、`ImageLibraryService` 和 `GeneralImageEditingService` 均改为由调用方注入本地化标签。`flutter analyze`、`general_image_editing_service_test.dart`、`image_generation_service_test.dart`、`image_library_service_test.dart`、`general_image_editor_widgets_test.dart`、`history_widget_test.dart`、`image_library_menu_test.dart`、`app_test.dart`、`batch_generation_workspace_test.dart`、`animation_project_workspace_test.dart` 和 `flutter build windows --debug` 均通过。
25. Phase 18 l10n 第十五批已完成：工具层显示标签和校验提示迁移收口，覆盖 `image_dimensions.dart`、`api_config_logic.dart`、`api_config_service.dart`、`batch_generation_queue.dart` 的 UI 调用路径；`image_size_widgets.dart`、接口配置面板、批量队列、图片编辑帧网格标签均已传入 l10n 标签。`flutter analyze`、`api_config_logic_test.dart`、`api_config_service_test.dart`、`api_settings_widgets_test.dart`、`batch_generation_job_test.dart`、`batch_generation_workspace_test.dart`、`image_generation_builders_test.dart`、`sprite_sheet_text_test.dart`、`general_image_editor_widgets_test.dart`、`app_test.dart` 和 `flutter build windows --debug` 均通过。
26. Phase 18 l10n 第十六批已完成：最后一轮中文硬编码扫描后，未发现新的直接 UI 文案残留。剩余中文已分类为业务默认数据名、底层异常、消息分类关键词、调试摘要、测试断言或注释。Phase 18 可收口。
27. Phase 19 无障碍审计第一批已完成：导航项、来源选择卡片、动画工程轨道卡片、时间轴帧块、合成预览、Sprite Sheet 预览画布、图片编辑预览画布、颜色 swatch、作品库卡片和作品预览已补 `Semantics` / semantic label；`animation_project_workspace_test.dart`、`frame_animation_preview_widgets_test.dart`、`general_image_editor_widgets_test.dart`、`image_library_menu_test.dart`、`image_library_pagination_test.dart` 和 `flutter analyze` 均通过。
28. Phase 19 无障碍审计第二批已完成：像素画画布支持键盘焦点、方向键移动光标、空格 / 回车绘制，并暴露画布尺寸和当前光标位置语义；Sprite Sheet 切片选择弹窗每帧暴露帧序号、按钮角色和选中状态。`pixel_art_workspace_test.dart`、`sprite_sheet_slice_picker_dialog_test.dart` 和 `flutter analyze` 均通过。
29. Phase 19 无障碍审计第三批已完成：作品库卡片增加稳定焦点承载层，点击卡片后空格可切换选择、回车 / 小键盘回车触发主操作，并增加键盘操作语义提示。`image_library_pagination_test.dart`、`image_library_menu_test.dart` 和 `flutter analyze` 均通过。
30. Phase 19 无障碍审计第四批已完成：作品库分页条增加整体语义标签，常用通用弹窗增加 `FocusTraversalGroup` + `ReadingOrderTraversalPolicy`，并引入 `meetsGuideline(labeledTapTargetGuideline)` 基线测试。`image_library_pagination_test.dart`、`app_dialogs_accessibility_test.dart`、`flutter analyze` 和 `flutter build windows --debug` 均通过。
31. Phase 19 无障碍审计第五批已完成：作品库选择弹窗、切片管理弹窗、生成结果预览弹窗增加焦点遍历分组和更完整的图片 / 选择项语义标签。新增 `image_library_dialog_widgets_accessibility_test.dart`，扩展 `preview_panel_test.dart`。`flutter analyze`、`preview_panel_test.dart`、`image_library_dialog_widgets_accessibility_test.dart`、`app_dialogs_accessibility_test.dart`、`sprite_sheet_slice_picker_dialog_test.dart`、`image_library_pagination_test.dart` 和 `flutter build windows --debug` 均通过。
32. Phase 19 无障碍审计第六批已完成：背景转透明、单帧取景、Sprite Sheet 单帧替换确认弹窗增加焦点遍历分组、滑杆语义值和图片预览语义标签；替换确认弹窗修复了 `AlertDialog` intrinsic layout 遇到 `LayoutBuilder` 的断言风险。新增 `complex_dialogs_accessibility_test.dart`。`flutter analyze`、`complex_dialogs_accessibility_test.dart`、`app_dialogs_accessibility_test.dart`、`general_image_editor_widgets_test.dart`、`image_library_dialog_widgets_accessibility_test.dart` 和 `flutter build windows --debug` 均通过。
33. Phase 19 无障碍审计第七批已完成：设置 / API 表单控件、图片高级参数、图片尺寸预设和批量生成配置补齐语义标签、当前值和滑杆语义格式；新增 `form_accessibility_test.dart` 覆盖稳定表单页面并扩展 `meetsGuideline(labeledTapTargetGuideline)` 基线。`flutter analyze`、`api_settings_widgets_test.dart`、`form_accessibility_test.dart`、`general_image_editor_widgets_test.dart` 和 `flutter build windows --debug` 均通过。
34. Phase 19 无障碍审计第八批已完成：设置菜单、作品库“更多操作”菜单、动画工程“像素化当前帧”菜单增加稳定外层语义，补齐按钮角色、启用态和选中态回归测试。`flutter analyze`、`image_library_menu_test.dart`、`animation_project_workspace_test.dart`、`app_test.dart` 和 `flutter build windows --debug` 均通过。
35. Phase 19 无障碍审计第九批已完成：公共 `PreviewStateSurface` 空 / 加载 / 错误状态增加外层语义和 live region，错误状态合并标题与详情；扩展 `preview_panel_test.dart` 覆盖空状态、错误状态和重试按钮。`flutter analyze`、`preview_panel_test.dart`、`frame_animation_preview_widgets_test.dart` 和 `flutter build windows --debug` 均通过。
36. Phase 19 无障碍审计第十批已完成：图片编辑和像素画撤销 / 重做按钮补齐禁用态原因语义；批量队列空状态和失败任务错误补齐语义 / live region。新增“暂无可撤销操作”“暂无可重做操作”l10n 文案。`flutter analyze`、`pixel_art_workspace_test.dart`、`general_image_editor_widgets_test.dart`、`batch_generation_workspace_test.dart` 和 `flutter build windows --debug` 均通过。
37. Phase 19 无障碍审计第十一批已完成：像素画颜色 swatch 增加颜色值语义、按钮角色和选中态；播放帧缩放按钮增加稳定语义、按钮角色和启用态。`flutter analyze`、`pixel_art_workspace_test.dart`、`frame_animation_preview_widgets_test.dart` 和 `flutter build windows --debug` 均通过。
38. Phase 19 无障碍审计第十二批已完成：批量生成主操作按钮补齐禁用态原因语义，动画工程已有工程态的导入 / 导出 / 新建 / 关闭按钮在工程忙碌时暴露统一不可用原因。新增批量操作与动画工程忙碌态 l10n 文案。`flutter analyze`、`batch_generation_workspace_test.dart`、`animation_project_workspace_test.dart` 和 `flutter build windows --debug` 均通过。
39. Phase 19 无障碍审计第十三批已完成：本地设置作品库导入 / 导出按钮补齐空状态和忙碌态禁用原因；作品库“选择当前结果”按钮补齐空结果和全部选中时的禁用原因。`flutter analyze`、`image_library_pagination_test.dart`、`app_test.dart` 和 `flutter build windows --debug` 均通过。
40. Phase 19 无障碍审计第十四批已完成：Sprite Sheet 预览播放 / 上一帧 / 下一帧按钮在单帧行时补齐禁用原因；本地设置“清理未引用文件”按钮在清理中补齐忙碌态禁用原因。`flutter analyze`、`frame_animation_preview_widgets_test.dart`、`local_settings_widgets_test.dart`、`app_test.dart` 和 `flutter build windows --debug` 均通过。
41. Phase 19 无障碍审计第十五批已完成：本地设置预设列表的应用 / 删除操作增加包含预设名的稳定语义标签；结果预览卡片浮层和预览弹窗图标按钮补充语义回归测试。`flutter analyze`、`local_settings_widgets_test.dart`、`preview_panel_test.dart`、`app_test.dart` 和 `flutter build windows --debug` 均通过。
42. Phase 19 无障碍审计第十六批已完成：完成剩余 `IconButton` / `PopupMenuButton` 全局扫描，并补齐 API 配置“删除当前配置”按钮在只剩一个配置时的禁用原因语义。新增 `apiSettingsDeleteConfigUnavailable` 文案。`flutter gen-l10n`、`api_settings_widgets_test.dart`、`flutter analyze` 和 `flutter build windows --debug` 均通过。
43. Phase 19 无障碍审计第十七批 / 收口评估已完成：全局历史工具条撤销、重做、历史菜单补齐禁用态原因语义；复查剩余低风险 `IconButton` / `PopupMenuButton` 候选后未发现新的高优先级缺口。`app_test.dart`、`flutter analyze` 和 `flutter build windows --debug` 均通过。Phase 19 可收口。
44. Phase 20 P1-8 长列表 Sliver 化 / 虚拟化评估第一批已完成：作品库确认已有分页、`SliverGrid` 和 builder 渲染；批量队列新增 `summarizeBatchGenerationJobs`，将状态计数、预览图、目标图数、预览宽高比和最新调试记录合并为一次遍历，降低大队列重建成本。`batch_generation_workspace_test.dart`、`flutter analyze` 和 `flutter build windows --debug` 均通过。
45. Phase 20 P1-8 长列表 Sliver 化 / 虚拟化评估第二批已完成：补齐作品库 80 项分页 / Sliver 回归测试，确认 `CustomScrollView` + `SliverGrid` 路径稳定且未退回 `GridView`；批量队列大列表测试扩展到 120 个任务，确认 `ListView` builder 路径、有界高度和首屏懒构建稳定。`image_library_pagination_test.dart`、`batch_generation_workspace_test.dart`、`flutter analyze` 和 `flutter build windows --debug` 均通过。
46. Phase 20 P1-8 长列表 Sliver 化 / 虚拟化评估第三批已完成：新增 `ImageLibraryViewDataMemoizer`，作品库列表引用和筛选 / 排序 / 搜索等输入不变时复用上一份 view data，避免 UI rebuild 重复执行存在性检查、分组统计、项目 / 标签集合和排序；`ImageLibraryWorkspace` 改为在 State 内持有 memoizer，缓存生命周期限定在工作区。`image_library_view_data_test.dart`、`image_library_pagination_test.dart`、`flutter analyze` 和 `flutter build windows --debug` 均通过。
47. Phase 20 P1-8 长列表 Sliver 化 / 虚拟化评估第四批已完成：`PreviewPanel` 从一次性 `Wrap` 改为 `GridView.builder`，大结果预览按可见区域懒构建；批量队列预览聚合最多传递 120 张结果图，避免大量历史结果反复进入预览 UI。`preview_panel_test.dart`、`batch_generation_workspace_test.dart`、`flutter analyze` 和 `flutter build windows --debug` 均通过。
48. Phase 20 P1-8 长列表 Sliver 化 / 虚拟化评估第五批 / 收口评估已完成：复查作品库、批量队列和结果预览后，未发现新的高优先级大列表性能瓶颈；性能主线可收口。`flutter analyze` 和 `flutter build windows --debug` 均通过；检测到已有 `feather_canvas_studio` 进程正在运行，本轮未重复启动第二个窗口。
49. Phase 21 P0-1 状态拆分准备第一批已完成：新增 `docs/p0-1-state-split-prep.md`，记录 `_FeatherCanvasHomePageState` 与 `src/home/*_state.dart` 的状态所有权边界、首批拆分候选和暂缓项。下一批建议从 `image_library_state.dart` 开始做低风险边界收敛。
50. Phase 22 图片编辑器布局优化第一批已完成：通用图片编辑器开始调整为“左侧参数面板 + 右侧预览顶部工具条”。`general_image_editor_widgets_test.dart`、`image_editor_pixelation_entry_test.dart`、`flutter analyze` 和 `flutter build windows --debug` 均通过。
51. Phase 22 图片编辑器布局优化第二批已完成：裁剪边距和输出尺寸迁移到右侧预览顶部工具条，点击后通过对话框配置；新增 `general_image_editor_widgets_test.dart` 几何工具对话框回归测试。
52. Phase 22 图片编辑器布局优化第二批修正已完成：应用并保存回到左侧控制区；几何 / 外观 / 标注 / 输出切换、撤销 / 重做、生成完整预览、重置参数和几何工具条只在右侧预览顶部显示；左侧不再显示“几何调整”卡片、裁剪边距摘要或输出尺寸摘要。`general_image_editor_widgets_test.dart`、`image_editor_pixelation_entry_test.dart`、`flutter analyze` 和 `flutter build windows --debug` 均通过。

---

## 下一批任务

优先按这个顺序推进：

1. **Phase 22 第三批：继续打磨图片编辑器右侧工具条**
   - 检查外观 / 标注 / 输出中是否也有适合上移到右侧顶部或弹窗化的高频执行按钮。
   - 保持左侧主要承载低频参数和状态摘要，避免把执行型功能重新堆回左侧。
   - 每批调整后跑 `general_image_editor_widgets_test.dart`、`image_editor_pixelation_entry_test.dart`、`flutter analyze` 和 Windows debug 编译。

2. **Phase 21 第二批：从作品库状态边界开始拆**
   - 优先从 `image_library_state.dart` 开始，不要先动 `home_shell_state.dart`。
   - 先补最小回归测试，再迁移低风险的筛选 / 选择 / 存在性缓存相关状态。
   - 保持 `ImageLibraryWorkspace` 和 `ImageLibraryPanel` 的外部行为不变。
   - 每批迁移后跑 `image_library_pagination_test.dart`、`image_library_menu_test.dart`、相关 service 测试、`flutter analyze` 和 Windows debug 编译。
   - 不要启动 `flutter run -d windows`；需要验证时继续使用 `flutter analyze`、相关 widget 测试和 `flutter build windows --debug`。

3. **Phase 18 后续只作为维护项**
   - `api_config_state.dart` 剩余 `默认配置` 是默认数据名，后续若要迁移需同步考虑 `ApiConfig.defaults()`、存储兼容和逻辑测试。
   - `home_shell_state.dart` 剩余中文是消息分类关键词，不是用户可见 UI，可暂时保留。
   - `display_labels.dart` 当前主要保留给调试摘要、兼容工具和少量非 UI 路径，可继续暂留。
   - 底层异常本地化和默认数据名迁移需要单独立任务，不要混入 UI 字面量收尾。

---

## 建议开场白

```
请先阅读 docs/ui-review.md 末尾的「2026-05-19：当前状态与下一任务队列」。
当前不要新建动画工程主线任务；Phase 14-17 已完成，Phase 18 第一批“本地设置 + 接口配置”也已完成。
Phase 18 第二批“文本生图 + 批量生成”已完成。
Phase 18 第三批“作品库”已完成。
Phase 18 第四批“图片编辑 + 像素画”已完成。
Phase 18 第五批“动画工程核心入口”已完成。
Phase 18 第六批“动画工程剩余细节”已完成。
Phase 18 第七批“图片编辑内部细分项”已完成。
Phase 18 第八批“共享图片 / Sprite Sheet 编辑组件”已完成。
Phase 18 第九批“Sprite Sheet 预览 / 旧编辑辅助组件”已完成。
Phase 18 第十批“home state 的历史 / 重置 / 像素画保存文案”已完成。
Phase 18 第十一批“图片编辑状态层 + 文本生图 / 动画工程状态层”已完成。
Phase 18 第十二批“接口配置状态提示 + 批量生成状态提示 + 结果预览 + 通用弹窗”已完成。
Phase 18 第十三批“作品库状态层 + 本地设置状态层”已完成。
Phase 18 第十四批“服务层作品库 / 历史 / 编辑摘要标签”已完成。
Phase 18 第十五批“工具层显示标签和校验提示”已完成。
Phase 18 第十六批“最后一轮 l10n 分类扫描”已完成，Phase 18 可收口。
Phase 19 第一批“关键 Semantics / semantic label 补强”已完成。
Phase 19 第二批“像素画画布键盘操作 + 切片选择弹窗帧语义”已完成。
Phase 19 第三批“作品库卡片键盘选择 + 主操作快捷键”已完成。
Phase 19 第四批“分页语义 + 通用弹窗焦点分组 + labeledTapTargetGuideline 基线”已完成。
Phase 19 第五批“复杂图片弹窗焦点分组 + 选择项 / 图片语义标签”已完成。
Phase 19 第六批“背景透明 / 单帧取景 / 替换确认弹窗无障碍收口”已完成。
Phase 19 第七批“设置 / API 表单控件 + 图片高级参数 + 批量生成配置语义”已完成。
Phase 19 第八批“常用弹出菜单入口语义 + 启用态回归”已完成。
Phase 19 第九批“公共预览空 / 加载 / 错误状态语义 + live region”已完成。
Phase 19 第十批“撤销 / 重做禁用态原因 + 批量队列空 / 错误状态语义”已完成。
Phase 19 第十一批“颜色 swatch 选中态 + 播放帧缩放按钮语义”已完成。
Phase 19 第十二批“批量操作按钮 + 动画工程导出 / 导入按钮禁用态原因语义”已完成。
Phase 19 第十三批“本地设置作品库导入 / 导出 + 作品库选择当前结果禁用态原因语义”已完成。
Phase 19 第十四批“Sprite Sheet 预览单帧播放 / 切帧禁用原因 + 本地设置清理中禁用原因语义”已完成。
Phase 19 第十五批“预设列表操作稳定语义 + 结果预览浮层 / 弹窗按钮语义回归”已完成。
Phase 19 第十六批“剩余 IconButton / PopupMenuButton 全局扫描 + API 配置删除按钮禁用原因语义”已完成。
Phase 19 第十七批 / 收口评估“全局历史工具条禁用原因语义 + 低风险入口复查”已完成，Phase 19 可收口。
Phase 20 第一批“P1-8 长列表性能评估 + 批量队列单次摘要聚合”已完成。
Phase 20 第二批“作品库 Sliver 分页回归 + 批量队列 120 任务大列表边界测试”已完成。
Phase 20 第三批“作品库 view data memoizer 缓存优化”已完成。
Phase 20 第四批“结果预览 lazy grid + 批量预览图聚合上限”已完成。
Phase 20 第五批 / 收口评估已完成，P1-8 性能主线可收口。
Phase 21 第一批“P0-1 状态拆分准备文档”已完成，详见 docs/p0-1-state-split-prep.md。
Phase 22 第一批“图片编辑器左侧参数面板 + 右侧预览顶部工具条”已完成。
Phase 22 第二批“几何裁剪 / 尺寸入口上移到右侧顶部并改为对话框配置”已完成。
Phase 22 第二批修正“应用并保存回到左侧，右侧顶部工具条从左侧彻底移除，左侧不再显示几何调整卡片”已完成。
请从 Phase 22 第三批开始：检查外观 / 标注 / 输出中是否也有适合上移到右侧顶部或弹窗化的高频执行按钮；确认稳定后再回到 Phase 21 第二批状态边界收敛。
```

---

## 环境

- 工作目录：`C:\Users\wuxianggujun\CodeSpace\FlutterProjects\FeatherCanvasStudio`
- Flutter SDK：`D:\Programs\flutter\bin\flutter.bat`
- Dart SDK：`D:\Programs\flutter\bin\dart.bat`
- 运行：`D:\Programs\flutter\bin\flutter.bat run -d windows`
- 编译：`D:\Programs\flutter\bin\flutter.bat build windows`
- 测试：`D:\Programs\flutter\bin\flutter.bat test`
- 除非用户明确要求，不要执行 `flutter run -d windows`，避免启动新的应用窗口。

---

## 工作准则

- `docs/ui-review.md` 是 UI 评审和下一任务队列的主记录。
- 每完成一个 Phase，都在 `docs/ui-review.md` 追加实施记录。
- 动画工程相关状态以 `docs/animation-timeline-architecture.md` 为准，当前已完成，不要重复开新主线。
- 所有回答和文档新增内容使用简体中文。
- 不要执行 `git reset --hard`、`git checkout --` 等会回滚用户改动的命令。
