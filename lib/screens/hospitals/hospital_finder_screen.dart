import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/hospital_location.dart';
import '../../services/hospital_finder_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_page.dart';

class HospitalFinderScreen extends StatefulWidget {
  const HospitalFinderScreen({
    super.key,
    this.allowSelection = false,
    this.autoLocate = true,
    this.showMapTiles = true,
    this.service,
  });

  final bool allowSelection;
  final bool autoLocate;
  final bool showMapTiles;
  final HospitalFinderService? service;

  @override
  State<HospitalFinderScreen> createState() => _HospitalFinderScreenState();
}

class _HospitalFinderScreenState extends State<HospitalFinderScreen> {
  static const _philippines = LatLng(12.8797, 121.7740);
  static const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _userAgentPackageName = 'com.example.evercare';

  final _searchController = TextEditingController();
  final _mapController = MapController();
  late final HospitalFinderService _service;
  late final bool _ownsService;
  Position? _position;
  List<HospitalLocation> _hospitals = const [];
  HospitalLocation? _selected;
  LocationAccessIssue? _locationIssue;
  String? _error;
  bool _loading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? HospitalFinderService();
    if (widget.autoLocate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _findNearby());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    if (_ownsService) _service.close();
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
            subtitle: 'OpenStreetMap hospital finder',
            showBack: true,
          ),
          Expanded(child: SafeArea(top: false, child: _buildContent())),
        ],
      ),
    );
  }

  Widget _buildContent() {
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
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: _philippines,
                  initialZoom: 5.4,
                  minZoom: 4,
                  maxZoom: 19,
                ),
                children: [
                  if (widget.showMapTiles)
                    TileLayer(
                      urlTemplate: _tileUrl,
                      userAgentPackageName: _userAgentPackageName,
                      maxNativeZoom: 19,
                    ),
                  MarkerLayer(markers: _markers),
                  RichAttributionWidget(
                    showFlutterMapAttribution: false,
                    attributions: [
                      LogoSourceAttribution(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .9),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Text(
                            '© OpenStreetMap contributors',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                        tooltip: 'OpenStreetMap copyright and attribution',
                        onTap: _openOpenStreetMapCopyright,
                      ),
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: _openOpenStreetMapCopyright,
                      ),
                    ],
                  ),
                ],
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
              InkWell(
                onTap: _openOpenStreetMapCopyright,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Text('© OpenStreetMap', style: AppTextStyles.small),
                ),
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
                    : _selectHospital(hospital),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Marker> get _markers {
    final markers = <Marker>[];
    final position = _position;
    if (position != null) {
      markers.add(
        Marker(
          point: LatLng(position.latitude, position.longitude),
          width: 42,
          height: 42,
          child: Semantics(
            label: 'Your current location',
            child: const Tooltip(
              message: 'Your location',
              child: _UserLocationMarker(),
            ),
          ),
        ),
      );
    }
    markers.addAll(
      _hospitals.map((hospital) {
        final selected = hospital.id == _selected?.id;
        return Marker(
          key: ValueKey(hospital.id),
          point: LatLng(hospital.latitude, hospital.longitude),
          width: 48,
          height: 52,
          alignment: Alignment.topCenter,
          child: Semantics(
            button: true,
            label: '${hospital.name}, ${hospital.distanceLabel}',
            child: Tooltip(
              message: hospital.name,
              child: GestureDetector(
                onTap: () => _selectHospital(hospital),
                child: _HospitalMapMarker(selected: selected),
              ),
            ),
          ),
        );
      }),
    );
    return markers;
  }

  Future<void> _findNearby() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _hasSearched = false;
      _locationIssue = null;
      _error = null;
    });
    try {
      final position = await _service.currentPosition();
      if (!mounted) return;
      setState(() => _position = position);
      _focusPosition(position);
      final hospitals = await _service.findNearby(
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
    } on HospitalFinderException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'The nearby-hospital service is unavailable right now. Check your internet connection and try again.';
      });
    }
  }

  Future<void> _searchHospitals() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _hasSearched = true;
      _locationIssue = null;
      _error = null;
    });
    try {
      final hospitals = await _service.search(
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
      if (hospitals.isNotEmpty) _focusHospital(hospitals.first);
    } on HospitalFinderException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'The hospital search service could not complete that request. Check your internet connection and try again.';
      });
    }
  }

  void _selectHospital(HospitalLocation hospital) {
    if (widget.allowSelection) {
      Navigator.pop(context, hospital);
      return;
    }
    setState(() => _selected = hospital);
    _focusHospital(hospital);
    _showEmergencyHospitalActions(hospital);
  }

  void _focusPosition(Position position) {
    _mapController.move(LatLng(position.latitude, position.longitude), 13);
  }

  void _focusHospital(HospitalLocation hospital) {
    _mapController.move(LatLng(hospital.latitude, hospital.longitude), 14.5);
  }

  Future<void> _openRelevantSettings() async {
    if (_locationIssue == LocationAccessIssue.servicesDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  Future<void> _openOpenStreetMapCopyright() async {
    await launchUrl(
      Uri.parse('https://www.openstreetmap.org/copyright'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _showEmergencyHospitalActions(HospitalLocation hospital) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _EmergencyHospitalActions(
        hospital: hospital,
        onDirections: () async {
          Navigator.pop(sheetContext);
          await _openGoogleMapsDirections(hospital);
        },
        onDetails: () async {
          Navigator.pop(sheetContext);
          await _openGoogleMapsHospitalDetails(hospital);
        },
      ),
    );
  }

  Future<void> _openGoogleMapsDirections(HospitalLocation hospital) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${hospital.latitude},${hospital.longitude}',
      'travelmode': 'driving',
    });
    await _launchExternalGoogleUrl(
      uri,
      failureMessage: 'Could not open Google Maps directions.',
    );
  }

  Future<void> _openGoogleMapsHospitalDetails(HospitalLocation hospital) async {
    final searchParts = <String>[
      hospital.name,
      if (hospital.address.isNotEmpty) hospital.address,
      'hospital',
    ];
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': searchParts.join(', '),
    });
    await _launchExternalGoogleUrl(
      uri,
      failureMessage: 'Could not open this hospital in Google Maps.',
    );
  }

  Future<void> _launchExternalGoogleUrl(
    Uri uri, {
    required String failureMessage,
  }) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened || !mounted) return;
    } catch (_) {
      if (!mounted) return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failureMessage)));
  }
}

