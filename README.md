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

正式发布使用 `Release` workflow。它由 `v*` tag 自动触发，构建完成后会把
Android APK、Windows 安装包和 Windows 便携包上传到 GitHub Release。

发布版本号只以 `pubspec.yaml` 的 `version` 字段为准。例如：

```yaml
version: 0.1.1+1
```

推送 `v0.1.1+1` tag 后会自动生成：

- GitHub Release：`FeatherCanvas Studio v0.1.1+1`
- Android 产物：`feather-canvas-studio-v0.1.1+1-android.apk`
- Windows 安装包：`feather-canvas-studio-v0.1.1+1-windows-setup.exe`
- Windows 便携包：`feather-canvas-studio-v0.1.1+1-windows-portable.zip`

Windows 不能只发布裸 `exe`。Flutter Windows 产物需要同时带上
`flutter_windows.dll`、`data/` 和插件 DLL 等运行文件，所以发布页会同时提供：

- `windows-setup.exe`：标准安装包，适合普通用户下载后安装。
- `windows-portable.zip`：便携版，解压整个目录后运行里面的应用程序。

当前仓库只启用了 Android 和 Windows 平台目录，所以 Release 只构建这两个平台。
后续如果需要发布 Web、Linux、macOS 或 iOS，需要先补齐对应 Flutter 平台目录，
再把对应平台加入 Release workflow。

发布前需要先完成这些步骤：

1. 修改 `pubspec.yaml` 中的 `version`。
2. 提交并推送到 `main`。
3. 创建并推送同名 tag，例如：

```bash
git tag -a v0.1.1+1 -m "FeatherCanvas Studio v0.1.1+1"
git push origin v0.1.1+1
```

如果 tag 已经存在但没有生成 Release，可以在 GitHub Actions 中手动运行
`Release` workflow，并输入现有 tag，例如 `v0.1.1+1`。

`Release` workflow 会检查 tag 是否和 `pubspec.yaml` 版本一致，并要求 tag
对应的提交已经在 `main` 分支上。它也会检查同名 Release 是否已经存在；
如果存在，会要求先提升版本号，避免覆盖已发布版本。

## 开源许可

MIT
