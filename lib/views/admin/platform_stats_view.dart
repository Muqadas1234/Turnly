import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodels/admin_viewmodel.dart';

class PlatformStatsView extends StatelessWidget {
const PlatformStatsView({super.key});

@override
Widget build(BuildContext context) {
final vm = Get.find<AdminViewModel>();

return SafeArea(
child: RefreshIndicator(
onRefresh: () async {
await vm.fetchStats();
await vm.fetchApprovedHospitals();
},
color: Colors.teal,
child: SingleChildScrollView(
physics: const AlwaysScrollableScrollPhysics(),
padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// Header row
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
const Text(
'Platform stats',
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
color: Colors.black87,
),
),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 14,
vertical: 6,
),
decoration: BoxDecoration(
color: Colors.teal,
borderRadius: BorderRadius.circular(16),
),
child: const Text(
'Today',
style: TextStyle(
color: Colors.white,
fontSize: 12,
fontWeight: FontWeight.w600,
),
),
),
],
),
const SizedBox(height: 20),

// 2x2 Real Live Database Metrics Grid
Obx(() {
final stats = vm.platformStats;
final totalHospitals =
stats['totalHospitals'] ?? vm.approvedCount.value;
final activeQueues = stats['activeQueues'] ?? 0;
final tokensToday = stats['tokensToday'] ?? 0;
final totalPatients = stats['totalPatients'] ?? 0;

return Column(
children: [
Row(
children: [
Expanded(
child: _buildMetricCard(
icon: Icons.local_hospital_rounded,
iconColor: Colors.teal.shade700,
iconBg: Colors.teal.shade50,
value: '$totalHospitals',
label: 'Total hospitals',
),
),
const SizedBox(width: 14),
Expanded(
child: _buildMetricCard(
icon: Icons.show_chart_rounded,
iconColor: Colors.blue.shade700,
iconBg: Colors.blue.shade50,
value: '$activeQueues',
label: 'Active queues',
),
),
],
),
const SizedBox(height: 14),
Row(
children: [
Expanded(
child: _buildMetricCard(
icon: Icons.confirmation_number_rounded,
iconColor: Colors.amber.shade800,
iconBg: Colors.amber.shade50,
value: '$tokensToday',
label: 'Tokens today',
),
),
const SizedBox(width: 14),
Expanded(
child: _buildMetricCard(
icon: Icons.people_alt_rounded,
iconColor: Colors.purple.shade700,
iconBg: Colors.purple.shade50,
value: totalPatients >= 1000
? '${(totalPatients / 1000).toStringAsFixed(1)}k'
: '$totalPatients',
label: 'Patients',
),
),
],
),
],
);
}),
const SizedBox(height: 24),

// Section: Tokens issued per hospital
Obx(() {
final rawList = vm.platformStats['tokensPerHospital'];
final tokensList = (rawList is List) ? rawList : [];
final colors = [
Colors.teal,
Colors.blue,
Colors.purple,
Colors.orange,
Colors.indigo,
];

final maxTokens = tokensList.fold<int>(
1,
(max, item) {
final count =
int.tryParse(item['token_count']?.toString() ?? '0') ??
0;
return count > max ? count : max;
},
);

return Container(
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: Colors.grey.shade200),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Tokens issued per hospital',
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.bold,
color: Colors.black87,
),
),
const SizedBox(height: 16),
if (tokensList.isEmpty)
Padding(
padding: const EdgeInsets.symmetric(vertical: 8),
child: Text(
'No token data available yet',
style: TextStyle(
fontSize: 13,
color: Colors.grey.shade600,
),
),
)
else
...tokensList.asMap().entries.map((entry) {
final idx = entry.key;
final item = entry.value as Map;
final hospitalName =
(item['name'] ?? 'Hospital').toString();
final count = int.tryParse(
item['token_count']?.toString() ?? '0') ??
0;
final color = colors[idx % colors.length];

return Padding(
padding: EdgeInsets.only(
bottom: idx == tokensList.length - 1 ? 0 : 12,
),
child: _buildHospitalProgressBar(
hospitalName,
count,
maxTokens,
color,
),
);
}),
],
),
);
}),
const SizedBox(height: 24),

// Section: Manage hospitals Header with "See all"
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
const Text(
'Manage hospitals',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
color: Colors.black87,
),
),
TextButton(
onPressed: () {
// Switch to the 'Hospitals' tab (index 2)
vm.selectedTab.value = 2;
vm.fetchApprovedHospitals();
},
style: TextButton.styleFrom(
foregroundColor: Colors.teal,
padding: EdgeInsets.zero,
),
child: const Text(
'See all',
style: TextStyle(fontWeight: FontWeight.w600),
),
),
],
),
const SizedBox(height: 12),

// Manage hospital tiles from live database (vm.approvedHospitals)
Obx(() {
final approvedList = vm.approvedHospitals;
if (approvedList.isEmpty) {
return Container(
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(14),
border: Border.all(color: Colors.grey.shade200),
),
child: Center(
child: Text(
'No active approved hospitals found',
style: TextStyle(
color: Colors.grey.shade600,
  fontSize: 13,
),
),
),
);
}
// Show the first approved hospital from live database
  final hospital = approvedList.first;
  final hospitalId =
      int.tryParse(hospital['id']?.toString() ?? '0') ?? 0;
  final name = (hospital['name'] ?? 'Hospital').toString().trim();
  final words = name.split(RegExp(r'\s+'));
  final initials = words.length >= 2
      ? '${words[0][0]}${words[1][0]}'.toUpperCase()
      : name
      .substring(0, name.length >= 2 ? 2 : name.length)
      .toUpperCase();
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blue.shade50,
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () =>
              _confirmSuspend(context, vm, hospitalId, name),
          style: TextButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block_rounded,
                size: 14,
                color: Colors.red.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                'Suspend',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}),
  const SizedBox(height: 20),
],
),
),
),
);
}
// Confirmation dialog before suspending a hospital
  void _confirmSuspend(
      BuildContext context,
      AdminViewModel vm,
      int hospitalId,
      String hospitalName,
      ) {
    Get.dialog(
      AlertDialog(
        title: const Text(
          'Suspend Hospital',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to suspend $hospitalName? Patients will no longer be able to book tokens.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await vm.suspendHospital(hospitalId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Suspend',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
// Metric card widget
  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
// Progress bar for tokens issued per hospital
  Widget _buildHospitalProgressBar(
      String name,
      int tokens,
      int maxTokens,
      Color barColor,
      ) {
    final ratio = (tokens / (maxTokens == 0 ? 1 : maxTokens)).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 95,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 32,
          child: Text(
            '$tokens',
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}