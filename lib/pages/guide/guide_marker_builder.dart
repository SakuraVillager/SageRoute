part of 'guide_page.dart';

/// 用于隐藏高德地图原生定位点的透明图标（1×1 透明像素）。
BitmapDescriptor? _transparentIconCache;

BitmapDescriptor get _transparentIcon {
  return _transparentIconCache ??= BitmapDescriptor.fromBytes(
    // 1×1 透明 PNG
    Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0A,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x63,
      0xF8,
      0x0F,
      0x00,
      0x00,
      0x01,
      0x01,
      0x00,
      0x05,
      0x18,
      0xD8,
      0x4E,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ]),
  );
}

/// ---------- top-level functions (marker building) ----------

Future<_GuideMapAssets> _loadAssets(
  _GuidePageState state, {
  required Color markerFillColor,
}) async {
  final locations = await state._locationRepository.fetchLocations();
  final iconMap = await state._iconRepository.fetchIconMap();
  final defaultMarkerIcon = await _buildScenicMarkerIcon(
    state,
    markerFillColor: markerFillColor,
  );
  final userLocationIcon = await _buildUserLocationIcon(state);

  // 为每个类别 SVG 路径预构建对应的标记图标缓存。
  final svgPathParser = SvgPathParser();
  final Map<String, BitmapDescriptor> categoryIconCache = {};

  // 收集所有需要构建图标的类别
  final categoriesToBuild = <String>{};
  for (final location in locations) {
    if (location.categories.isNotEmpty) {
      final cat = location.categories.first;
      if (iconMap[cat] != null && iconMap[cat]!.isNotEmpty) {
        categoriesToBuild.add(cat);
      }
    }
  }

  // 异步构建每个类别的图标
  for (final category in categoriesToBuild) {
    categoryIconCache[category] = await _buildCategoryMarkerIcon(
      state,
      markerFillColor: markerFillColor,
      svgPathData: iconMap[category]!,
      svgPathParser: svgPathParser,
    );
  }

  BitmapDescriptor getIconForLocation(LocationRecord location) {
    final primaryCategory = location.categories.isNotEmpty
        ? location.categories.first
        : null;
    if (primaryCategory == null) return defaultMarkerIcon;
    return categoryIconCache[primaryCategory] ?? defaultMarkerIcon;
  }

  double? minLatitude;
  double? maxLatitude;
  double? minLongitude;
  double? maxLongitude;

  final markers = locations
      .where((location) => location.coordinates.length >= 2)
      .map<Marker>((location) {
        final longitude = location.coordinates[0];
        final latitude = location.coordinates[1];

        if (minLatitude == null || latitude < minLatitude!) {
          minLatitude = latitude;
        }
        if (maxLatitude == null || latitude > maxLatitude!) {
          maxLatitude = latitude;
        }
        if (minLongitude == null || longitude < minLongitude!) {
          minLongitude = longitude;
        }
        if (maxLongitude == null || longitude > maxLongitude!) {
          maxLongitude = longitude;
        }

        return Marker(
          position: LatLng(latitude, longitude),
          icon: getIconForLocation(location),
          infoWindowEnable: false,
          anchor: const ui.Offset(0.5, 0.5),
          zIndex: 1,
          onTap: (_) => state._showLocationDetails(location),
        );
      })
      .toSet();

  LatLng? focusPoint;
  LatLngBounds? locationBounds;

  if (minLatitude != null &&
      maxLatitude != null &&
      minLongitude != null &&
      maxLongitude != null) {
    final hasSinglePoint =
        minLatitude == maxLatitude && minLongitude == maxLongitude;

    if (hasSinglePoint) {
      focusPoint = LatLng(minLatitude!, minLongitude!);
    } else {
      locationBounds = LatLngBounds(
        southwest: LatLng(minLatitude!, minLongitude!),
        northeast: LatLng(maxLatitude!, maxLongitude!),
      );
    }
  }

  return _GuideMapAssets(
    markers: markers,
    userLocationIcon: userLocationIcon,
    focusPoint: focusPoint,
    locationBounds: locationBounds,
  );
}

