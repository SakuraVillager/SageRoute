# SageRoute

SageRoute 是一款以历史人物和地点为线索的文旅导览应用。用户可以浏览人物、文章和地点，在地图上探索目的地，并创建、保存和管理多站点旅行路线。项目使用 Flutter 和 Dart，Android 版本复用 Supabase 保存账号及业务数据，并通过高德地图提供地图、定位和路线规划能力。

## 当前版本

`main` 是已完成的 Android 应用基线。Web 适配在 `web端` 分支持续开发；该分支复用 Dart 业务逻辑，并针对桌面浏览器重新设计页面布局。

## 环境要求

- Flutter SDK，版本需符合 `pubspec.yaml` 中的 Dart SDK 约束（Dart `^3.8.1`）。
- Android Studio 或 Android SDK，以及可运行的 Android 模拟器或设备。
- Supabase 项目和高德地图 Android Key，用于验证在线账号、数据及地图功能。

## 本地运行

1. 安装依赖：

   ```bash
   flutter pub get
   ```

2. 复制 `dart_define.example.json` 为 `dart_define.json`，填写自己的高德 Android Key：

   ```json
   {
     "AMAP_ANDROID_KEY": "YOUR_ANDROID_AMAP_KEY"
   }
   ```

3. 在本地配置文件 `assets/env.env` 中填写 Supabase 客户端配置。不要提交真实密钥或个人环境文件。

4. 连接 Android 设备或启动模拟器，然后运行：

   ```bash
   flutter run --dart-define-from-file=dart_define.json
   ```

如果 Android 原生工程已配置高德 Key，可以省略 `--dart-define-from-file`。

## 检查与构建

```bash
flutter analyze
flutter test
flutter build apk --dart-define-from-file=dart_define.json
```

构建文件位于 `build/app/outputs/flutter-apk/`。正式发布前请使用自己的 Supabase 和高德配置，并确认 Android 签名及发布参数。

## 项目结构

```text
lib/
├── auth/             登录、注册和密码恢复
├── components/       可复用界面组件
├── data/             数据仓储与数据访问
├── models/           业务及数据库模型
├── pages/            导览、设置等页面
├── route_planning/   路线规划模型与协调逻辑
├── services/         Supabase、高德及平台服务
├── theme/            主题与视觉样式
└── views/            首页、地点、人物和路线流程

assets/               图片、字体等静态资源
android/              Android 原生工程
test/                 单元及组件测试
docs/                 架构、数据层和设计说明
```

## 开发说明

- 业务页面和数据访问分层维护，仓储负责 Supabase 数据映射，路线规划协调逻辑不依赖具体地图页面。
- Android 地图和定位需要有效的高德 Key、网络连接及相应设备权限。
- 单元测试使用模拟数据和确定性服务，不应依赖线上 Supabase 或高德服务。
- Web 构建、配置和静态部署说明见 `web端` 分支中的 `docs/web_deployment.md`；该分支的布局记录和验收结果分别见 `docs/web_layout_redesign.md` 与 `docs/web_validation.md`。

## 配置安全

`dart_define.json`、`assets/env.env` 和其他本地配置文件不得包含在提交中。客户端公开 Key 会随应用分发，只能用于客户端访问；严禁将 Supabase `service_role` 或 secret Key 写入客户端配置。生产环境请在 Supabase RLS 和高德控制台限制访问范围。
