import 'dart:io';
import 'package:flutter/material.dart';
import 'package:new_amst_flutter/Data/distance_utils.dart';
import 'package:new_amst_flutter/Model/super_journeyplan_model.dart';
import 'dart:ui';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';



const kText = Color(0xFF1E1E1E);
const kMuted = Color(0xFF707883);
const kShadow = Color(0x14000000);

const _kGrad = LinearGradient(
  colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// distance limit in meters to allow marking as visited
const double kVisitRadiusMeters = 13000;

// storage keys
const String _pendingVisitKey = 'pending_visit_v1';
const String _journeyDateKey = 'journey_date_v1';

String _visitedKeyFor(String date) => 'visited_$date';
String _endedKeyFor(String date) => 'journey_ended_$date';

String _dateKey(DateTime dt) {
  final y = dt.year.toString();
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

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

  final GetStorage _box = GetStorage();
  late String _todayKey;

  int get _totalLocations => _all.length;
  int get _completedLocations =>
      _all.where((jp) => jp.isVisited == true).length;

  @override
  void initState() {
    super.initState();
    _all = List<JourneyPlanSupervisor>.from(kJourneyPlan);
    _todayKey = _dateKey(DateTime.now());
    _restoreDayState();
    _initLocation().then((_) async {
      await _restorePendingPopup();
      _maybeShowJourneyEnded();
    });
  }

  /* --------------------------- Daily persistence --------------------------- */

  void _restoreDayState() {
    final lastDate = _box.read<String>(_journeyDateKey);
    if (lastDate != _todayKey) {
      // new day -> reset day-related data
      _box.write(_journeyDateKey, _todayKey);
      _box.remove(_pendingVisitKey);
      if (lastDate != null) {
        _box.remove(_visitedKeyFor(lastDate));
        _box.remove(_endedKeyFor(lastDate));
      }
      for (final jp in _all) {
        jp.isVisited = false;
      }
    } else {
      // same day -> restore visited list
      final raw = _box.read<List>(_visitedKeyFor(_todayKey)) ?? [];
      final visitedNames = raw.cast<String>();
      for (final jp in _all) {
        jp.isVisited = visitedNames.contains(jp.name);
      }
    }
  }

  /* --------------------------- Location & distance --------------------------- */

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

  /* ---------------------- Forced popup / visited flow ---------------------- */

  void _onToggleVisited(_JourneyWithDistance item) {
    // if today already ended, just show info
    final journeyEnded = _box.read<bool>(_endedKeyFor(_todayKey)) ?? false;
    if (journeyEnded) {
      _maybeShowJourneyEnded();
      return;
    }

    if (_currentPos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current location not available yet.'),
        ),
      );
      return;
    }

    final dKm = distanceInKm(
      _currentPos!.latitude,
      _currentPos!.longitude,
      item.supervisor.lat,
      item.supervisor.lng,
    );
    final dMeters = dKm * 1000;

    if (dMeters > kVisitRadiusMeters) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You must be at ${item.supervisor.name} (within '
            '${kVisitRadiusMeters.toStringAsFixed(0)} m).\n'
            'Current distance: ${dMeters.toStringAsFixed(0)} m',
          ),
        ),
      );
      return;
    }

    _startVisitFlow(item.supervisor);
  }

  void _startVisitFlow(JourneyPlanSupervisor jp) {
    _box.write(_pendingVisitKey, jp.name);
    _showVisitPopup(jp);
  }

  Future<void> _restorePendingPopup() async {
    final pendingName = _box.read<String>(_pendingVisitKey);
    if (pendingName == null) return;

    JourneyPlanSupervisor? jp;
    for (final s in _all) {
      if (s.name == pendingName) {
        jp = s;
        break;
      }
    }
    if (jp == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showVisitPopup(jp!);
    });
  }

  Future<void> _showVisitPopup(JourneyPlanSupervisor jp) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        XFile? pickedImage;
        final commentCtrl = TextEditingController();
        bool submitting = false;

        return WillPopScope(
          onWillPop: () async => false,
          child: StatefulBuilder(
            builder: (ctx, setState) {
              Future<void> _pickImage() async {
                final picker = ImagePicker();
                final img = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (img != null) {
                  setState(() => pickedImage = img);
                }
              }

              final canSubmit = pickedImage != null &&
                  commentCtrl.text.trim().isNotEmpty &&
                  !submitting;

              return AlertDialog(
                backgroundColor: Colors.white.withOpacity(0.95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                titlePadding:
                    const EdgeInsets.only(top: 16, left: 20, right: 20),
                contentPadding:
                    const EdgeInsets.fromLTRB(20, 8, 20, 16),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visit details',
                      style: TextStyle(
                        fontFamily: 'ClashGrotesk',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: kText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      jp.name,
                      style: const TextStyle(
                        fontFamily: 'ClashGrotesk',
                        fontSize: 13,
                        color: kMuted,
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                          color: Colors.grey.shade100,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: pickedImage == null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.camera_alt_rounded,
                                        size: 32, color: kMuted),
                                    SizedBox(height: 6),
                                    Text(
                                      'Capture outlet photo',
                                      style: TextStyle(
                                        fontFamily: 'ClashGrotesk',
                                        color: kMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Image.file(
                                File(pickedImage!.path),
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7F53FD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt_rounded,
                              size: 18, color: Colors.white),
                          label: const Text(
                            'Take Photo',
                            style: TextStyle(
                              fontFamily: 'ClashGrotesk',
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Comments',
                          style: const TextStyle(
                            fontFamily: 'ClashGrotesk',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: commentCtrl,
                        maxLines: 4,
                        minLines: 3,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText:
                              'Write 3–4 lines about display, stock, etc.',
                          hintStyle: const TextStyle(
                            fontFamily: 'ClashGrotesk',
                            fontSize: 12,
                            color: kMuted,
                          ),
                          fillColor: const Color(0xFFF2F3F5),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'ClashGrotesk',
                          fontSize: 13,
                          color: kText,
                        ),
                      ),
                    ],
                  ),
                ),
                actionsPadding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 12),
                actions: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C6FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: canSubmit
                          ? () async {
                              setState(() => submitting = true);
                              // TODO: send image + comment to API if needed
                              Navigator.of(ctx).pop(<String, dynamic>{
                                'imagePath': pickedImage!.path,
                                'comment': commentCtrl.text.trim(),
                              });
                            }
                          : null,
                      child: submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Submit',
                              style: TextStyle(
                                fontFamily: 'ClashGrotesk',
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (result != null) {
      _box.remove(_pendingVisitKey);
      _markVisitedPersist(jp);
    }
  }

  void _markVisitedPersist(JourneyPlanSupervisor jp) {
    setState(() {
      jp.isVisited = true;
    });

    final key = _visitedKeyFor(_todayKey);
    final raw = _box.read<List>(key) ?? [];
    final visited = raw.cast<String>();
    if (!visited.contains(jp.name)) {
      visited.add(jp.name);
    }
    _box.write(key, visited);

    _buildMarkers();

    if (_completedLocations == _totalLocations) {
      _box.write(_endedKeyFor(_todayKey), true);
      _maybeShowJourneyEnded();
    }
  }

  /* --------------------------- Journey ended popup --------------------------- */

  void _maybeShowJourneyEnded() {
    final ended = _box.read<bool>(_endedKeyFor(_todayKey)) ?? false;
    if (!ended) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showJourneyEndedDialog();
    });
  }

  Future<void> _showJourneyEndedDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Today's journey ended",
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: const Text(
              'You have visited all outlets planned for today.\n\n'
              'Please come back tomorrow to start a new journey.',
              style: TextStyle(
                fontFamily: 'ClashGrotesk',
                fontSize: 13,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontFamily: 'ClashGrotesk',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /* --------------------------- RECENTER BUTTON --------------------------- */

  Future<void> _recenterOnUser() async {
    if (_mapController == null) return;

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

  /* --------------------------- BUILD --------------------------- */

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
                        myLocationButtonEnabled: false,
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

              // header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Journey Plan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              //  fontFamily: 'ClashGrotesk',
                              ),
                            ),
                                   const Text(
                              '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              //  fontFamily: 'ClashGrotesk',
                              ),
                            ),
                           // const SizedBox(height: 2),
                            // Text(
                            //   'Total: $_totalLocations  •  Done: $_completedLocations',
                            //   style: const TextStyle(
                            //     color: Colors.white,
                            //     fontSize: 14,
                            //     fontWeight: FontWeight.w900,
                            //   //  fontFamily: 'ClashGrotesk',
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                    // Padding(
                    //   padding: EdgeInsets.only(
                    //     top: MediaQuery.of(context).size.height * 0.16,
                    //   ),
                    //   child: IconButton(
                    //     icon: const Icon(
                    //       Icons.my_location_rounded,
                    //       color: Colors.black,
                    //       size: 32,
                    //     ),
                    //     tooltip: 'Re-center on my location',
                    //     onPressed: _recenterOnUser,
                    //   ),
                    // ),
                  ],
                ),
              ),

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


