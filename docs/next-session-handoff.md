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
53. Phase 22 第二批修正复核已完成：再次确认左侧 `_buildControls` 中不再残留工具条，相关按钮只由右侧 `_buildPreviewSurface` 渲染；文档已同步为当前最终布局。
54. Phase 22 几何弹窗稳定性前置修复已完成：新增 `_geometryDialogOpen` 单实例锁，裁剪边距和输出尺寸弹窗连续触发时只允许打开一个 `AlertDialog`，避免快速连点导致重复入栈或崩溃；新增 `geometry dialogs ignore rapid repeated toolbar taps` 回归测试。`general_image_editor_widgets_test.dart` 和 `image_editor_pixelation_entry_test.dart` 均通过。
55. Phase 22 右侧工具条对齐修正已完成：右侧预览顶部改为左侧分类切换、右侧执行按钮的分区工具栏；撤销 / 重做 / 生成完整预览 / 重置参数靠右显示，几何执行工具条也靠右。`general_image_editor_widgets_test.dart`、`image_editor_pixelation_entry_test.dart`、`flutter analyze` 和 `flutter build windows --debug` 均通过。
56. Phase 22 顶部工具条空白修正已完成：移除会撑开分类入口与执行按钮之间空白的 `Expanded + Align.centerRight`，改为紧凑的双 `Flexible` 分区；新增布局断言防止按钮组再次被拉出大空白。`general_image_editor_widgets_test.dart`、`image_editor_pixelation_entry_test.dart`、`flutter analyze` 和 `flutter build windows --debug` 均通过。
57. Phase 22 小窗口工具条响应式修正已完成：预览区宽度不足 1280 时，顶部工具栏改为两行左对齐，第一行分类入口、第二行执行按钮，避免按钮组贴近右侧滚动条或产生横向挤压；宽屏仍保持同一行紧凑排列。新增窄预览和宽屏两组布局回归测试。`general_image_editor_widgets_test.dart`、`image_editor_pixelation_entry_test.dart`、`flutter analyze` 和 `flutter build windows --debug` 均通过。
58. Phase 22 小窗口切回宽屏右上角修正已完成：单行阈值降为 1080；宽屏时执行按钮恢复 `Expanded + Align.centerRight` 右上角对齐；编辑器根节点和预览根节点显式撑满可用宽度，避免工具条被内容宽度限制。新增动态窗口尺寸回归测试，覆盖同一个 widget 从小窗口切到大窗口后自动重排。随后追加 `WidgetsBindingObserver.didChangeMetrics` 主动重建，并让单行判断同时参考预览区约束和整窗宽度，防止真实窗口拖拽后局部约束没有及时触发重排。`general_image_editor_widgets_test.dart`、`image_editor_pixelation_entry_test.dart`、`flutter analyze` 和 `flutter build windows --debug` 均通过。
59. Phase 22 顶部工具栏最终响应式修正已完成：移除固定宽度阈值判断，改用 `Wrap(alignment: WrapAlignment.spaceBetween)`。宽度足够时分类入口在左、执行按钮在右并自动同一行；宽度不足时自动换两行且第二行左对齐。动态窗口测试覆盖 1100 逻辑宽拖到 1800 逻辑宽后同一个 widget 从两行回到单行。`general_image_editor_widgets_test.dart`、`image_editor_pixelation_entry_test.dart`、`flutter analyze` 和 `flutter build windows --debug` 均通过。
60. Phase 22 外观 / 标注动作上移已完成：外观面板的“居中半幅 / 全图处理”和标注面板的“添加标注 / 清空标注”已从左侧参数区移到右侧预览顶部动作区；左侧保留参数、颜色、位置和标注列表。新增 `appearance and annotation actions stay in preview toolbar` 回归测试。`general_image_editor_widgets_test.dart`、`image_editor_pixelation_entry_test.dart`、`flutter analyze` 和 `flutter build windows --debug` 均通过。
61. Phase 22 像素画画布长按拖动已完成：画布支持长按约 500ms 后拖动平移，普通短拖仍用于绘制；提前移动会取消长按计时，平移结束也不会误触发点击上色。`pixel_art_workspace_test.dart` 通过，后续如需继续收敛可补更底层的滚动偏移回归测试。
62. Phase 22 动画工程导入卡顿与分栏把手可发现性修正已完成：图片序列导入创建工程和追加轨道时，逐帧读文件 / 解码 / 缩放 / PNG 编码改为后台 isolate 执行；单帧插入 / 替换的帧归一化也复用后台 isolate；主线程只负责保存与状态更新。公共 `WorkspaceResizeHandle` 命中区扩大到 20px，纵向把手在有高度约束时撑满整条分隔线，横向时间轴把手同步扩大。`animation_project_service_test.dart`、`responsive_workspace_split_test.dart` 和 `flutter analyze` 均通过。
63. Phase 22 GIF 合成后台化已完成：`GifComposer.compose` 调用接口不变，内部通过 `compute` 在后台 isolate 完成播放序列展开、图片读取 / 解码 / 缩放和 GIF 编码，减少多帧大图合成时的 UI 卡顿。同步旧路径已清理，服务内乱码错误文案同步修正。`gif_composer_test.dart` 和 `flutter analyze` 均通过。

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
Phase 22 几何弹窗稳定性前置修复已完成：连续触发裁剪 / 输出尺寸按钮回调时只会出现一个 `AlertDialog`。
Phase 22 右侧工具条对齐修正已完成：分类入口在右侧预览顶部左边，执行按钮靠右显示。
Phase 22 顶部工具条空白修正已完成：分类入口与执行按钮改为紧凑排布，不再出现中间大空白。
Phase 22 小窗口工具条响应式修正已完成：中等宽度下顶部工具栏自动拆成两行左对齐，宽屏仍保持单行紧凑。
Phase 22 小窗口切回宽屏右上角修正已完成：大窗口恢复执行按钮右上角对齐，小窗口继续两行。
Phase 22 顶部工具栏最终响应式修正已完成：已改为 `Wrap` 自动按实际可用宽度同排或换行，不再依赖固定断点。
Phase 22 外观 / 标注动作上移已完成：外观选区快捷动作和标注添加 / 清空动作已在右侧顶部显示，左侧不再承载这些执行按钮。
Phase 22 像素画预览区空白与尺寸交互修正已完成：像素画右侧画布视口已改为基于可用面板宽高居中，小画布不再贴左造成右侧大空白；非专注模式画布面板高度也已调高，减少高窗口底部白底留空。已移除固定尺寸快捷按钮，避免绕过“应用画布尺寸”直接改变作品；修改宽高输入现在必须点击应用才会改变画布。大画布仍保留横向 / 纵向滚动。新增 `pixel-art-canvas-panel` 布局测试定位、`pixel art canvas is centered in the preview panel`、`pixel art canvas panel fills tall windows vertically` 和 `pixel art size changes require applying the draft` 回归测试，`pixel_art_workspace_test.dart`、`image_editor_pixelation_entry_test.dart`、`general_image_editor_widgets_test.dart` 和 `flutter analyze` 均已通过。
Phase 22 像素画 PNG 导出补齐已完成：像素画编辑器新增 `导出 PNG` 按钮，使用现有 `getSaveLocation` 和 `ImageLibraryFileService.exportBytesToPath` 直接导出 PNG 文件；“保存到作品库”继续保留。新增导出忙碌态和导出成功 / 失败提示，本地化文案已生成。新增 `pixel art workspace exports png bytes` 回归测试，`pixel_art_workspace_test.dart`、`image_editor_pixelation_entry_test.dart`、`general_image_editor_widgets_test.dart` 和 `flutter analyze` 均已通过。
Phase 22 像素画画布长按拖动已完成：像素画画布现在支持长按约 500ms 后拖动平移；普通短拖仍然绘制，长按前发生明显移动会取消平移计时，平移结束不会误点上色。`pixel_art_workspace_test.dart` 已通过。
Phase 22 动画工程导入卡顿与分栏拖拽可发现性修正已完成：图片序列导入、单帧插入和单帧替换的重计算已搬到后台 isolate；公共分栏把手扩大命中区并在可用高度内拉成长分隔线，减少“看起来不能拖”的问题。
Phase 22 GIF 合成后台化已完成：GIF 合成中的读图、解码、缩放和编码已搬到后台 isolate，调用方无需改动。
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

