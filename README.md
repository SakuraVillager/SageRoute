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
