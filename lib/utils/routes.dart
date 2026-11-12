import 'package:get/get.dart';

import '../views/auth/splash_view.dart';
import '../views/auth/role_selection_view.dart';
import '../views/auth/login_view.dart';
import '../views/auth/signup_view.dart';
import '../views/auth/otp_view.dart';
import '../views/auth/otp_success_view.dart';
import '../views/patient/home_view.dart';
import '../views/patient/hospital_detail_view.dart';
import '../views/patient/doctor_list_view.dart';
import '../views/patient/booking_view.dart';
import '../views/patient/my_tokens_view.dart';
import '../views/patient/my_token_view.dart';
import '../views/patient/family_members_view.dart';
import '../views/patient/profile_view.dart';
import '../views/patient/ai_guide_view.dart';
import '../views/manager/registration_form_view.dart';
import '../views/manager/manager_dashboard_view.dart';
import '../views/manager/doctor_management_view.dart';
import '../views/manager/queue_control_view.dart';
import '../views/admin/admin_panel_view.dart';
import '../views/admin/platform_stats_view.dart';

class AppRoutes {
  static const splash = '/splash';
  static const roleSelection = '/role-selection';
  static const login = '/login';
  static const signup = '/signup';
  static const otp = '/otp';
  static const otpSuccess = '/otp-success';
  static const home = '/home';
  static const hospitalDetail = '/hospital-detail';
  static const doctorList = '/doctor-list';
  static const booking = '/booking';
  static const myTokens = '/my-tokens';
  static const myToken = '/my-token';
  static const familyMembers = '/family-members';
  static const profile = '/profile';
  static const aiGuide = '/ai-guide';
  static const registrationForm = '/registration-form';
  static const managerDashboard = '/manager-dashboard';
  static const doctorManagement = '/doctor-management';
  static const queueControl = '/queue-control';
  static const adminPanel = '/admin-panel';
  static const platformStats = '/platform-stats';
}

class AppPages {
  static final routes = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashView()),
    GetPage(name: AppRoutes.roleSelection, page: () => const RoleSelectionView()),
    GetPage(name: AppRoutes.login, page: () => const LoginView()),
    GetPage(name: AppRoutes.signup, page: () => const SignupView()),
    GetPage(name: AppRoutes.otp, page: () => const OtpView()),
    GetPage(name: AppRoutes.otpSuccess, page: () => const OtpSuccessView()),
    GetPage(name: AppRoutes.home, page: () => const HomeView()),
    GetPage(name: AppRoutes.hospitalDetail, page: () => const HospitalDetailView()),
    GetPage(name: AppRoutes.doctorList, page: () => const DoctorListView()),
    GetPage(name: AppRoutes.booking, page: () => const BookingView()),
    GetPage(name: AppRoutes.myTokens, page: () => const MyTokensView()),
    GetPage(name: AppRoutes.myToken, page: () => const MyTokenView()),
    GetPage(name: AppRoutes.familyMembers, page: () => const FamilyMembersView()),
    GetPage(name: AppRoutes.profile, page: () => const ProfileView()),
    GetPage(name: AppRoutes.aiGuide, page: () => const AiGuideView()),
    GetPage(name: AppRoutes.registrationForm, page: () => const RegistrationFormView()),
    GetPage(name: AppRoutes.managerDashboard, page: () => const ManagerDashboardView()),
    GetPage(name: AppRoutes.doctorManagement, page: () => const DoctorManagementView()),
    GetPage(name: AppRoutes.queueControl, page: () => const QueueControlView()),
    GetPage(name: AppRoutes.adminPanel, page: () => const AdminPanelView()),
    GetPage(name: AppRoutes.platformStats, page: () => const PlatformStatsView()),
  ];
}