## 2026-05-20 本轮补充进度

- 普通图片生成工作区已补齐“参考图（图生图）”入口，不再只把参考图能力隐藏在动画 / Sprite Sheet 流程里。
- 图生图支持本地图片和作品库图片；作品库里的 Sprite Sheet 仍可选择单帧切片作为参考图，并用临时文件接入请求。
- 文本生图与图生图共用同一个生成面板和底层请求能力，避免新增一个重复入口造成误导；选择参考图后按钮文案会切换为“图生图”，高级参数会显示“参考图保真度”。
- `ImageGenerationService.generateTextImages` 已透传 `templateImagePath`，底层 OpenAI / Gemini 请求能力继续复用已有实现。
- 删除作品库图片时，会同步清理普通图生图参考图引用，避免引用已经删除的文件。
- 已补充图生图服务层回归测试：`generateTextImages` 传入参考图后会进入 image edit multipart 路径，并保留图生图作品库标题 / 来源语义。
- Sprite Sheet 导出元数据检查已搬到后台 isolate；替换帧、复制帧、清空帧、像素化当前帧和像素化整张表最终保存时，不再在 UI 线程重新解码整张表生成 metadata。
- 本轮验证通过：`flutter gen-l10n`、`flutter analyze`、`image_generation_builders_test.dart`、`image_generation_service_test.dart`、`image_library_deletion_test.dart`、`form_accessibility_test.dart`、`sprite_sheet_preview_test.dart`。

