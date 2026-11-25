import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_endpoints.dart';
import '../../utils/app_colors.dart';
import '../../viewmodels/admin_viewmodel.dart';

class ReviewRegistrationView extends StatefulWidget {
  final Map<String, dynamic> hospital;

  const ReviewRegistrationView({super.key, required this.hospital});

  @override
  State<ReviewRegistrationView> createState() => _ReviewRegistrationViewState();
}

class _ReviewRegistrationViewState extends State<ReviewRegistrationView> {
  final TextEditingController _rejectionController = TextEditingController();
  final AdminViewModel _adminVm = Get.find<AdminViewModel>();

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
  }

  /// Open a URL in the external browser / PDF viewer
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Error', 'Could not open: $url');
      }
    } catch (_) {
      Get.snackbar('Error', 'Unable to open file');
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hospital;
    final name = h['name'] ?? 'Hospital';
    final city = h['city'] ?? '';
    final address = (h['address'] != null && h['address'].toString().trim().isNotEmpty)
        ? h['address'].toString()
        : 'Not specified';
    final phone = (h['phone'] != null && h['phone'].toString().trim().isNotEmpty)
        ? h['phone'].toString()
        : 'Not specified';
    final type = (h['type'] != null && h['type'].toString().trim().isNotEmpty)
        ? h['type'].toString()
        : 'Not specified';
    final opdTimings = (h['opd_timings'] != null && h['opd_timings'].toString().trim().isNotEmpty)
        ? h['opd_timings'].toString()
        : 'Not specified';
    final managerName = h['manager_name'] ?? 'Not assigned';
    final managerEmail = h['manager_email'] ?? '';
    final hospitalId = h['id'] as int? ?? 0;
    final status = (h['status'] ?? 'pending').toString().toLowerCase();

    // ── License document (file 1) ──
    final rawDocName = h['document_name'] ?? h['license_doc_name'];
    final bool hasDoc = (h['has_document'] == true) ||
        (rawDocName != null &&
            rawDocName.toString().trim().isNotEmpty &&
            rawDocName.toString() != 'null');
    final licenseDocName = hasDoc ? rawDocName.toString() : '';
    final licenseDocSize = h['license_doc_size']?.toString() ?? '';

    // ── Registration certificate (file 2) ──
    final rawCertName = h['certificate_doc_name'];
    final bool hasCert = (h['has_certificate'] == true) ||
        (rawCertName != null &&
            rawCertName.toString().trim().isNotEmpty &&
            rawCertName.toString() != 'null');
    final certDocName = hasCert ? rawCertName.toString() : '';
    final certDocSize = h['certificate_doc_size']?.toString() ?? '';

    // ── Hospital logo (file 3) ──
    final rawLogoName = h['logo_name'];
    final bool hasLogo = (h['has_logo'] == true) ||
        (rawLogoName != null &&
            rawLogoName.toString().trim().isNotEmpty &&
            rawLogoName.toString() != 'null');
    final logoFileName = hasLogo ? rawLogoName.toString() : '';

    // Status badge
    final Color statusBg;
    final Color statusText;
    final String statusLabel;

    switch (status) {
      case 'approved':
        statusBg = AppColors.adminApprovedBg;
        statusText = AppColors.adminApprovedText;
        statusLabel = 'Approved';
        break;
      case 'suspended':
        statusBg = AppColors.adminSuspendedBg;
        statusText = AppColors.adminSuspendedText;
        statusLabel = 'Suspended';
        break;
      case 'rejected':
        statusBg = AppColors.adminRejectBg;
        statusText = AppColors.adminRejectText;
        statusLabel = 'Rejected';
        break;
      default:
        statusBg = AppColors.adminPendingBg;
        statusText = AppColors.adminPendingText;
        statusLabel = 'Pending review';
    }

    // Generate initials (e.g. 'City General Hospital' -> 'CG')
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words.length >= 2
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Review registration',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.adminPrimaryLight,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.adminPrimaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Hospital specs table card ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Type', type),
                  _buildDivider(),
                  _buildDetailRow('City', city),
                  _buildDivider(),
                  _buildDetailRow('Address', address),
                  _buildDivider(),
                  _buildDetailRow('Phone', phone),
                  _buildDivider(),
                  _buildDetailRow('OPD timings', opdTimings),
                  _buildDivider(),
                  _buildDetailRow(
                    'Manager',
                    managerEmail.isNotEmpty ? '$managerName · $managerEmail' : managerName,
                  ),
                  _buildDivider(),
                  _buildDetailRow('Submitted', 'Recently submitted'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Verification Documents card (3 tiles) ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.folder_shared_outlined, color: AppColors.adminPrimary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Verification Documents',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tile 1 — Hospital Logo
                  _buildDocTile(
                    label: '1. Hospital Logo',
                    fileName: logoFileName.isNotEmpty ? logoFileName : null,
                    iconData: Icons.image_outlined,
                    iconColor: Colors.teal,
                    iconBg: Colors.teal.shade50,
                    onView: hasLogo
                        ? () => _openUrl(ApiEndpoints.hospitalLogoUrl(hospitalId))
                        : null,
                  ),
                  const SizedBox(height: 10),

                  // Tile 2 — Hospital License
                  _buildDocTile(
                    label: '2. Hospital License',
                    fileName: licenseDocName.isNotEmpty ? licenseDocName : null,
                    fileSize: licenseDocSize,
                    iconData: Icons.picture_as_pdf_rounded,
                    iconColor: Colors.red.shade700,
                    iconBg: Colors.red.shade50,
                    onView: hasDoc
                        ? () => _openUrl(ApiEndpoints.hospitalDocumentUrl(hospitalId))
                        : null,
                  ),
                  const SizedBox(height: 10),

                  // Tile 3 — Registration Certificate (optional)
                  _buildDocTile(
                    label: '3. Registration Certificate',
                    fileName: certDocName.isNotEmpty ? certDocName : null,
                    fileSize: certDocSize,
                    isOptional: true,
                    iconData: Icons.verified_outlined,
                    iconColor: Colors.indigo.shade700,
                    iconBg: Colors.indigo.shade50,
                    onView: hasCert
                        ? () => _openUrl(ApiEndpoints.hospitalCertificateUrl(hospitalId))
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Rejection note + action buttons (pending only) ──
            if (status == 'pending') ...[
              const Text(
                'Rejection note (optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _rejectionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a reason if rejecting...',
                  hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.adminPrimary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Approve button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await _adminVm.approveHospital(hospitalId);
                    if (success) {
                      Get.back();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminPrimary,
                    foregroundColor: AppColors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Approve hospital',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Reject button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () async {
                    final success = await _adminVm.rejectHospital(
                      hospitalId,
                      reason: _rejectionController.text.trim(),
                    );
                    if (success) {
                      Get.back();
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.adminRejectText,
                  ),
                  child: const Text(
                    'Reject registration',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Single document tile used for all three file types.
  /// Shows a "Missing" badge when [fileName] is null, otherwise shows file name + View button.
  Widget _buildDocTile({
    required String label,
    required String? fileName,
    String fileSize = '',
    bool isOptional = false,
    required IconData iconData,
    required Color iconColor,
    required Color iconBg,
    VoidCallback? onView,
  }) {
    final bool uploaded = fileName != null && fileName.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              if (isOptional) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'optional',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        ),

        // File tile
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: uploaded ? AppColors.border : Colors.orange.shade200,
            ),
          ),
          child: Row(
            children: [
              // Icon box
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: uploaded ? iconBg : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  uploaded ? iconData : Icons.upload_file_outlined,
                  color: uploaded ? iconColor : Colors.grey.shade500,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Name + size
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uploaded ? fileName : (isOptional ? 'Not uploaded' : 'No file attached'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: uploaded ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    if (uploaded && fileSize.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        fileSize,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // View button or Missing badge
              if (uploaded && onView != null)
                TextButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.adminPrimary,
                    backgroundColor: AppColors.adminPendingBg,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOptional ? Colors.grey.shade100 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOptional ? Colors.grey.shade300 : Colors.orange.shade200,
                    ),
                  ),
                  child: Text(
                    isOptional ? 'N/A' : 'Missing',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isOptional ? Colors.grey.shade600 : Colors.orange.shade800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: AppColors.divider);
  }
}