// const kText = Color(0xFF1E1E1E);
// const kMuted = Color(0xFF707883);
// const kShadow = Color(0x14000000);

// const _kGrad = LinearGradient(
//   colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
//   begin: Alignment.topLeft,
//   end: Alignment.bottomRight,
// );

// // user must be within this radius (meters) to mark visited
// const double kVisitRadiusMeters = 13000;
// // key to persist pending outlet
// const String _pendingVisitKey = 'pending_visit_v1';

// class _JourneyWithDistance {
//   final JourneyPlanSupervisor supervisor;
//   final double distanceKm;

//   _JourneyWithDistance({
//     required this.supervisor,
//     required this.distanceKm,
//   });
// }

// /* --------------------------- Main Screen --------------------------- */

// class JourneyPlanMapScreen extends StatefulWidget {
//   const JourneyPlanMapScreen({super.key});

//   @override
//   State<JourneyPlanMapScreen> createState() => _JourneyPlanMapScreenState();
// }

// class _JourneyPlanMapScreenState extends State<JourneyPlanMapScreen> {
//   Position? _currentPos;
//   String? _error;
//   bool _loading = true;

//   late List<JourneyPlanSupervisor> _all;
//   List<_JourneyWithDistance> _items = [];

//   GoogleMapController? _mapController;
//   final Set<Marker> _markers = {};

//   final GetStorage _box = GetStorage();

