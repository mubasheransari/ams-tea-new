import 'package:flutter/material.dart';
import 'package:new_amst_flutter/Data/distance_utils.dart';
import 'package:new_amst_flutter/Model/super_journeyplan_model.dart';




// lib/screens/journey_plan_map_screen.dart

import 'dart:ui';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

const kText = Color(0xFF1E1E1E);
const kMuted = Color(0xFF707883);
const kShadow = Color(0x14000000);

const _kGrad = LinearGradient(
  colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/* --------------------------- Helper Class --------------------------- */

class _JourneyWithDistance {
  final JourneyPlanSupervisor supervisor;
  final double distanceKm;

  _JourneyWithDistance({
    required this.supervisor,
    required this.distanceKm,
  });
}

/* --------------------------- Main Screen --------------------------- */

class JourneyPlanMapScreen extends StatefulWidget {
  const JourneyPlanMapScreen({super.key});

  @override
  State<JourneyPlanMapScreen> createState() => _JourneyPlanMapScreenState();
}

class _JourneyPlanMapScreenState extends State<JourneyPlanMapScreen> {
  Position? _currentPos;
  String? _error;
  bool _loading = true;

  late List<JourneyPlanSupervisor> _all;
  List<_JourneyWithDistance> _items = [];

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  int get _totalLocations => _all.length;
  int get _completedLocations =>
      _all.where((jp) => jp.isVisited == true).length;

  @override
  void initState() {
    super.initState();
    _all = List<JourneyPlanSupervisor>.from(kJourneyPlan);
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Location services are disabled.';
          _loading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission denied.';
          _loading = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPos = pos;
      _computeDistancesAndMarkers();
    } catch (e) {
      setState(() {
        _error = 'Failed to get location: $e';
        _loading = false;
      });
    }
  }

  void _computeDistancesAndMarkers() {
    if (_currentPos == null) {
      setState(() {
        _error = 'Current location unavailable.';
        _loading = false;
      });
      return;
    }

    final lat1 = _currentPos!.latitude;
    final lon1 = _currentPos!.longitude;

    _items = _all
        .map(
          (jp) => _JourneyWithDistance(
            supervisor: jp,
            distanceKm: distanceInKm(lat1, lon1, jp.lat, jp.lng),
          ),
        )
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    _buildMarkers();

    setState(() {
      _loading = false;
      _error = null;
    });

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(lat1, lon1),
            zoom: 12.5,
          ),
        ),
      );
    }
  }

  void _buildMarkers() {
    final markers = <Marker>{};

    // Current location marker
    if (_currentPos != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPos!.latitude, _currentPos!.longitude),
          infoWindow: const InfoWindow(title: 'You are here'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    // Journey plan markers
    for (final item in _items) {
      final jp = item.supervisor;
      markers.add(
        Marker(
          markerId: MarkerId(jp.name),
          position: LatLng(jp.lat, jp.lng),
          infoWindow: InfoWindow(
            title: jp.name,
            snippet: '${item.distanceKm.toStringAsFixed(1)} km away',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            jp.isVisited ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(markers);
    });
  }

  void _onToggleVisited(_JourneyWithDistance item) {
    setState(() {
      item.supervisor.isVisited = !item.supervisor.isVisited;
    });
    _buildMarkers(); // this also triggers marker color change
  }

  /* --------------------------- RECENTER BUTTON --------------------------- */

  Future<void> _recenterOnUser() async {
    if (_mapController == null) return;

    // If no location yet, try to fetch again
    if (_currentPos == null) {
      setState(() => _loading = true);
      await _initLocation();
      setState(() => _loading = false);
      if (_currentPos == null) return;
    }

    final target = LatLng(
      _currentPos!.latitude,
      _currentPos!.longitude,
    );

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: 15.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _currentPos != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: _kGrad,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Map
              Positioned.fill(
                child: hasLocation
                    ? GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            _currentPos!.latitude,
                            _currentPos!.longitude,
                          ),
                          zoom: 12.0,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled:
                            false, // we use our own recenter button
                        compassEnabled: true,
                        markers: _markers,
                        onMapCreated: (c) {
                          _mapController = c;
                        },
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
              ),

              // Top dark gradient overlay
              Container(
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Header with stats + recenter button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // If you want a back button, uncomment this:
                    // IconButton(
                    //   icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    //       color: Colors.white),
                    //   onPressed: () => Navigator.pop(context),
                    // ),
                    // const SizedBox(width: 4),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Journey Plan Map',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'ClashGrotesk',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total: $_totalLocations  •  Done: $_completedLocations',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'ClashGrotesk',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Padding(
                      padding:  EdgeInsets.only(top: MediaQuery.of(context).size.height *0.16),
                      child: IconButton(
                        icon: const Icon(
                          Icons.my_location_rounded,
                          color: Colors.black,
                          size: 32,
                        ),
                        tooltip: 'Re-center on my location',
                        onPressed: _recenterOnUser,
                      ),
                    ),
                  ],
                ),
              ),

              // Error overlay
              if (!_loading && _error != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'ClashGrotesk',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Glass bottom sheet with list
              if (!_loading && _error == null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 260),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.35),
                              width: 1.3,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sheet header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 10, 16, 4),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Nearby Outlets',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        fontFamily: 'ClashGrotesk',
                                      ),
                                    ),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${_items.length} stops',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'ClashGrotesk',
                                          ),
                                        ),
                                        Text(
                                          'Done: $_completedLocations',
                                          style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: 'ClashGrotesk',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                      12, 4, 12, 12),
                                  itemCount: _items.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (_, i) {
                                    final item = _items[i];
                                    return _GlassJourneyCard(
                                      index: i + 1,
                                      data: item,
                                      onTap: () {
                                        _mapController?.animateCamera(
                                          CameraUpdate.newCameraPosition(
                                            CameraPosition(
                                              target: LatLng(
                                                item.supervisor.lat,
                                                item.supervisor.lng,
                                              ),
                                              zoom: 15.5,
                                            ),
                                          ),
                                        );
                                      },
                                      onToggleVisited: () =>
                                          _onToggleVisited(item),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* --------------------------- Glass Card Row --------------------------- */

class _GlassJourneyCard extends StatelessWidget {
  const _GlassJourneyCard({
    required this.index,
    required this.data,
    required this.onTap,
    required this.onToggleVisited,
  });

  final int index;
  final _JourneyWithDistance data;
  final VoidCallback onTap;
  final VoidCallback onToggleVisited;

  @override
  Widget build(BuildContext context) {
    final jp = data.supervisor;
    final distText = '${data.distanceKm.toStringAsFixed(1)} km';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black.withOpacity(0.5),
            width: 0.9,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // index badge
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFECFEFF)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'ClashGrotesk',
                    color: kText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // name + distance
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jp.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'ClashGrotesk',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        distText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'ClashGrotesk',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // visited chip
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onToggleVisited,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: jp.isVisited
                      ? Colors.greenAccent.withOpacity(0.18)
                      : Colors.orangeAccent.withOpacity(0.18),
                  border: Border.all(
                    color: jp.isVisited
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      jp.isVisited
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: jp.isVisited
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      jp.isVisited ? 'Visited' : 'Pending',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'ClashGrotesk',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}





/*
const kText = Color(0xFF1E1E1E);
const kMuted = Color(0xFF707883);
const kShadow = Color(0x14000000);

const _kGrad = LinearGradient(
  colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/* --------------------------- Helper Class --------------------------- */

class _JourneyWithDistance {
  final JourneyPlanSupervisor supervisor;
  final double distanceKm;

  _JourneyWithDistance({
    required this.supervisor,
    required this.distanceKm,
  });
}

/* --------------------------- Main Screen --------------------------- */

class JourneyPlanMapScreen extends StatefulWidget {
  const JourneyPlanMapScreen({super.key});

  @override
  State<JourneyPlanMapScreen> createState() => _JourneyPlanMapScreenState();
}

class _JourneyPlanMapScreenState extends State<JourneyPlanMapScreen> {
  Position? _currentPos;
  String? _error;
  bool _loading = true;

  late List<JourneyPlanSupervisor> _all;
  List<_JourneyWithDistance> _items = [];

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _all = List<JourneyPlanSupervisor>.from(kJourneyPlan);
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Location services are disabled.';
          _loading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission denied.';
          _loading = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPos = pos;
      _computeDistancesAndMarkers();
    } catch (e) {
      setState(() {
        _error = 'Failed to get location: $e';
        _loading = false;
      });
    }
  }

  void _computeDistancesAndMarkers() {
    if (_currentPos == null) {
      setState(() {
        _error = 'Current location unavailable.';
        _loading = false;
      });
      return;
    }

    final lat1 = _currentPos!.latitude;
    final lon1 = _currentPos!.longitude;

    _items = _all
        .map(
          (jp) => _JourneyWithDistance(
            supervisor: jp,
            distanceKm: distanceInKm(lat1, lon1, jp.lat, jp.lng),
          ),
        )
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    _buildMarkers();

    setState(() {
      _loading = false;
      _error = null;
    });

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(lat1, lon1),
            zoom: 12.5,
          ),
        ),
      );
    }
  }

  void _buildMarkers() {
    final markers = <Marker>{};

    // Current location marker
    if (_currentPos != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPos!.latitude, _currentPos!.longitude),
          infoWindow: const InfoWindow(title: 'You are here'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    // Journey plan markers
    for (final item in _items) {
      final jp = item.supervisor;
      markers.add(
        Marker(
          markerId: MarkerId(jp.name),
          position: LatLng(jp.lat, jp.lng),
          infoWindow: InfoWindow(
            title: jp.name,
            snippet: '${item.distanceKm.toStringAsFixed(1)} km away',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            jp.isVisited ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(markers);
    });
  }

  void _onToggleVisited(_JourneyWithDistance item) {
    setState(() {
      item.supervisor.isVisited = !item.supervisor.isVisited;
    });
    _buildMarkers();
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _currentPos != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: _kGrad,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Map
              Positioned.fill(
                child: hasLocation
                    ? GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            _currentPos!.latitude,
                            _currentPos!.longitude,
                          ),
                          zoom: 12.0,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        compassEnabled: true,
                        markers: _markers,
                        onMapCreated: (c) {
                          _mapController = c;
                        },
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
              ),

              Container(
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // IconButton(
                    //   icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    //       color: Colors.white),
                    //   onPressed: () => Navigator.pop(context),
                    // ),//i want to total locations to be visited and location done to be shown in view and recenter button to be worked of google map
              //      const SizedBox(width: 4,height: 10,),
                    Padding(
                      padding: const EdgeInsets.only(top:8.0,left: 10),
                      child: const Text(
                        'Journey Plan Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'ClashGrotesk',
                        ),
                      ),
                    ),
               //     const Spacer(),
                    // if (hasLocation)
                    //   const Icon(Icons.my_location_rounded,
                    //       color: Colors.white70, size: 20),
                  ],
                ),
              ),

              // Error overlay
              if (!_loading && _error != null)
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'ClashGrotesk',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Glass bottom sheet with list
              if (!_loading && _error == null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 260),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.35),
                              width: 1.3,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sheet header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 10, 16, 4),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Nearby Outlets',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        fontFamily: 'ClashGrotesk',
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_items.length} stops',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'ClashGrotesk',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                      12, 4, 12, 12),
                                  itemCount: _items.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (_, i) {
                                    final item = _items[i];
                                    return _GlassJourneyCard(
                                      index: i + 1,
                                      data: item,
                                      onTap: () {
                                        _mapController?.animateCamera(
                                          CameraUpdate.newCameraPosition(
                                            CameraPosition(
                                              target: LatLng(
                                                item.supervisor.lat,
                                                item.supervisor.lng,
                                              ),
                                              zoom: 15.5,
                                            ),
                                          ),
                                        );
                                      },
                                      onToggleVisited: () =>
                                          _onToggleVisited(item),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* --------------------------- Glass Card Row --------------------------- */

class _GlassJourneyCard extends StatelessWidget {
  const _GlassJourneyCard({
    required this.index,
    required this.data,
    required this.onTap,
    required this.onToggleVisited,
  });

  final int index;
  final _JourneyWithDistance data;
  final VoidCallback onTap;
  final VoidCallback onToggleVisited;

  @override
  Widget build(BuildContext context) {
    final jp = data.supervisor;
    final distText = '${data.distanceKm.toStringAsFixed(1)} km';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 0.9,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // index badge
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFECFEFF)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'ClashGrotesk',
                    color: kText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // name + distance
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jp.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'ClashGrotesk',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        distText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'ClashGrotesk',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // visited chip
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onToggleVisited,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: jp.isVisited
                      ? Colors.greenAccent.withOpacity(0.18)
                      : Colors.orangeAccent.withOpacity(0.18),
                  border: Border.all(
                    color: jp.isVisited
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      jp.isVisited
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: jp.isVisited
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      jp.isVisited ? 'Visited' : 'Pending',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'ClashGrotesk',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


*/



// const kText = Color(0xFF1E1E1E);
// const kMuted = Color(0xFF707883);
// const kField = Color(0xFFF2F3F5);
// const kCard = Colors.white;
// const kShadow = Color(0x14000000);

// const _kGrad = LinearGradient(
//   colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
//   begin: Alignment.centerLeft,
//   end: Alignment.centerRight,
// );

// const _kCardDeco = BoxDecoration(
//   color: Colors.white,
//   borderRadius: BorderRadius.all(Radius.circular(16)),
//   boxShadow: [
//     BoxShadow(
//       color: Colors.black12,
//       blurRadius: 12,
//       offset: Offset(0, 6),
//     ),
//   ],
// );


// class JourneyPlanSupervisorScreen extends StatefulWidget {
//   const JourneyPlanSupervisorScreen({super.key});

//   @override
//   State<JourneyPlanSupervisorScreen> createState() =>
//       _JourneyPlanSupervisorScreenState();
// }

// class _JourneyPlanSupervisorScreenState
//     extends State<JourneyPlanSupervisorScreen> {
//   final _search = TextEditingController();
//   late List<JourneyPlanSupervisor> _all;

//   @override
//   void initState() {
//     super.initState();
//     _all = List<JourneyPlanSupervisor>.from(kJourneyPlan);
//   }

//   @override
//   void dispose() {
//     _search.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final q = _search.text.trim().toLowerCase();

//     final filtered = _all.where((e) {
//       if (q.isEmpty) return true;
//       return e.name.toLowerCase().contains(q);
//     }).toList();

//     final visitedCount = _all.where((e) => e.isVisited).length;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF2F3F5),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: kText),
//         title: const Text(
//           'Journey Plan',
//           style: TextStyle(
//             color: kText,
//             fontWeight: FontWeight.w700,
//             fontFamily: 'ClashGrotesk',
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Search bar
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
//               child: Container(
//                 height: 52,
//                 decoration: _kCardDeco.copyWith(
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: const Color(0xFFEDEFF2)),
//                 ),
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.search_rounded, color: Colors.black54),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: TextField(
//                         controller: _search,
//                         onChanged: (_) => setState(() {}),
//                         textInputAction: TextInputAction.search,
//                         decoration: const InputDecoration(
//                           hintText: 'Search outlet (e.g. Imtiaz, Naheed)',
//                           hintStyle: TextStyle(
//                             color: Colors.black54,
//                             fontFamily: 'ClashGrotesk',
//                           ),
//                           border: InputBorder.none,
//                           isCollapsed: true,
//                           contentPadding: EdgeInsets.only(top: 2),
//                         ),
//                         style: const TextStyle(
//                           color: Colors.black,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           height: 1.35,
//                           fontFamily: 'ClashGrotesk',
//                         ),
//                       ),
//                     ),
//                     if (_search.text.isNotEmpty)
//                       IconButton(
//                         icon: const Icon(
//                           Icons.close_rounded,
//                           color: Colors.black45,
//                         ),
//                         onPressed: () {
//                           _search.clear();
//                           setState(() {});
//                         },
//                       ),
//                   ],
//                 ),
//               ),
//             ),

//             // Counts row
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
//               child: Row(
//                 children: [
//                   Text(
//                     '${filtered.length} outlets',
//                     style: const TextStyle(
//                       color: kMuted,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       fontFamily: 'ClashGrotesk',
//                     ),
//                   ),
//                   const Spacer(),
//                   Text(
//                     'Visited: $visitedCount / ${_all.length}',
//                     style: const TextStyle(
//                       color: Color(0xFF7F53FD),
//                       fontWeight: FontWeight.w800,
//                       fontSize: 12,
//                       fontFamily: 'ClashGrotesk',
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // List
//             Expanded(
//               child: ListView.separated(
//                 padding: const EdgeInsets.fromLTRB(0, 6, 0, 16),
//                 itemCount: filtered.length,
//                 separatorBuilder: (_, __) => const SizedBox(height: 12),
//                 itemBuilder: (_, i) {
//                   final jp = filtered[i];
//                   return Center(
//                     child: FractionallySizedBox(
//                       widthFactor: 0.95,
//                       child: _JourneyPlanCard(
//                         supervisor: jp,
//                         onToggleVisited: () {
//                           setState(() {
//                             jp.isVisited = !jp.isVisited;
//                           });
//                         },
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


// class _JourneyPlanCard extends StatelessWidget {
//   const _JourneyPlanCard({
//     required this.supervisor,
//     required this.onToggleVisited,
//   });

//   final JourneyPlanSupervisor supervisor;
//   final VoidCallback onToggleVisited;

//   @override
//   Widget build(BuildContext context) {
//     final t = Theme.of(context).textTheme;

//     return Container(
//       decoration: const BoxDecoration(
//         gradient: _kGrad,
//         borderRadius: BorderRadius.all(Radius.circular(16)),
//       ),
//       child: Container(
//         margin: const EdgeInsets.all(1.6),
//         decoration: BoxDecoration(
//           color: kCard,
//           borderRadius: BorderRadius.circular(14.4),
//           boxShadow: const [
//             BoxShadow(
//               color: kShadow,
//               blurRadius: 14,
//               offset: Offset(0, 8),
//             ),
//           ],
//         ),
//         padding: const EdgeInsets.all(14),
//         child: Row(
//           children: [
//             // Left icon
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: const Color(0xFF7F53FD).withOpacity(.10),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Icon(
//                 Icons.store_mall_directory_rounded,
//                 color: Color(0xFF7F53FD),
//               ),
//             ),
//             const SizedBox(width: 12),

//             // Text
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     supervisor.name,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: t.titleMedium?.copyWith(
//                       color: kText,
//                       fontWeight: FontWeight.w700,
//                       fontFamily: 'ClashGrotesk',
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     children: [
//                       const Icon(Icons.location_on_rounded,
//                           size: 14, color: kMuted),
//                       const SizedBox(width: 4),
//                       Flexible(
//                         child: Text(
//                           '${supervisor.lat}, ${supervisor.lng}',
//                           style: t.bodySmall?.copyWith(
//                             color: kMuted,
//                             fontFamily: 'ClashGrotesk',
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(width: 8),

//             // Visited / Pending pill
//             InkWell(
//               borderRadius: BorderRadius.circular(999),
//               onTap: onToggleVisited,
//               child: Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(999),
//                   color: supervisor.isVisited
//                       ? const Color(0xFF22C55E).withOpacity(0.12)
//                       : const Color(0xFFF97316).withOpacity(0.12),
//                   border: Border.all(
//                     color: supervisor.isVisited
//                         ? const Color(0xFF22C55E)
//                         : const Color(0xFFF97316),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       supervisor.isVisited
//                           ? Icons.check_circle_rounded
//                           : Icons.radio_button_unchecked_rounded,
//                       size: 16,
//                       color: supervisor.isVisited
//                           ? const Color(0xFF22C55E)
//                           : const Color(0xFFF97316),
//                     ),
//                     const SizedBox(width: 6),
//                     Text(
//                       supervisor.isVisited ? 'Visited' : 'Pending',
//                       style: const TextStyle(
//                         fontSize: 11,
//                         fontWeight: FontWeight.w700,
//                         fontFamily: 'ClashGrotesk',
//                         color: kText,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
