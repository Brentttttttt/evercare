import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/emergency_guidance.dart';
import '../../models/emergency_contact.dart';
import '../../repositories/emergency_repository.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/care_photo_banner.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/evercare_backend_scope.dart';
import '../../widgets/section_header.dart';
import '../hospitals/hospital_finder_screen.dart';
import 'emergency_widgets.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  EmergencyRepository? _repository;
  List<EmergencyContact> _contacts = const [];
  EmergencyMedicalProfile? _medicalProfile;
  bool _initialized = false;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final client = EverCareBackendScope.maybeClient(context);
    if (client?.auth.currentUser == null) {
      _loading = false;
      return;
    }
    _repository = EmergencyRepository(client!);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final primary = _contacts.cast<EmergencyContact?>().firstWhere(
      (contact) => contact?.isPrimary == true,
      orElse: () => null,
    );
    final otherContacts = _contacts
        .where((contact) => contact.id != primary?.id)
        .toList(growable: false);
    final medicalItems = _medicalItems(_medicalProfile);

    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CarePhotoBanner(
            assetPath: 'assets/images/emergency_preparedness.png',
            semanticLabel:
                'A daughter reassuring an older woman beside a prepared care bag and medical folder',
            title: 'Prepared care brings peace of mind',
            subtitle: 'Keep trusted contacts and important details nearby.',
            height: 168,
          ),
          const SizedBox(height: 20),
          _EmergencyHotlineCard(onCopy: () => _copyNumber('143')),
          const SizedBox(height: 14),
          _EmergencyHospitalFinderCard(onOpen: _openHospitalFinder),
          const SizedBox(height: 27),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(36),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_repository == null)
            const EmptyStateCard(
              title: 'Sign in to prepare emergency details',
              message:
                  'Your trusted contacts and medical information will appear here after you sign in.',
              icon: Icons.lock_outline_rounded,
            )
          else if (_error != null)
            _EmergencyLoadError(message: _error!, onRetry: _load)
          else ...[
            const SectionHeader(
              title: 'Primary Emergency Contact',
              subtitle: 'The trusted person you chose to contact first',
            ),
            const SizedBox(height: 12),
            if (primary == null)
              EmptyStateCard(
                title: 'No primary contact yet',
                message: 'Add a trusted contact and mark them as primary.',
                icon: Icons.contact_emergency_outlined,
              )
            else
              EmergencyContactCard(
                contact: primary,
                onCopyNumber: () => _copyNumber(primary.phoneNumber),
                onDetails: _openContacts,
              ),
            if (otherContacts.isNotEmpty) ...[
              const SizedBox(height: 27),
              const SectionHeader(
                title: 'Other Emergency Contacts',
                subtitle: 'Your additional trusted contacts',
              ),
              const SizedBox(height: 12),
              ...otherContacts.map(
                (contact) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: EmergencyContactCard(
                    contact: contact,
                    onCopyNumber: () => _copyNumber(contact.phoneNumber),
                    onDetails: _openContacts,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const SectionHeader(
              title: 'Emergency Medical Information',
              subtitle: 'Details saved to your private EverCare account',
            ),
            const SizedBox(height: 12),
            EmergencyInformationCard(
              title: _medicalProfile?.fullName.isNotEmpty == true
                  ? '${_medicalProfile!.fullName}’s Medical ID'
                  : 'Emergency Medical ID',
              subtitle: medicalItems.isEmpty
                  ? 'Add health details that may help during an emergency.'
                  : 'Review these details regularly and keep them accurate.',
              items: medicalItems,
              onShowFullId: _openMedicalInformation,
            ),
          ],
          const SizedBox(height: 27),
          const SectionHeader(
            title: 'While Waiting for Help',
            subtitle: 'Simple reminders during an emergency',
          ),
          const SizedBox(height: 12),
          const EmergencyChecklistCard(
            items: EmergencyGuidance.waitingChecklist,
          ),
          const SizedBox(height: 8),
          const Text(
            'These are general safety reminders, not medical advice. Always follow instructions from qualified emergency personnel.',
            textAlign: TextAlign.center,
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    final repository = _repository;
    if (repository == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<Object>([
        repository.fetchContacts(),
        repository.fetchMedicalProfile(),
      ]);
      if (!mounted) return;
      setState(() {
        _contacts = values[0] as List<EmergencyContact>;
        _medicalProfile = values[1] as EmergencyMedicalProfile;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'EverCare could not load your emergency details. Please try again.';
      });
    }
  }

  Future<void> _copyNumber(String phoneNumber) async {
    await Clipboard.setData(ClipboardData(text: phoneNumber));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$phoneNumber copied. Open your Phone app to call.'),
      ),
    );
  }

  Future<void> _openContacts() async {
    await Navigator.pushNamed(context, AppRoutes.emergencyContacts);
    if (mounted) await _load();
  }

  Future<void> _openMedicalInformation() async {
    await Navigator.pushNamed(context, AppRoutes.medicalInfo);
    if (mounted) await _load();
  }

  Future<void> _openHospitalFinder() async {
    await Navigator.push<void>(
      context,
      EverCarePageRoute(builder: (_) => const HospitalFinderScreen()),
    );
  }

  List<(String, String)> _medicalItems(EmergencyMedicalProfile? profile) {
    if (profile == null) return const [];
    return [
      if (profile.bloodType.isNotEmpty) ('Blood type', profile.bloodType),
      if (profile.allergies.isNotEmpty)
        ('Allergies', profile.allergies.join(', ')),
      if (profile.conditions.isNotEmpty)
        ('Conditions', profile.conditions.join(', ')),
      if (profile.preferredHospital.isNotEmpty)
        ('Preferred hospital', profile.preferredHospital),
    ];
  }
}

class _EmergencyHotlineCard extends StatelessWidget {
  const _EmergencyHotlineCard({required this.onCopy});

  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFFFF8F4),
      borderColor: const Color(0xFFF5D8D3),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5E1),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(
              Icons.sos_rounded,
              color: AppColors.danger,
              size: 32,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Do you need immediate help?',
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle,
          ),
          const SizedBox(height: 7),
          const Text(
            'Use your Phone app to call the Philippine Red Cross emergency hotline. EverCare does not place calls itself.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCopy,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy Philippine Red Cross Hotline 143'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'If the person is unconscious, has difficulty breathing, severe chest pain, or faces immediate danger, contact emergency services now.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _EmergencyHospitalFinderCard extends StatelessWidget {
  const _EmergencyHospitalFinderCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFEAF5EF),
      borderColor: const Color(0xFFC8E3D5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: AppColors.primaryGreen,
                  size: 29,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find Nearby Emergency Hospitals',
                      style: AppTextStyles.cardTitle,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Use your location to see hospitals and open driving directions.',
                      style: AppTextStyles.bodyMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.map_rounded),
              label: const Text('Open Emergency Hospital Map'),
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Hospital availability and travel conditions can change. Call ahead when possible.',
            textAlign: TextAlign.center,
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }
}

class _EmergencyLoadError extends StatelessWidget {
  const _EmergencyLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: AppColors.danger,
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
