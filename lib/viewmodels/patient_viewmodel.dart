import 'package:get/get.dart';
import '../services/api_service.dart';

class PatientViewModel extends GetxController {
  // Master list of all approved hospitals to keep availableCities permanent
  final List<Map<String, dynamic>> _masterHospitals = [];

  // Observables for state
  final hospitals = <Map<String, dynamic>>[].obs;
  final availableCities = <String>['All'].obs;
  final activeToken = Rxn<Map<String, dynamic>>();
  final isLoading = false.obs;
  final selectedCity = 'All'.obs;
  final currentSearchQuery = ''.obs;

  // Hospital Details state
  final currentHospital = Rxn<Map<String, dynamic>>();
  final departments = <Map<String, dynamic>>[].obs;
  final doctors = <Map<String, dynamic>>[].obs;
  final selectedDepartmentId = RxnInt();
  final selectedDoctor = Rxn<Map<String, dynamic>>();
  final isLoadingDetails = false.obs;

  // Request counter to discard stale search responses
  int _requestGen = 0;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
    fetchActiveToken();
  }

  // Load initial unfiltered hospitals and extract permanent available cities
  Future<void> loadInitialData() async {
    isLoading.value = true;
    try {
      final response = await ApiService.getPatientHospitals();
      if (response['success'] == true) {
        final list = (response['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _masterHospitals.clear();
        _masterHospitals.addAll(list);
        hospitals.assignAll(list);

        final cities = list
            .map((h) => h['city']?.toString().trim())
            .where((c) => c != null && c.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();
        cities.sort();
        availableCities.assignAll(['All', ...cities]);
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch approved hospitals from database with city & search filtering
  Future<void> fetchHospitals({String? city, String? search}) async {
    final currentGen = ++_requestGen;
    isLoading.value = true;
    try {
      final queryText = search ?? currentSearchQuery.value;
      final isSearching = queryText.trim().isNotEmpty;

      // When searching, search across all cities (reset city constraint)
      final targetCity = isSearching
          ? null
          : (city ?? (selectedCity.value.toLowerCase() == 'all' ? null : selectedCity.value));

      final response = await ApiService.getPatientHospitals(
        city: targetCity,
        search: isSearching ? queryText : null,
      );

      if (currentGen != _requestGen) return;

      if (response['success'] == true) {
        final list = (response['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        hospitals.assignAll(list);
      } else {
        hospitals.clear();
      }
    } catch (_) {
      if (currentGen == _requestGen) {
        hospitals.clear();
      }
    } finally {
      if (currentGen == _requestGen) {
        isLoading.value = false;
      }
    }
  }

  // City chip selection handler
  void setCityFilter(String city) {
    selectedCity.value = city;
    currentSearchQuery.value = '';
    fetchHospitals(city: city, search: '');
  }

  // Real-time search query handler
  void search(String query) {
    currentSearchQuery.value = query;
    if (query.trim().isNotEmpty) {
      selectedCity.value = 'All'; // Automatically reset filter chip to 'All' when searching
    }
    fetchHospitals(search: query);
  }

  // Fetch current active token for logged in patient
  Future<void> fetchActiveToken() async {
    try {
      final response = await ApiService.getPatientActiveToken();
      if (response['success'] == true && response['data'] != null) {
        activeToken.value = Map<String, dynamic>.from(response['data'] as Map);
      } else {
        activeToken.value = null;
      }
    } catch (_) {
      activeToken.value = null;
    }
  }

  // Fetch hospital specifications, departments, and doctors from database
  Future<void> fetchHospitalDetails(int hospitalId) async {
    isLoadingDetails.value = true;
    try {
      final response = await ApiService.getHospitalDetails(hospitalId);
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        currentHospital.value = Map<String, dynamic>.from(data['hospital'] as Map);

        final deptList = (data['departments'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        departments.assignAll(deptList);

        final docList = (data['doctors'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        doctors.assignAll(docList);

        // Default to first department if available
        if (deptList.isNotEmpty) {
          selectedDepartmentId.value = deptList.first['id'] as int?;
        } else {
          selectedDepartmentId.value = null;
        }

        // Reset selected doctor
        selectedDoctor.value = docList.isNotEmpty ? docList.first : null;
      }
    } catch (_) {
    } finally {
      isLoadingDetails.value = false;
    }
  }

  // Filter doctors by selected department
  List<Map<String, dynamic>> get filteredDoctors {
    if (selectedDepartmentId.value == null) return doctors;
    return doctors
        .where((d) => d['department_id'] == selectedDepartmentId.value)
        .toList();
  }

  // Department chip selection handler
  void selectDepartment(int deptId) {
    selectedDepartmentId.value = deptId;
  }

  // Select doctor for booking flow
  void selectDoctor(Map<String, dynamic> doc) {
    selectedDoctor.value = doc;
  }
}
