import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';

// ── Campus centre (Pondicherry University) ──────────────────────────────────
final _campusCenter = LatLng(12.0180, 79.8555);
final _campusFallback = LatLng(12.0098, 79.8545); // Main gate fallback

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;

  // GPS
  LatLng _myLocation = _campusFallback;
  double _accuracy = 0;
  bool _gpsReady = false;
  bool _gpsPermissionDenied = false;
  bool _followMe = false;
  StreamSubscription<Position>? _posStream;

  // Navigation
  _Landmark? _destination;
  bool _isNavigating = false;

  // Live tick (every second)
  Timer? _liveTimer;
  int _tick = 0;

  // Buses
  late final List<_BusRoute> _buses;

  static final LatLngBounds _campusBounds = LatLngBounds(
    LatLng(12.005, 79.838),
    LatLng(12.037, 79.874),
  );

  List<_Landmark> _getLandmarks(Tc tc) => [
        _Landmark('Library', LatLng(12.0155, 79.8565), Icons.local_library, tc.accent, detail: 'Central Library · 8 AM – 8 PM'),
        _Landmark('Cafeteria', LatLng(12.0140, 79.8590), Icons.restaurant, tc.primary, detail: 'Main Cafeteria · 7 AM – 10 PM'),
        _Landmark('Sports Complex', LatLng(12.0120, 79.8555), Icons.sports_soccer, AppColors.accentGreen, detail: 'Indoor & Outdoor · 6 AM – 9 PM'),
        _Landmark('Admin Block', LatLng(12.0170, 79.8575), Icons.business, AppColors.accentPurple, detail: 'Administration · 9 AM – 5 PM'),
        _Landmark('Main Gate', LatLng(12.0098, 79.8545), Icons.door_front_door, AppColors.accentPink, detail: 'Main Entrance · Open 24 h'),
        _Landmark('Hostels', LatLng(12.0210, 79.8530), Icons.hotel, AppColors.accentTeal, detail: 'Residential Blocks A–F'),
        _Landmark('Silver Jubilee', LatLng(12.0080, 79.8520), Icons.account_balance, tc.primary, detail: 'Convention Hall · Events'),
        _Landmark('Stadium', LatLng(12.0115, 79.8500), Icons.stadium, AppColors.accentGreen, detail: 'Athletic Ground · 5 AM – 10 PM'),
        _Landmark('Gate 2', LatLng(12.0075, 79.8505), Icons.door_sliding, AppColors.accentRed, detail: 'Secondary Entrance'),
      ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _buses = _initBuses();
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _tick++);
    });
    _initGps();
  }

  @override
  void dispose() {
    _posStream?.cancel();
    _liveTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  List<_BusRoute> _initBuses() => [
        _BusRoute(
          name: 'Route A',
          path: 'Main Gate → Library → Hostel',
          color: const Color(0xFF4B9EFF),
          icon: Icons.directions_bus_rounded,
          waypoints: [
            LatLng(12.0098, 79.8545),
            LatLng(12.0120, 79.8552),
            LatLng(12.0140, 79.8558),
            LatLng(12.0155, 79.8565),
            LatLng(12.0180, 79.8548),
            LatLng(12.0210, 79.8530),
            LatLng(12.0180, 79.8540),
            LatLng(12.0140, 79.8550),
            LatLng(12.0098, 79.8545),
          ],
          cycleSecs: 900,
          offsetSecs: 0,
        ),
        _BusRoute(
          name: 'Route B',
          path: 'Hostel → Cafeteria → Sports Complex',
          color: const Color(0xFFAB7FFF),
          icon: Icons.directions_bus_outlined,
          waypoints: [
            LatLng(12.0210, 79.8530),
            LatLng(12.0190, 79.8548),
            LatLng(12.0165, 79.8570),
            LatLng(12.0140, 79.8590),
            LatLng(12.0130, 79.8572),
            LatLng(12.0120, 79.8555),
            LatLng(12.0140, 79.8542),
            LatLng(12.0175, 79.8535),
            LatLng(12.0210, 79.8530),
          ],
          cycleSecs: 1200,
          offsetSecs: 360,
        ),
        _BusRoute(
          name: 'Route C',
          path: 'Academic Block → Lab → Main Gate',
          color: const Color(0xFF2DD4A7),
          icon: Icons.airport_shuttle_rounded,
          waypoints: [
            LatLng(12.0170, 79.8575),
            LatLng(12.0150, 79.8560),
            LatLng(12.0130, 79.8550),
            LatLng(12.0115, 79.8535),
            LatLng(12.0098, 79.8545),
            LatLng(12.0115, 79.8555),
            LatLng(12.0145, 79.8562),
            LatLng(12.0158, 79.8570),
            LatLng(12.0170, 79.8575),
          ],
          cycleSecs: 1500,
          offsetSecs: 730,
        ),
      ];

  Future<void> _initGps() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _gpsPermissionDenied = true);
      return;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
      if (mounted) setState(() => _gpsPermissionDenied = true);
      return;
    }
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && mounted) {
        setState(() {
          _myLocation = LatLng(last.latitude, last.longitude);
          _accuracy = last.accuracy;
          _gpsReady = true;
        });
      }
    } catch (_) {}
    _posStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((pos) {
      if (!mounted) return;
      setState(() {
        _myLocation = LatLng(pos.latitude, pos.longitude);
        _accuracy = pos.accuracy;
        _gpsReady = true;
      });
      if (_followMe) _mapController.move(_myLocation, _mapController.camera.zoom);
    }, onError: (_) {});
  }

  double _distanceMetres(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = (b.latitude - a.latitude) * (math.pi / 180);
    final dLng = (b.longitude - a.longitude) * (math.pi / 180);
    final sinLat = math.sin(dLat / 2);
    final sinLng = math.sin(dLng / 2);
    final h = sinLat * sinLat + math.cos(a.latitudeInRad) * math.cos(b.latitudeInRad) * sinLng * sinLng;
    return 2 * r * math.asin(math.sqrt(h));
  }

  String _formatDistance(double m) => m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.round()} m';
  int _walkingMinutes(double m) => math.max(1, (m / 80).round());

  void _navigate(_Landmark lm) {
    setState(() { _destination = lm; _isNavigating = true; _followMe = false; });
    final bounds = LatLngBounds.fromPoints([_myLocation, lm.position]);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)));
  }

  void _clearNavigation() {
    setState(() { _destination = null; _isNavigating = false; });
    _mapController.move(_campusCenter, 15.0);
  }

  void _toggleFollowMe() {
    setState(() => _followMe = !_followMe);
    if (_followMe) _mapController.move(_myLocation, 17.0);
  }

  List<LatLng> _buildRoute(LatLng from, LatLng to) {
    const steps = 20;
    return List.generate(steps + 1, (i) {
      final t = i / steps;
      return LatLng(from.latitude + (to.latitude - from.latitude) * t, from.longitude + (to.longitude - from.longitude) * t);
    });
  }

  LatLng _busPosition(_BusRoute bus) {
    final elapsed = (_tick + bus.offsetSecs) % bus.cycleSecs;
    final progress = elapsed / bus.cycleSecs;
    final pts = bus.waypoints;
    final totalSegs = pts.length - 1;
    final segF = progress * totalSegs;
    final segIdx = segF.floor().clamp(0, totalSegs - 1);
    final t = segF - segIdx;
    final a = pts[segIdx];
    final b = pts[segIdx + 1];
    return LatLng(a.latitude + (b.latitude - a.latitude) * t, a.longitude + (b.longitude - a.longitude) * t);
  }

  int _busEtaSecs(_BusRoute bus) {
    final elapsed = (_tick + bus.offsetSecs) % bus.cycleSecs;
    return bus.cycleSecs - elapsed;
  }

  String _busEtaLabel(_BusRoute bus) {
    final secs = _busEtaSecs(bus);
    if (secs <= 30) return 'Arriving now';
    return '~${(secs / 60).ceil()} min';
  }

  String _busStatusDetail(_BusRoute bus) {
    final secs = _busEtaSecs(bus);
    if (secs <= 30) return 'At stop now';
    if (secs <= 120) return 'Almost here';
    if (secs >= bus.cycleSecs - 60) return 'Just departed';
    return 'In transit';
  }

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    final dest = _destination;
    final dist = dest != null ? _distanceMetres(_myLocation, dest.position) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Campus Map', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _gpsPermissionDenied ? Icons.location_off_rounded : _gpsReady ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                          size: 13,
                          color: _gpsPermissionDenied ? AppColors.accentRed : _gpsReady ? AppColors.accentGreen : tc.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _gpsPermissionDenied ? 'Location permission denied' : _gpsReady ? 'Live GPS · ±${_accuracy.round()} m' : 'Acquiring GPS…',
                          style: TextStyle(
                            color: _gpsPermissionDenied ? AppColors.accentRed : _gpsReady ? AppColors.accentGreen : tc.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_gpsPermissionDenied)
                TextButton.icon(
                  icon: const Icon(Icons.location_on_rounded, size: 16),
                  label: const Text('Enable'),
                  onPressed: () async => Geolocator.openLocationSettings(),
                  style: TextButton.styleFrom(foregroundColor: tc.accent, textStyle: const TextStyle(fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Live Bus Tracking'),
          const SizedBox(height: 14),
          ..._buses.map((bus) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _buildBusCard(tc, bus))),
          const SizedBox(height: 28),
          const SectionHeader(title: 'University Map'),
          const SizedBox(height: 14),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: SizedBox(
                    height: 400,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _campusCenter,
                            initialZoom: 15.0,
                            minZoom: 13,
                            maxZoom: 19,
                            cameraConstraint: CameraConstraint.contain(bounds: _campusBounds),
                            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                            onPositionChanged: (_, hasGesture) {
                              if (hasGesture && _followMe) setState(() => _followMe = false);
                            },
                          ),
                          children: [
                            TileLayer(urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', userAgentPackageName: 'com.punova.campus', maxZoom: 19),
                            TileLayer(urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}', userAgentPackageName: 'com.punova.campus', maxZoom: 19),
                            if (_gpsReady && _accuracy > 0)
                              CircleLayer(circles: [
                                CircleMarker(point: _myLocation, radius: _accuracy, color: tc.accent.withValues(alpha: 0.12), borderColor: tc.accent.withValues(alpha: 0.5), borderStrokeWidth: 1, useRadiusInMeter: true),
                              ]),
                            if (_isNavigating && dest != null)
                              PolylineLayer(polylines: [
                                Polyline(points: _buildRoute(_myLocation, dest.position), strokeWidth: 4.5, color: tc.accent, pattern: StrokePattern.dashed(segments: const [14, 7])),
                              ]),
                            MarkerLayer(
                              markers: [
                                // User dot
                                Marker(
                                  point: _myLocation,
                                  width: 40,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: tc.accent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [BoxShadow(color: tc.accent.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2)],
                                    ),
                                    child: Icon(_gpsReady ? Icons.my_location : Icons.location_searching, color: Colors.white, size: 17),
                                  ),
                                ),
                                // Landmarks
                                ..._getLandmarks(tc).map((lm) => Marker(
                                      point: lm.position,
                                      width: 120,
                                      height: 58,
                                      child: GestureDetector(
                                        onTap: () => _navigate(lm),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _destination == lm ? lm.color : Colors.white,
                                                borderRadius: BorderRadius.circular(7),
                                                border: Border.all(color: lm.color, width: 1.5),
                                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4)],
                                              ),
                                              child: Text(lm.name, style: TextStyle(color: _destination == lm ? Colors.white : lm.color, fontSize: 9, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                                            ),
                                            Icon(Icons.location_on, color: lm.color, size: 24),
                                          ],
                                        ),
                                      ),
                                    )),
                                // Live bus markers
                                ..._buses.map((bus) {
                                  final pos = _busPosition(bus);
                                  return Marker(
                                    point: pos,
                                    width: 36,
                                    height: 36,
                                    child: Tooltip(
                                      message: '${bus.name}: ${_busEtaLabel(bus)}',
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: bus.color,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [BoxShadow(color: bus.color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)],
                                        ),
                                        child: Icon(bus.icon, color: Colors.white, size: 18),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                        // Map FABs
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _mapFab(icon: _followMe ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded, color: _followMe ? tc.accent : tc.textMuted, tooltip: _followMe ? 'Stop following' : 'Follow my location', onTap: _toggleFollowMe),
                              const SizedBox(height: 8),
                              _mapFab(icon: Icons.center_focus_strong_rounded, color: tc.textMuted, tooltip: 'Re-centre campus', onTap: () { setState(() => _followMe = false); _mapController.move(_campusCenter, 15.0); }),
                            ],
                          ),
                        ),
                        // GPS loading banner
                        if (!_gpsReady && !_gpsPermissionDenied)
                          Positioned(
                            top: 10, left: 0, right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(20)),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                    SizedBox(width: 8),
                                    Text('Acquiring GPS…', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Navigation info panel
                if (_isNavigating && dest != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: tc.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: tc.accent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(color: dest.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Icon(dest.icon, color: dest.color, size: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Navigating to ${dest.name}', style: TextStyle(color: tc.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(height: 3),
                              Text(dest.detail, style: TextStyle(color: tc.textMuted, fontSize: 11)),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(Icons.straighten, size: 13, color: tc.accent),
                                  const SizedBox(width: 4),
                                  Text(_formatDistance(dist), style: TextStyle(color: tc.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 12),
                                  Icon(Icons.directions_walk, size: 13, color: tc.accent),
                                  const SizedBox(width: 4),
                                  Text('~${_walkingMinutes(dist)} min walk', style: TextStyle(color: tc.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close_rounded), color: tc.textMuted, iconSize: 20, onPressed: _clearNavigation),
                      ],
                    ),
                  ),
                // Quick-navigate chips
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Navigate', style: TextStyle(color: tc.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 10, runSpacing: 10, children: _getLandmarks(tc).map((lm) => _navChip(tc, lm)).toList()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard(Tc tc, _BusRoute bus) {
    final etaLabel = _busEtaLabel(bus);
    final isArriving = _busEtaSecs(bus) <= 30;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: bus.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)), child: Icon(bus.icon, color: bus.color, size: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(bus.name, style: TextStyle(color: tc.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(width: 8),
                    Container(width: 7, height: 7, decoration: BoxDecoration(color: isArriving ? AppColors.accentGreen : bus.color, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('Live', style: TextStyle(color: tc.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(bus.path, style: TextStyle(color: tc.textMuted, fontSize: 12)),
                const SizedBox(height: 3),
                Text(_busStatusDetail(bus), style: TextStyle(color: tc.textSecondary, fontSize: 11, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: isArriving ? AppColors.accentGreen.withValues(alpha: 0.15) : bus.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Text(etaLabel, style: TextStyle(color: isArriving ? AppColors.accentGreen : bus.color, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _navChip(Tc tc, _Landmark lm) {
    final isActive = _destination == lm;
    return GestureDetector(
      onTap: () => _navigate(lm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? lm.color.withValues(alpha: 0.18) : tc.glassWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? lm.color : lm.color.withValues(alpha: 0.3), width: isActive ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(lm.icon, size: 15, color: lm.color),
            const SizedBox(width: 6),
            Text(lm.name, style: TextStyle(color: isActive ? lm.color : tc.textPrimary, fontSize: 12, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
            if (isActive) ...[const SizedBox(width: 6), Icon(Icons.navigation_rounded, size: 13, color: lm.color)],
          ],
        ),
      ),
    );
  }

  Widget _mapFab({required IconData icon, required Color color, required String tooltip, required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

class _Landmark {
  final String name;
  final LatLng position;
  final IconData icon;
  final Color color;
  final String detail;
  const _Landmark(this.name, this.position, this.icon, this.color, {this.detail = ''});
}

class _BusRoute {
  final String name;
  final String path;
  final Color color;
  final IconData icon;
  final List<LatLng> waypoints;
  final int cycleSecs;
  final int offsetSecs;
  const _BusRoute({required this.name, required this.path, required this.color, required this.icon, required this.waypoints, required this.cycleSecs, required this.offsetSecs});
}