下一轮建议：

1. 继续补图生图 UI 层回归：重点测选择参考图后按钮文案、参考图保真度字段和清除参考图状态。
2. 继续性能收口：优先看 Sprite Sheet 预览 / 切片 composer 里从多帧构建整表的路径是否还需要后台化。
3. 需要给用户看程序时先清理旧进程，只保留一个 Windows 实例。

---

## 工作准则

- `docs/ui-review.md` 是 UI 评审和下一任务队列的主记录。
- 每完成一个 Phase，都在 `docs/ui-review.md` 追加实施记录。
- 动画工程相关状态以 `docs/animation-timeline-architecture.md` 为准，当前已完成，不要重复开新主线。
- 所有回答和文档新增内容使用简体中文。
- 不要执行 `git reset --hard`、`git checkout --` 等会回滚用户改动的命令。

---

## 2026-05-20 补充性能进度

- Sprite Sheet 预览构建已后台化：单张 Sprite Sheet 的解码、裁切和 PNG 编码，以及多帧合成整表、单帧 PNG 编码，都改为通过 `compute` 在后台 isolate 执行。
- `buildFromSheetBytes` 保留为低层同步入口；公开异步入口新增 `buildFromSheetBytesInBackground`，供 UI 预览链路使用。
- `frame_animation_preview_widgets_test.dart` 已适配后台 isolate 异步完成机制，等待 helper 使用 `tester.runAsync` 等待真实异步返回，避免 widget test 只推进测试时钟导致误判。
- Sprite Sheet 切片选择弹窗、作品库切片浏览弹窗、旧编辑器替换帧预览已改为后台构建预览数据，避免弹窗打开或替换确认前同步裁切大图。
- `SpriteSheetFileService` 的替换帧、复制帧、清空帧和保存整表元数据路径已改为复用后台入口，主线程只负责读写文件和状态更新。
- 本轮追加验证通过：`flutter analyze`、`sprite_sheet_preview_test.dart`、`frame_animation_preview_widgets_test.dart`、`image_library_dialog_widgets_accessibility_test.dart`、`sprite_sheet_slice_picker_dialog_test.dart`、`general_image_editor_widgets_test.dart`、`image_editor_pixelation_entry_test.dart`。

