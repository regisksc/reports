import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:reports/design/reports_design.dart';

class LocationMap extends StatefulWidget {
  const LocationMap({
    super.key,
    required this.position,
    required this.enabled,
    required this.onSelected,
  });

  final ({double latitude, double longitude})? position;
  final bool enabled;
  final ValueChanged<({double latitude, double longitude})> onSelected;

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  final _controller = MapController();
  final _http = http.Client();
  final _address = TextEditingController();
  Timer? _searchDelay;
  bool _tileError = false;
  bool _searching = false;
  String? _searchError;
  int _searchVersion = 0;

  LatLng get _point => widget.position == null
      ? const LatLng(34.054047, -118.24317)
      : LatLng(widget.position!.latitude, widget.position!.longitude);

  @override
  void didUpdateWidget(covariant LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.position != oldWidget.position || !widget.enabled) {
      _searchDelay?.cancel();
      _searchVersion++;
      _searching = false;
    }
    if (widget.position != oldWidget.position && widget.position != null) {
      _controller.move(_point, _controller.camera.zoom);
    }
  }

  @override
  void dispose() {
    _searchDelay?.cancel();
    _controller.dispose();
    _http.close();
    _address.dispose();
    super.dispose();
  }

  void _select(LatLng point) {
    _searchDelay?.cancel();
    _searchVersion++;
    setState(() {
      _searching = false;
      _searchError = null;
    });
    widget.onSelected((latitude: point.latitude, longitude: point.longitude));
  }

  void _scheduleSearch(String value) {
    _searchDelay?.cancel();
    _searchVersion++;
    setState(() {
      _searching = false;
      _searchError = null;
    });
    _searchDelay = Timer(const Duration(seconds: 2), _searchAddress);
  }

  Future<void> _searchAddress() async {
    final query = _address.text.trim();
    if (query.isEmpty || _searching || !widget.enabled) return;
    final version = ++_searchVersion;
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final results = await Geocoding().locationFromAddress(
        '$query, Los Angeles, CA',
      );
      if (!mounted || version != _searchVersion || !widget.enabled) return;
      if (results.isEmpty) {
        setState(
          () => _searchError =
              'No match found. Try a street address or intersection in Los Angeles.',
        );
      } else {
        _select(LatLng(results.first.latitude, results.first.longitude));
      }
    } on Object {
      if (mounted && version == _searchVersion && widget.enabled) {
        setState(
          () => _searchError =
              'Address search is unavailable. Check your connection or choose a point on the map.',
        );
      }
    } finally {
      if (mounted && version == _searchVersion) {
        setState(() => _searching = false);
      }
    }
  }

  void _zoom(double delta) => _controller.move(
    _controller.camera.center,
    (_controller.camera.zoom + delta).clamp(3, 19),
  );

  Future<void> _openAttribution() async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse('https://www.openstreetmap.org/copyright'),
        mode: LaunchMode.externalApplication,
      );
    } on Object {
      opened = false;
    }
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not open map licence. Visit https://www.openstreetmap.org/copyright',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.position;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('report-address'),
          controller: _address,
          enabled: widget.enabled,
          textInputAction: TextInputAction.search,
          onChanged: _scheduleSearch,
          decoration: const InputDecoration(
            labelText: 'Street address or intersection',
            hintText: 'e.g. Main St & 1st St',
          ),
        ),
        if (_searching) const Text('Searching…'),
        if (_searchError != null)
          Text(
            _searchError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const Text('Tap the map or move it, then choose its center.'),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 260,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: _point,
                    initialZoom: 16,
                    minZoom: 3,
                    maxZoom: 19,
                    interactionOptions: InteractionOptions(
                      flags: widget.enabled
                          ? InteractiveFlag.drag | InteractiveFlag.pinchZoom
                          : InteractiveFlag.none,
                    ),
                    onTap: widget.enabled
                        ? (tap, point) => _select(point)
                        : null,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'org.regisksc.reports',
                      tileProvider: NetworkTileProvider(httpClient: _http),
                      tileDisplay: const TileDisplay.instantaneous(),
                      errorTileCallback: (tile, error, stack) {
                        if (mounted && !_tileError) {
                          setState(() => _tileError = true);
                        }
                      },
                    ),
                    if (position != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _point,
                            width: 48,
                            height: 48,
                            alignment: Alignment.topCenter,
                            child: const Icon(
                              Icons.location_on,
                              size: 48,
                              color: ReportsStyle.orangeDark,
                              semanticLabel: 'Selected dumping location',
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const IgnorePointer(
                  child: Center(child: Icon(Icons.add, size: 28)),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        IconButton(
                          tooltip: 'Zoom in',
                          onPressed: widget.enabled ? () => _zoom(1) : null,
                          icon: const Icon(Icons.add),
                        ),
                        IconButton(
                          tooltip: 'Zoom out',
                          onPressed: widget.enabled ? () => _zoom(-1) : null,
                          icon: const Icon(Icons.remove),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ColoredBox(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: TextButton(
                        onPressed: _openAttribution,
                        child: const Text(
                          '© OpenStreetMap contributors',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: widget.enabled
              ? () => _select(_controller.camera.center)
              : null,
          icon: const Icon(Icons.center_focus_strong),
          label: const Text('Use map center'),
        ),
        if (_tileError)
          const Text('Some map tiles could not load. Check your connection.'),
        const SizedBox(height: 8),
        Text(
          position == null
              ? 'No map point selected'
              : '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
        ),
        const Text('Selected location · not City verified'),
      ],
    );
  }
}