//   int get _totalLocations => _all.length;
//   int get _completedLocations =>
//       _all.where((jp) => jp.isVisited == true).length;

//   @override
//   void initState() {
//     super.initState();
//     _all = List<JourneyPlanSupervisor>.from(kJourneyPlan);
//     _initLocation().then((_) => _restorePendingPopup());
//   }

//   /* --------------------------- Location & distance --------------------------- */

//   Future<void> _initLocation() async {
//     try {
//       final serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         setState(() {
//           _error = 'Location services are disabled.';
//           _loading = false;
//         });
//         return;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }
//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         setState(() {
//           _error = 'Location permission denied.';
//           _loading = false;
//         });
//         return;
//       }

//       final pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       _currentPos = pos;
//       _computeDistancesAndMarkers();
//     } catch (e) {
//       setState(() {
//         _error = 'Failed to get location: $e';
//         _loading = false;
//       });
//     }
//   }

//   void _computeDistancesAndMarkers() {
//     if (_currentPos == null) {
//       setState(() {
//         _error = 'Current location unavailable.';
//         _loading = false;
//       });
//       return;
//     }

//     final lat1 = _currentPos!.latitude;
//     final lon1 = _currentPos!.longitude;

//     _items = _all
//         .map(
//           (jp) => _JourneyWithDistance(
//             supervisor: jp,
//             distanceKm: distanceInKm(lat1, lon1, jp.lat, jp.lng),
//           ),
//         )
//         .toList()
//       ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

//     _buildMarkers();

//     setState(() {
//       _loading = false;
//       _error = null;
//     });

//     if (_mapController != null) {
//       _mapController!.animateCamera(
//         CameraUpdate.newCameraPosition(
//           CameraPosition(
//             target: LatLng(lat1, lon1),
//             zoom: 12.5,
//           ),
//         ),
//       );
//     }
//   }

//   void _buildMarkers() {
//     final markers = <Marker>{};

//     if (_currentPos != null) {
//       markers.add(
//         Marker(
//           markerId: const MarkerId('current_location'),
//           position: LatLng(_currentPos!.latitude, _currentPos!.longitude),
//           infoWindow: const InfoWindow(title: 'You are here'),
//           icon: BitmapDescriptor.defaultMarkerWithHue(
//             BitmapDescriptor.hueAzure,
//           ),
//         ),
//       );
//     }

//     for (final item in _items) {
//       final jp = item.supervisor;
//       markers.add(
//         Marker(
//           markerId: MarkerId(jp.name),
//           position: LatLng(jp.lat, jp.lng),
//           infoWindow: InfoWindow(
//             title: jp.name,
//             snippet: '${item.distanceKm.toStringAsFixed(1)} km away',
//           ),
//           icon: BitmapDescriptor.defaultMarkerWithHue(
//             jp.isVisited ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
//           ),
//         ),
//       );
//     }

//     setState(() {
//       _markers
//         ..clear()
//         ..addAll(markers);
//     });
//   }

//   /* ---------------------- Forced popup / visited flow ---------------------- */

//   // When user taps "Visited" chip
//   void _onToggleVisited(_JourneyWithDistance item) {
//     if (_currentPos == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Current location not available yet.'),
//         ),
//       );
//       return;
//     }

//     final dKm = distanceInKm(
//       _currentPos!.latitude,
//       _currentPos!.longitude,
//       item.supervisor.lat,
//       item.supervisor.lng,
//     );
//     final dMeters = dKm * 1000;

//     if (dMeters > kVisitRadiusMeters) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'You must be at ${item.supervisor.name} (within '
//             '${kVisitRadiusMeters.toStringAsFixed(0)} m).\n'
//             'Current distance: ${dMeters.toStringAsFixed(0)} m',
//           ),
//         ),
//       );
//       return;
//     }

//     // inside radius -> start visit flow
//     _startVisitFlow(item.supervisor);
//   }

//   void _startVisitFlow(JourneyPlanSupervisor jp) {
//     // Persist which outlet is pending
//     _box.write(_pendingVisitKey, jp.name);
//     _showVisitPopup(jp);
//   }

//   Future<void> _restorePendingPopup() async {
//     final pendingName = _box.read<String>(_pendingVisitKey);
//     if (pendingName == null) return;

//     // find that outlet
//     JourneyPlanSupervisor? jp;
//     for (final s in _all) {
//       if (s.name == pendingName) {
//         jp = s;
//         break;
//       }
//     }
//     if (jp == null) return;

//     // show popup after first frame
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _showVisitPopup(jp!);
//     });
//   }

//   Future<void> _showVisitPopup(JourneyPlanSupervisor jp) async {
//     final result = await showDialog<Map<String, dynamic>?>(
//       context: context,
//       barrierDismissible: false, // can't tap outside to close
//       builder: (ctx) {
//         XFile? pickedImage;
//         final commentCtrl = TextEditingController();
//         bool submitting = false;

//         return WillPopScope(
//           onWillPop: () async => false, // disable Android back
//           child: StatefulBuilder(
//             builder: (ctx, setState) {
//               Future<void> _pickImage() async {
//                 final picker = ImagePicker();
//                 final img = await picker.pickImage(
//                   source: ImageSource.camera,
//                   imageQuality: 80,
//                 );
//                 if (img != null) {
//                   setState(() => pickedImage = img);
//                 }
//               }

