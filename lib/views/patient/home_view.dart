import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../services/notification_service.dart';
import '../../utils/app_assets.dart';
import '../../utils/app_colors.dart';
import 'my_tokens_view.dart';
import 'patient_home_tab.dart';
import 'profile_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PatientHomeTab(),
    MyTokensView(),
    ProfileView(),
  ];

  Worker? _tabWorker;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<NotificationService>()) {
      final svc = Get.find<NotificationService>();
      // a notification tap may have arrived before this screen existed
      _applyPendingTab(svc);
      _tabWorker = ever(svc.pendingTab, (_) => _applyPendingTab(svc));
    }
  }

  void _applyPendingTab(NotificationService svc) {
    final tab = svc.pendingTab.value;
    if (tab == null) return;
    svc.pendingTab.value = null;
    if (mounted && tab >= 0 && tab < _screens.length) {
      setState(() => _currentIndex = tab);
    }
  }

  @override
  void dispose() {
    _tabWorker?.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, AppAssets.hospitalIcon, 'Home'),
                _buildNavItem(1, AppAssets.ticketIcon, 'My Tokens'),
                _buildNavItem(2, AppAssets.userIcon, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconAsset, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.adminPrimary : AppColors.textHint;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
