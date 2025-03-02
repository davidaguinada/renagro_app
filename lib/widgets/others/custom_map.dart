import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EditableGoogleMap extends StatefulWidget {
  final double latitude;
  final double longitude;

  const EditableGoogleMap({super.key, required this.latitude, required this.longitude});

  @override
  EditableGoogleMapState createState() => EditableGoogleMapState();
}

class EditableGoogleMapState extends State<EditableGoogleMap> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  // ignore: unused_field
  LatLng? _lastPosition;

  @override
  void initState() {
    super.initState();
    // Initialize circles around specific coordinates
    _markers.add(
      Marker(
        markerId: const MarkerId("marker1"),
        position: LatLng(widget.latitude, widget.longitude), // Santo Domingo
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const ContinuousRectangleBorder(),
      actionsAlignment: MainAxisAlignment.center,
      content: SizedBox(
        width: 700,
        height: 500,
        child: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.latitude, widget.longitude),
            zoom: 8.0,
          ),
          markers: _markers,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        )
      ],
    );
  }
}
