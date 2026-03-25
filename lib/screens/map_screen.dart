import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;

  // ── Pondicherry University coordinates ──
  static const double _centerLat = 12.0180;
  static const double _centerLng = 79.8555;
  static final LatLng _campusCenter = LatLng(_centerLat, _centerLng);

  // ── Current user / origin location (campus entrance) ──
  static final LatLng _myLocation = LatLng(12.0098, 79.8545);

  // ── Bounding box ──
  static final LatLngBounds _campusBounds = LatLngBounds(
    LatLng(12.007, 79.840),
    LatLng(12.035, 79.872),
  );

  // ── Navigation state ──
  _Landmark? _destination;
  bool _isNavigating = false;

  // ── Campus landmarks ──
  static final List<_Landmark> _landmarks = [
    _Landmark('Library', LatLng(12.0155, 79.8565), Icons.local_library,
        AppColors.accentTeal,
        detail: 'Central Library · 8 AM – 8 PM'),
    _Landmark('Cafeteria', LatLng(12.0140, 79.8590), Icons.restaurant,
        AppColors.accentOrange,
        detail: 'Main Cafeteria · 7 AM – 10 PM'),
    _Landmark('Sports Complex', LatLng(12.0120, 79.8555), Icons.sports_soccer,
        AppColors.accentGreen,
        detail: 'Indoor & Outdoor · 6 AM – 9 PM'),
    _Landmark('Admin Block', LatLng(12.0170, 79.8575), Icons.business,
        AppColors.accentPurple,
        detail: 'Administration · 9 AM – 5 PM'),
    _Landmark('Main Gate', LatLng(12.0098, 79.8545), Icons.door_front_door,
        AppColors.accentPink,
        detail: 'Main Entrance · Open 24 h'),
    _Landmark(
        'Hostels', LatLng(12.0210, 79.8530), Icons.hotel, AppColors.accentCyan,
        detail: 'Residential Blocks A–F'),
    _Landmark('Silver Jubilee', LatLng(12.0080, 79.8520), Icons.account_balance,
        AppColors.accentOrange,
        detail: 'Convention Hall · Events'),
    _Landmark('Stadium', LatLng(12.0115, 79.8500), Icons.stadium,
        AppColors.accentGreen,
        detail: 'Athletic Ground · 5 AM – 10 PM'),
    _Landmark('Gate 2', LatLng(12.0075, 79.8505), Icons.door_sliding,
        AppColors.accentRed,
        detail: 'Secondary Entrance'),
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ── Haversine distance in metres ──
  double _distanceMetres(LatLng a, LatLng b) {
    const r = 6371000.0;
    final lat1 = a.latitudeInRad;
    final lat2 = b.latitudeInRad;
    final dLat = (b.latitude - a.latitude) * (math.pi / 180);
    final dLng = (b.longitude - a.longitude) * (math.pi / 180);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  String _formatDistance(double m) =>
      m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.round()} m';

  int _walkingMinutes(double m) => math.max(1, (m / 80).round());

  void _navigate(_Landmark lm) {
    setState(() {
      _destination = lm;
      _isNavigating = true;
    });
    _mapController.move(lm.position, 17.0);
  }

  void _clearNavigation() {
    setState(() {
      _destination = null;
      _isNavigating = false;
    });
    _mapController.move(_campusCenter, 15.0);
  }

  // ── Build intermediate waypoints for a smooth route line ──
  List<LatLng> _buildRoute(LatLng from, LatLng to) {
    final pts = <LatLng>[from];
    const steps = 10;
    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      pts.add(LatLng(
        from.latitude + (to.latitude - from.latitude) * t,
        from.longitude + (to.longitude - from.longitude) * t,
      ));
    }
    pts.add(to);
    return pts;
  }

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    final dest = _destination;
    final dist =
        dest != null ? _distanceMetres(_myLocation, dest.position) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Campus Map', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('Satellite view with navigation',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Bus Tracking'),
          const SizedBox(height: 14),
          _buildBusCard(tc, 'Route A', 'Main Gate → Library → Hostel',
              'Arriving in 5 min', AppColors.accentTeal),
          const SizedBox(height: 12),
          _buildBusCard(tc, 'Route B', 'Hostel → Cafeteria → Sports Complex',
              'Arriving in 12 min', AppColors.accentPurple),
          const SizedBox(height: 12),
          _buildBusCard(tc, 'Route C', 'Academic Block → Lab → Main Gate',
              'In Transit', AppColors.accentOrange),
          const SizedBox(height: 28),
          const SectionHeader(title: 'University Map'),
          const SizedBox(height: 14),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // ── Satellite Map ──
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: SizedBox(
                    height: 380,
                    width: double.infinity,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _campusCenter,
                        initialZoom: 15.0,
                        minZoom: 14,
                        maxZoom: 19,
                        cameraConstraint:
                            CameraConstraint.contain(bounds: _campusBounds),
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        // Base: Esri World Imagery (satellite)
                        TileLayer(
                          urlTemplate:
                              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                          userAgentPackageName: 'com.punova.app',
                          maxZoom: 19,
                        ),
                        // Overlay: Esri building labels & boundaries
                        TileLayer(
                          urlTemplate:
                              'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                          userAgentPackageName: 'com.punova.app',
                          maxZoom: 19,
                        ),
                        // Route polyline
                        if (_isNavigating && dest != null)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _buildRoute(_myLocation, dest.position),
                                strokeWidth: 4.0,
                                color: AppColors.accentTeal,
                                pattern: StrokePattern.dashed(
                                    segments: const [12, 6]),
                              ),
                            ],
                          ),
                        // Markers
                        MarkerLayer(
                          markers: [
                            // My location marker
                            Marker(
                              point: _myLocation,
                              width: 36,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.accentTeal,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accentTeal
                                          .withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.my_location,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                            // Landmark markers
                            ..._landmarks.map((lm) => Marker(
                                  point: lm.position,
                                  width: 120,
                                  height: 58,
                                  child: GestureDetector(
                                    onTap: () => _navigate(lm),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _destination == lm
                                                ? lm.color
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(7),
                                            border: Border.all(
                                              color: lm.color,
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 5,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            lm.name,
                                            style: TextStyle(
                                              color: _destination == lm
                                                  ? Colors.white
                                                  : lm.color,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(Icons.location_on,
                                            color: lm.color, size: 24),
                                      ],
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Navigation info panel ──
                if (_isNavigating && dest != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.accentTeal.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: dest.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(dest.icon, color: dest.color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Navigating to ${dest.name}',
                                style: TextStyle(
                                  color: tc.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                dest.detail,
                                style: TextStyle(
                                    color: tc.textMuted, fontSize: 11),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(Icons.straighten,
                                      size: 13, color: AppColors.accentTeal),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDistance(dist),
                                    style: TextStyle(
                                      color: AppColors.accentTeal,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.directions_walk,
                                      size: 13, color: AppColors.accentTeal),
                                  const SizedBox(width: 4),
                                  Text(
                                    '~${_walkingMinutes(dist)} min walk',
                                    style: TextStyle(
                                      color: AppColors.accentTeal,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          color: tc.textMuted,
                          iconSize: 20,
                          onPressed: _clearNavigation,
                        ),
                      ],
                    ),
                  ),

                // ── Quick-navigate chips ──
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Navigate',
                          style: TextStyle(
                              color: tc.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            _landmarks.map((lm) => _navChip(tc, lm)).toList(),
                      ),
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

  Widget _buildBusCard(
      Tc tc, String route, String path, String status, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.directions_bus_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route,
                    style: TextStyle(
                        color: tc.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text(path, style: TextStyle(color: tc.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Text(status,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
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
          border: Border.all(
            color: isActive ? lm.color : lm.color.withValues(alpha: 0.3),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(lm.icon, size: 15, color: lm.color),
            const SizedBox(width: 6),
            Text(
              lm.name,
              style: TextStyle(
                color: isActive ? lm.color : tc.textPrimary,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Icon(Icons.navigation_rounded, size: 13, color: lm.color),
            ],
          ],
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

  const _Landmark(this.name, this.position, this.icon, this.color,
      {this.detail = ''});
}
