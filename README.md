# SageRoute

SageRoute 是一款以历史人物和地点为线索的文旅导览应用。用户可以浏览人物、文章和地点，在地图上探索目的地，并创建、保存和管理多站点旅行路线。项目使用 Flutter 和 Dart，Android 与 Web 共用主要业务逻辑、数据模型和 Supabase 数据访问；地图、定位和路线服务按平台适配。

## 平台与功能

- **Android**：原生应用，使用高德地图组件提供导览、地点探索、路线规划和定位。
- **Web**：面向桌面和手机浏览器，采用适配浏览器的导航和响应式布局，通过高德 JavaScript API 提供地图及路线服务。
- **账号与数据**：复用现有 Supabase 项目和业务数据；客户端只使用公开 anon/publishable Key。
- **路线**：支持多站点路线创建、交通方式选择、预览、保存、编辑和管理。

Web 配置、调试和静态部署见 [Web 部署说明](docs/web_deployment.md)；功能对照和验收结果见 [Web 验证记录](docs/web_validation.md)，布局方案见 [Web 布局重设计](docs/web_layout_redesign.md)。

## 环境要求

- Flutter SDK；Dart 版本需符合 `pubspec.yaml` 中的 `^3.8.1` 约束。
- Android Studio 或 Android SDK，以及 Android 模拟器或设备。
- Web 调试需要 Chrome 或 Edge。
- 验证在线账号、数据及地图功能需要 Supabase 项目配置和相应平台的高德 Key。

## 本地配置

### Android

复制 `dart_define.example.json` 为 `dart_define.json`，填入自己的高德 Android Key：

```json
{
  "AMAP_ANDROID_KEY": "YOUR_ANDROID_AMAP_KEY"
}
```

在本地的 `assets/env.env` 中填写 Supabase URL 和客户端公开 Key。不要提交真实配置文件。

### Web

复制 `dart_define.web.example.json` 为 `dart_define.web.json`，填写 Supabase URL、anon/publishable Key、高德 JavaScript API Web Key 和配套安全密钥。构建参数会进入浏览器可读取的客户端产物；不能填入 Supabase `service_role` 或 secret Key。生产环境应使用独立 Web Key 并限制允许域名。

## 运行与构建

安装依赖：

```bash
flutter pub get
```

运行 Android：

```bash
flutter run --dart-define-from-file=dart_define.json
```

运行 Web（Edge）：

```bash
flutter run -d edge --web-port=8080 --dart-define-from-file=dart_define.web.json
```

构建 Android APK：

```bash
flutter build apk --dart-define-from-file=dart_define.json
```

构建静态 Web 站点：

```bash
flutter build web --release --dart-define-from-file=dart_define.web.json
```

Web 发布内容位于 `build/web`，静态托管需支持 HTTPS 和 SPA 路径回退。认证回调、缓存头及本地预览步骤见 Web 部署说明。

## 检查

```bash
flutter analyze
flutter test
```

测试使用模拟仓储和确定性服务，不依赖线上 Supabase 或高德服务。浏览器验收记录及未验证的环境限制见 `docs/web_validation.md`。

## 项目结构

```text
lib/
├── auth/             登录、注册和密码恢复
├── components/       可复用组件、地图和 Web 布局
├── data/             数据仓储及模拟数据
├── models/           业务与数据库模型
├── navigation/       跨平台导航
├── pages/            导览、设置等页面
├── route_planning/   路线规划模型与协调逻辑
├── services/         Supabase、高德、定位及平台服务
├── theme/            主题与视觉样式
└── views/            首页、地点、人物和路线流程

assets/               图片、字体等资源
android/              Android 原生工程
web/                  Web 入口与高德 JS 桥接
test/                 单元、组件和 Web 桥接测试
docs/                 架构、数据层、设计和部署说明
```

## 配置安全

`dart_define.json`、`dart_define.web.json`、`assets/env.env`、本地签名配置和其他个人配置不得提交。Web 中的 Supabase 和地图客户端 Key 可被访问者读取，只能使用客户端公开凭据，并在对应服务控制台限制访问范围。