//               final canSubmit = pickedImage != null &&
//                   commentCtrl.text.trim().isNotEmpty &&
//                   !submitting;

//               return AlertDialog(
//                 backgroundColor: Colors.white.withOpacity(0.95),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 titlePadding:
//                     const EdgeInsets.only(top: 16, left: 20, right: 20),
//                 contentPadding:
//                     const EdgeInsets.fromLTRB(20, 8, 20, 16),
//                 title: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Visit details',
//                       style: const TextStyle(
//                         fontFamily: 'ClashGrotesk',
//                         fontWeight: FontWeight.w700,
//                         fontSize: 18,
//                         color: kText,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       jp.name,
//                       style: const TextStyle(
//                         fontFamily: 'ClashGrotesk',
//                         fontSize: 13,
//                         color: kMuted,
//                       ),
//                     ),
//                   ],
//                 ),
//                 content: SingleChildScrollView(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // photo preview
//                       Container(
//                         height: 160,
//                         width: double.infinity,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(16),
//                           border: Border.all(
//                             color: Colors.grey.shade300,
//                           ),
//                           color: Colors.grey.shade100,
//                         ),
//                         clipBehavior: Clip.antiAlias,
//                         child: pickedImage == null
//                             ? Center(
//                                 child: Column(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: const [
//                                     Icon(Icons.camera_alt_rounded,
//                                         size: 32, color: kMuted),
//                                     SizedBox(height: 6),
//                                     Text(
//                                       'Capture outlet photo',
//                                       style: TextStyle(
//                                         fontFamily: 'ClashGrotesk',
//                                         color: kMuted,
//                                         fontSize: 12,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               )
//                             : Image.file(
//                                 File(pickedImage!.path),
//                                 fit: BoxFit.cover,
//                               ),
//                       ),
//                       const SizedBox(height: 12),
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton.icon(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF7F53FD),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(14),
//                             ),
//                           ),
//                           onPressed: _pickImage,
//                           icon: const Icon(Icons.camera_alt_rounded,
//                               size: 18, color: Colors.white),
//                           label: const Text(
//                             'Take Photo',
//                             style: TextStyle(
//                               fontFamily: 'ClashGrotesk',
//                               color: Colors.white,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Text(
//                           'Comments',
//                           style: const TextStyle(
//                             fontFamily: 'ClashGrotesk',
//                             fontSize: 13,
//                             fontWeight: FontWeight.w600,
//                             color: kText,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       TextField(
//                         controller: commentCtrl,
//                         maxLines: 4,
//                         minLines: 3,
//                         onChanged: (_) => setState(() {}),
//                         decoration: InputDecoration(
//                           hintText: 'Write 3–4 lines about display, stock, etc.',
//                           hintStyle: const TextStyle(
//                             fontFamily: 'ClashGrotesk',
//                             fontSize: 12,
//                             color: kMuted,
//                           ),
//                           fillColor: const Color(0xFFF2F3F5),
//                           filled: true,
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(14),
//                             borderSide: BorderSide.none,
//                           ),
//                         ),
//                         style: const TextStyle(
//                           fontFamily: 'ClashGrotesk',
//                           fontSize: 13,
//                           color: kText,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 actionsPadding:
//                     const EdgeInsets.fromLTRB(20, 0, 20, 12),
//                 actions: [
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF00C6FF),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(18),
//                         ),
//                         padding: const EdgeInsets.symmetric(vertical: 10),
//                       ),
//                       onPressed: canSubmit
//                           ? () async {
//                               setState(() => submitting = true);
//                               // TODO: call API to send image + comment if needed

//                               Navigator.of(ctx).pop(<String, dynamic>{
//                                 'imagePath': pickedImage!.path,
//                                 'comment': commentCtrl.text.trim(),
//                               });
//                             }
//                           : null,
//                       child: submitting
//                           ? const SizedBox(
//                               height: 18,
//                               width: 18,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 valueColor:
//                                     AlwaysStoppedAnimation<Color>(Colors.white),
//                               ),
//                             )
//                           : const Text(
//                               'Submit',
//                               style: TextStyle(
//                                 fontFamily: 'ClashGrotesk',
//                                 fontWeight: FontWeight.w700,
//                                 color: Colors.white,
//                               ),
//                             ),
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         );
//       },
//     );

//     // result is null if somehow dialog was killed (should only happen on app kill)
//     if (result != null) {
//       // user completed form
//       setState(() {
//         jp.isVisited = true;
//       });
//       _box.remove(_pendingVisitKey);
//       _buildMarkers();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Visit saved for ${jp.name}'),
//         ),
//       );
//     } else {
//       // keep pending key so popup appears again next time
//     }
//   }

//   /* --------------------------- RECENTER BUTTON --------------------------- */

//   Future<void> _recenterOnUser() async {
//     if (_mapController == null) return;

//     if (_currentPos == null) {
//       setState(() => _loading = true);
//       await _initLocation();
//       setState(() => _loading = false);
//       if (_currentPos == null) return;
//     }

//     final target = LatLng(
//       _currentPos!.latitude,
//       _currentPos!.longitude,
//     );

