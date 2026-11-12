import 'package:get/get.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../viewmodels/booking_viewmodel.dart';
import '../viewmodels/hospital_viewmodel.dart';
import '../viewmodels/manager_viewmodel.dart';
import '../viewmodels/queue_viewmodel.dart';

/// Registers all ViewModels.
class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthViewModel(), permanent: true);
    Get.lazyPut(() => HospitalViewModel(), fenix: true);
    Get.lazyPut(() => BookingViewModel(), fenix: true);
    Get.lazyPut(() => QueueViewModel(), fenix: true);
    Get.lazyPut(() => AdminViewModel(), fenix: true);
    Get.lazyPut(() => ManagerViewModel(), fenix: true);
  }
}
