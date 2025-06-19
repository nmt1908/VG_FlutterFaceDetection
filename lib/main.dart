// lib/main.dart

import 'package:flutter/material.dart';
import 'package:face_camera/face_camera.dart';
import 'screens/FaceDetectionScreen.dart'; // 👈 Import màn hình vừa tách

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FaceCamera.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FacePreviewScreen(), 
      debugShowCheckedModeBanner: false,
    );
  }
}
