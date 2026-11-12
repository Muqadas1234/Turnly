import 'package:flutter/material.dart';

import '../../widgets/session_home.dart';

class AdminPanelView extends StatelessWidget {
  const AdminPanelView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SessionHome(
      title: 'Admin',
      subtitle: 'You are signed in as an admin.',
    );
  }
}
