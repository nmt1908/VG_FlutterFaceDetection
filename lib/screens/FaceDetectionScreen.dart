import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:face_camera/face_camera.dart';
import 'package:cross_file/cross_file.dart';

class FacePreviewScreen extends StatefulWidget {
  const FacePreviewScreen({super.key});

  @override
  State<FacePreviewScreen> createState() => _FacePreviewScreenState();
}

class _FacePreviewScreenState extends State<FacePreviewScreen> {
  late final FaceCameraController controller;
  Timer? _timer;
  bool _faceLookingStraight = false;
  bool _takePicture = false;
  XFile? _capturedImage;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () async {
      setState(() {
        _takePicture = true;
      });
      try {
        final picture = await controller.takePicture();
        setState(() {
          _capturedImage = picture;
        });
      } catch (e) {
        print("Error taking picture: $e");
      }

      // Hiển thị ảnh 1 giây rồi ẩn
      Timer(const Duration(seconds: 1), () {
        setState(() {
          _takePicture = false;
          _capturedImage = null;
          _timer = null; // reset timer để có thể tạo timer mới khi cần
        });
      });
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _takePicture = false;
      _capturedImage = null;
    });
  }

  @override
  void initState() {
    super.initState();
    controller = FaceCameraController(
      autoCapture: false,
      defaultCameraLens: CameraLens.front,
      onFaceDetected: (face) {
        if (face == null) {
          _faceLookingStraight = false;
          _resetTimer();
          return;
        }
        final angleY = face.headEulerAngleY ?? 1000;

        if (angleY >= -10 && angleY <= 10) {
          if (!_faceLookingStraight) {
            _faceLookingStraight = true;
            _startTimer();
          }
        } else {
          _faceLookingStraight = false;
          _resetTimer();
        }
      },
      onCapture: (_) {},
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            SmartFaceCamera(
              controller: controller,
              showControls: false,
              showFlashControl: false,
              showCaptureControl: false,
              showCameraLensControl: false,
              message: null,
              indicatorShape: IndicatorShape.circle,
            ),

            Positioned(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 59, 58, 58).withOpacity(0.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 90,
                      height: 90,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Face Detection',
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_capturedImage != null)
              Center(
                child: Image.file(
                  File(_capturedImage!.path),
                  width: 500,
                  fit: BoxFit.fitWidth, // Giữ tỉ lệ ảnh theo width
                ),
              ),
          ],
        ),
      ),
    );
  }
}
