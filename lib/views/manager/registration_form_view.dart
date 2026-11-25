import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';
import '../../viewmodels/manager_viewmodel.dart';

class RegistrationFormView extends StatefulWidget {
  const RegistrationFormView({super.key});

  @override
  State<RegistrationFormView> createState() => _RegistrationFormViewState();
}

class _RegistrationFormViewState extends State<RegistrationFormView> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  ManagerViewModel get vm => Get.find<ManagerViewModel>();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map && args['step'] is int) {
      vm.goToStep(args['step'] as int);
    }
  }

  String _stepSubtitle(int step) {
    switch (step) {
      case 1:
        return 'Step 1 of 4 · Hospital details';
      case 2:
        return 'Step 2 of 4 · Manager details';
      case 3:
        return 'Step 3 of 4 · Logo & documents';
      case 4:
      default:
        return 'Step 4 of 4 · Review & submit';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          final step = vm.currentStep.value;
          return Column(
            children: [
              // Top header + progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: vm.previousStep,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.chevron_left_rounded,
                              color: AppColors.textPrimary,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Register hospital',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _stepSubtitle(step),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tealPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(4, (index) {
                        final active = index < step;
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                            decoration: BoxDecoration(
                              color: active ? AppColors.tealPrimary : AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // Body content per step
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: _buildStepBody(step),
                ),
              ),

              // Bottom action bar
              _buildBottomActions(step),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepBody(int step) {
    switch (step) {
      case 1:
        return _buildStep1HospitalDetails();
      case 2:
        return _buildStep2ManagerDetails();
      case 3:
        return _buildStep3LogoAndDocs();
      case 4:
      default:
        return _buildStep4ReviewAndSubmit();
    }
  }

  // Step 1: Hospital details (supports Edit from M8)
  Widget _buildStep1HospitalDetails() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTealField(
            controller: vm.hospitalNameC,
            label: 'Hospital name',
            hint: 'City General Hospital',
            icon: Icons.local_hospital_outlined,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Hospital name is required' : null,
          ),
          const SizedBox(height: 16),
          const Text(
            'Hospital type',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Obx(() => DropdownButtonFormField<String>(
                value: vm.hospitalType.value,
                decoration: _tealInputDecoration(hint: 'Select type'),
                items: ManagerViewModel.hospitalTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) vm.hospitalType.value = val;
                },
              )),
          const SizedBox(height: 16),
          _buildTealField(
            controller: vm.cityC,
            label: 'City',
            hint: 'Karachi',
            icon: Icons.location_city_outlined,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'City is required' : null,
          ),
          const SizedBox(height: 16),
          _buildTealField(
            controller: vm.opdTimingsC,
            label: 'OPD timings',
            hint: '9:00 AM - 8:00 PM',
            icon: Icons.access_time_rounded,
          ),
          const SizedBox(height: 16),
          _buildTealField(
            controller: vm.addressC,
            label: 'Street address (optional)',
            hint: 'Block 4, Clifton, Karachi',
            icon: Icons.place_outlined,
          ),
        ],
      ),
    );
  }

  // Step 2 (M6): Manager details
  Widget _buildStep2ManagerDetails() {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTealField(
            controller: vm.managerNameC,
            label: 'Full name',
            hint: 'Dr. Farhan Ali',
            icon: Icons.person_outline_rounded,
            highlightBorder: true,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
          ),
          const SizedBox(height: 16),
          _buildTealField(
            controller: vm.managerEmailC,
            label: 'Work email',
            hint: 'farhan@cgh.pk',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Work email is required';
              if (!GetUtils.isEmail(v.trim())) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTealField(
            controller: vm.managerPhoneC,
            label: 'Mobile number',
            hint: '+92 300 5551234',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Mobile number is required' : null,
          ),
          const SizedBox(height: 16),
          const Text(
            'Designation',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Obx(() => DropdownButtonFormField<String>(
                value: vm.managerDesignation.value,
                decoration: _tealInputDecoration(hint: 'Select designation'),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                items: ManagerViewModel.designations
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) vm.managerDesignation.value = val;
                },
              )),
          const SizedBox(height: 20),
          Obx(() => InkWell(
                onTap: () => vm.isAuthorizedConfirmed.toggle(),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: vm.isAuthorizedConfirmed.value,
                        activeColor: AppColors.tealPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (v) => vm.isAuthorizedConfirmed.value = v ?? false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "I confirm I'm authorized to register and manage this hospital on Turnly.",
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // Step 3 (M7): Logo & documents
  Widget _buildStep3LogoAndDocs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dashed upload hospital logo card
        Obx(() {
          final hasLogo = vm.logoFileName.value.isNotEmpty;
          return GestureDetector(
            onTap: () => _pickFileFromDevice(
              title: 'Upload hospital logo',
              onSelected: (name, size, base64, mimeType) {
                vm.attachLogo(name: name, size: size, base64: base64);
              },
            ),
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: AppColors.tealBorder,
                radius: 14,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.tealLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.upload_rounded,
                        color: AppColors.tealPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hasLogo ? vm.logoFileName.value : 'Upload hospital logo',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasLogo
                          ? '${vm.logoFileSize.value} · Tap to change'
                          : 'PNG or JPG · up to 2 MB',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 22),
        const Text(
          'Verification documents',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Hospital license card
        Obx(() {
          final uploaded = vm.licenseDocName.value.isNotEmpty;
          return _buildDocumentCard(
            title: 'Hospital license',
            subtitle: uploaded
                ? '${vm.licenseDocName.value} · ${vm.licenseDocSize.value}'
                : 'Required · PDF or image (max 2 MB)',
            isUploaded: uploaded,
            onTap: () => _pickFileFromDevice(
              title: 'Upload hospital license',
              onSelected: (name, size, base64, mimeType) {
                vm.attachLicense(
                  name: name,
                  size: size,
                  base64: base64,
                  mimeType: mimeType,
                );
              },
            ),
          );
        }),
        const SizedBox(height: 12),

        // Registration certificate card
        Obx(() {
          final uploaded = vm.certificateDocName.value.isNotEmpty;
          return _buildDocumentCard(
            title: 'Registration certificate',
            subtitle: uploaded
                ? '${vm.certificateDocName.value} · ${vm.certificateDocSize.value}'
                : 'Optional · PDF or image (max 2 MB)',
            isUploaded: uploaded,
            onTap: () => _pickFileFromDevice(
              title: 'Upload registration certificate',
              onSelected: (name, size, base64, mimeType) {
                vm.attachCertificate(name: name, size: size);
              },
            ),
          );
        }),
        const SizedBox(height: 18),

        // Info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.infoBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.infoBorder),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.infoText,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Documents are only used by the Turnly admin team to verify your hospital.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.infoText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required bool isUploaded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUploaded ? AppColors.success.withOpacity(0.6) : AppColors.border,
            width: isUploaded ? 1.3 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isUploaded ? AppColors.successBg : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.description_outlined,
                color: isUploaded ? AppColors.tealPrimary : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isUploaded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Uploaded',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tealPrimary,
                  ),
                ),
              )
            else
              const Icon(
                Icons.add_rounded,
                color: AppColors.tealPrimary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  // Step 4 (M8): Review & submit
  Widget _buildStep4ReviewAndSubmit() {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReviewCard(
              title: 'Hospital',
              onEdit: () => vm.goToStep(1),
              rows: {
                'Name': vm.hospitalNameC.text.trim().isEmpty
                    ? 'City General Hospital'
                    : vm.hospitalNameC.text.trim(),
                'Type': vm.hospitalType.value,
                'City': vm.cityC.text.trim().isEmpty ? 'Karachi' : vm.cityC.text.trim(),
                'OPD': vm.opdTimingsC.text.trim().isEmpty
                    ? '9:00 AM - 8:00 PM'
                    : vm.opdTimingsC.text.trim(),
              },
            ),
            const SizedBox(height: 14),
            _buildReviewCard(
              title: 'Manager',
              onEdit: () => vm.goToStep(2),
              rows: {
                'Name': vm.managerNameC.text.trim().isEmpty
                    ? 'Dr. Farhan Ali'
                    : vm.managerNameC.text.trim(),
                'Email': vm.managerEmailC.text.trim().isEmpty
                    ? 'farhan@cgh.pk'
                    : vm.managerEmailC.text.trim(),
              },
            ),
            const SizedBox(height: 14),
            _buildReviewCard(
              title: 'Documents',
              onEdit: () => vm.goToStep(3),
              rows: {
                'License': vm.licenseDocName.value.isEmpty
                    ? 'license_cgh.pdf'
                    : vm.licenseDocName.value,
                'Certificate': vm.certificateDocName.value.isEmpty
                    ? 'cert_cgh.pdf'
                    : vm.certificateDocName.value,
              },
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () => vm.isTermsConfirmed.toggle(),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: vm.isTermsConfirmed.value,
                      activeColor: AppColors.tealPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (v) => vm.isTermsConfirmed.value = v ?? false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'I confirm the information above is accurate and agree to the Turnly Terms.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }

  Widget _buildReviewCard({
    required String title,
    required VoidCallback onEdit,
    required Map<String, String> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 15, color: AppColors.tealPrimary),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tealPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...rows.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      e.key,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(int step) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: step == 4
          ? SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: vm.isLoading.value ? null : vm.submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tealPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: vm.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit for approval',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            )
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: vm.previousStep,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (step == 1 && !_step1FormKey.currentState!.validate()) return;
                        if (step == 2) {
                          if (!_step2FormKey.currentState!.validate()) return;
                          if (!vm.isAuthorizedConfirmed.value) {
                            Get.snackbar(
                              'Authorization Required',
                              'Please confirm you are authorized to register this hospital.',
                              backgroundColor: Colors.orange.shade50,
                              colorText: Colors.orange.shade900,
                            );
                            return;
                          }
                        }
                        if (step == 3) {
                          if (vm.documentBase64.value.isEmpty && vm.licenseDocName.value.isEmpty) {
                            Get.snackbar(
                              'Document Required',
                              'Please attach a hospital license or verification document (PDF/Image) before proceeding.',
                              backgroundColor: Colors.orange.shade50,
                              colorText: Colors.orange.shade900,
                            );
                            return;
                          }
                        }
                        vm.nextStep();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tealPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTealField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool highlightBorder = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: _tealInputDecoration(
            hint: hint,
            icon: icon,
            highlightBorder: highlightBorder,
          ),
        ),
      ],
    );
  }

  InputDecoration _tealInputDecoration({
    required String hint,
    IconData? icon,
    bool highlightBorder = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
      prefixIcon: icon != null
          ? Icon(icon, color: AppColors.textSecondary, size: 20)
          : null,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: highlightBorder ? AppColors.tealPrimary : AppColors.border,
          width: highlightBorder ? 1.4 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.tealPrimary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  // Real file picker method for logo and documents (PDF, PNG, JPG only, max 2 MB)
  Future<void> _pickFileFromDevice({
    required String title,
    required void Function(String name, String size, String base64, String mimeType) onSelected,
  }) async {
    try {
      final files = await FilePicker.pickFiles(
        dialogTitle: title,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (files.isEmpty) return;

      final file = files.first;

      // 1. File size validation (Maximum 2 MB)
      final bytesLength = await file.length() ?? 0;
      final sizeInMB = bytesLength / (1024 * 1024);
      if (sizeInMB > 2.0) {
        Get.snackbar(
          'File Too Large',
          'Please select a file smaller than 2 MB (Selected: ${sizeInMB.toStringAsFixed(1)} MB)',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
        return;
      }

      // 2. Format file size label
      final kb = bytesLength / 1024;
      final sizeString = kb > 1024
          ? '${(kb / 1024).toStringAsFixed(1)} MB'
          : '${kb.toStringAsFixed(0)} KB';

      // 3. Read bytes and convert to Base64 for BYTEA database storage
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        Get.snackbar(
          'Error',
          'Selected file is empty. Please choose a valid file.',
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800,
        );
        return;
      }
      final base64String = base64Encode(bytes);

      // 4. Determine file MIME type
      final ext = file.extension?.toLowerCase() ?? '';
      final mimeType = (ext == 'pdf')
          ? 'application/pdf'
          : (ext == 'png' ? 'image/png' : 'image/jpeg');

      onSelected(file.name, sizeString, base64String, mimeType);

      Get.snackbar(
        'Attached',
        '${file.name} selected successfully',
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick file: $e',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
      );
    }
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
