import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';

import '../../utils/svg_path_parser.dart';

/// Semantic icon groups used by map markers.
enum CategoryMarkerKind {
  temple,
  palace,
  garden,
  nature,
  bridge,
  residence,
  heritage,
  generic,
}

/// Maps the first matching location category to a stable marker icon.
///
/// [rawCategories] accepts the comma-separated representation used by
/// [RoutePlace], including Chinese punctuation.
CategoryMarkerKind categoryMarkerKindFor(String? rawCategories) {
  final value = (rawCategories ?? '').replaceAll(RegExp(r'\s+'), '');
  if (value.isEmpty) return CategoryMarkerKind.generic;

  if (_containsAny(value, const ['寺', '庙', '佛', '道观', '宗教'])) {
    return CategoryMarkerKind.temple;
  }
  if (_containsAny(value, const ['宫', '殿', '城', '楼', '塔'])) {
    return CategoryMarkerKind.palace;
  }
  if (_containsAny(value, const ['园', '林', '公园', '植物'])) {
    return CategoryMarkerKind.garden;
  }
  if (_containsAny(value, const ['桥', '栈道'])) {
    return CategoryMarkerKind.bridge;
  }
  if (_containsAny(value, const ['故居', '旧居', '宅', '村', '民居'])) {
    return CategoryMarkerKind.residence;
  }
  if (_containsAny(value, const [
    '山',
    '峰',
    '自然',
    '景观',
    '风景',
    '湖',
    '江',
    '河',
    '溪',
    '瀑',
  ])) {
    return CategoryMarkerKind.nature;
  }
  if (_containsAny(value, const [
    '古迹',
    '遗址',
    '历史',
    '文化',
    '博物馆',
    '纪念馆',
    '展馆',
    '书院',
    '祠',
  ])) {
    return CategoryMarkerKind.heritage;
  }
  return CategoryMarkerKind.generic;
}

bool _containsAny(String value, List<String> keywords) =>
    keywords.any(value.contains);

/// Builds all category marker bitmaps once so map rebuilds never rasterize SVG
/// paths on the UI hot path.
Future<Map<CategoryMarkerKind, BitmapDescriptor>> buildCategoryMarkerIcons({
  required Color fillColor,
}) async {
  final entries = await Future.wait(
    CategoryMarkerKind.values.map((kind) async {
      final icon = await _buildMarkerIcon(
        fillColor: fillColor,
        svgPathData: _lucideSvgPaths[kind]!,
      );
      return MapEntry(kind, icon);
    }),
  );
  return Map<CategoryMarkerKind, BitmapDescriptor>.fromEntries(entries);
}

Future<BitmapDescriptor> _buildMarkerIcon({
  required Color fillColor,
  required String svgPathData,
}) async {
  const size = 84;
  const center = ui.Offset(size / 2, size / 2);
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  canvas.drawCircle(
    center,
    39,
    ui.Paint()
      ..style = ui.PaintingStyle.fill
      ..color = const ui.Color(0xFFFFFFFF),
  );
  canvas.drawCircle(
    center,
    29,
    ui.Paint()
      ..style = ui.PaintingStyle.fill
      ..color = fillColor,
  );

  final path = SvgPathParser().parse(svgPathData);
  final bounds = path.getBounds();
  if (bounds.width > 0 && bounds.height > 0) {
    const maxDimension = 40.0;
    final scale = maxDimension / math.max(bounds.width, bounds.height);
    final offsetX = center.dx - bounds.center.dx * scale;
    final offsetY = center.dy - bounds.center.dy * scale;

    canvas
      ..save()
      ..translate(offsetX, offsetY)
      ..scale(scale, scale)
      ..drawPath(
        path,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = ui.StrokeCap.round
          ..strokeJoin = ui.StrokeJoin.round
          ..color = const ui.Color(0xFFFFFFFF),
      )
      ..restore();
  }

  final image = await recorder.endRecording().toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Unable to rasterize category marker icon');
  }
  return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
}

// Path data adapted from Lucide Icons (ISC), normalized into one path per icon.
// Source: https://github.com/lucide-icons/lucide/tree/main/icons
const Map<CategoryMarkerKind, String> _lucideSvgPaths = {
  CategoryMarkerKind.temple:
      'M10 18v-7 M11.119 2.205a2 2 0 0 1 1.762 0l7.84 3.846A.5.5 0 0 1 20.5 7h-17a.5.5 0 0 1-.22-.949z M14 18v-7 M18 18v-7 M3 22h18 M6 18v-7',
  CategoryMarkerKind.palace:
      'M10 5V3 M14 5V3 M15 21v-3a3 3 0 0 0-6 0v3 M18 3v8 M18 5H6 M22 11H2 M22 9v10a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9 M6 3v8',
  CategoryMarkerKind.garden:
      'M10 10v.2A3 3 0 0 1 8.9 16H5a3 3 0 0 1-1-5.8V10a3 3 0 0 1 6 0Z M7 16v6 M13 19v3 M12 19h8.3a1 1 0 0 0 .7-1.7L18 14h.3a1 1 0 0 0 .7-1.7L16 9h.2a1 1 0 0 0 .8-1.7L13 3l-1.4 1.5',
  CategoryMarkerKind.nature: 'M8 3l4 8 5-5 5 15H2L8 3z',
  CategoryMarkerKind.bridge:
      'M10 9.728V16 M14 9.728V16 M18 20V4 M22 11l-4-4A7.5 7.5 0 0 1 6 7l-4 4 M22 16H2 M6 20V4',
  CategoryMarkerKind.residence:
      'M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8 M3 10a2 2 0 0 1 .709-1.528l7-6a2 2 0 0 1 2.582 0l7 6A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z',
  CategoryMarkerKind.heritage:
      'M10 18v-7 M11.119 2.205a2 2 0 0 1 1.762 0l7.84 3.846A.5.5 0 0 1 20.5 7h-17a.5.5 0 0 1-.22-.949z M14 18v-7 M18 18v-7 M3 22h18 M6 18v-7',
  CategoryMarkerKind.generic:
      'M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0 M15 10a3 3 0 1 1-6 0a3 3 0 0 1 6 0',
};
