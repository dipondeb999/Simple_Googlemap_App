import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController _googleMapController;
  bool _inProgress = false;
  Marker? _currentMarker;

  LatLng _currentPosition = const LatLng(24.530601652086695, 91.72512379949839);
  List<LatLng> _polylineCoordinates = [];

  @override
  void initState() {
    listenCurrentLocation();
    super.initState();
  }

  Future<void> listenCurrentLocation() async {
    final isGranted = await isLocationPermissionGranted();
    if (isGranted) {
      final isServiceEnable = await checkGPSServiceEnable();
      if (isServiceEnable) {
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            timeLimit: Duration(seconds: 10),
            accuracy: LocationAccuracy.bestForNavigation,
          ),
        ).listen((pos) {
          LatLng newLatLng = LatLng(pos.latitude, pos.longitude);

          _currentMarker = Marker(
            markerId: const MarkerId('current_location'),
            position: newLatLng,
            infoWindow: InfoWindow(
              title: 'My Current Location',
              snippet: 'Lat: ${pos.latitude}, Lng: ${pos.longitude}',
            ),
          );

          _polylineCoordinates.add(newLatLng);

          _currentPosition = newLatLng;
          setState(() {});

          _googleMapController.animateCamera(
            CameraUpdate.newLatLng(newLatLng),
          );
        });
      } else {
        Geolocator.openLocationSettings();
      }
    } else {
      final result = await requestLocationPermission();
      if (result) {
        getCurrentLocation();
      } else {
        Geolocator.openAppSettings();
      }
    }
  }

  Future<void> getCurrentLocation() async {
    final isGranted = await isLocationPermissionGranted();
    if (isGranted) {
      final isServiceEnable = await checkGPSServiceEnable();
      if (isServiceEnable) {
        _inProgress = true;
        setState(() {});

        Position pos = await Geolocator.getCurrentPosition();
        LatLng newLatLng = LatLng(pos.latitude, pos.longitude);

        _polylineCoordinates.add(newLatLng);

        _currentMarker = Marker(
            markerId: const MarkerId('current_location'),
          position: newLatLng,
          infoWindow: InfoWindow(
            title: 'My Current Location',
            snippet: 'Lat: ${pos.latitude}, Lng: ${pos.longitude}',
          ),
        );

        _currentPosition = newLatLng;
        _inProgress = false;
        setState(() {});

        _googleMapController.animateCamera(
            CameraUpdate.newLatLng(newLatLng),
        );
      } else {
        Geolocator.openLocationSettings();
      }
    } else {
      final result = await requestLocationPermission();
      if (result) {
        getCurrentLocation();
      } else {
        Geolocator.openAppSettings();
      }
    }
  }

  Future<bool> isLocationPermissionGranted() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> checkGPSServiceEnable() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blue,
        title: const Text(
          'Simple Google Map',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _inProgress
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 16,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _currentMarker != null ? {_currentMarker!} : {},
              polylines: <Polyline>{
                Polyline(
                  polylineId: const PolylineId('polyline_tracking'),
                  points: _polylineCoordinates,
                  color: Colors.blue,
                  width: 4,
                ),
              },
              onMapCreated: (GoogleMapController controller) {
                _googleMapController = controller;
              },
            ),
    );
  }
}
