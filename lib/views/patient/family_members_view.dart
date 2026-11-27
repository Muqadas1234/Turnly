import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../viewmodels/patient_viewmodel.dart';

class FamilyMembersView extends StatefulWidget {
  const FamilyMembersView({super.key});
  @override
  State<FamilyMembersView> createState() => _FamilyMembersViewState();
}

class _FamilyMembersViewState extends State<FamilyMembersView> {
  final PatientViewModel vm = Get.find<PatientViewModel>();
  final name = TextEditingController();
  final relation = TextEditingController();
  final age = TextEditingController();

  @override
  void initState() { super.initState(); vm.fetchFamilyMembers(); }
  @override
  void dispose() { name.dispose(); relation.dispose(); age.dispose(); super.dispose(); }

  Future<void> add() async {
    final n = name.text.trim(); final r = relation.text.trim(); final a = int.tryParse(age.text.trim());
    if (n.length < 2 || r.isEmpty || a == null || a < 0 || a > 120) {
      Get.snackbar('Check details', 'Enter a valid name, relation and age (0–120).'); return;
    }
    final result = await vm.createFamilyMember(name: n, relation: r, age: a);
    if (result['success'] == true) { name.clear(); relation.clear(); age.clear(); Get.back(); Get.snackbar('Saved', 'Family member added.'); }
    else { Get.snackbar('Unable to save', '${result['message'] ?? ''}'); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Family members'), backgroundColor: Colors.white, foregroundColor: AppColors.textPrimary, elevation: 0),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => Get.dialog(AlertDialog(
      title: const Text('Add family member'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
        TextField(controller: relation, decoration: const InputDecoration(labelText: 'Relation')),
        TextField(controller: age, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age')),
      ]),
      actions: [TextButton(onPressed: () => Get.back(), child: const Text('Cancel')), ElevatedButton(onPressed: add, child: const Text('Save'))],
    )), icon: const Icon(Icons.person_add_alt_1), label: const Text('Add member')),
    body: Obx(() {
      if (vm.familyMembers.isEmpty) return const Center(child: Text('No family members saved yet.'));
      return ListView.builder(padding: const EdgeInsets.all(16), itemCount: vm.familyMembers.length, itemBuilder: (_, i) {
        final m = vm.familyMembers[i];
        return Card(elevation: 0, child: ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text('${m['name'] ?? ''}'), subtitle: Text('${m['relation'] ?? ''} · ${m['age'] ?? ''} years')));
      });
    }),
  );
}
