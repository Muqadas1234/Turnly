import 'package:get/get.dart';
import '../services/api_service.dart';

/// Patient-side state shared by the home, hospital, doctor, booking and token screens.
class PatientViewModel extends GetxController {
  final isLoadingHospitals = false.obs;
  final isLoadingDetails = false.obs;
  final isLoadingTokens = false.obs;
  final errorMessage = ''.obs;

  // Compatibility alias used by PatientHomeTab.
  RxBool get isLoading => isLoadingHospitals;

  final hospitals = <Map<String, dynamic>>[].obs;
  final availableCities = <String>['All'].obs;
  final selectedCity = 'All'.obs;
  final currentSearchQuery = ''.obs;
  final currentHospital = Rxn<Map<String, dynamic>>();
  final departments = <Map<String, dynamic>>[].obs;
  final doctors = <Map<String, dynamic>>[].obs;
  final selectedDepartmentId = RxnInt();
  final selectedDoctor = Rxn<Map<String, dynamic>>();
  final activeTokens = <Map<String, dynamic>>[].obs;
  final historyTokens = <Map<String, dynamic>>[].obs;
  final activeToken = Rxn<Map<String, dynamic>>();
  final familyMembers = <Map<String, dynamic>>[].obs;
  // Guards against out-of-order responses (fast typing / rapid chip taps / reopening a hospital).
  int _hospitalsGen = 0;
  int _detailsGen = 0;

  List<Map<String, dynamic>> get filteredDoctors {
    final id = selectedDepartmentId.value;
    if (id == null) return doctors.toList();
    return doctors.where((d) => _asInt(d['department_id']) == id).toList();
  }

  bool _isAvailable(Map<String, dynamic> d) => d['is_available'] != false;

  /// First bookable doctor of a department (null when none is available).
  Map<String, dynamic>? _firstAvailableDoctor(int? departmentId) {
    for (final d in doctors) {
      if (departmentId != null && _asInt(d['department_id']) != departmentId) continue;
      if (_isAvailable(d)) return d;
    }
    return null;
  }

