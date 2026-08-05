import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk_platform_interface/flutter_google_places_sdk_platform_interface.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:url_launcher/url_launcher.dart';

import '../../config/google_maps_config.dart';
import '../../models/hospital_location.dart';
import '../../services/hospital_finder_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_page.dart';

class HospitalFinderScreen extends StatefulWidget {
  const HospitalFinderScreen({super.key, this.allowSelection = false});

  final bool allowSelection;

  @override
  State<HospitalFinderScreen> createState() => _HospitalFinderScreenState();
}

class _HospitalFinderScreenState extends State<HospitalFinderScreen> {
  static const _philippines = maps.CameraPosition(
    target: maps.LatLng(12.8797, 121.7740),
    zoom: 5.4,
  );

  final _searchController = TextEditingController();
  final HospitalFinderService? _service = GoogleMapsConfig.isConfigured
      ? HospitalFinderService()
      : null;
  maps.GoogleMapController? _mapController;
  Position? _position;
  List<HospitalLocation> _hospitals = const [];
  HospitalLocation? _selected;
  LocationAccessIssue? _locationIssue;
  String? _error;
  bool _loading = false;
  bool _hasSearched = false;

  bool get _supportsEmbeddedMap =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    if (_service != null && _supportsEmbeddedMap) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _findNearby());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          EverCareHeader(
            title: widget.allowSelection
                ? 'Choose a Hospital'
                : 'Nearby Emergency Hospitals',
            subtitle: 'Powered by Google Maps',
            showBack: true,
          ),
          Expanded(child: SafeArea(top: false, child: _buildContent())),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (!GoogleMapsConfig.isConfigured) {
      return _SetupRequired(allowSelection: widget.allowSelection);
    }
    if (!_supportsEmbeddedMap) {
      return const _FinderMessage(
        icon: Icons.phone_android_rounded,
        title: 'Open this feature on Android',
        message:
            'EverCare’s embedded Google hospital map is available in the Android mobile app.',
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchHospitals(),
                  decoration: InputDecoration(
                    labelText: 'Search hospitals',
                    hintText: 'Hospital name or city',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear hospital search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 9),
              IconButton.filled(
                tooltip: 'Search hospitals',
                onPressed: _loading ? null : _searchHospitals,
                icon: const Icon(Icons.search_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              maps.GoogleMap(
                initialCameraPosition: _philippines,
                mapType: maps.MapType.normal,
                compassEnabled: true,
                mapToolbarEnabled: false,
                myLocationEnabled: _position != null,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                markers: _markers,
                onMapCreated: (controller) {
                  _mapController = controller;
                  final position = _position;
                  if (position != null) _focusPosition(position);
                },
              ),
              Positioned(
                top: 12,
                right: 12,
                child: FloatingActionButton.small(
                  heroTag: 'hospital-current-location',
                  tooltip: 'Find hospitals near my location',
                  onPressed: _loading ? null : _findNearby,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryGreen,
                  child: const Icon(Icons.my_location_rounded),
                ),
              ),
              if (_loading)
                const Positioned(top: 12, left: 12, child: _LoadingPill()),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: _buildResults(),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_locationIssue != null && _hospitals.isEmpty) {
      return _LocationHelp(
        issue: _locationIssue!,
        onRetry: _findNearby,
        onSettings: _openRelevantSettings,
      );
    }
    if (_error != null && _hospitals.isEmpty) {
      return _FinderMessage(
        icon: Icons.map_outlined,
        title: 'Hospitals could not be loaded',
        message: _error!,
        actionLabel: 'Try Again',
        onAction: _hasSearched ? _searchHospitals : _findNearby,
      );
    }
    if (_loading && _hospitals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hospitals.isEmpty) {
      return _FinderMessage(
        icon: Icons.local_hospital_outlined,
        title: _hasSearched ? 'No hospitals found' : 'Find nearby hospitals',
        message: _hasSearched
            ? 'Try another hospital name, city, or province.'
            : 'Allow location access to see hospitals near you, or search by name.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 13, 18, 5),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _hasSearched
                      ? '${_hospitals.length} search results'
                      : '${_hospitals.length} hospitals nearby',
                  style: AppTextStyles.cardTitle,
                ),
              ),
              Image(
                image: FlutterGooglePlacesSdkPlatform
                    .ASSET_POWERED_BY_GOOGLE_ON_WHITE,
                height: 15,
                semanticLabel: 'Powered by Google',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 7, 14, 20),
            itemCount: _hospitals.length,
            separatorBuilder: (_, _) => const SizedBox(height: 9),
            itemBuilder: (context, index) {
              final hospital = _hospitals[index];
              return _HospitalResultCard(
                hospital: hospital,
                selected: hospital.id == _selected?.id,
                allowSelection: widget.allowSelection,
                onTap: () => _selectHospital(hospital),
                onPrimaryAction: () => widget.allowSelection
                    ? Navigator.pop(context, hospital)
                    : _openDirections(hospital),
              );
            },
          ),
        ),
      ],
    );
  }

  Set<maps.Marker> get _markers => _hospitals.map((hospital) {
    final selected = hospital.id == _selected?.id;
    return maps.Marker(
      markerId: maps.MarkerId(hospital.id),
      position: maps.LatLng(hospital.latitude, hospital.longitude),
      infoWindow: maps.InfoWindow(
        title: hospital.name,
        snippet: hospital.address,
      ),
      icon: maps.BitmapDescriptor.defaultMarkerWithHue(
        selected
            ? maps.BitmapDescriptor.hueOrange
            : maps.BitmapDescriptor.hueGreen,
      ),
      onTap: () => _selectHospital(hospital),
    );
  }).toSet();

  Future<void> _findNearby() async {
    final service = _service;
    if (service == null || _loading) return;
    setState(() {
      _loading = true;
      _hasSearched = false;
      _locationIssue = null;
      _error = null;
    });
    try {
      final position = await service.currentPosition();
      if (!mounted) return;
      setState(() => _position = position);
      await _focusPosition(position);
      final hospitals = await service.findNearby(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      setState(() {
        _hospitals = hospitals;
        _selected = hospitals.firstOrNull;
        _loading = false;
      });
    } on LocationAccessException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _locationIssue = error.issue;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Check your connection and Google Maps setup, then try again.';
      });
    }
  }

  Future<void> _searchHospitals() async {
    final service = _service;
    final query = _searchController.text.trim();
    if (service == null || query.isEmpty || _loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _hasSearched = true;
      _locationIssue = null;
      _error = null;
    });
    try {
      final hospitals = await service.search(
        query: query,
        originLatitude: _position?.latitude,
        originLongitude: _position?.longitude,
      );
      if (!mounted) return;
      setState(() {
        _hospitals = hospitals;
        _selected = hospitals.firstOrNull;
        _loading = false;
      });
      if (hospitals.isNotEmpty) await _focusHospital(hospitals.first);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Google could not complete that hospital search.';
      });
    }
  }

  void _selectHospital(HospitalLocation hospital) {
    setState(() => _selected = hospital);
    _focusHospital(hospital);
  }

  Future<void> _focusPosition(Position position) async {
    await _mapController?.animateCamera(
      maps.CameraUpdate.newLatLngZoom(
        maps.LatLng(position.latitude, position.longitude),
        13,
      ),
    );
  }

  Future<void> _focusHospital(HospitalLocation hospital) async {
    await _mapController?.animateCamera(
      maps.CameraUpdate.newLatLngZoom(
        maps.LatLng(hospital.latitude, hospital.longitude),
        14.5,
      ),
    );
  }

  Future<void> _openRelevantSettings() async {
    if (_locationIssue == LocationAccessIssue.servicesDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  Future<void> _openDirections(HospitalLocation hospital) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${hospital.latitude},${hospital.longitude}',
      'destination_place_id': hospital.id,
      'travelmode': 'driving',
      'dir_action': 'navigate',
    });
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps directions.')),
      );
    }
  }
}