//     await _mapController!.animateCamera(
//       CameraUpdate.newCameraPosition(
//         CameraPosition(
//           target: target,
//           zoom: 15.0,
//         ),
//       ),
//     );
//   }

//   /* --------------------------- BUILD --------------------------- */

//   @override
//   Widget build(BuildContext context) {
//     final hasLocation = _currentPos != null;

//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: _kGrad,
//         ),
//         child: SafeArea(
//           child: Stack(
//             children: [
//               Positioned.fill(
//                 child: hasLocation
//                     ? GoogleMap(
//                         initialCameraPosition: CameraPosition(
//                           target: LatLng(
//                             _currentPos!.latitude,
//                             _currentPos!.longitude,
//                           ),
//                           zoom: 12.0,
//                         ),
//                         myLocationEnabled: true,
//                         myLocationButtonEnabled: false,
//                         compassEnabled: true,
//                         markers: _markers,
//                         onMapCreated: (c) {
//                           _mapController = c;
//                         },
//                       )
//                     : const Center(
//                         child: CircularProgressIndicator(
//                           valueColor:
//                               AlwaysStoppedAnimation<Color>(Colors.white),
//                         ),
//                       ),
//               ),

//               Container(
//                 height: 96,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       Colors.black.withOpacity(0.4),
//                       Colors.transparent,
//                     ],
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                   ),
//                 ),
//               ),

//               // header
//               Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Padding(
//                         padding: const EdgeInsets.only(top: 8.0, left: 4),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Journey Plan Map',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.w700,
//                                 fontFamily: 'ClashGrotesk',
//                               ),
//                             ),
//                             const SizedBox(height: 2),
//                             Text(
//                               'Total: $_totalLocations  •  Done: $_completedLocations',
//                               style: const TextStyle(
//                                 color: Colors.white70,
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w900,
//                                 fontFamily: 'ClashGrotesk',
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: EdgeInsets.only(
//                         top: MediaQuery.of(context).size.height * 0.16,
//                       ),
//                       child: IconButton(
//                         icon: const Icon(
//                           Icons.my_location_rounded,
//                           color: Colors.black,
//                           size: 32,
//                         ),
//                         tooltip: 'Re-center on my location',
//                         onPressed: _recenterOnUser,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               if (!_loading && _error != null)
//                 Center(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 16, vertical: 12),
//                     margin: const EdgeInsets.symmetric(horizontal: 24),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.6),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       _error!,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontFamily: 'ClashGrotesk',
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),

