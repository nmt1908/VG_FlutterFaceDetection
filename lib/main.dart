// lib/main.dart

import 'package:flutter/material.dart';
import 'package:face_camera/face_camera.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'screens/FaceDetectionScreen.dart';
import 'models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/MenuScreen.dart';
import 'package:demo/utils/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FaceCamera.initialize();
  debugPrint("🏁 App khởi động");
  final user = await getUserSession();
  runApp(
    DevicePreview(
      enabled: false, // 👉 Tắt khi build release
      builder: (context) =>  MyApp(initialUser: user),
    ),
  );
}

class MyApp extends StatelessWidget {
  final User? initialUser;
  const MyApp({super.key, required this.initialUser});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // Thiết kế theo iPhone 13/14
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          useInheritedMediaQuery: true,
          builder: DevicePreview.appBuilder, // Device preview support
          debugShowCheckedModeBanner: false,
          home: initialUser == null
              ? const FacePreviewScreen()
              : MenuScreen(activeUser: initialUser!),
        );
      },
    );
  }
}