class _HospitalResultCard extends StatelessWidget {
  const _HospitalResultCard({
    required this.hospital,
    required this.selected,
    required this.allowSelection,
    required this.onTap,
    required this.onPrimaryAction,
  });

  final HospitalLocation hospital;
  final bool selected;
  final bool allowSelection;
  final VoidCallback onTap;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      borderColor: selected ? AppColors.primaryGreen : AppColors.border,
      color: selected ? AppColors.lightGreen : Colors.white,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: selected ? Colors.white : AppColors.lightGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospital.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle,
                ),
                if (hospital.address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    hospital.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  hospital.distanceLabel,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          IconButton.filledTonal(
            tooltip: allowSelection
                ? 'Use ${hospital.name}'
                : 'Directions to ${hospital.name}',
            onPressed: onPrimaryAction,
            icon: Icon(
              allowSelection ? Icons.check_rounded : Icons.directions_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationHelp extends StatelessWidget {
  const _LocationHelp({
    required this.issue,
    required this.onRetry,
    required this.onSettings,
  });

  final LocationAccessIssue issue;
  final VoidCallback onRetry;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final servicesDisabled = issue == LocationAccessIssue.servicesDisabled;
    final deniedForever = issue == LocationAccessIssue.permissionDeniedForever;
    return _FinderMessage(
      icon: Icons.location_off_outlined,
      title: servicesDisabled
          ? 'Turn on device location'
          : 'Location access is needed',
      message: servicesDisabled
          ? 'Enable Location Services, then return to find nearby hospitals.'
          : 'EverCare uses your location only to search for hospitals near you. You can still type a hospital name above.',
      actionLabel: servicesDisabled || deniedForever
          ? 'Open Settings'
          : 'Retry',
      onAction: servicesDisabled || deniedForever ? onSettings : onRetry,
    );
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 12)],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 9),
          Text('Finding hospitals…', style: AppTextStyles.small),
        ],
      ),
    );
  }
}

class _FinderMessage extends StatelessWidget {
  const _FinderMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.primaryGreen),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SetupRequired extends StatelessWidget {
  const _SetupRequired({required this.allowSelection});

  final bool allowSelection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: AppCard(
        color: AppColors.lightGreen,
        borderColor: const Color(0xFFC8E3D5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.map_outlined,
              size: 52,
              color: AppColors.primaryGreen,
            ),
            const SizedBox(height: 12),
            const Text(
              'Google Maps setup required',
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 8),
            Text(
              allowSelection
                  ? 'A Google Maps API key is needed before hospitals can be searched and selected. You can return and type the clinic details manually.'
                  : 'A Google Maps API key is needed before EverCare can locate nearby hospitals.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