//               if (!_loading && _error == null)
//                 Align(
//                   alignment: Alignment.bottomCenter,
//                   child: Padding(
//                     padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(20),
//                       child: BackdropFilter(
//                         filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//                         child: Container(
//                           width: double.infinity,
//                           constraints: const BoxConstraints(maxHeight: 260),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.16),
//                             borderRadius: BorderRadius.circular(20),
//                             border: Border.all(
//                               color: Colors.white.withOpacity(0.35),
//                               width: 1.3,
//                             ),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Padding(
//                                 padding: const EdgeInsets.fromLTRB(
//                                     16, 10, 16, 4),
//                                 child: Row(
//                                   children: [
//                                     const Text(
//                                       'Nearby Outlets',
//                                       style: TextStyle(
//                                         color: Colors.black,
//                                         fontWeight: FontWeight.w900,
//                                         fontSize: 15,
//                                         fontFamily: 'ClashGrotesk',
//                                       ),
//                                     ),
//                                     const Spacer(),
//                                     Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.end,
//                                       children: [
//                                         Text(
//                                           '${_items.length} stops',
//                                           style: const TextStyle(
//                                             color: Colors.black,
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.w900,
//                                             fontFamily: 'ClashGrotesk',
//                                           ),
//                                         ),
//                                         Text(
//                                           'Done: $_completedLocations',
//                                           style: const TextStyle(
//                                             color: Colors.greenAccent,
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.w900,
//                                             fontFamily: 'ClashGrotesk',
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Expanded(
//                                 child: ListView.separated(
//                                   padding: const EdgeInsets.fromLTRB(
//                                       12, 4, 12, 12),
//                                   itemCount: _items.length,
//                                   separatorBuilder: (_, __) =>
//                                       const SizedBox(height: 8),
//                                   itemBuilder: (_, i) {
//                                     final item = _items[i];
//                                     return _GlassJourneyCard(
//                                       index: i + 1,
//                                       data: item,
//                                       onTap: () {
//                                         _mapController?.animateCamera(
//                                           CameraUpdate.newCameraPosition(
//                                             CameraPosition(
//                                               target: LatLng(
//                                                 item.supervisor.lat,
//                                                 item.supervisor.lng,
//                                               ),
//                                               zoom: 15.5,
//                                             ),
//                                           ),
//                                         );
//                                       },
//                                       onToggleVisited: () =>
//                                           _onToggleVisited(item),
//                                     );
//                                   },
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// /* --------------------------- Glass Card Row --------------------------- */

// class _GlassJourneyCard extends StatelessWidget {
//   const _GlassJourneyCard({
//     required this.index,
//     required this.data,
//     required this.onTap,
//     required this.onToggleVisited,
//   });

//   final int index;
//   final _JourneyWithDistance data;
//   final VoidCallback onTap;
//   final VoidCallback onToggleVisited;

//   @override
//   Widget build(BuildContext context) {
//     final jp = data.supervisor;
//     final distText = '${data.distanceKm.toStringAsFixed(1)} km';

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.black.withOpacity(0.18),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: Colors.black.withOpacity(0.5),
//             width: 0.9,
//           ),
//         ),
//         padding: const EdgeInsets.all(10),
//         child: Row(
//           children: [
//             Container(
//               width: 34,
//               height: 34,
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                   colors: [Colors.white, Color(0xFFECFEFF)],
//                 ),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Center(
//                 child: Text(
//                   '$index',
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w800,
//                     fontFamily: 'ClashGrotesk',
//                     color: kText,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     jp.name,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                       fontFamily: 'ClashGrotesk',
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Row(
//                     children: [
//                       const Icon(Icons.location_on_rounded,
//                           size: 14, color: Colors.white70),
//                       const SizedBox(width: 4),
//                       Text(
//                         distText,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                           fontFamily: 'ClashGrotesk',
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 8),
//             InkWell(
//               borderRadius: BorderRadius.circular(999),
//               onTap: onToggleVisited,
//               child: Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(999),
//                   color: jp.isVisited
//                       ? Colors.greenAccent.withOpacity(0.18)
//                       : Colors.orangeAccent.withOpacity(0.18),
//                   border: Border.all(
//                     color: jp.isVisited
//                         ? Colors.greenAccent
//                         : Colors.orangeAccent,
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       jp.isVisited
//                           ? Icons.check_circle_rounded
//                           : Icons.radio_button_unchecked_rounded,
//                       size: 16,
//                       color: jp.isVisited
//                           ? Colors.greenAccent
//                           : Colors.orangeAccent,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       jp.isVisited ? 'Visited' : 'Pending',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 11,
//                         fontWeight: FontWeight.w700,
//                         fontFamily: 'ClashGrotesk',
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


/*
const kText = Color(0xFF1E1E1E);
const kMuted = Color(0xFF707883);
const kShadow = Color(0x14000000);

const _kGrad = LinearGradient(
  colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// how close user must be to mark "Visited" (in meters)
const double kVisitRadiusMeters = 200;

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

  /* 🔒 Only allow visited if user is physically at that location */
  void _onToggleVisited(_JourneyWithDistance item) {
    if (_currentPos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current location not available yet.'),
        ),
      );
      return;
    }

    // distance between user and this outlet
    final dKm = distanceInKm(
      _currentPos!.latitude,
      _currentPos!.longitude,
      item.supervisor.lat,
      item.supervisor.lng,
    );
    final dMeters = dKm * 1000;

    if (dMeters > kVisitRadiusMeters) {
      // too far → show error, do NOT toggle
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You must be at ${item.supervisor.name} (within '
            '${kVisitRadiusMeters.toStringAsFixed(0)} m).\n'
            'Current distance: ${dMeters.toStringAsFixed(0)} m',
          ),
        ),
      );
      return;
    }

    // close enough → mark visited/unvisited
    setState(() {
      item.supervisor.isVisited = !item.supervisor.isVisited;
    });
    _buildMarkers(); // update marker color
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
                        myLocationButtonEnabled: false,
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
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.16,
                      ),
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

            // visited chip (tap will be validated in _onToggleVisited)
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
}*/


// const kText = Color(0xFF1E1E1E);
// const kMuted = Color(0xFF707883);
// const kShadow = Color(0x14000000);

// const _kGrad = LinearGradient(
//   colors: [Color(0xFF00C6FF), Color(0xFF7F53FD)],
//   begin: Alignment.topLeft,
//   end: Alignment.bottomRight,
// );


// class _JourneyWithDistance {
//   final JourneyPlanSupervisor supervisor;
//   final double distanceKm;

//   _JourneyWithDistance({
//     required this.supervisor,
//     required this.distanceKm,
//   });
// }

// /* --------------------------- Main Screen --------------------------- */

// class JourneyPlanMapScreen extends StatefulWidget {
//   const JourneyPlanMapScreen({super.key});

//   @override
//   State<JourneyPlanMapScreen> createState() => _JourneyPlanMapScreenState();
// }

// class _JourneyPlanMapScreenState extends State<JourneyPlanMapScreen> {
//   Position? _currentPos;
//   String? _error;
//   bool _loading = true;

//   late List<JourneyPlanSupervisor> _all;
//   List<_JourneyWithDistance> _items = [];

//   GoogleMapController? _mapController;
//   final Set<Marker> _markers = {};

//   int get _totalLocations => _all.length;
//   int get _completedLocations =>
//       _all.where((jp) => jp.isVisited == true).length;

//   @override
//   void initState() {
//     super.initState();
//     _all = List<JourneyPlanSupervisor>.from(kJourneyPlan);
//     _initLocation();
//   }

//   Future<void> _initLocation() async {
//     try {
//       final serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         setState(() {
//           _error = 'Location services are disabled.';
//           _loading = false;
//         });
//         return;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }
//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         setState(() {
//           _error = 'Location permission denied.';
//           _loading = false;
//         });
//         return;
//       }

//       final pos = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       _currentPos = pos;
//       _computeDistancesAndMarkers();
//     } catch (e) {
//       setState(() {
//         _error = 'Failed to get location: $e';
//         _loading = false;
//       });
//     }
//   }

