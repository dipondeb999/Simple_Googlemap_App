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
  Marker? _initialMarker;
  Marker? _currentMarker;

  LatLng _currentPosition = const LatLng(24.530737579984187, 91.72509873853774);

  List<LatLng> _polylineCoordinates = [];

  @override
  void initState() {
    _setInitialMarker();
    listenCurrentLocation();
    super.initState();
  }

  Future<void> _setInitialMarker() async {
    _initialMarker = Marker(
      markerId: const MarkerId('initial_marker'),
      position: _currentPosition,
      infoWindow: const InfoWindow(
        title: 'Selected Location',
        snippet: 'Selected Point',
      ),
    );
    setState(() {});
  }

  Future<void> listenCurrentLocation() async {
    final isGranted = await isLocationPermissionGranted();
    if (isGranted) {
      final isServiceEnable = await checkGPSServiceEnable();
      if (isServiceEnable) {
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
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
          _updateCameraBounds();
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

  void _updateCameraBounds() {
    if (_initialMarker != null && _currentMarker != null) {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          _initialMarker!.position.latitude <= _currentMarker!.position.latitude
              ? _initialMarker!.position.latitude
              : _currentMarker!.position.latitude,
          _initialMarker!.position.longitude <= _currentMarker!.position.longitude
              ? _initialMarker!.position.longitude
              : _currentMarker!.position.longitude,
        ),
        northeast: LatLng(
          _initialMarker!.position.latitude > _currentMarker!.position.latitude
              ? _initialMarker!.position.latitude
              : _currentMarker!.position.latitude,
          _initialMarker!.position.longitude > _currentMarker!.position.longitude
              ? _initialMarker!.position.longitude
              : _currentMarker!.position.longitude,
        ),
      );

      _googleMapController.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  Future<void> getCurrentLocation() async {
    final isGranted = await isLocationPermissionGranted();
    if (isGranted) {
      final isServiceEnable = await checkGPSServiceEnable();
      if (isServiceEnable) {
        Position pos = await Geolocator.getCurrentPosition();
        LatLng newLatLng = LatLng(pos.latitude, pos.longitude);

        _polylineCoordinates.add(newLatLng);

        _currentMarker = Marker(
          markerId: const MarkerId('current_location'),
          position: newLatLng,
          infoWindow: InfoWindow(
            title: 'My current Location',
            snippet: 'Lat: ${pos.latitude}, Lng: ${pos.longitude}',
          ),
        );

        _currentPosition = newLatLng;
        setState(() {});
        _updateCameraBounds();
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
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
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
          'Tracking Map',
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
        markers: <Marker> {
          if (_initialMarker != null) _initialMarker!,
          if (_currentMarker != null) _currentMarker!,
        },
        polylines: <Polyline> {
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
