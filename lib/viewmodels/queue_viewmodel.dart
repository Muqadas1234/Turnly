import 'package:get/get.dart';

/// ViewModel for the queue screens: holds state (Rx) and business logic.
class QueueViewModel extends GetxController {
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // TODO: Rx state + methods called by the Views (will use ApiService)
}