  int? _asInt(dynamic value) =>
      value == null ? null : int.tryParse(value.toString());

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (value is Map) {
      for (final key in const [
        'data',
        'items',
        'results',
        'hospitals',
        'tokens',
        'doctors',
        'departments',
        'family_members',
      ]) {
        final nested = value[key];
        if (nested is List) return _mapList(nested);
        if (nested is Map) {
          final result = _mapList(nested);
          if (result.isNotEmpty) return result;
        }
      }
    }
    return [];
  }

  @override
  void onInit() {
    super.onInit();
    _loadCityCatalog();
    fetchHospitals();
    fetchActiveToken();
  }

  /// City chips come from the UNFILTERED hospital list so they never disappear
  /// while a search or city filter is active.
  Future<void> _loadCityCatalog() async {
    try {
      final response = await ApiService.getHospitals();
      if (response['success'] != true) return;
      final list = _mapList(response['hospitals'] ?? response['data']);
      final cities = list
          .map((h) => h['city']?.toString().trim() ?? '')
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      availableCities.assignAll(['All', ...cities]);
      if (!availableCities.contains(selectedCity.value)) selectedCity.value = 'All';
    } catch (_) {
      // chips fall back to whatever the filtered list provides
    }
  }

  Future<void> fetchHospitals({String? search, String? city}) async {
    final gen = ++_hospitalsGen;
    isLoadingHospitals.value = true;
    errorMessage.value = '';
    try {
      final response = await ApiService.getHospitals(
        search: search ?? (currentSearchQuery.value.isEmpty ? null : currentSearchQuery.value),
        city: city ?? (selectedCity.value == 'All' ? null : selectedCity.value),
      );
      if (gen != _hospitalsGen) return; // a newer request superseded this one
      if (response['success'] == true) {
        final raw = response['hospitals'] ?? response['data'];
        final list = _mapList(raw);
        hospitals.assignAll(list);
        if (availableCities.length <= 1) {
          final cities = list
              .map((h) => h['city']?.toString().trim() ?? '')
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          if (cities.isNotEmpty) availableCities.assignAll(['All', ...cities]);
        }
        if (!availableCities.contains(selectedCity.value)) {
          selectedCity.value = 'All';
        }
      } else {
        errorMessage.value =
            response['message']?.toString() ?? 'Hospitals could not be loaded';
      }
    } catch (e) {
      errorMessage.value = 'Could not connect to Turnly API: $e';
    } finally {
      if (gen == _hospitalsGen) isLoadingHospitals.value = false;
    }
  }

  Future<void> search(String query) async {
    currentSearchQuery.value = query.trim();
    // Searching looks across every city, so the city chip goes back to "All".
    if (currentSearchQuery.value.isNotEmpty) selectedCity.value = 'All';
    await fetchHospitals(
      search: currentSearchQuery.value,
      city: selectedCity.value == 'All' ? null : selectedCity.value,
    );
  }

  Future<void> setCityFilter(String city) async {
    selectedCity.value = city;
    await fetchHospitals(city: city == 'All' ? null : city);
  }

  Future<void> refreshCatalog() async {
    await Future.wait([_loadCityCatalog(), fetchHospitals(), fetchActiveToken()]);
  }

  Future<void> fetchActiveToken() async {
    await fetchTokens(scope: 'active');
  }

  Future<void> fetchHospitalDetails(int hospitalId) async {
    if (hospitalId <= 0) {
      errorMessage.value = 'Invalid hospital selected';
      return;
    }
    final gen = ++_detailsGen;
    isLoadingDetails.value = true;
    errorMessage.value = '';
    selectedDoctor.value = null;
    currentHospital.value = null;
    departments.clear();
    doctors.clear();
    selectedDepartmentId.value = null;
    try {
      final results = await Future.wait([
        ApiService.getHospitalDetail(hospitalId),
        ApiService.getHospitalDepartments(hospitalId),
        ApiService.getHospitalDoctors(hospitalId),
      ]);
      if (gen != _detailsGen) return;
      final hospitalResponse = results[0];
      final departmentResponse = results[1];
      final doctorResponse = results[2];
      if (hospitalResponse['success'] != true) {
        throw Exception(hospitalResponse['message'] ?? 'Hospital not found');
      }
      final hospitalData =
          hospitalResponse['hospital'] ?? hospitalResponse['data'];
      currentHospital.value = hospitalData is Map
          ? Map<String, dynamic>.from(hospitalData)
          : <String, dynamic>{};
      departments.assignAll(_mapList(
        departmentResponse['departments'] ?? departmentResponse['data'],
      ));
      doctors.assignAll(_mapList(
        doctorResponse['doctors'] ?? doctorResponse['data'],
      ));
      selectedDepartmentId.value =
          departments.isEmpty ? null : _asInt(departments.first['id'] ?? departments.first['department_id']);
      selectedDoctor.value = _firstAvailableDoctor(selectedDepartmentId.value);
    } catch (e) {
      if (gen == _detailsGen) {
        errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      if (gen == _detailsGen) isLoadingDetails.value = false;
    }
  }

  void selectDepartment(dynamic id) {
    selectedDepartmentId.value = _asInt(id);
    selectedDoctor.value = _firstAvailableDoctor(selectedDepartmentId.value);
  }

  void selectDoctor(Map<String, dynamic> doctor) {
    selectedDoctor.value = doctor;
  }

  Future<void> fetchTokens({String scope = 'active'}) async {
    isLoadingTokens.value = true;
    try {
      final response = await ApiService.getMyTokens(scope: scope);
      if (response['success'] == true) {
        final list = _mapList(response['tokens'] ?? response['data']);
        if (scope == 'history') {
          historyTokens.assignAll(list);
        } else {
          activeTokens.assignAll(list);
          activeToken.value = list.isEmpty ? null : list.first;
        }
      } else {
        errorMessage.value =
            response['message']?.toString() ?? 'Tokens could not be loaded';
      }
    } catch (e) {
      errorMessage.value = 'Could not load tokens: $e';
    } finally {
      isLoadingTokens.value = false;
    }
  }

  Future<Map<String, dynamic>> book({
    required int doctorId,
    DateTime? date,
    int? familyMemberId,
  }) async {
    final dateText = date == null
        ? null
        : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await ApiService.bookToken(
      doctorId: doctorId,
      date: dateText,
      familyMemberId: familyMemberId,
    );
    if (response['success'] == true) await fetchTokens();
    return response;
  }

  Future<Map<String, dynamic>> fetchTokenDetail(int tokenId) =>
      ApiService.getTokenDetail(tokenId);

  Future<Map<String, dynamic>> cancelToken(int tokenId) async {
    final response = await ApiService.cancelMyToken(tokenId);
    if (response['success'] == true) await fetchTokens();
    return response;
  }

  Future<void> fetchFamilyMembers() async {
    try {
      final response = await ApiService.getFamilyMembers();
      if (response['success'] == true) {
        familyMembers.assignAll(_mapList(
          response['family_members'] ?? response['data'],
        ));
      } else {
        errorMessage.value =
            response['message']?.toString() ?? 'Family members could not be loaded';
      }
    } catch (e) {
      errorMessage.value = 'Could not load family members: $e';
    }
  }

  Future<Map<String, dynamic>> createFamilyMember({
    required String name,
    required String relation,
    required int age,
  }) async {
    final response = await ApiService.addFamilyMember(
      name: name,
      relation: relation,
      age: age,
    );
    if (response['success'] == true) await fetchFamilyMembers();
    return response;
  }
}
