import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/itinerary_activity.dart';
import 'package:url_launcher/url_launcher.dart';

class ItineraryMapView extends StatefulWidget {
  final List<ItineraryActivity> activities;

  const ItineraryMapView({super.key, required this.activities});

  @override
  State<ItineraryMapView> createState() => _ItineraryMapViewState();
}

class _ItineraryMapViewState extends State<ItineraryMapView> {
  late final MapController _mapController;

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

  @override
  Widget build(BuildContext context) {
    // Filter activities that have valid coordinates
    final mapActivities = widget.activities.where((a) => a.latitude != null && a.longitude != null).toList();

    if (mapActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.map_outlined, color: Colors.white54, size: 48),
            SizedBox(height: 16),
            Text('No coordinate data available for this day.', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    final List<Marker> markers = [];
    final List<LatLng> points = [];

    for (int i = 0; i < mapActivities.length; i++) {
      final act = mapActivities[i];
      final point = LatLng(act.latitude!, act.longitude!);
      points.add(point);

      Color markerColor;
      IconData iconData;

      switch (act.category.toLowerCase()) {
        case 'food':
          markerColor = Colors.orange;
          iconData = Icons.restaurant;
          break;
        case 'stay':
          markerColor = Colors.blue;
          iconData = Icons.hotel;
          break;
        case 'transport':
          markerColor = Colors.yellow;
          iconData = Icons.directions_bus;
          break;
        default:
          markerColor = const Color(0xFFC77DFF);
          iconData = Icons.place;
      }

      markers.add(
        Marker(
          point: point,
          width: 40,
          height: 40,
          alignment: Alignment.topCenter, // Point of pin is exactly at coord
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(act.title),
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'Navigate',
                    onPressed: () {
                      if (act.googleMapsQuery != null) {
                        launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(act.googleMapsQuery!)}'));
                      }
                    },
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: markerColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Calculate bounds to fit all markers
    final bounds = LatLngBounds.fromPoints(points);
    final initialCenter = LatLng(
      (bounds.north + bounds.south) / 2,
      (bounds.east + bounds.west) / 2,
    );

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 13.0,
        initialCameraFit: CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(40.0),
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.solostep.app',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: points,
              strokeWidth: 3.0,
              color: const Color(0xFFC77DFF).withValues(alpha: 0.7),
              pattern: const StrokePattern.dotted(),
            ),
          ],
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