//   void _computeDistancesAndMarkers() {
//     if (_currentPos == null) {
//       setState(() {
//         _error = 'Current location unavailable.';
//         _loading = false;
//       });
//       return;
//     }

//     final lat1 = _currentPos!.latitude;
//     final lon1 = _currentPos!.longitude;

//     _items = _all
//         .map(
//           (jp) => _JourneyWithDistance(
//             supervisor: jp,
//             distanceKm: distanceInKm(lat1, lon1, jp.lat, jp.lng),
//           ),
//         )
//         .toList()
//       ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

//     _buildMarkers();

//     setState(() {
//       _loading = false;
//       _error = null;
//     });

//     if (_mapController != null) {
//       _mapController!.animateCamera(
//         CameraUpdate.newCameraPosition(
//           CameraPosition(
//             target: LatLng(lat1, lon1),
//             zoom: 12.5,
//           ),
//         ),
//       );
//     }
//   }

//   void _buildMarkers() {
//     final markers = <Marker>{};

//     // Current location marker
//     if (_currentPos != null) {
//       markers.add(
//         Marker(
//           markerId: const MarkerId('current_location'),
//           position: LatLng(_currentPos!.latitude, _currentPos!.longitude),
//           infoWindow: const InfoWindow(title: 'You are here'),
//           icon: BitmapDescriptor.defaultMarkerWithHue(
//             BitmapDescriptor.hueAzure,
//           ),
//         ),
//       );
//     }

//     // Journey plan markers
//     for (final item in _items) {
//       final jp = item.supervisor;
//       markers.add(
//         Marker(
//           markerId: MarkerId(jp.name),
//           position: LatLng(jp.lat, jp.lng),
//           infoWindow: InfoWindow(
//             title: jp.name,
//             snippet: '${item.distanceKm.toStringAsFixed(1)} km away',
//           ),
//           icon: BitmapDescriptor.defaultMarkerWithHue(
//             jp.isVisited ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
//           ),
//         ),
//       );
//     }

//     setState(() {
//       _markers
//         ..clear()
//         ..addAll(markers);
//     });
//   }

//   void _onToggleVisited(_JourneyWithDistance item) {
//     setState(() {
//       item.supervisor.isVisited = !item.supervisor.isVisited;
//     });
//     _buildMarkers(); // this also triggers marker color change
//   }

//   /* --------------------------- RECENTER BUTTON --------------------------- */

//   Future<void> _recenterOnUser() async {
//     if (_mapController == null) return;

//     // If no location yet, try to fetch again
//     if (_currentPos == null) {
//       setState(() => _loading = true);
//       await _initLocation();
//       setState(() => _loading = false);
//       if (_currentPos == null) return;
//     }

//     final target = LatLng(
//       _currentPos!.latitude,
//       _currentPos!.longitude,
//     );

//     await _mapController!.animateCamera(
//       CameraUpdate.newCameraPosition(
//         CameraPosition(
//           target: target,
//           zoom: 15.0,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final hasLocation = _currentPos != null;

//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: _kGrad,
//         ),
//         child: SafeArea(
//           child: Stack(
//             children: [
//               // Map
//               Positioned.fill(
//                 child: hasLocation
//                     ? GoogleMap(
//                         initialCameraPosition: CameraPosition(
//                           target: LatLng(
//                             _currentPos!.latitude,
//                             _currentPos!.longitude,
//                           ),
//                           zoom: 12.0,
//                         ),
//                         myLocationEnabled: true,
//                         myLocationButtonEnabled:
//                             false, // we use our own recenter button
//                         compassEnabled: true,
//                         markers: _markers,
//                         onMapCreated: (c) {
//                           _mapController = c;
//                         },
//                       )
//                     : const Center(
//                         child: CircularProgressIndicator(
//                           valueColor:
//                               AlwaysStoppedAnimation<Color>(Colors.white),
//                         ),
//                       ),
//               ),

//               // Top dark gradient overlay
//               Container(
//                 height: 96,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       Colors.black.withOpacity(0.4),
//                       Colors.transparent,
//                     ],
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                   ),
//                 ),
//               ),

//               // Header with stats + recenter button
//               Padding(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 child: Row(
//                   children: [
//                     // If you want a back button, uncomment this:
//                     // IconButton(
//                     //   icon: const Icon(Icons.arrow_back_ios_new_rounded,
//                     //       color: Colors.white),
//                     //   onPressed: () => Navigator.pop(context),
//                     // ),
//                     // const SizedBox(width: 4),

//                     Expanded(
//                       child: Padding(
//                         padding: const EdgeInsets.only(top: 8.0, left: 4),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Journey Plan Map',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.w700,
//                                 fontFamily: 'ClashGrotesk',
//                               ),
//                             ),
//                             const SizedBox(height: 2),
//                             Text(
//                               'Total: $_totalLocations  •  Done: $_completedLocations',
//                               style: const TextStyle(
//                                 color: Colors.white70,
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w900,
//                                 fontFamily: 'ClashGrotesk',
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),