class _HospitalMapMarker extends StatelessWidget {
  const _HospitalMapMarker({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.12 : 1,
      duration: const Duration(milliseconds: 180),
      child: Icon(
        Icons.location_pin,
        size: 48,
        color: selected ? AppColors.warning : AppColors.primaryGreen,
        shadows: const [
          Shadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF2585E6),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 7)],
      ),
    );
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
                : 'Emergency options for ${hospital.name}',
            onPressed: onPrimaryAction,
            icon: Icon(
              allowSelection
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyHospitalActions extends StatelessWidget {
  const _EmergencyHospitalActions({
    required this.hospital,
    required this.onDirections,
    required this.onDetails,
  });

  final HospitalLocation hospital;
  final VoidCallback onDirections;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: AppColors.primaryGreen,
                    size: 29,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hospital.name, style: AppTextStyles.sectionTitle),
                      if (hospital.address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(hospital.address, style: AppTextStyles.bodyMuted),
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
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onDirections,
              icon: const Icon(Icons.directions_rounded),
              label: const Text('Get Directions in Google Maps'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onDetails,
              icon: const Icon(Icons.contact_phone_outlined),
              label: const Text('Find Contact Number & Details'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: AppColors.primaryGreen,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Google Maps opens outside EverCare. Verify the hospital\'s contact details and availability before traveling when possible.',
                      style: AppTextStyles.small,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