下一步建议：继续排查图片编辑器滤镜预览、像素化导出前 PNG 编码、作品库批量导入缩略图生成等仍可能卡 UI 线程的路径。

## 2026-05-20 补充性能进度

- 旧图片编辑器的背景转透明流程已改为后台 isolate 执行，避免大图抠透明时阻塞 UI 线程。
- 单帧取景 / Patch framing 渲染已新增后台入口，旧编辑器调用链已切换到后台渲染。
- Sprite Sheet 预览、切片选择、作品库切片浏览、替换帧预览、复制帧、清空帧、替换帧与保存链路已切到后台 isolate。
- 像素画保存到作品库与导出 PNG 的编码流程已切到后台 isolate，避免大尺寸像素画导出时卡住界面。
- `pixel_art_workspace_test.dart` 已补齐 `SharedPreferences` mock，并适配后台编码的真实异步等待。

本轮验证：

- `D:\Programs\flutter\bin\flutter.bat test test\pixel_art_workspace_test.dart --timeout 60s --reporter expanded` 通过。

下一步建议：

1. 继续跑 `flutter analyze` 和 Windows debug 编译确认整体状态。
2. 清理旧 `feather_canvas_studio` 进程，只启动一个 debug exe 实例给用户查看。
3. 后续性能收口优先排查图片编辑器滤镜预览、作品库批量导入缩略图生成、动画工程导出前校验等仍可能同步处理大图的路径。

## 2026-05-20 补充回归进度

- 图生图 UI 层已补回归：普通图片生成面板在选择参考图后会切换为“图生图”主按钮。
- 高级输出参数展开后会显示“参考图保真度”；清除参考图后该字段会消失，并恢复普通“生成图片”按钮。
- 本轮验证：`D:\Programs\flutter\bin\flutter.bat test test\form_accessibility_test.dart --timeout 60s --reporter expanded` 通过。

下一步建议：

1. 继续跑 `flutter analyze`。
2. 若继续推进性能，优先做实际残留路径审计：动画工程导出前诊断、作品库归档导入 / 导出、通用图片编辑器滤镜预览的真实调用链。

## 2026-05-20 作品库归档性能进度

- `ImageLibraryArchiveService` 新增 `exportArchiveInBackground` 与 `importArchiveInBackground`。
- 本地设置页导出作品库归档已切换到后台 isolate，避免大作品库 ZIP 构建阻塞界面。
- 作品库归档导入默认会先解析目标生成目录，再在后台 isolate 解压、校验 manifest、写入导入文件和动画工程依赖帧。
- 同步 `_exportArchive` / `_importArchiveToDirectory` 核心逻辑仍保留在服务内部，便于测试和后台入口复用。

本轮验证：

