import 'package:flutter/material.dart';
import 'package:user_mobile/features/auth/screens/role_selection_screen.dart';
import 'package:user_mobile/features/blind_mode/screens/blind_dashboard_screen.dart';
import 'package:user_mobile/features/blind_mode/screens/glasses_connection_screen.dart';
import 'package:user_mobile/features/caregiver_mode/screens/caregiver_dashboard_screen.dart';
import 'package:user_mobile/features/caregiver_mode/screens/caregiver_profile_screen.dart';
import 'package:user_mobile/features/caregiver_mode/screens/caregiver_main_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Drishti',
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.deepPurple),
      // home: const CaregiverMainScreen(),
      // home: const RoleSelectionScreen(),
      // home: const BlindDashboardScreen(),
      home: const GlassesConnectionScreen(),
      
    );
  }
}
