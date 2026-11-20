import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/app_assets.dart';
import '../../utils/app_colors.dart';
import '../../utils/routes.dart';
import '../../widgets/custom_button.dart';
import 'my_token_view.dart';

class MyTokensView extends StatefulWidget {
  const MyTokensView({super.key});

  @override
  State<MyTokensView> createState() => _MyTokensViewState();
}

class _MyTokensViewState extends State<MyTokensView> {
  int _selectedTab = 0;
  // Set to false to show Empty State (matching mockup design), or true to show active tokens list
  final bool _hasActiveTokens = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Title
              const Text('My tokens', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),

              // Active / History Sliding Segmented Control
              CustomSlidingSegmentedControl<int>(
                initialValue: _selectedTab,
                isStretch: true,
                children: {
                  0: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Active', style: TextStyle(fontSize: 14, fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.w500, color: _selectedTab == 0 ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ), 1: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('History',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.w500,
                        color: _selectedTab == 1 ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                },
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                thumbDecoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4.0,
                      offset: const Offset(0.0, 2.0),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                onValueChanged: (v) {
                  setState(() => _selectedTab = v);
                },
              ),
              const SizedBox(height: 20),

              // Tab Content
              if (_selectedTab == 0) ...[
                if (!_hasActiveTokens)
                  _buildEmptyState()
                else ...[
                  // Token Card 1: #12
                  _buildActiveTokenCard(
                    tokenNumber: '#12',
                    status: 'Waiting',
                    statusColor: AppColors.adminPrimaryDark,
                    statusBg: AppColors.adminPrimaryLight,
                    doctorName: 'Dr. Ahmed Raza · Cardiology',
                    patientName: 'For Ayesha Khan (you)',
                    hospital: 'City General Hospital',
                    queueInfo: 'Today · 3 patients ahead · ~25 min',
                  ),
                  const SizedBox(height: 16),

                  // Token Card 2: #7
                  _buildActiveTokenCard(
                    tokenNumber: '#7',
                    status: 'Serving',
                    statusColor: AppColors.adminBlue,
                    statusBg: AppColors.adminBlueBg,
                    doctorName: 'Dr. Hina Qureshi · Pediatrics',
                    patientName: 'For Sara Khan (daughter)',
                    hospital: 'Aga Khan University Hospital',
                    queueInfo: 'Today · Being served now',
                  ),
                  const SizedBox(height: 24),

                  // Recent History Section
                  const Text(
                    'Recent history',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildHistoryItem(
                    doctorName: 'Dr. Bilal Shah · ENT',
                    dateInfo: '10 Nov · Token #5',
                  ),
                ],
              ] else ...[
                // Full History List
                _buildHistoryItem(
                  doctorName: 'Dr. Bilal Shah · ENT',
                  dateInfo: '10 Nov · Token #5',
                ),
                const SizedBox(height: 12),
                _buildHistoryItem(
                  doctorName: 'Dr. Sana Tariq · Dermatology',
                  dateInfo: '02 Nov · Token #18',
                ),
                const SizedBox(height: 12),
                _buildHistoryItem(
                  doctorName: 'Dr. Ahmed Raza · Cardiology',
                  dateInfo: '20 Oct · Token #12',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Active Token Card Widget
  Widget _buildActiveTokenCard({
    required String tokenNumber,
    required String status,
    required Color statusColor,
    required Color statusBg,
    required String doctorName,
    required String patientName,
    required String hospital,
    required String queueInfo,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Token Number & Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tokenNumber,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.adminPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Doctor & Department
          Text(
            doctorName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),

          // Patient Name
          Text(
            patientName,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Location
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hospital,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Queue / Time Info
          Row(
            children: [
              const Icon(
                Icons.access_time_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  queueInfo,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons: Track live & Cancel (Using CustomButton)
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Track live',
                  height: 42,
                  backgroundColor: AppColors.adminPrimaryLight,
                  textColor: AppColors.adminPrimaryDark,
                  onPressed: () {
                    Get.to(() => const MyTokenView());
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Cancel',
                  height: 42,
                  backgroundColor: AppColors.errorBg,
                  textColor: AppColors.error,
                  onPressed: () {
                    _showCancelDialog(tokenNumber);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // History Item Widget
  Widget _buildHistoryItem({
    required String doctorName,
    required String dateInfo,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.successBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dateInfo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Empty State Widget (When no active tokens)
  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 70),

        // Big Circular Avatar with Ticket Icon
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: AppColors.adminPrimaryLight,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            AppAssets.ticketIcon,
            width: 44,
            height: 44,
            colorFilter: const ColorFilter.mode(
              AppColors.adminPrimary,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Title
        const Text(
          'No active tokens',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),

        // Subtitle Description
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Book a token from home and skip the waiting room. Your live queue position will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 80),

        // Find a Hospital Button
        CustomButton(
          label: 'Find a hospital',
          height: 48,
          backgroundColor: AppColors.adminPrimary,
          textColor: AppColors.surface,
          onPressed: () {
            Get.offAllNamed(AppRoutes.home);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Cancel Confirmation Dialog
  void _showCancelDialog(String tokenNumber) {
    Get.defaultDialog(
      title: 'Cancel Token',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      middleText: 'Are you sure you want to cancel token $tokenNumber?',
      textConfirm: 'Yes, Cancel',
      textCancel: 'Keep Token',
      confirmTextColor: AppColors.surface,
      buttonColor: AppColors.error,
      cancelTextColor: AppColors.textSecondary,
      onConfirm: () {
        Get.back();
        Get.snackbar(
          'Token Cancelled',
          'Token $tokenNumber has been successfully cancelled.',
          backgroundColor: AppColors.error,
          colorText: AppColors.surface,
        );
      },
    );
  }
}