- `D:\Programs\flutter\bin\flutter.bat test test\image_library_archive_service_test.dart --timeout 60s --reporter expanded` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\form_accessibility_test.dart --timeout 60s --reporter expanded` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过。

## 2026-05-20 动画工程诊断后台化进度

- `AnimationProjectAssetInspector.inspectInBackground` 已新增，动画工程工作台的持续资产诊断改为后台 isolate 执行。
- 动画工程工作台打开后不再在 UI 线程里反复做资产缺失 / 无用资产 / 失效引用统计。
- 原有同步 `inspect(project)` 仍保留给明确同步调用和测试复用。

本轮验证：

- `D:\Programs\flutter\bin\flutter.bat test test\animation_project_service_test.dart test\animation_project_workspace_test.dart --timeout 60s --reporter expanded` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过。
## 2026-05-20 动画帧编辑性能补充

- `AnimationProjectFrameEditor.replaceFrameWithBytes` 和 `insertFrameWithBytes` 已移除调用线程里的预解码，图片字节归一化统一交给后台 isolate。
- `_FrameBytesNormalizeRequest` 现在支持可选目标尺寸；工程画布尺寸为空时由后台 isolate 使用图片原始尺寸 fallback。
- `pixelateFrame` 已切换到 `_pixelateFrameInBackground`，当前帧读取、解码、缩放、像素化和 PNG 编码都在后台 isolate 中执行。
- 已删除不再使用的同步 `_normalizeFrameImage`，避免后续误回退到 UI 线程处理。

本轮验证：

- `D:\Programs\flutter\bin\flutter.bat test test\animation_project_service_test.dart test\animation_project_workspace_test.dart --timeout 60s --reporter expanded` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_archive_service_test.dart --timeout 60s --reporter expanded` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\form_accessibility_test.dart --timeout 60s --reporter expanded` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过。

下一步建议：

1. 继续检查动画工程导出前的剩余同步校验路径。
2. 检查通用图片编辑滤镜预览是否还有 UI 线程大图计算。
3. 编译运行前继续清理旧 `feather_canvas_studio` 进程，只保留一个实例。
## 2026-05-20 图片编辑加载性能补充

- `GeneralImageEditingService.inspect` / `inspectInBackground` 新增 `detectAlpha` 参数，默认仍完整扫描透明通道，保证兼容。
- 从本地或作品库打开图片进入通用图片编辑器时，改用 `detectAlpha: false`，加载阶段只读取宽高，不再逐像素扫描 alpha。
- 应用编辑后的输出仍使用完整检查，保证输出信息准确。
- 新增 `general_image_editing_service_test.dart` 轻量检查回归。

本轮验证：

- `D:\Programs\flutter\bin\flutter.bat test test\general_image_editing_service_test.dart --timeout 60s --reporter expanded` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\general_image_editor_widgets_test.dart --timeout 60s --reporter expanded` 通过。
- `D:\Programs\flutter\bin\flutter.bat test test\image_library_menu_test.dart --timeout 60s --reporter expanded` 通过。
- `D:\Programs\flutter\bin\flutter.bat analyze` 通过。

下一步建议：

1. 编译 Windows debug 并只启动一个 `feather_canvas_studio` 实例。
2. 提交前可补一次动画工程 + 图片编辑 + 作品库归档组合回归。
3. 若继续性能主线，优先做实际大图导入 / 编辑手测，而不是继续无信号扩大重构。
## 2026-05-20 发布前回归基线

本轮目标是为后续 Phase 21 第二批状态拆分建立稳定基线，不继续扩大性能重构。

自动化验证：

- `D:\Programs\flutter\bin\flutter.bat test --timeout 60s --reporter expanded` 通过，合计 232 个测试。

发布前建议手测清单：

1. 动画工程
   - 从本地导入 20+ 张图片序列创建工程。
   - 从作品库导入图片序列追加轨道。
   - 替换单帧、插入图片帧、像素化当前帧。
   - 拖动左侧控制宽度和底部时间轴高度。
   - 导出工程 Sprite Sheet、工程 GIF、工程 PNG 序列。
2. 图片编辑器
   - 从本地和作品库分别打开一张大图。
   - 使用裁剪、输出尺寸、外观效果、标注工具。
   - 小窗口切到大窗口，确认右侧顶部工具条能自动重排。
   - 应用编辑并保存到作品库。
3. 像素画
   - 修改画布尺寸后确认必须点击应用才生效。
   - 长按画布拖动平移，确认不会误画像素。
   - 保存到作品库并导出 PNG。
4. 作品库和设置
   - 作品库分页、筛选、打开更多菜单。
   - 导出作品库归档，再导入归档。
   - 删除作品后确认图生图参考图引用被清理。

下一步建议：

1. 跑 `flutter analyze` 和 Windows debug 编译。
2. 清理旧进程，只启动一个 `feather_canvas_studio` 实例给用户手测。
3. 若手测稳定，进入 Phase 21 第二批：从 `image_library_state.dart` 做状态边界收敛。