//                     Padding(
//                       padding:  EdgeInsets.only(top: MediaQuery.of(context).size.height *0.16),
//                       child: IconButton(
//                         icon: const Icon(
//                           Icons.my_location_rounded,
//                           color: Colors.black,
//                           size: 32,
//                         ),
//                         tooltip: 'Re-center on my location',
//                         onPressed: _recenterOnUser,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Error overlay
//               if (!_loading && _error != null)
//                 Center(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 16, vertical: 12),
//                     margin: const EdgeInsets.symmetric(horizontal: 24),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.6),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       _error!,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontFamily: 'ClashGrotesk',
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),

//               // Glass bottom sheet with list
//               if (!_loading && _error == null)
//                 Align(
//                   alignment: Alignment.bottomCenter,
//                   child: Padding(
//                     padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(20),
//                       child: BackdropFilter(
//                         filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//                         child: Container(
//                           width: double.infinity,
//                           constraints: const BoxConstraints(maxHeight: 260),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.16),
//                             borderRadius: BorderRadius.circular(20),
//                             border: Border.all(
//                               color: Colors.white.withOpacity(0.35),
//                               width: 1.3,
//                             ),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               // Sheet header
//                               Padding(
//                                 padding: const EdgeInsets.fromLTRB(
//                                     16, 10, 16, 4),
//                                 child: Row(
//                                   children: [
//                                     const Text(
//                                       'Nearby Outlets',
//                                       style: TextStyle(
//                                         color: Colors.black,
//                                         fontWeight: FontWeight.w900,
//                                         fontSize: 15,
//                                         fontFamily: 'ClashGrotesk',
//                                       ),
//                                     ),
//                                     const Spacer(),
//                                     Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.end,
//                                       children: [
//                                         Text(
//                                           '${_items.length} stops',
//                                           style: const TextStyle(
//                                             color: Colors.black,
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.w900,
//                                             fontFamily: 'ClashGrotesk',
//                                           ),
//                                         ),
//                                         Text(
//                                           'Done: $_completedLocations',
//                                           style: const TextStyle(
//                                             color: Colors.greenAccent,
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.w900,
//                                             fontFamily: 'ClashGrotesk',
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Expanded(
//                                 child: ListView.separated(
//                                   padding: const EdgeInsets.fromLTRB(
//                                       12, 4, 12, 12),
//                                   itemCount: _items.length,
//                                   separatorBuilder: (_, __) =>
//                                       const SizedBox(height: 8),
//                                   itemBuilder: (_, i) {
//                                     final item = _items[i];
//                                     return _GlassJourneyCard(
//                                       index: i + 1,
//                                       data: item,
//                                       onTap: () {
//                                         _mapController?.animateCamera(
//                                           CameraUpdate.newCameraPosition(
//                                             CameraPosition(
//                                               target: LatLng(
//                                                 item.supervisor.lat,
//                                                 item.supervisor.lng,
//                                               ),
//                                               zoom: 15.5,
//                                             ),
//                                           ),
//                                         );
//                                       },
//                                       onToggleVisited: () =>
//                                           _onToggleVisited(item),
//                                     );
//                                   },
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// /* --------------------------- Glass Card Row --------------------------- */

// class _GlassJourneyCard extends StatelessWidget {
//   const _GlassJourneyCard({
//     required this.index,
//     required this.data,
//     required this.onTap,
//     required this.onToggleVisited,
//   });

//   final int index;
//   final _JourneyWithDistance data;
//   final VoidCallback onTap;
//   final VoidCallback onToggleVisited;

//   @override
//   Widget build(BuildContext context) {
//     final jp = data.supervisor;
//     final distText = '${data.distanceKm.toStringAsFixed(1)} km';

//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.black.withOpacity(0.18),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: Colors.black.withOpacity(0.5),
//             width: 0.9,
//           ),
//         ),
//         padding: const EdgeInsets.all(10),
//         child: Row(
//           children: [
//             // index badge
//             Container(
//               width: 34,
//               height: 34,
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                   colors: [Colors.white, Color(0xFFECFEFF)],
//                 ),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Center(
//                 child: Text(
//                   '$index',
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w800,
//                     fontFamily: 'ClashGrotesk',
//                     color: kText,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 10),

//             // name + distance
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     jp.name,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                       fontFamily: 'ClashGrotesk',
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Row(
//                     children: [
//                       const Icon(Icons.location_on_rounded,
//                           size: 14, color: Colors.white70),
//                       const SizedBox(width: 4),
//                       Text(
//                         distText,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                           fontFamily: 'ClashGrotesk',
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(width: 8),

//             // visited chip
//             InkWell(
//               borderRadius: BorderRadius.circular(999),
//               onTap: onToggleVisited,
//               child: Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(999),
//                   color: jp.isVisited
//                       ? Colors.greenAccent.withOpacity(0.18)
//                       : Colors.orangeAccent.withOpacity(0.18),
//                   border: Border.all(
//                     color: jp.isVisited
//                         ? Colors.greenAccent
//                         : Colors.orangeAccent,
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       jp.isVisited
//                           ? Icons.check_circle_rounded
//                           : Icons.radio_button_unchecked_rounded,
//                       size: 16,
//                       color: jp.isVisited
//                           ? Colors.greenAccent
//                           : Colors.orangeAccent,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       jp.isVisited ? 'Visited' : 'Pending',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 11,
//                         fontWeight: FontWeight.w700,
//                         fontFamily: 'ClashGrotesk',
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

