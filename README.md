# Universal AI Client

> Flutter 全平台 AI 客户端 — 一套代码，跑遍 Android / iOS / Web / Windows / macOS / Linux。统一接入任意 OpenAI Compatible Endpoint，提供对话、文生图、视频生成能力。

[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.22-02569B?logo=flutter)](https://flutter.dev) [![Dart](https://img.shields.io/badge/Dart-%5E3.13-0175C2?logo=dart)](https://dart.dev) [![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey)](#) [![License](https://img.shields.io/badge/license-MIT-green)](#license)

[English](#) · [设计稿](./UI) · [Issues](https://github.com/unifare/aichat/issues)

---

## Why this project

市面上每个 AI 服务都有自己的 App / 网页，模型、Key、计费分散。本项目做一件事：

**一个 App，接管你所有的 AI API。**

- 不绑定任何厂商 — 通过 Provider 抽象，OpenAI / 自建网关 / 公司内网 / 本地 LAN 模型，只要是 OpenAI Compatible 协议就能接入
- 不写假数据 — 列表初始为空，所有结果来自真实接口；未配置时展示真实错误，不展示假成功、假进度、假图片
- 全端一致 — `lib/` 一份业务代码，六端行为一致；响应式布局复刻设计稿（`UI/desktop.html` / `UI/android.html` / `UI/app.html`）

## Features

| 模块 | 能力 | 状态 |
|------|------|------|
| **Chat** | 真实时流式（SSE `ResponseType.stream` 逐 token 渲染）、Markdown + 代码高亮、可复制、停止生成、历史持久化、会话内随时切换 Provider/Model | ✅ 已实现 |
| **Image** | 文生图（`POST imageEndpoint`）、尺寸可调、多图网格、成功/失败/生成中三态、错误可复制 | ✅ 已实现 |
| **Video** | 异步视频（`POST → task_id → 3s 轮询 getVideoTask`）、进度与状态来自服务端、任务卡片管理 | ✅ 已实现 |
| **Settings** | 多 Provider 管理（Base URL / Chat/Image/Video Endpoint / Models / API Key）、设为当前、Test Connection、SecureStorage 加密存 Key | ✅ 已实现 |
| **跨端** | `≥1024px` 三栏 / `600–1024px` NavigationRail / `<600px` Drawer+NavigationBar；TopBar 桌面 `88px 图标+文字`、手机 `44×32 仅图标` | ✅ 已实现 |

> 未实现的功能会在 UI 中明确标注“未实现”及原因，不用假交互掩盖。

## Screenshots

> 设计原型在 [`UI/`](./UI) 目录（`desktop.html` / `android.html` / `app.html`），`AppShell` / `AppTheme` 已按 `oklch` token 还原：`bg #111827` / `surface #1A2230` / `surface2 #232E42` / `border #2E3B52` / `accent #10B981`。

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

**Provider 契约**（UI 只依赖抽象，不感知厂商）：

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

- `CompatibleProvider` — `Dio + Bearer` 直连 `baseUrl + endpoint`，Chat 优先 `stream:true` 的 `text/event-stream`，自动跳过 `keepalive` 空 `delta`，失败回退非流式
- `UnconfiguredProvider` — 未配置时所有调用抛真实错误，UI 展示黄条引导去设置
- 无 Mock / 无假数据分支 — 列表初始为空

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
│   │   ├── api_client.dart      # Dio 封装
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
│   ├── ai_provider.dart          # 抽象
│   ├── compatible_provider.dart  # 真实实现（SSE stream）
│   └── app_providers.dart        # Riverpod 状态 + 持久化
├── features/
│   ├── chat/chat_page.dart
│   ├── image/image_page.dart
│   ├── video/video_page.dart
│   └── settings/settings_page.dart
└── widgets/
    ├── top_bar.dart      # 顶部 Tab（图标化，手机仅图标）
    ├── app_sidebar.dart  # 会话列表
    └── right_panel.dart  # 参数/说明面板
```

## Quick Start

**Requirements**

- Flutter `>=3.22.0` (Dart `^3.13.2`) — 本仓库使用 Flutter `3.47.x`
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

首次启动为空状态，去 **设置 → 添加 Provider**：

| 字段 | 说明 | 示例 |
|------|------|------|
| `Provider Name` | 展示名 | `My Gateway` |
| `Base URL` | 网关根地址（不含 endpoint） | `https://api.example.com/v1` |
| `API Key` | Bearer Token，加密存储 | `sk-...` |
| `Chat Endpoint` | 相对路径 | `/chat/completions` |
| `Image Endpoint` | 相对路径 | `/images/generations` |
| `Video Endpoint` | 相对路径 | `/video/generations` |
| `Chat / Image / Video Model` | 默认模型名 | `gpt-4o` / `dall-e-3` / `sora` |

> `Base URL + Endpoint` 拼接为完整请求地址，支持 OpenAI 官方、OpenAI Compatible、私有网关。`Test Connection` 会先 `GET /models`，失败回退轻量 `POST chat` 探测。

**聊天内切换**：对话页顶部有两个下拉 — 左为当前会话的 Provider，右为 Model。切换 Provider 会改写该会话的 `providerId/model` 并持久化，后续消息走新 Provider。

## API Contract

兼容 OpenAI Chat Completions（SSE）：

```
POST {baseUrl}{chatEndpoint}
Body: { "model": "...", "messages": [...], "stream": true }
Accept: text/event-stream

data: {"choices":[{"delta":{"content":"你好"},"finish_reason":null}]}
data: {"choices":[{"delta":{},"finish_reason":null}]}   # keepalive，客户端跳过
data: [DONE]
```

Image / Video 按 `CompatibleProvider` 约定解析 `data[].url` / `task_id` / `status` / `progress` / `video_url`，字段缺失会抛真实错误并在 UI 展示。

## Tech Stack

| 方向 | 选型 |
|------|------|
| 跨端 | Flutter (Android / iOS / Web / Windows / macOS / Linux) |
| 状态 | `flutter_riverpod` |
| 路由 | `go_router` |
| 网络 | `dio` (`ResponseType.stream` 真流式) |
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

## Principles

- **No fake data** — 禁止 mock/假进度/假图片/假对话充数；做不到就标注“未实现”
- **Real errors** — 未配置/网络失败/服务端错误均展示真实错误与重试入口
- **Icons** — 全 UI 使用 `Material Icons`，不使用 emoji

## Roadmap

- [ ] 附件（图片输入）与多模态消息
- [ ] 语音输入
- [ ] 图片编辑 / 局部重绘 / 放大
- [ ] 视频转视频
- [ ] 会话搜索与导出
- [ ] Provider 导入/导出

## Contributing

PR / Issue 欢迎。提交前请跑：

```bash
flutter analyze
flutter test
```

## License

MIT — see [LICENSE](LICENSE) (or add one if missing).