Future<BitmapDescriptor> _buildScenicMarkerIcon(
  _GuidePageState state, {
  required Color markerFillColor,
}) async {
  const int size = 84;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const center = ui.Offset(size / 2, size / 2);

  final borderPaint = ui.Paint()
    ..style = ui.PaintingStyle.fill
    ..color = const ui.Color(0xFFFFFFFF);
  final fillPaint = ui.Paint()
    ..style = ui.PaintingStyle.fill
    ..color = markerFillColor;

  canvas.drawCircle(center, 39, borderPaint);
  canvas.drawCircle(center, 27, fillPaint);

  final image = await recorder.endRecording().toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    return BitmapDescriptor.defaultMarker;
  }

  return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
}

/// 构建带类别 SVG 图标的标记圆点。
/// 在白色外圈和主题色内圈之上绘制白色 SVG 图标。
Future<BitmapDescriptor> _buildCategoryMarkerIcon(
  _GuidePageState state, {
  required Color markerFillColor,
  required String svgPathData,
  required SvgPathParser svgPathParser,
}) async {
  const int size = 84;
  const double iconAreaRadius = 21.0;
  const double iconPadding = 1.5;
  const double maxIconDimension = (iconAreaRadius - iconPadding) * 2;

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const center = ui.Offset(size / 2, size / 2);

  // 绘制白色外圈
  final borderPaint = ui.Paint()
    ..style = ui.PaintingStyle.fill
    ..color = const ui.Color(0xFFFFFFFF);
  canvas.drawCircle(center, 39, borderPaint);

  // 绘制主题色内圈
  final fillPaint = ui.Paint()
    ..style = ui.PaintingStyle.fill
    ..color = markerFillColor;
  canvas.drawCircle(center, 27, fillPaint);

  // 解析 SVG 路径并绘制白色图标
  ui.Path? svgPath;
  try {
    svgPath = svgPathParser.parse(svgPathData);
  } catch (_) {
    // SVG 解析失败时跳过图标绘制，返回纯圆点。
  }

  if (svgPath != null) {
    // 计算 SVG 路径的边界框并缩放居中到圆形内
    final bounds = svgPath.getBounds();
    if (bounds.width > 0 && bounds.height > 0) {
      final scale = maxIconDimension / math.max(bounds.width, bounds.height);
      final scaledWidth = bounds.width * scale;
      final scaledHeight = bounds.height * scale;
      final offsetX = center.dx - scaledWidth / 2 - bounds.left * scale;
      final offsetY = center.dy - scaledHeight / 2 - bounds.top * scale;

      canvas.save();
      canvas.translate(offsetX, offsetY);
      canvas.scale(scale, scale);

      final iconPaint = ui.Paint()
        ..style = ui.PaintingStyle.fill
        ..color = const ui.Color(0xFFFFFFFF);

      canvas.drawPath(svgPath, iconPaint);
      canvas.restore();
    }
  }

  final image = await recorder.endRecording().toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    return BitmapDescriptor.defaultMarker;
  }

  return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
}

Future<BitmapDescriptor> _buildUserLocationIcon(_GuidePageState state) async {
  const int size = 84;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const center = ui.Offset(size / 2, size / 2);

  final borderPaint = ui.Paint()
    ..style = ui.PaintingStyle.fill
    ..color = const ui.Color(0xFFFFFFFF);
  final fillPaint = ui.Paint()
    ..style = ui.PaintingStyle.fill
    ..color = const ui.Color(0xFF1E88E5);

  canvas.drawCircle(center, 39, borderPaint);
  canvas.drawCircle(center, 27, fillPaint);

  final image = await recorder.endRecording().toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    return BitmapDescriptor.defaultMarker;
  }

  return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
}
