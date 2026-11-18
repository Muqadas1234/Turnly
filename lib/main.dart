import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'utils/app_bindings.dart';
import 'utils/app_colors.dart';
import 'utils/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Push notifications need `flutterfire configure`. Auth uses the Node API.
  }
  runApp(const TurnlyApp());
}

class TurnlyApp extends StatelessWidget {
  const TurnlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Turnly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      initialBinding: AppBindings(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
    );
  }
}
