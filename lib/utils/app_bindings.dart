import 'package:get/get.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/admin_viewmodel.dart';
import '../viewmodels/booking_viewmodel.dart';
import '../viewmodels/hospital_viewmodel.dart';
import '../viewmodels/manager_viewmodel.dart';
import '../viewmodels/queue_viewmodel.dart';
import '../viewmodels/patient_viewmodel.dart';

/// Registers all ViewModels.
class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthViewModel(), permanent: true);
    Get.lazyPut(() => HospitalViewModel(), fenix: true);
    Get.lazyPut(() => PatientViewModel(), fenix: true);
    Get.lazyPut(() => BookingViewModel(), fenix: true);
    Get.lazyPut(() => QueueViewModel(), fenix: true);
    Get.lazyPut(() => AdminViewModel(), fenix: true);
    // Permanent: it owns TextEditingControllers and the hospital status shared by many
    // screens. A route-scoped / lazy instance gets deleted when the login route is removed,
    // which disposed the controllers while the dashboard was still using them.
    Get.put(ManagerViewModel(), permanent: true);
  }
}
