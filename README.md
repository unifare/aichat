# Universal AI Client

> Flutter 全平台 AI 客户端 — 一套代码覆盖 Android / iOS / Web / Windows / macOS / Linux，统一接入任意 OpenAI Compatible Endpoint，提供对话、文生图、视频生成能力。

[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.22-02569B?logo=flutter)](https://flutter.dev) [![Dart](https://img.shields.io/badge/Dart-%5E3.13-0175C2?logo=dart)](https://dart.dev) [![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey)](#) [![License](https://img.shields.io/badge/license-MIT-green)](#license)

[设计稿](./UI) · [Issues](https://github.com/unifare/aichat/issues)

---

## Overview

一个 App，管理你所有的 AI API。

通过 Provider 抽象，OpenAI 官方、OpenAI Compatible、私有网关、内网 API、本地 LAN 模型均可接入。`lib/` 一份业务代码，六端行为一致，响应式布局适配桌面、平板、手机。

## Features

| 模块 | 能力 |
|------|------|
| **Chat** | SSE 流式逐 token 输出、Markdown 与代码块渲染、可复制、停止生成、历史会话持久化、会话内切换 Provider / Model |
| **Image** | 文生图、尺寸可选、多图网格、生成中 / 已完成 / 失败三态、错误信息可复制 |
| **Video** | 异步视频生成（创建任务 → 轮询任务状态 → 返回资源链接）、任务卡片管理 |
| **Settings** | 多 Provider 管理（Base URL / Chat / Image / Video Endpoint / Models / API Key）、设为当前、连接测试、API Key 加密存储 |
| **Adaptive UI** | `≥1024px` 三栏布局 / `600–1024px` NavigationRail / `<600px` Drawer + NavigationBar；TopBar 桌面端图标+文字、移动端仅图标 |

## Screenshots

设计原型位于 [`UI/`](./UI)（`desktop.html` / `android.html` / `app.html`），`AppTheme` 已按设计 token 还原：`bg #111827` / `surface #1A2230` / `border #2E3B52` / `accent #10B981`。

| Desktop (≥1024) | Tablet (600–1024) | Mobile (<600) |
|---|---|---|
| Sidebar + 主区 + RightPanel | NavigationRail + 主区 | Drawer + NavigationBar |

## Architecture

```
                    ┌──────────────────────┐
                    │      Flutter UI      │
                    │ Android / iOS /      │
                    │ Windows / macOS /    │
                    │ Linux / Web          │
                    └──────────┬───────────┘
                               │
                     ┌─────────▼─────────┐
                     │    AI Gateway     │
                     │  AIProvider 抽象   │
                     └─────────┬─────────┘
                               │
              ┌────────────────┼─────────────────┐
              │                │                 │
        ┌─────▼─────┐    ┌─────▼─────┐    ┌─────▼─────┐
        │   Chat    │    │   Image   │    │   Video   │
        │ chatStream│    │generateImg│    │generate + │
        │  (SSE)    │    │           │    │  polling  │
        └─────┬─────┘    └─────┬─────┘    └─────┬─────┘
              │                │                 │
        Chat Endpoint     Image Endpoint    Video Endpoint
              └────────────────┼─────────────────┘
                               ▼
                    任意 OpenAI Compatible 服务
              OpenAI / 自建网关 / 内网 API / ComfyUI / Replicate …
```

**Provider 契约** — UI 仅依赖抽象，不感知具体厂商：

```dart
abstract class AIProvider {
  String get id;
  String get name;
  Future<ChatResponse> chat({required List<ChatMessage> messages, required String model});
  Stream<String> chatStream({required List<ChatMessage> messages, required String model});
  Future<ImageResponse> generateImage({required String prompt, required String model});
  Future<VideoTask> generateVideo({required String prompt, required String model});
  Future<VideoTask> getVideoTask(String taskId);
  Future<bool> testConnection();
}
```

- `CompatibleProvider` — `Dio + Bearer` 直连 `baseUrl + endpoint`，Chat 优先 `stream: true` 的 `text/event-stream`，自动处理空 delta，失败回退非流式
- `UnconfiguredProvider` — 未配置时引导用户前往设置页完成配置

## Project Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart          # MaterialApp + Riverpod
│   ├── router.dart       # go_router: /chat /image /video /settings
│   ├── shell.dart        # 响应式三档布局
│   └── theme.dart        # AppColors + AppTheme.dark()
├── core/
│   ├── api/
│   │   ├── api_client.dart
│   │   └── api_exception.dart
│   └── storage/
│       └── local_storage.dart   # SharedPreferences + flutter_secure_storage
├── models/
│   ├── chat_message.dart
│   ├── conversation.dart
│   ├── image_task.dart
│   ├── video_task.dart
│   └── provider_config.dart
├── providers/
│   ├── ai_provider.dart
│   ├── compatible_provider.dart  # SSE 流式实现
│   └── app_providers.dart        # Riverpod 状态与持久化
├── features/
│   ├── chat/chat_page.dart
│   ├── image/image_page.dart
│   ├── video/video_page.dart
│   └── settings/settings_page.dart
└── widgets/
    ├── top_bar.dart
    ├── app_sidebar.dart
    └── right_panel.dart
```

## Quick Start

**Requirements**

- Flutter `>=3.22.0` (Dart `^3.13.2`)，本仓库基于 Flutter `3.47.x` 开发
- JDK 17（Android 构建）

```bash
git clone https://github.com/unifare/aichat.git
cd aichat
flutter pub get

# 任选一个平台运行
flutter run -d windows    # Windows
flutter run -d macos      # macOS
flutter run -d chrome     # Web (Chrome)
flutter run -d android    # Android（需设备/模拟器）
```

**Web 静态预览（release）**

```bash
flutter build web --release
python -m http.server 8081 --directory build/web
# 打开 http://127.0.0.1:8081/
```

## Configuration

首次启动后，前往 **设置 → 添加 Provider** 完成配置：

| 字段 | 说明 | 示例 |
|------|------|------|
| `Provider Name` | 展示名 | `My Gateway` |
| `Base URL` | 网关根地址（不含 endpoint） | `https://api.example.com/v1` |
| `API Key` | Bearer Token，加密存储 | `sk-...` |
| `Chat Endpoint` | 相对路径 | `/chat/completions` |
| `Image Endpoint` | 相对路径 | `/images/generations` |
| `Video Endpoint` | 相对路径 | `/video/generations` |
| `Chat / Image / Video Model` | 默认模型名 | `gpt-4o` / `dall-e-3` / `sora` |

`Base URL + Endpoint` 拼接为完整请求地址，支持 OpenAI 官方、兼容协议及私有网关。`Test Connection` 会先请求 `GET /models`，失败则回退为轻量 `POST chat` 探测。

对话页顶部提供 Provider 与 Model 下拉，可在会话内切换。切换后该会话的后续请求将使用新的 Provider / Model，并自动持久化。

## API Compatibility

兼容 OpenAI Chat Completions SSE：

```
POST {baseUrl}{chatEndpoint}
Body: { "model": "...", "messages": [...], "stream": true }
Accept: text/event-stream

data: {"choices":[{"delta":{"content":"你好"},"finish_reason":null}]}
data: {"choices":[{"delta":{},"finish_reason":null}]}
data: [DONE]
```

Image / Video 按 `CompatibleProvider` 约定解析 `data[].url` / `task_id` / `status` / `progress` / `video_url`。

## Tech Stack

| 方向 | 选型 |
|------|------|
| 跨端 | Flutter (Android / iOS / Web / Windows / macOS / Linux) |
| 状态 | `flutter_riverpod` |
| 路由 | `go_router` |
| 网络 | `dio` (`ResponseType.stream`) |
| 持久化 | `shared_preferences` + `flutter_secure_storage` |
| 渲染 | `flutter_markdown` / `cached_network_image` / `video_player` |
| 工具 | `uuid` / `intl` |

## Build

```bash
flutter build apk --release              # Android
flutter build ios --release              # iOS (需 Xcode)
flutter build web --release              # Web
flutter build windows --release          # Windows
flutter build macos --release            # macOS
flutter build linux --release            # Linux
```

## Roadmap

- [ ] 附件（图片输入）与多模态消息
- [ ] 语音输入
- [ ] 图片编辑 / 局部重绘 / 放大
- [ ] 视频转视频
- [ ] 会话搜索与导出
- [ ] Provider 导入 / 导出

## Contributing

欢迎提交 Issue / PR。提交前请执行：

```bash
flutter analyze
flutter test
```

## License

MIT — see [LICENSE](LICENSE) (or add one if missing).
