import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../../services/client_config.dart';
import '../../services/web/map_bridge.dart';
import 'map_types.dart';

class PlatformMap extends StatefulWidget {
  const PlatformMap({
    super.key,
    required this.initialCameraPosition,
    required this.markers,
    required this.polylines,
    this.onMapCreated,
    this.onLocationChanged,
    this.myLocationStyleOptions,
  });
  final MapCameraPosition initialCameraPosition;
  final Set<MapMarkerData> markers;
  final Set<MapPolylineData> polylines;
  final ValueChanged<SageMapController>? onMapCreated;
  final ValueChanged<MapUserLocation>? onLocationChanged;
  final MapLocationStyle? myLocationStyleOptions;
  @override
  State<PlatformMap> createState() => _PlatformMapState();
}

class _PlatformMapState extends State<PlatformMap> {
  int? _id;
  String? _error;
  int _generation = 0;
  int _attempt = 0;
  Map<String, MapMarkerData> _markersById = {};
  final Map<MapIcon, String> _icons = {};

  Future<void> _create(web.HTMLDivElement host) async {
    final generation = ++_generation;
    host.style.width = '100%';
    host.style.height = '100%';
    try {
      final id =
          (await mapBridge
                  .create(
                    host,
                    {
                      'config': ClientConfig.mapConfig,
                      'center': widget.initialCameraPosition.target.lngLat,
                      'zoom': widget.initialCameraPosition.zoom,
                    }.jsify()!,
                    ((JSString markerId) {
                      final id = markerId.toDart;
                      _markersById[id]?.onTap?.call(id);
                    }).toJS,
                  )
                  .toDart)
              .toDartInt;
      if (!mounted || generation != _generation) {
        mapBridge.destroy(id.toJS);
        return;
      }
      _id = id;
      _update();
      widget.onMapCreated?.call(_WebController(id));
    } catch (error) {
      if (mounted && generation == _generation) {
        if (_id != null) mapBridge.destroy(_id!.toJS);
        _id = null;
        setState(() => _error = '地图加载失败：$error');
      }
    }
  }

  void _update() {
    if (_id == null) return;
    _markersById = {};
    final markers = <Map<String, dynamic>>[];
    var index = 0;
    for (final marker in widget.markers) {
      final id = marker.id ?? 'marker-${index++}';
      _markersById[id] = marker;
      markers.add({
        'id': id,
        'position': marker.position.lngLat,
        'title': marker.infoWindow.title,
        'anchor': [marker.anchor.dx, marker.anchor.dy],
        'clickable': marker.clickable,
        'zIndex': marker.zIndex,
        'infoWindowEnable': marker.infoWindowEnable,
        'icon': marker.icon.bytes == null
            ? null
            : _icons.putIfAbsent(
                marker.icon,
                () =>
                    'data:image/png;base64,${base64Encode(marker.icon.bytes!)}',
              ),
      });
    }
    mapBridge.update(
      _id!.toJS,
      {
        'markers': markers,
        'polylines': widget.polylines
            .map(
              (p) => {
                'points': p.points.map((point) => point.lngLat).toList(),
                'width': p.width,
                'color':
                    '#${(p.color.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0')}',
                'opacity': p.color.a,
              },
            )
            .toList(),
      }.jsify()!,
    );
  }

  @override
  void didUpdateWidget(covariant PlatformMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  @override
  void dispose() {
    ++_generation;
    if (_id != null) mapBridge.destroy(_id!.toJS);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
              FilledButton(
                onPressed: () => setState(() {
                  _error = null;
                  _attempt++;
                }),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }
    return HtmlElementView.fromTagName(
      key: ValueKey(_attempt),
      tagName: 'div',
      onElementCreated: (element) {
        final host = element as web.HTMLDivElement;
        // The SDK requires an attached DOM container.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _create(host);
        });
      },
    );
  }
}

class _WebController implements SageMapController {
  _WebController(this.id);
  final int id;
  @override
  Future<void> moveCamera(
    MapCameraUpdate update, {
    bool animated = true,
    int duration = 300,
  }) async {
    mapBridge.camera(
      id.toJS,
      {
        'target': update.target?.lngLat,
        'zoom': update.zoom,
        'bounds': update.bounds == null
            ? null
            : [
                update.bounds!.southwest.lngLat,
                update.bounds!.northeast.lngLat,
              ],
        'padding': update.padding,
        'animated': animated,
        'duration': duration,
      }.jsify()!,
    );
  }
}
