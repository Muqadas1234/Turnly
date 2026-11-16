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

  // Request counters to discard stale async responses
  int _requestGen = 0;
  int _detailsRequestGen = 0;
  int _tokenRequestGen = 0;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
    fetchActiveToken();
  }

  // Load initial unfiltered hospitals and extract permanent available cities
  Future<void> loadInitialData() async {
    final currentGen = ++_requestGen;
    isLoading.value = true;
    try {
      final response = await ApiService.getPatientHospitals();
      if (response['success'] == true) {
        final list = (response['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _masterHospitals.clear();
        _masterHospitals.addAll(list);

        final cities = list
            .map((h) => h['city']?.toString().trim())
            .where((c) => c != null && c.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();
        cities.sort();
        availableCities.assignAll(['All', ...cities]);

        // Only assign to displayed hospitals if no newer search or filter took ownership
        if (currentGen == _requestGen && currentSearchQuery.value.isEmpty && selectedCity.value.toLowerCase() == 'all') {
          hospitals.assignAll(list);
        }
      }
    } catch (_) {
    } finally {
      if (currentGen == _requestGen && currentSearchQuery.value.isEmpty && selectedCity.value.toLowerCase() == 'all') {
        isLoading.value = false;
      }
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
    final currentGen = ++_tokenRequestGen;
    try {
      final response = await ApiService.getPatientActiveToken();
      if (currentGen != _tokenRequestGen) return;

      if (response['success'] == true && response['data'] != null) {
        activeToken.value = Map<String, dynamic>.from(response['data'] as Map);
      } else {
        activeToken.value = null;
      }
    } catch (_) {
      if (currentGen == _tokenRequestGen) {
        activeToken.value = null;
      }
    }
  }

  // Fetch hospital specifications, departments, and doctors from database
  Future<void> fetchHospitalDetails(int hospitalId) async {
    final currentGen = ++_detailsRequestGen;

    // Reset hospital-specific state so previous details are not exposed
    currentHospital.value = null;
    departments.clear();
    doctors.clear();
    selectedDoctor.value = null;
    selectedDepartmentId.value = null;
    isLoadingDetails.value = true;

    try {
      final response = await ApiService.getHospitalDetails(hospitalId);
      if (currentGen != _detailsRequestGen) return;

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
        final firstDeptId = deptList.isNotEmpty ? deptList.first['id'] as int? : null;
        selectedDepartmentId.value = firstDeptId;

        // Select an eligible (available) doctor belonging to the selected department
        selectedDoctor.value = docList.firstWhereOrNull(
          (d) => (firstDeptId == null || d['department_id'] == firstDeptId) && d['is_available'] == true,
        );
      } else {
        currentHospital.value = null;
      }
    } catch (_) {
      if (currentGen == _detailsRequestGen) {
        currentHospital.value = null;
      }
    } finally {
      if (currentGen == _detailsRequestGen) {
        isLoadingDetails.value = false;
      }
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
    // Invalidate or update selected doctor if not belonging to chosen department
    if (selectedDoctor.value != null && selectedDoctor.value?['department_id'] != deptId) {
      selectedDoctor.value = doctors.firstWhereOrNull(
        (d) => d['department_id'] == deptId && d['is_available'] == true,
      );
    }
  }

  // Refresh both master city catalog and active filtered hospitals
  Future<void> refreshCatalog() async {
    try {
      final response = await ApiService.getPatientHospitals();
      if (response['success'] == true) {
        final list = (response['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _masterHospitals.clear();
        _masterHospitals.addAll(list);

        final cities = list
            .map((h) => h['city']?.toString().trim())
            .where((c) => c != null && c.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();
        cities.sort();
        availableCities.assignAll(['All', ...cities]);
      }
    } catch (_) {}

    await Future.wait([
      fetchHospitals(),
      fetchActiveToken(),
    ]);
  }

  // Select doctor for booking flow
  void selectDoctor(Map<String, dynamic> doc) {
    selectedDoctor.value = doc;
  }
}
