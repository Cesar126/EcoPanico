import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/config/app_colors.dart';
import '../viewmodels/alert_viewmodel.dart';
import '../../domain/entities/alert_entity.dart';
import '../providers/repository_providers.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final LatLng _center = const LatLng(-2.1432, -79.9015); // Los Ceibos center
  
  // Set of markers and polylines for the real Google Maps
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (mounted) {
          setState(() {
            _currentPosition = pos;
          });
          _animateToCurrentPosition();
        }

        _positionSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
            });
            _animateToCurrentPosition();
          }
        });
      }
    } catch (_) {}
  }

  void _animateToCurrentPosition() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertState = ref.watch(alertViewModelProvider);
    final isMock = ref.watch(mockModeStateProvider);

    // If mock mode is active, we render our high-end vector InteractiveMockMap
    if (isMock) {
      return Scaffold(
        backgroundColor: const Color(0xff121212), // Premium dark theme map background
        appBar: AppBar(
          title: const Text('Mapa Sector Los Ceibos', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 1,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gps_fixed, color: AppColors.success, size: 14),
                  SizedBox(width: 6),
                  Text('GPS Demo', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        body: InteractiveMockMap(
          activeAlerts: alertState.activeAlerts,
          ownAlert: alertState.currentOwnAlert,
          onAttendAlert: (id) {
            ref.read(alertViewModelProvider.notifier).attendAlert(id);
          },
          onResolveAlert: (id) {
            ref.read(alertViewModelProvider.notifier).resolveAlert(id);
          },
        ),
      );
    }

    // Otherwise, render standard Google Maps
    _updateGoogleMapMarkersAndRoutes(alertState);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Comunitario (Live)'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              _animateToCurrentPosition();
            },
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : _center,
              zoom: 15.5,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),
          if (alertState.activeAlerts.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: AppColors.alert),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hay ${alertState.activeAlerts.length} emergencia(s) activa(s). Rutas de respuesta trazadas.',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _updateGoogleMapMarkersAndRoutes(AlertState state) {
    _markers.clear();
    _polylines.clear();

    final userLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _center;

    // Draw markers for alerts
    for (final alert in state.activeAlerts) {
      final isRobbery = alert.type == 'robo';
      final isShake = alert.type == 'shake_emergencia';
      
      double markerHue = BitmapDescriptor.hueRed;
      if (alert.type == 'sospechoso') {
        markerHue = BitmapDescriptor.hueOrange;
      }

      _markers.add(
        Marker(
          markerId: MarkerId(alert.id),
          position: LatLng(alert.latitude, alert.longitude),
          infoWindow: InfoWindow(
            title: '${alert.type.toUpperCase()}: ${alert.neighborName}',
            snippet: 'Casa ${alert.neighborHouseNumber} • Estado: ${alert.status}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
        ),
      );

      // Draw polyline route from current user coordinate to the alert
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route_${alert.id}'),
          points: [
            userLatLng,
            LatLng(alert.latitude, alert.longitude),
          ],
          color: isRobbery || isShake ? AppColors.alert : AppColors.warning,
          width: 4,
          patterns: [PatternItem.dash(10), PatternItem.gap(10)],
        ),
      );
    }
  }
}

// INTERACTIVE MOCK MAP: Custom Vector Drawing
class InteractiveMockMap extends StatefulWidget {
  final List<AlertEntity> activeAlerts;
  final AlertEntity? ownAlert;
  final Function(String) onAttendAlert;
  final Function(String) onResolveAlert;

  const InteractiveMockMap({
    super.key,
    required this.activeAlerts,
    this.ownAlert,
    required this.onAttendAlert,
    required this.onResolveAlert,
  });

  @override
  State<InteractiveMockMap> createState() => _InteractiveMockMapState();
}

