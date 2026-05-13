# FeatherCanvas Studio

FeatherCanvas Studio 是一个基于 Flutter 的 OpenAI-compatible 生图客户端。
目标很直接：让用户自己填写接口地址、密钥、模型和参数，
然后快速生成、预览和管理图片结果。

## 当前定位

- Base URL 配置
- API Key 配置
- 模型与尺寸参数
- 图片结果预览
- 本地历史与图片缓存

## 计划支持

- OpenAI Images
- 兼容 OpenAI 格式的第三方服务

## 本地开发

```bash
flutter pub get
flutter run -d windows
```

## 持续集成

项目使用 GitHub Actions 做提交校验和临时构建。

- `Flutter CI`：在 `main` 分支 push、面向 `main` 的 PR、手动触发时运行。
- 校验内容：`dart format`、`flutter analyze`、`flutter test`。
- 构建平台：当前仓库已启用的 Android 和 Windows。
- 临时产物：保留 7 天，文件名会带上 `pubspec.yaml` 中的版本号。
- 依赖缓存：复用 Flutter SDK、Pub cache、Gradle cache。
- 缓存清理：`Cleanup Actions Cache` 每周清理超过 7 天未访问的 Actions cache。

## 发布版本

正式发布使用 `Release` workflow，不需要手工提前创建 tag。

发布版本号只以 `pubspec.yaml` 的 `version` 字段为准。例如：

```yaml
version: 0.1.0+1
```

运行 `Release` workflow 后会自动生成：

- Git tag：`v0.1.0+1`
- GitHub Release：`FeatherCanvas Studio v0.1.0+1`
- Android 产物：`feather-canvas-studio-v0.1.0+1-android.apk`
- Windows 产物：`feather-canvas-studio-v0.1.0+1-windows.zip`

发布前需要先完成这些步骤：

1. 修改 `pubspec.yaml` 中的 `version`。
2. 提交并推送到 `main`。
3. 在 GitHub Actions 中手动运行 `Release` workflow。

`Release` workflow 只允许从 `main` 分支运行。它会先检查同名 tag 或
Release 是否已经存在；如果存在，会要求先提升版本号，避免覆盖已发布版本。

## 开源许可

MIT
