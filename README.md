# sageroute

SageRoute Flutter 项目。

## 高德地图导览页

项目已在导览页接入 `amap_map`，运行前需要注入 Android Key：

1. 复制 `dart_define.example.json` 为你自己的配置文件（例如 `dart_define.json`）。
2. 将 `AMAP_ANDROID_KEY` 替换为你申请的高德 Android Key。
3. 运行：

```bash
flutter run --dart-define-from-file=dart_define.json
```

如果你已在原生侧注入 Key，也可以不传 `--dart-define`。

# Roadmap

## 地图

- [ ] 完成地图的图标对应数据库的种类
- [ ] 完成点击图标后显示的一系列内容，如
  - [ ] 基础信息完善
  - [ ] 主题化导览设计
  - [ ] ui动画

## 路线规划

- [ ] 明确路线规划的几种方式
- [ ] 引入决策变量，影响路线规划
- [ ] ai