class _InteractiveMockMapState extends State<InteractiveMockMap> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  
  Offset _mapOffset = Offset.zero;
  double _zoomScale = 1.0;
  Offset? _dragStart;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        _dragStart = details.localFocalPoint;
      },
      onScaleUpdate: (details) {
        setState(() {
          if (details.scale == 1.0 && _dragStart != null) {
            _mapOffset += (details.localFocalPoint - _dragStart!);
            _dragStart = details.localFocalPoint;
          } else {
            _zoomScale = (details.scale).clamp(0.6, 2.5);
          }
        });
      },
      onScaleEnd: (_) {
        _dragStart = null;
      },
      child: Stack(
        children: [
          // Background canvas drawing streets and markers
          Positioned.fill(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: MapVectorPainter(
                      offset: _mapOffset,
                      scale: _zoomScale,
                      pulseProgress: _pulseController.value,
                      activeAlerts: widget.activeAlerts,
                      ownAlert: widget.ownAlert,
                    ),
                  );
                },
              ),
            ),
          ),

          // Zoom control buttons
          Positioned(
            right: 20,
            bottom: 120,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: () => setState(() => _zoomScale = (_zoomScale + 0.2).clamp(0.6, 2.5)),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: () => setState(() => _zoomScale = (_zoomScale - 0.2).clamp(0.6, 2.5)),
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // Cards for active alerts overlay (allows user to attend/resolve them directly from map)
          if (widget.activeAlerts.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              height: 120,
              child: PageView.builder(
                itemCount: widget.activeAlerts.length,
                itemBuilder: (context, idx) {
                  final alert = widget.activeAlerts[idx];
                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: alert.isCritical ? AppColors.alert : AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              alert.type == 'robo'
                                  ? Icons.campaign
                                  : alert.type == 'sospechoso'
                                      ? Icons.visibility
                                      : Icons.screen_rotation,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  alert.type == 'robo'
                                      ? '🚨 ROBO EN CURSO'
                                      : alert.type == 'sospechoso'
                                          ? '⚠️ ACTIVIDAD SOSPECHOSA'
                                          : '🚨 EMERGENCIA AGITACIÓN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: alert.isCritical ? AppColors.alert : AppColors.warning,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Vecino: ${alert.neighborName} (${alert.neighborHouseNumber})',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  if (alert.status == 'activa') {
                                    widget.onAttendAlert(alert.id);
                                  } else {
                                    widget.onResolveAlert(alert.id);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: alert.status == 'activa' ? AppColors.primary : AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(alert.status == 'activa' ? 'ATENDER' : 'RESOLVER', style: const TextStyle(fontSize: 11)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class MapVectorPainter extends CustomPainter {
  final Offset offset;
  final double scale;
  final double pulseProgress;
  final List<AlertEntity> activeAlerts;
  final AlertEntity? ownAlert;

  MapVectorPainter({
    required this.offset,
    required this.scale,
    required this.pulseProgress,
    required this.activeAlerts,
    this.ownAlert,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerPoint = Offset(size.width / 2, size.height / 2);
    final drawOffset = centerPoint + offset;

    // 1. Draw grid background (mock dark radar map look)
    final bgPaint = Paint()..color = const Color(0xff1c1c1e);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw radar background circles
    final radarPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (double r = 100; r < 600; r += 100) {
      canvas.drawCircle(drawOffset, r * scale, radarPaint);
    }

    // 2. Draw mock streets (Los Ceibos grid mockup)
    final streetPaint = Paint()
      ..color = const Color(0xff2c2c2e)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0 * scale
      ..strokeCap = StrokeCap.round;

    final double l = 300 * scale;
    // Horizontal streets
    canvas.drawLine(drawOffset + Offset(-l, -l/2), drawOffset + Offset(l, -l/2), streetPaint);
    canvas.drawLine(drawOffset + Offset(-l, 0), drawOffset + Offset(l, 0), streetPaint);
    canvas.drawLine(drawOffset + Offset(-l, l/2), drawOffset + Offset(l, l/2), streetPaint);

    // Vertical streets
    canvas.drawLine(drawOffset + Offset(-l/2, -l), drawOffset + Offset(-l/2, l), streetPaint);
    canvas.drawLine(drawOffset + Offset(0, -l), drawOffset + Offset(0, l), streetPaint);
    canvas.drawLine(drawOffset + Offset(l/2, -l), drawOffset + Offset(l/2, l), streetPaint);

    // Diagonal arterial roads
    canvas.drawLine(drawOffset + Offset(-l, -l), drawOffset + Offset(l, l), streetPaint);

    // Street text names
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 3. Draw User position (pulsating blue dot in center of map)
    final userPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    
    // Pulse effect
    final userPulsePaint = Paint()
      ..color = AppColors.primary.withOpacity((1.0 - pulseProgress).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(drawOffset, 20 * scale * pulseProgress, userPulsePaint);
    canvas.drawCircle(drawOffset, 8 * scale, userPaint);

    // User tag
    textPainter.text = TextSpan(
      text: 'Tú (Casa)',
      style: TextStyle(color: Colors.white, fontSize: 10 * scale, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, drawOffset + Offset(-textPainter.width / 2, 12 * scale));

    // 4. Draw Alerts and response routes
    for (final alert in activeAlerts) {
      // Map alert coordinates to local offset (mock scaling around center)
      // Since it's mock, we map lat/lng differences from _center to pixels
      final double dx = (alert.longitude - (-79.9015)) * 12000 * scale;
      final double dy = -(alert.latitude - (-2.1432)) * 12000 * scale; // invert Y for latitude
      
      final alertOffset = drawOffset + Offset(dx, dy);

      // Draw route line from User to Alert
      final routePaint = Paint()
        ..color = alert.isCritical ? AppColors.alert : AppColors.warning
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * scale;

      // Dashed path line
      final double distance = (alertOffset - drawOffset).distance;
      final Offset direction = (alertOffset - drawOffset) / (distance == 0 ? 1 : distance);
      for (double d = 0; d < distance; d += 15) {
        if (d + 8 < distance) {
          canvas.drawLine(
            drawOffset + direction * d,
            drawOffset + direction * (d + 8),
            routePaint,
          );
        }
      }

      // Draw Alert glowing marker
      final alertColor = alert.isCritical ? AppColors.alert : AppColors.warning;
      
      // Pulse glow for shake emergencies (flashing)
      if (alert.type == 'shake_emergencia') {
        final shakePulsePaint = Paint()
          ..color = AppColors.alert.withOpacity(0.5 * (1.0 - pulseProgress))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(alertOffset, 32 * scale * pulseProgress, shakePulsePaint);
      }

      final markerPaint = Paint()
        ..color = alertColor
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(alertOffset, 12 * scale, markerPaint);
      
      // Pin icon mock (white inner circle)
      final innerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(alertOffset, 5 * scale, innerPaint);

      // Label text
      final label = alert.type == 'robo'
          ? '🚨 ROBO'
          : alert.type == 'sospechoso'
              ? '⚠️ SOSPECHOSO'
              : '⚡ AGITACIÓN';
      
      textPainter.text = TextSpan(
        text: '$label\n(${alert.neighborName})',
        style: TextStyle(
          color: alertColor,
          fontSize: 9 * scale,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black.withOpacity(0.6),
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, alertOffset + Offset(-textPainter.width / 2, -26 * scale));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
